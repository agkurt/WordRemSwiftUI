// Telefondan gelen kaydı kurgu dosyasına çevirir:
//   node prep.mjs es01                      →  public/clips/es01.mp4 + edits/es01.json
//   node prep.mjs es01 --skip 0-8 --skip 26.4-37.4   →  kaynak videodan bu aralıklar atılır (saniye)
// Konuşma sınırları kayıttaki gerçek sesten ölçülür; elle düzeltilen metinler (aynı orijinal cümle) korunur.
import fs from "node:fs";
import { execFileSync } from "node:child_process";

const id = process.argv[2];
if (!id) throw new Error("kullanım: node prep.mjs <id> [--skip a-b]...");
const skips = process.argv.flatMap((a, i, all) => (a === "--skip" ? [all[i + 1].split("-").map(Number)] : []));
const inbox = new URL("../inbox/", import.meta.url);
const timeline = JSON.parse(fs.readFileSync(new URL(`${id}.json`, inbox)));
const script = JSON.parse(fs.readFileSync(new URL(`../studio/${id}.json`, import.meta.url)));

fs.mkdirSync("public/clips", { recursive: true });
fs.copyFileSync(new URL(`${id}.mp4`, inbox), `public/clips/${id}.mp4`);
const probe = execFileSync("npx", ["remotion", "ffprobe", "-v", "error", "-select_streams", "v:0",
  "-show_entries", "stream=width,height:format=duration", "-of", "json", `public/clips/${id}.mp4`]).toString();
const meta = JSON.parse(probe);
const { width, height } = meta.streams[0];
const duration = Number(meta.format.duration);

// Ses zarfı (20 ms): kimin gerçekten ne zaman konuştuğu buradan ölçülür
const wavPath = `public/clips/${id}.wav`;
execFileSync("npx", ["remotion", "ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", `public/clips/${id}.mp4`,
  "-vn", "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le", wavPath]);
const pcm = new Int16Array(fs.readFileSync(wavPath).buffer.slice(44));
fs.rmSync(wavPath);
const STEP = 0.02;
const env = [];
for (let i = 0; i + 320 <= pcm.length; i += 320) {
  let sum = 0;
  for (let j = i; j < i + 320; j++) sum += pcm[j] * pcm[j];
  env.push(Math.sqrt(sum / 320));
}
const loud = [...env].sort((a, b) => a - b)[Math.floor(env.length * 0.95)] ?? 1000;
const TH = Math.max(300, loud * 0.08);
/** [lo, hi] içindeki ilk ve son konuşma (en az 60 ms süren ses) */
const speech = (lo, hi) => {
  let first = null, last = null, run = 0;
  for (let i = Math.max(0, Math.floor(lo / STEP)); i < Math.min(env.length, Math.ceil(hi / STEP)); i++) {
    run = env[i] > TH ? run + 1 : 0;
    if (run === 3) { first ??= (i - 2) * STEP; }
    if (run >= 3) last = (i + 1) * STEP;
  }
  return first == null ? null : { from: first, to: last };
};

const turns = timeline.turns;
const clean = (s) => s.trim().replace(/^"(.*)"$/s, "$1");
const lines = [];
const cards = [];
let lupa = null;
for (const e of timeline.events) {
  if (e.ev === "turn" && e.role === "ai") {
    // Aynı cevap içinde ses kısa bir an kesilirse yeni satır açılmaz
    if (lupa && lupa.end == null) lupa.text = clean(turns[e.i].text);
    else { lupa = { who: "lupa", start: e.t, end: null, text: clean(turns[e.i].text), words: [] }; lines.push(lupa); }
  }
  if (e.ev === "phase") {
    if (e.v === "aiSpeaking" && lupa && lupa.end != null && e.t - lupa.end < 0.6) lupa.end = null;
    else if (e.v !== "aiSpeaking" && lupa && lupa.end == null) lupa.end = e.t;
  }
  if (e.ev === "learner_start") lines.push({ who: "you", start: e.t, end: null, text: e.text, words: [] });
  if (e.ev === "word") lines.findLast((l) => l.who === "you")?.words.push({ w: e.w, t: e.t });
  if (e.ev === "learner_end") { const l = lines.findLast((l) => l.who === "you"); if (l) l.end = e.t; }
  if (e.ev === "turn" && e.role === "card") cards.push({ t: e.t, text: turns[e.i].text, tr: turns[e.i].detail || undefined });
}
for (const [i, l] of lines.entries()) {
  if (l.end == null) l.end = Math.min(duration, l.start + 4);
  l.orig = l.text;
  // Gerçek ses: öğrenci sesi bazen geç başlar, Lupa olaydan önce susar
  const next = lines[i + 1];
  const v = speech(l.start - 0.1, next ? next.start + 0.05 : l.end + 1.5);
  if (v) { l.start = v.from; l.end = v.to; }
  if (l.who === "you") l.tr = cards.find((c) => c.text === l.text)?.tr;
  // Lupa'nın öğrettiği cümle ve anlamı: "¡Hola!", "Hello!" → "¡Hola!" (Hello!)
  if (l.who === "lupa") l.text = l.text.replace(/"([^"]+)",\s*"([^"]+)"/g, '"$1" ($2)');
}
// Atlanan aralıklar: içindeki satır ve kartlar çıkar, yarısı atılan satır kalan kısmından başlar
for (const [a, b] of skips) {
  for (let i = lines.length - 1; i >= 0; i--) {
    const l = lines[i];
    if (l.start >= a && l.end <= b) lines.splice(i, 1);
    else if (l.start < b && l.end > b && l.start >= a - 0.5) { l.start = b; l.partial = true; }
  }
  cards.splice(0, cards.length, ...cards.filter((c) => c.t < a || c.t > b));
}
// Video öğrencinin son cümlesiyle (vedasıyla) biter; Lupa'nın sonrasındaki yorumu ve boş satırlar atılır
const lastYou = lines.findLastIndex((l) => l.who === "you");
if (lastYou >= 0) lines.splice(lastYou + 1);
for (let i = lines.length - 1; i >= 0; i--) if (!lines[i].text.trim()) lines.splice(i, 1);
const lastCardAt = lines.at(-1)?.end ?? duration;
cards.splice(0, cards.length, ...cards.filter((c) => c.t <= lastCardAt + 0.5));

// Konuşma olmayan boşluklar kesilir; kart gelişi ve son satır biraz nefes alır
const spans = lines.map((l) => ({ from: l.start - (l.partial ? 0 : 0.12), to: l.end + 0.22 }));
const last = lines.at(-1);
if (last) spans.push({ from: last.end, to: Math.min(duration - 0.05, last.end + 0.9) });
spans.sort((a, b) => a.from - b.from);
const keeps = [];
for (const s of spans) {
  const prev = keeps.at(-1);
  if (prev && s.from - prev.to < 0.25) prev.to = Math.max(prev.to, s.to);
  else keeps.push({ from: Math.max(0, s.from), to: s.to });
}
for (const [a, b] of skips) {
  for (let i = keeps.length - 1; i >= 0; i--) {
    const k = keeps[i];
    if (k.to <= a || k.from >= b) continue;
    const parts = [];
    if (k.from < a) parts.push({ from: k.from, to: a });
    if (k.to > b) parts.push({ from: b, to: k.to });
    keeps.splice(i, 1, ...parts);
  }
}
const r = (n) => Math.round(n * 1000) / 1000;

const out = `edits/${id}.json`;
const old = fs.existsSync(out) ? JSON.parse(fs.readFileSync(out)) : {};
const edit = {
  id,
  video: `clips/${id}.mp4`,
  width, height,
  hook: old.hook ?? script.hook ?? script.title,
  title: old.title ?? script.videoTitle ?? script.title,
  lang: script.native === "en" ? "en" : "tr",
  target: script.target ?? "en",
  cta: old.cta ?? (script.native === "en" ? "Coming soon on the App Store" : "Çok yakında App Store'da"),
  keeps: keeps.map((k) => ({ from: r(k.from), to: r(k.to) })),
  // Lupa'nın izleyicinin dilindeki satırları çevrilmez; Türkçe videoda Claude doldurur
  // Aynı orijinal cümleye elle yazılmış metin ve çeviri korunur
  lines: lines.map((l) => {
    const kept = old.lines?.find((o) => o.orig === l.orig);
    return { ...l, start: r(l.start), end: r(l.end), text: kept?.text ?? l.text, tr: kept?.tr || l.tr || "" };
  }),
  cards,
};
fs.mkdirSync("edits", { recursive: true });
fs.writeFileSync(out, JSON.stringify(edit, null, 2));
const total = edit.keeps.reduce((a, k) => a + k.to - k.from, 0);
console.log(`${out}: ${lines.length} satır, ${cards.length} kart, ${duration.toFixed(1)} sn → ${total.toFixed(1)} sn`);

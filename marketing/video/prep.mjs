// Telefondan gelen kaydı kurgu dosyasına çevirir:
//   node prep.mjs es01                      →  public/clips/es01.mp4 + edits/es01.json
//   node prep.mjs es01 --skip 0-8 --skip 26.4-37.4   →  kaynak videodan bu aralıklar atılır (saniye)
// Konuşma sınırları kayıttaki gerçek sesten ölçülür; elle düzeltilen metinler (aynı orijinal cümle) korunur.
import fs from "node:fs";
import { execFileSync } from "node:child_process";
import { defaultTts, speak } from "./voice.mjs";

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
/** [lo, hi] içindeki ilk ve son konuşma (en az 60 ms süren ses); kelimenin yumuşak başı ve sönen sonu da dahil */
const speech = (lo, hi) => {
  const a = Math.max(0, Math.floor(lo / STEP)), b = Math.min(env.length, Math.ceil(hi / STEP));
  let first = null, last = null, run = 0;
  for (let i = a; i < b; i++) {
    run = env[i] > TH ? run + 1 : 0;
    if (run === 3) { first ??= i - 2; }
    if (run >= 3) last = i + 1;
  }
  if (first == null) return null;
  while (first > a && env[first - 1] > TH * 0.35) first--;
  while (last < b && env[last] > TH * 0.35) last++;
  return { from: first * STEP, to: last * STEP };
};
/** Satırın içindeki sesli bölümler: altyazı kelimeleri sessiz aralara düşmesin */
const voiced = (from, to) => {
  const segs = [];
  for (let i = Math.floor(from / STEP); i < Math.ceil(to / STEP) && i < env.length; i++) {
    if (env[i] <= TH * 0.5) continue;
    const t = i * STEP, prev = segs.at(-1);
    if (prev && t - prev[1] < 0.15) prev[1] = t + STEP;
    else segs.push([t, t + STEP]);
  }
  return segs.filter(([a, b]) => b - a >= 0.06);
};

const r = (n) => Math.round(n * 1000) / 1000;
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
// Ses aranacak pencere olayların kendisinden: önceki satırın bitişi ile sonrakinin başlangıcı arası
const events = lines.map((l) => ({ start: l.start, end: l.end }));
const tts = script.tts === false ? null : { ...defaultTts(script.native), ...(script.tts ?? {}) };
for (const [i, l] of lines.entries()) {
  if (l.end == null) l.end = Math.min(duration, l.start + 4);
  l.orig = l.text;
  const lo = i ? (events[i - 1].end ?? events[i - 1].start) + 0.05 : Math.max(0, l.start - 3);
  const hi = lines[i + 1] ? events[i + 1].start - 0.02 : l.end + 1.5;
  // Gerçek ses: öğrenci sesi bazen geç başlar, Lupa'nın sesi yazısından önce başlar ve olaydan önce susar
  const v = speech(Math.min(lo, l.start - 0.1), Math.max(hi, l.start + 0.3));
  if (v) { l.start = v.from; l.end = v.to; }
  l.segs = voiced(l.start, l.end).map(([a, b]) => [r(a), r(b)]);
  if (l.who === "you") l.tr = cards.find((c) => c.text === l.text)?.tr;
  // Öğrencinin sesi: telefondaki Ava sesi susturulur, yerine OpenAI sesi aynı anda başlar; satırın süresi yeni sese göre
  if (l.who === "you" && tts) {
    const v = await speak(l.text, tts).catch((err) => { console.warn(`! ${err.message.split("\n")[0]}`); return null; });
    if (v) {
      l.mute = [r(l.start - 0.1), r(l.end + 0.15)];
      l.voice = { src: v.src, lead: v.lead };
      const end = l.start + v.dur;
      const room = lines[i + 1] ? events[i + 1].start - 0.4 : Infinity;
      if (end > room) console.warn(`! "${l.text}" yeni seste ${(end - room).toFixed(2)} sn uzun: Lupa'nın cevabına biniyor`);
      l.end = end;
      l.segs = v.segs.map(([a, b]) => [r(l.start + a), r(l.start + b)]);
      l.words = [];
    } else if (i === lines.findIndex((x) => x.who === "you")) console.warn("! OpenAI sesi yok: öğrenci sesi telefondaki ses (Ava) olarak kalıyor");
  }
  // Lupa'nın öğrettiği cümle ve anlamı: "¡Hola!", "Hello!" → "¡Hola!" (Hello!)
  if (l.who === "lupa") l.text = l.text.replace(/"([^"]+)",\s*"([^"]+)"/g, '"$1" ($2)');
}
// Atlanan aralıklar yalnızca bütün satırları atar: yarısına denk gelen satır kesilmez, aralık o satırı dışarıda bırakır
for (const sk of skips) {
  for (const l of lines) {
    if (l.start >= sk[0] && l.end <= sk[1]) continue;
    if (l.start < sk[1] && l.end > sk[0]) {
      console.warn(`! --skip ${sk[0]}-${sk[1]} "${l.text.slice(0, 40)}" satırını yarıdan keserdi: satır korunuyor`);
      if (l.start <= sk[0]) sk[0] = l.end + 0.35; else sk[1] = l.start - 0.2;
    }
  }
}
for (const [a, b] of skips) {
  if (b <= a) continue;
  for (let i = lines.length - 1; i >= 0; i--) if (lines[i].start >= a && lines[i].end <= b) lines.splice(i, 1);
  cards.splice(0, cards.length, ...cards.filter((c) => c.t < a || c.t > b));
}
// Video öğrencinin son cümlesiyle (vedasıyla) biter; Lupa'nın sonrasındaki yorumu ve boş satırlar atılır
const lastYou = lines.findLastIndex((l) => l.who === "you");
if (lastYou >= 0) lines.splice(lastYou + 1);
for (let i = lines.length - 1; i >= 0; i--) if (!lines[i].text.trim()) lines.splice(i, 1);
const lastCardAt = lines.at(-1)?.end ?? duration;
cards.splice(0, cards.length, ...cards.filter((c) => c.t <= lastCardAt + 0.5));

// Konuşma olmayan boşluklar kesilir; kart gelişi ve son satır biraz nefes alır
// Konuşmanın başına 0,2, sonuna 0,35 sn pay: ses kesimde yarım kalmaz
const spans = lines.map((l) => ({ from: l.start - 0.2, to: l.end + 0.35 }));
const last = lines.at(-1);
if (last) spans.push({ from: last.end, to: Math.min(duration - 0.05, last.end + 0.9) });
spans.sort((a, b) => a.from - b.from);
const keeps = [];
for (const s of spans) {
  const prev = keeps.at(-1);
  if (prev && s.from - prev.to < 0.4) prev.to = Math.max(prev.to, s.to);
  else keeps.push({ from: Math.max(0, s.from), to: s.to });
}
for (const [a, b] of skips.filter(([a, b]) => b > a)) {
  for (let i = keeps.length - 1; i >= 0; i--) {
    const k = keeps[i];
    if (k.to <= a || k.from >= b) continue;
    const parts = [];
    if (k.from < a) parts.push({ from: k.from, to: a });
    if (k.to > b) parts.push({ from: b, to: k.to });
    keeps.splice(i, 1, ...parts);
  }
}

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

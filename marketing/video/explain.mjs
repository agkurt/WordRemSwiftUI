// Açıklama reel'i: senaryodan dış sesi cümle cümle üretir ve kurgu dosyasını yazar (telefon kaydı gerekmez).
//   node explain.mjs ex01                 →  edits/ex01.json (sonra: preview.mjs → render.mjs → review.mjs)
//   node explain.mjs ex01 --voices marin,coral,ash  →  out/voices/ex01-<ses>.wav: ilk cümle bu seslerle, Ahmet seçsin
// Senaryo: marketing/explainers/<id>.json. Her "beat" bir kart ve o kartta söylenen cümleler; *yıldızlı* kelime vurgulanır.
// Ses dosyaları hiç kesilmez: her cümle ayrı üretilir, aralarına yalnızca sessizlik eklenir.
// Kelime zamanları Whisper'dan (ekranda her kelime söylendiği an belirir); alınamazsa sesli bölümlere harf sayısıyla dağıtılır.
import fs from "node:fs";
import crypto from "node:crypto";
import { speak } from "./voice.mjs";
import { env } from "../publish/env.mjs";

const id = process.argv[2];
if (!id) throw new Error("kullanım: node explain.mjs <id> [--voices a,b,c]");
const script = JSON.parse(fs.readFileSync(new URL(`../explainers/${id}.json`, import.meta.url)));

/** Anlatıcı: senaryoda "tts" yoksa bu */
const NARRATOR = {
  voice: "marin",
  instructions: "A warm, upbeat English teacher in her late twenties recording a short social media video. Clear standard American accent, natural and friendly, a brisk, energetic pace like a popular short-form creator. Read every word of the text exactly as written, including words like 'say' or 'try' before a quote. Say the example sentences the way people really say them in everyday life.",
};
const tts = { ...NARRATOR, ...(script.tts ?? {}) };
const plain = (s) => s.replace(/\*/g, "");

const vi = process.argv.indexOf("--voices");
if (vi > 0) {
  fs.mkdirSync("out/voices", { recursive: true });
  const text = plain(script.beats[0].say[0]);
  for (const voice of process.argv[vi + 1].split(",")) {
    const v = await speak(text, { ...tts, voice });
    fs.copyFileSync(`public/${v.src}`, `out/voices/${id}-${voice}.wav`);
    console.log(`out/voices/${id}-${voice}.wav  ${v.dur.toFixed(2)} sn`);
  }
  process.exit(0);
}

/** Whisper kelime zamanları (dosya başına göre saniye), public/voice/<ad>.words.json önbelleği */
async function wordTimes(src) {
  const cache = `public/${src.replace(/\.wav$/, ".words.json")}`;
  if (fs.existsSync(cache)) return JSON.parse(fs.readFileSync(cache));
  const key = env().OPENAI_API_KEY;
  if (!key) return null;
  const form = new FormData();
  form.append("file", new Blob([fs.readFileSync(`public/${src}`)], { type: "audio/wav" }), "s.wav");
  form.append("model", "whisper-1");
  form.append("response_format", "verbose_json");
  form.append("timestamp_granularities[]", "word");
  form.append("language", "en");
  const res = await fetch("https://api.openai.com/v1/audio/transcriptions", { method: "POST", headers: { Authorization: `Bearer ${key}` }, body: form });
  if (!res.ok) { console.warn(`! Whisper: ${res.status} ${(await res.text()).slice(0, 160)}`); return null; }
  const words = (await res.json()).words?.map((w) => ({ w: w.word, start: w.start, end: w.end })) ?? null;
  if (words) fs.writeFileSync(cache, JSON.stringify(words));
  return words;
}

/** Cümlenin kelimeleri: *yıldız* içindekiler vurgulu (birden çok kelimeyi kapsayabilir) */
const tokenize = (text) => {
  let on = false;
  return text.split(/\s+/).filter(Boolean).map((raw) => {
    const opens = /^[("“]?\*/.test(raw);
    if (opens) on = true;
    const tok = { w: raw.replace(/\*/g, ""), key: on };
    if (/\*[^\w]*$/.test(raw)) on = false;
    return tok;
  });
};

const r = (n) => Math.round(n * 1000) / 1000;
const START = 0.15, GAP = 0.22, BEAT_GAP = 0.42, HOLD = 1.6;
let cursor = START;
const sentences = [];
const beats = [];
for (const [b, beat] of script.beats.entries()) {
  if (b) cursor += BEAT_GAP - GAP;
  const from = b ? cursor - 0.2 : 0;
  for (const [k, say] of beat.say.entries()) {
    const toks = tokenize(say);
    // Ses metinden kelime atladıysa (TTS bazen bir cümleyi yutuyor) yazı ile ses tutmaz: yeniden üretilir, 3 denemede olmazsa durur
    let v, heard;
    for (let attempt = 1; ; attempt++) {
      v = await speak(plain(say), tts);
      if (!v) throw new Error("OPENAI_API_KEY yok (marketing/.env)");
      heard = await wordTimes(v.src);
      if (!heard || heard.length >= toks.length) break;
      const miss = `"${plain(say)}" seste ${toks.length - heard.length} kelime eksik (Whisper: "${heard.map((w) => w.w).join(" ")}")`;
      if (attempt === 3) throw new Error(`${miss}. Cümleyi yeniden yaz.`);
      console.warn(`! ${miss}, yeniden üretiliyor`);
      fs.rmSync(`public/${v.src}`);
      fs.rmSync(`public/${v.src.replace(/\.wav$/, ".words.json")}`);
    }
    let times;
    if (heard && heard.length === toks.length) times = heard.map((w) => w.start - v.lead);
    else {
      if (heard) console.warn(`! "${plain(say).slice(0, 40)}": Whisper ${heard.length} kelime, senaryo ${toks.length}; zamanlar tahmini`);
      // Sesli bölümlere harf sayısıyla dağıt
      const total = v.segs.reduce((a, [x, y]) => a + y - x, 0);
      const letters = toks.reduce((a, t) => a + t.w.length + 1, 0);
      let acc = 0;
      times = toks.map((t) => {
        let left = (acc / letters) * total;
        acc += t.w.length + 1;
        for (const [x, y] of v.segs) { if (left <= y - x) return x + left; left -= y - x; }
        return v.segs.at(-1)[1];
      });
    }
    sentences.push({
      beat: b, k, text: say, src: v.src, lead: r(v.lead), at: r(cursor), dur: r(v.dur),
      words: toks.map((t, i) => ({ w: t.w, key: t.key, t: r(cursor + Math.max(0, times[i])) })),
    });
    cursor += v.dur + GAP;
  }
  beats.push({ card: beat.card, from: r(from) });
}
const main = cursor - GAP;
for (const [i, b] of beats.entries()) b.to = r(beats[i + 1]?.from ?? main + HOLD);

const edit = {
  kind: "explainer",
  id,
  hook: plain(script.hook ?? script.beats[0].say[0]),
  cta: script.cta ?? "Coming soon on the App Store",
  beats,
  sentences,
  total: r(main + HOLD),
  // review.mjs ile uyum: tek parça, kesim yok; satırlar = cümleler
  keeps: [{ from: 0, to: r(main + HOLD) }],
  lines: sentences.map((s) => ({ who: "voice", start: s.at, end: r(s.at + s.dur), text: plain(s.text), words: [] })),
};
fs.mkdirSync("edits", { recursive: true });
fs.writeFileSync(`edits/${id}.json`, JSON.stringify(edit, null, 2));
const words = sentences.reduce((a, s) => a + s.words.length, 0);
console.log(`edits/${id}.json: ${beats.length} kart, ${sentences.length} cümle, ${words} kelime, ${edit.total.toFixed(1)} sn`);

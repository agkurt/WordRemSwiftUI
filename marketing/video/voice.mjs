// Öğrencinin repliklerini OpenAI sesiyle üretir (kurgu, telefondaki Ava sesinin yerine bunu çalar).
// prep.mjs çağırır; anahtar marketing/.env → OPENAI_API_KEY. Aynı metin + ses bir kez üretilir (public/voice/ önbellek).
import fs from "node:fs";
import crypto from "node:crypto";
import { env } from "../publish/env.mjs";

const MODEL = "gpt-4o-mini-tts";
const STEP = 0.02;

/** Öğrenci kimdir: senaryodaki "tts" alanı yoksa ana dile göre */
export const defaultTts = (native) => ({
  voice: "cedar",
  instructions: native === "tr"
    ? "A young Turkish adult practising English with a tutor. Natural, warm and confident, a light Turkish accent, normal conversational pace, like a real person talking, not reading."
    : "A young American adult practising a new language with a tutor. Natural, warm and confident, a light American accent on the foreign words, normal conversational pace, like a real person talking, not reading.",
});

/** WAV'ın ses verisi (OpenAI başlıktaki uzunluğu boş bırakabilir: "data" bölümü aranır) */
const samples = (buf) => {
  let o = 12;
  while (o + 8 <= buf.length) {
    const id = buf.toString("ascii", o, o + 4);
    const size = buf.readUInt32LE(o + 4);
    if (id === "data") return new Int16Array(buf.buffer.slice(buf.byteOffset + o + 8, buf.byteOffset + Math.min(buf.length, o + 8 + size)));
    o += 8 + size;
  }
  throw new Error("WAV verisi bulunamadı");
};

/** Sesin başındaki sessizlik, konuşma süresi ve içindeki sesli bölümler (saniye, konuşma başına göre) */
const measure = (file) => {
  const pcm = samples(fs.readFileSync(file));
  const rate = 24000, win = Math.round(rate * STEP);
  const env = [];
  for (let i = 0; i + win <= pcm.length; i += win) {
    let s = 0;
    for (let j = i; j < i + win; j++) s += pcm[j] * pcm[j];
    env.push(Math.sqrt(s / win));
  }
  const th = Math.max(200, [...env].sort((a, b) => a - b)[Math.floor(env.length * 0.95)] * 0.06);
  const first = env.findIndex((v) => v > th);
  const last = env.length - 1 - [...env].reverse().findIndex((v) => v > th);
  const segs = [];
  for (let i = first; i <= last; i++) {
    if (env[i] <= th) continue;
    const t = (i - first) * STEP, prev = segs.at(-1);
    if (prev && t - prev[1] < 0.15) prev[1] = t + STEP;
    else segs.push([t, t + STEP]);
  }
  return { lead: first * STEP, dur: (last + 1 - first) * STEP, segs };
};

/** Metni sese çevirir (önbellekte varsa yeniden üretmez); public/ altındaki yolu ve ölçüleri döner */
export async function speak(text, tts) {
  const key = env().OPENAI_API_KEY;
  const hash = crypto.createHash("sha1").update(JSON.stringify([MODEL, tts.voice, tts.instructions, text])).digest("hex").slice(0, 16);
  const src = `voice/${hash}.wav`;
  const file = `public/${src}`;
  if (!fs.existsSync(file)) {
    if (!key) return null;
    const res = await fetch("https://api.openai.com/v1/audio/speech", {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: MODEL, voice: tts.voice, input: text, instructions: tts.instructions, response_format: "wav" }),
    });
    if (!res.ok) throw new Error(`OpenAI ses: ${res.status} ${(await res.text()).slice(0, 200)}`);
    fs.mkdirSync("public/voice", { recursive: true });
    fs.writeFileSync(file, Buffer.from(await res.arrayBuffer()));
  }
  return { src, ...measure(file) };
}

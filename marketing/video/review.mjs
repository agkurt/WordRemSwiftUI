// Render edilen videoyu Claude'un "izleyebileceği" resimlere çevirir ve konuşma kesilmesini otomatik denetler:
//   node review.mjs tr01  →  review/tr01/ (contact.png, cut-*.png, phone-*.png, loop.png, poster.png) + rapor
// Claude videoyu bu karelerden puanlar (BRIEF.md → Eleştiri döngüsü), en büyük 3 sorunu düzeltip yeniden render eder.
import fs from "node:fs";
import { execFileSync } from "node:child_process";
import { FPS, HOOK_SECONDS, RECAP_SECONDS } from "./src/types.ts";

const id = process.argv[2];
if (!id) throw new Error("kullanım: node review.mjs <id>");
const video = `out/${id}.mp4`;
const edit = JSON.parse(fs.readFileSync(`edits/${id}.json`));
// Bob bölümleri satır sınırını kelimelerden alır
for (const l of edit.lines) { l.start ??= l.words[0].t; l.end ??= l.words.at(-1).end; }
const dir = `review/${id}`;
fs.rmSync(dir, { recursive: true, force: true });
fs.mkdirSync(dir, { recursive: true });

const ff = (...args) => execFileSync("npx", ["remotion", "ffmpeg", "-hide_banner", "-loglevel", "error", "-y", ...args]);
const duration = Number(JSON.parse(execFileSync("npx", ["remotion", "ffprobe", "-v", "error", "-show_entries", "format=duration",
  "-of", "json", video]).toString()).format.duration);

// Kareler public/review/<id>/ altına çıkarılır, Remotion'ın "Sheet" kompozisyonu ızgaraya dizer (paketli ffmpeg'de tile/hstack yok)
const frames = `public/review/${id}`;
fs.rmSync(frames, { recursive: true, force: true });
fs.mkdirSync(frames, { recursive: true });
let n = 0;
const grab = (t, w) => {
  const f = `review/${id}/f${String(n++).padStart(4, "0")}.png`;
  ff("-ss", Math.max(0, Math.min(t, duration - 0.15)).toFixed(3), "-i", video, "-frames:v", "1", "-vf", `scale=${w}:-2`, `public/${f}`);
  return f;
};
const label = (t) => `${t.toFixed(2)}s`;
const sheet = (name, times, cols, w, safe = false, labels = times.map(label)) => {
  const props = { images: times.map((t) => grab(t, w)), labels, cols, w, h: Math.round((w * 1920) / 1080), safe };
  fs.writeFileSync(`${frames}/props.json`, JSON.stringify(props));
  execFileSync("npx", ["remotion", "still", "src/index.ts", "Sheet", `${dir}/${name}.png`, `--props=${frames}/props.json`, "--log=error"]);
};

// 1) Kontakt sayfası: saniyede 2 kare, tek sayfada bütün akış
sheet("contact", Array.from({ length: Math.floor(duration * 2) }, (_, i) => i / 2), 8, 216);

// 2) Kesim şeritleri: her kesimin etrafındaki 12 ardışık kare (sıçrama, takılma)
const cuts = [];
let acc = 0;
for (const [i, k] of edit.keeps.entries()) { if (i) cuts.push(acc); acc += k.to - k.from; }
for (const [i, c] of cuts.entries()) sheet(`cut-${i + 1}`, Array.from({ length: 12 }, (_, j) => c + (j - 6) / FPS), 12, 160);

// 3) Telefon testi: 360 px genişlikte okunuyor mu (kanca, her satırın ortası, özet, kapanış)
const main = acc;
const outAt = (s) => {
  let a = 0;
  for (const k of edit.keeps) { if (s >= k.from && s <= k.to) return a + (s - k.from); a += k.to - k.from; }
  return null;
};
const moments = [["hook", 0.6], ...edit.lines.map((l, i) => [`line${i + 1}-${l.who}`, outAt((l.start + l.end) / 2)]),
  ["recap", main + RECAP_SECONDS - 0.3], ["outro", duration - 0.3]].filter(([, t]) => t != null && t < duration);
for (const [name, t] of moments) fs.copyFileSync(`public/${grab(t, 360)}`, `${dir}/phone-${name}.png`);
// Güvenli alan: aynı anlar, platform arayüzünün örttüğü bölgeler kırmızı (yazı kırmızıya taşmamalı)
sheet("safe", moments.map(([, t]) => t), 4, 270, true, moments.map(([name, t]) => `${name} ${label(t)}`));

// 4) Döngü: son kare + ilk kare yan yana (video başa sararken sıçrama var mı) ve kapak (ilk kare)
sheet("loop", [duration - 0.15, 0], 2, 360);
ff("-i", video, "-frames:v", "1", `${dir}/poster.png`);
fs.rmSync(frames, { recursive: true, force: true });

// 5) Konuşma kesilmesi: kaynak sesin her kesim sınırında konuşma var mı, her satır bir parçanın içinde mi
//    Açıklama reel'inde kaynak video yok: her cümlenin sesi bir sonrakinden ve videonun sonundan önce bitmeli
const problems = [];
if (edit.kind === "explainer") {
  for (const [i, s] of edit.sentences.entries()) {
    const end = s.at + s.dur, next = edit.sentences[i + 1];
    if (next && end > next.at) problems.push(`cümle "${s.text.slice(0, 40)}" bir sonrakinin üstüne biniyor (${(end - next.at).toFixed(2)} sn)`);
    if (end > duration - 0.3) problems.push(`cümle "${s.text.slice(0, 40)}" videonun sonunda kesiliyor`);
    if (!fs.existsSync(`public/${s.src}`)) problems.push(`cümle "${s.text.slice(0, 40)}" ses dosyası yok: ${s.src}`);
  }
} else {
  const wav = `${dir}/_src.wav`;
  ff("-i", `public/${edit.video}`, "-vn", "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le", wav);
  const pcm = new Int16Array(fs.readFileSync(wav).buffer.slice(44));
  fs.rmSync(wav);
  const env = [];
  for (let i = 0; i + 160 <= pcm.length; i += 160) {
    let sum = 0;
    for (let j = i; j < i + 160; j++) sum += pcm[j] * pcm[j];
    env.push(Math.sqrt(sum / 160));
  }
  const loud = [...env].sort((a, b) => a - b)[Math.floor(env.length * 0.95)] ?? 1000;
  // Ortam sesi (sokak, kafe) konuşma sayılmasın: eşik en az gürültü tabanının 2,5 katı
  const floor = [...env].sort((a, b) => a - b)[Math.floor(env.length * 0.5)] ?? 0;
  const TH = Math.max(Math.max(300, loud * 0.08) * 0.5, floor * 2.5);
  const rms = (s) => env[Math.round(s / 0.01)] ?? 0;
  for (const k of edit.keeps) {
    for (const [edge, s] of [["başı", k.from], ["sonu", k.to]]) {
      // Sınırın 80 ms içinde ses varsa kesim konuşmanın üstüne denk geliyor
      const hot = [-0.08, -0.04, 0, 0.04, 0.08].filter((d) => rms(s + d) > TH).length;
      if (hot >= 2) problems.push(`parça ${edge} (kaynak ${s.toFixed(2)} sn, kurgu ${(outAt(s) ?? 0).toFixed(2)} sn): sesin üstüne kesiliyor`);
    }
  }
  for (const l of edit.lines) {
    if (!edit.keeps.some((k) => l.start >= k.from - 0.01 && l.end <= k.to + 0.01))
      problems.push(`satır "${l.text.slice(0, 50)}" bütünüyle bir parçanın içinde değil: yarısı kesiliyor`);
    if (l.partial) problems.push(`satır "${l.text.slice(0, 50)}" partial işaretli: başı atılmış`);
  }
}

// 6) Bozuk kare: bütün kareler 36×64 griye indirilir; iki komşusu birbirine benzerken kendisi ikisinden de çok farklı olan kare bozuktur
const W = 36, H = 64;
const raw = execFileSync("npx", ["remotion", "ffmpeg", "-hide_banner", "-loglevel", "error", "-i", video, "-vf", `scale=${W}:${H}`,
  "-f", "image2pipe", "-c:v", "rawvideo", "-pix_fmt", "gray", "-"], { maxBuffer: 1 << 28 });
const nf = Math.floor(raw.length / (W * H));
const diff = (a, b) => { let d = 0; for (let j = 0; j < W * H; j++) d += Math.abs(raw[a * W * H + j] - raw[b * W * H + j]); return d / (W * H); };
for (let f = 1; f + 1 < nf; f++) {
  const around = diff(f - 1, f + 1), prev = diff(f, f - 1), next = diff(f, f + 1);
  if (prev > 12 && next > 12 && around < Math.min(prev, next) / 3)
    problems.push(`bozuk kare: ${f}. kare (${(f / FPS).toFixed(2)} sn) komşularından çok farklı, yeniden render et`);
}

const report = [
  `# ${id} · ${duration.toFixed(1)} sn (konuşma ${main.toFixed(1)} sn, ${cuts.length} kesim, ${edit.lines.length} satır)`,
  `İlk saniye yazısı: ${HOOK_SECONDS} sn · "${edit.hook}"`,
  problems.length ? `\n## Sorunlar: ${problems.length}\n- ${problems.join("\n- ")}` : "\n## Konuşma kesilmesi ve bozuk kare: yok ✓",
  `\nKareler: ${dir}/ (contact.png, cut-*.png, phone-*.png, safe.png, loop.png, poster.png)`,
].join("\n");
fs.writeFileSync(`${dir}/report.md`, report + "\n");
console.log(report);
process.exitCode = problems.length ? 1 : 0;

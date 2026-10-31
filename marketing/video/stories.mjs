// Günün hikâye karelerini üretir:
//   node stories.mjs 2026-10-28  →  out/stories/2026-10-28/1.jpg, 2.jpg, 3.jpg (1080×1920, Instagram hikâyesi JPEG ister)
// İçerik: marketing/stories/<tarih>.json. "promo" karesi o günün paylaşımını (reel ya da slayt, "reel" alanı) kapak olarak kullanır.
import fs from "node:fs";
import { execFileSync } from "node:child_process";

const date = process.argv[2] ?? new Date().toISOString().slice(0, 10);
const day = JSON.parse(fs.readFileSync(new URL(`../stories/${date}.json`, import.meta.url)));
const out = `out/stories/${date}`;
fs.mkdirSync(out, { recursive: true });
fs.mkdirSync("public/stories", { recursive: true });

/** Yönlendirme karesinin görseli (public/stories/<id>.jpg): slaytta ilk slayt, açıklama reel'i ve Bob'da ilk kare (kanca), sahne reel'inde Lupa'nın ilk cümlesi */
const cover = (id) => {
  if (fs.existsSync(`out/slides/${id}/1.jpg`)) return fs.copyFileSync(`out/slides/${id}/1.jpg`, `public/stories/${id}.jpg`);
  if (!fs.existsSync(`out/${id}.mp4`)) return;
  const edit = JSON.parse(fs.readFileSync(`edits/${id}.json`));
  let at = 0;
  if (edit.kind !== "explainer" && !edit.series) {
    // Sahne reel'i: Lupa'nın ilk İngilizce cümlesinin ortası (ifade kartı ekranda)
    const lupa = edit.lines.find((l) => l.who === "lupa");
    let acc = 0;
    at = 6;
    for (const k of edit.keeps) { if (lupa && lupa.end >= k.from && lupa.end <= k.to) { at = acc + (lupa.end - k.from) - 1.2; break; } acc += k.to - k.from; }
  }
  execFileSync("npx", ["remotion", "ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-ss", at.toFixed(2), "-i", `out/${id}.mp4`,
    "-frames:v", "1", "-q:v", "2", `public/stories/${id}.jpg`]);
};
// Günün paylaşımı "reel"; ikinci paylaşımın (Bob) yönlendirme karesi kendi "reel" alanını taşır
for (const id of new Set([day.reel, ...day.frames.map((f) => f.reel)].filter(Boolean))) cover(id);
for (const [i, frame] of day.frames.entries()) {
  const props = `${out}/${i + 1}.json`;
  fs.writeFileSync(props, JSON.stringify(frame));
  execFileSync("npx", ["remotion", "still", "src/index.ts", "Story", `${out}/${i + 1}.jpg`, `--props=${props}`, "--image-format=jpeg",
    "--jpeg-quality=92", "--log=error"]);
  fs.rmSync(props);
  console.log(`${out}/${i + 1}.jpg  ${frame.kind}`);
}

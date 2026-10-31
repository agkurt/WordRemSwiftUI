// Kaydırmalı gönderi (slayt) üretir:
//   node slides.mjs sl01  →  out/slides/sl01/1.jpg… (TikTok 1080×1920) ve out/slides/sl01/ig/1.jpg… (Instagram 4:5, 1080×1350)
// İçerik: marketing/slides/<id>.json. Yazılar ortadaki 1080×1350 alanda olduğu için Instagram kırpması bir şey kesmez.
import fs from "node:fs";
import { execFileSync } from "node:child_process";

const id = process.argv[2];
if (!id) throw new Error("kullanım: node slides.mjs <id>");
const post = JSON.parse(fs.readFileSync(new URL(`../slides/${id}.json`, import.meta.url)));
const out = `out/slides/${id}`;
fs.rmSync(out, { recursive: true, force: true });
fs.mkdirSync(`${out}/ig`, { recursive: true });
for (const [i, slide] of post.slides.entries()) {
  const props = `${out}/${i + 1}.json`;
  fs.writeFileSync(props, JSON.stringify({ ...slide, index: i, total: post.slides.length }));
  execFileSync("npx", ["remotion", "still", "src/index.ts", "Slide", `${out}/${i + 1}.jpg`, `--props=${props}`, "--image-format=jpeg", "--jpeg-quality=92", "--log=error"]);
  fs.rmSync(props);
  execFileSync("npx", ["remotion", "ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", `${out}/${i + 1}.jpg`, "-vf", "crop=1080:1350:0:285", "-q:v", "2", `${out}/ig/${i + 1}.jpg`]);
  console.log(`${out}/${i + 1}.jpg  ${slide.kind}`);
}

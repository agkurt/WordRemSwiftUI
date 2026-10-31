// TikTok taslağını yeniden gönderir (Instagram'a dokunmaz): bulut worker'ı bir sonraki turda (5 dk) yalnızca TikTok adımını çalıştırır.
//   node publish/resend-tiktok.mjs sl01      →  slayt (video/out/slides/sl01/1..n.jpg, 9:16)
//   node publish/resend-tiktok.mjs ex02      →  reel (video/out/ex02.mp4)
// Worker'ın tiktokOnly desteği olan sürümü deploy edilmiş olmalı (yoksa iş Instagram'a da gider).
import fs from "node:fs";
import * as cloud from "./cloud.mjs";

const id = process.argv[2];
if (!id) throw new Error("kullanım: node publish/resend-tiktok.mjs <id>");
const post = JSON.parse(fs.readFileSync(new URL(`posts/${id}.json`, import.meta.url), "utf8"));
const slides = new URL(`../video/out/slides/${id}/`, import.meta.url);
const stamp = Date.now().toString(36);
const at = new Date().toISOString();
if (fs.existsSync(slides)) {
  const n = fs.readdirSync(slides).filter((f) => /^\d+\.jpg$/.test(f)).length;
  const tiktokImages = [];
  for (let i = 1; i <= n; i++) {
    tiktokImages.push(`slides/${id}/tt-${stamp}-${i}.jpg`);
    await cloud.upload(tiktokImages.at(-1), new URL(`${i}.jpg`, slides), "image/jpeg");
  }
  await cloud.putJob({ id: `carousel-${id}-tiktok-${stamp}`, type: "carousel", tiktokOnly: true, at, approved: true, images: [], tiktokImages,
    caption: post.caption, tiktokCaption: post.tiktokCaption, title: post.caption.split("\n")[0] });
} else {
  const media = `reels/${id}-tiktok-${stamp}.mp4`;
  await cloud.upload(media, new URL(`../video/out/${id}.mp4`, import.meta.url), "video/mp4");
  await cloud.putJob({ id: `reel-${id}-tiktok-${stamp}`, type: "reel", tiktokOnly: true, at, approved: true, media, caption: post.caption, tiktokCaption: post.tiktokCaption });
}
console.log(`${id}: TikTok işi kuyrukta, 5 dakika içinde gönderilir; taslak gelen kutusuna düşünce telefona bildirim gelir.`);

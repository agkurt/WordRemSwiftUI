// Onay paneli: http://localhost:4747
//   node publish/server.mjs
// Hazır videolar (video/out) listelenir; açıklama düzenlenir, "Paylaş" ile Instagram'a, "Taslak gönder" ile TikTok'a gider.
// Hiçbir şey kendiliğinden paylaşılmaz: her paylaşım panelde Ahmet'in tıklamasıyla başlar.
import http from "node:http";
import fs from "node:fs";
import crypto from "node:crypto";
import { spawn } from "node:child_process";
import * as instagram from "./instagram.mjs";
import * as tiktok from "./tiktok.mjs";
import * as cloud from "./cloud.mjs";
import { env, tokens } from "./env.mjs";

const PORT = Number(process.env.PANEL_PORT ?? 4747);
const here = new URL("./", import.meta.url);
const outDir = new URL("../video/out/", import.meta.url);
const postsDir = new URL("posts/", here);
const editsDir = new URL("../video/edits/", import.meta.url);
const storiesOut = new URL("../video/out/stories/", import.meta.url);
const slidesOut = new URL("../video/out/slides/", import.meta.url);
const slidesSrc = new URL("../slides/", import.meta.url);
const storiesSrc = new URL("../stories/", import.meta.url);
const storiesLog = new URL("stories/", here);

const logs = new Map();   // id → adım adım durum
const busy = new Set();   // aynı video aynı anda iki kez paylaşılmasın
let shared = null;        // Instagram'ın çekeceği tek seferlik adres: { token, name, file }

const videoFile = (id) => new URL(`${id}.mp4`, outDir);

function post(id) {
  const file = new URL(`${id}.json`, postsDir);
  if (fs.existsSync(file)) return JSON.parse(fs.readFileSync(file, "utf8"));
  const edit = new URL(`${id}.json`, editsDir);
  const hook = fs.existsSync(edit) ? JSON.parse(fs.readFileSync(edit, "utf8")).hook : "";
  return { id, caption: hook, tiktokCaption: "", schedule: null, instagram: null, tiktok: null };
}
const save = (p) => fs.writeFileSync(new URL(`${p.id}.json`, postsDir), JSON.stringify(p, null, 2));

function log(id) {
  logs.set(id, []);
  return (line) => logs.get(id).push(`${new Date().toLocaleTimeString("tr-TR")}  ${line}`);
}

async function state() {
  const ids = fs.existsSync(outDir) ? fs.readdirSync(outDir).filter((f) => f.endsWith(".mp4")).map((f) => f.slice(0, -4)).sort() : [];
  const e = env();
  const ig = { configured: !!e.IG_ACCESS_TOKEN };
  if (ig.configured) { try { ig.username = (await instagram.account()).username; } catch (err) { ig.error = err.message; } }
  const tt = { configured: !!(e.TIKTOK_CLIENT_KEY && e.TIKTOK_CLIENT_SECRET), connected: !!tokens.read().tiktok };
  // Bulut açıkken TikTok oturumunu yalnızca bulut yeniler (iki yerden yenilenirse biri geçersiz kalır)
  if (tt.connected && !cloud.enabled()) { try { tt.username = (await tiktok.account()).username; } catch (err) { tt.error = err.message; } }
  const out = { posts: ids.map((id) => ({ ...post(id), busy: busy.has(id), log: logs.get(id) ?? [] })), carousels: carousels(), stories: stories(), instagram: ig, tiktok: tt };
  if (cloud.enabled()) {
    try {
      const c = await cloud.jobs();
      out.cloud = { ok: true, tiktok: c.tiktok };
      const byId = Object.fromEntries(c.jobs.map((j) => [j.id, j]));
      for (const p of out.posts) {
        const j = byId[`reel-${p.id}`];
        if (!j) continue;
        p.cloud = { done: !!j.done, error: j.state?.error, failed: !!j.state?.failed };
        if (j.state?.ig?.mediaId && !p.instagram) p.instagram = j.state.ig;
        if (j.state?.tiktok && !p.tiktok) p.tiktok = j.state.tiktok;
      }
      for (const c of out.carousels) {
        const j = byId[`carousel-${c.id}`];
        if (!j) continue;
        c.cloud = { done: !!j.done, error: j.state?.error, failed: !!j.state?.failed };
        if (j.state?.ig?.mediaId && !c.instagram) c.instagram = j.state.ig;
        if (j.state?.tiktok && !c.tiktok) c.tiktok = j.state.tiktok;
      }
      for (const d of out.stories) for (const f of d.frames) {
        const j = byId[`story-${d.date}-${f.n}`];
        if (j?.state?.ig?.mediaId && !f.instagram) f.instagram = j.state.ig;
        if (j?.state?.error) f.log = [...f.log, `Bulut: ${j.state.error}`];
        if (j && f.kind === "ask" && j.done) f.instagram = { reminded: true };
      }
    } catch (err) { out.cloud = { ok: false, error: err.message }; }
  }
  return out;
}

/** Hikâye günleri (en yenisi önce): kareler, türleri ve hangilerinin paylaşıldığı */
function stories() {
  if (!fs.existsSync(storiesOut)) return [];
  // Bugün ve sonraki günler, tarih sırasıyla (geçmiş günler panelde gösterilmez)
  return fs.readdirSync(storiesOut).filter((d) => /^\d{4}-\d{2}-\d{2}$/.test(d) && d >= today()).sort().slice(0, 8).map((date) => {
    const src = new URL(`${date}.json`, storiesSrc);
    const frames = fs.existsSync(src) ? JSON.parse(fs.readFileSync(src, "utf8")).frames : [];
    const done = storyLog(date);
    const files = fs.readdirSync(new URL(`${date}/`, storiesOut)).filter((f) => f.endsWith(".jpg")).sort();
    return { date, approved: !!done.approved, frames: files.map((f) => {
      const n = Number(f.slice(0, -4));
      const key = `story-${date}-${n}`;
      return { n, kind: frames[n - 1]?.kind ?? "", label: frames[n - 1]?.label ?? "", sticker: frames[n - 1]?.sticker, at: slot(frames[n - 1]),
        instagram: done[n] ?? null, busy: busy.has(key), log: logs.get(key) ?? [] };
    }) };
  });
}
const storyLog = (date) => { const f = new URL(`${date}.json`, storiesLog); return fs.existsSync(f) ? JSON.parse(fs.readFileSync(f, "utf8")) : {}; };
const storyFile = (date, n) => new URL(`${date}/${n}.jpg`, storiesOut);

/** Kaydırmalı gönderiler (slides/<id>.json, video/out/slides/<id>/): açıklama ve zamanlama posts/<id>.json'da */
const slideCount = (id) => fs.existsSync(new URL(`${id}/`, slidesOut)) ? fs.readdirSync(new URL(`${id}/`, slidesOut)).filter((f) => /^\d+\.jpg$/.test(f)).length : 0;
const slideFile = (id, n, igCrop = false) => new URL(`${id}/${igCrop ? "ig/" : ""}${n}.jpg`, slidesOut);
function carousel(id) {
  const p = post(id);
  const src = new URL(`${id}.json`, slidesSrc);
  if (!p.caption && fs.existsSync(src)) p.caption = JSON.parse(fs.readFileSync(src, "utf8")).caption ?? "";
  return { ...p, kind: "carousel", count: slideCount(id) };
}
const carousels = () => fs.existsSync(slidesOut) ? fs.readdirSync(slidesOut).filter((d) => slideCount(d) > 0).sort().map(carousel) : [];
const writeStoryLog = (date, patch) => {
  fs.mkdirSync(storiesLog, { recursive: true });
  fs.writeFileSync(new URL(`${date}.json`, storiesLog), JSON.stringify({ ...storyLog(date), ...patch }, null, 2));
};

// Hikâye saatleri: sabah öğret, öğle etkileşim (telefondan, hatırlatma), yönlendir günün paylaşımından 30 dk sonra. Karede "at" ile değişir.
const SLOTS = { teach: "08:30", ask: "13:30", promo: "20:00" };
const slot = (frame) => frame?.at ?? SLOTS[frame?.kind] ?? null;
/** Yerel saatle bugün (YYYY-AA-GG) ve şu anki dakika (SS:DD) */
const today = () => new Date().toLocaleDateString("sv-SE");
const nowHM = () => new Date().toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" });

/** Hikâyeyi Instagram'a gönderir (tek seferlik tünelle); başladıysa true */
function postStory(date, n) {
  const key = `story-${date}-${n}`;
  if (busy.has(key) || !fs.existsSync(storyFile(date, n))) return false;
  busy.add(key);
  const say = log(key);
  instagram.publishStory({
    name: `${date}-${n}.jpg`, port: PORT, log: say,
    share: (name) => { shared = { token: crypto.randomBytes(16).toString("hex"), name, file: storyFile(date, n) }; return `/public/${shared.token}/${name}`; },
    unshare: () => { shared = null; },
  })
    .then((result) => writeStoryLog(date, { [n]: result }))
    .catch((err) => say(`✗ ${err.message}`))
    .finally(() => busy.delete(key));
  return true;
}

/** Mac bildirimi (etkileşim karesi ve TikTok taslağı hatırlatması) */
const notify = (text, title = "WordRem hikâye") =>
  spawn("osascript", ["-e", `display notification ${JSON.stringify(text)} with title ${JSON.stringify(title)}`]);
/** Mac panosuna yazar (aynı Apple hesabındaki iPhone'da da yapıştırılabilir) */
const copy = (text) => { const p = spawn("pbcopy"); p.stdin.end(text); };

/**
 * Zamanlayıcı: dakikada bir bugünün onaylı karelerine bakar. Saati gelen kare paylaşılır; yönlendirme karesi
 * o günün reel'i Instagram'da yayında değilse bekler. Etkileşim karesi için yalnızca hatırlatma gider.
 * Paylaşım sırasında başka iş varsa (tek tünel) sıradaki dakikaya kalır.
 */
function tick() {
  // Bulut zamanlayıcısı açıkken paylaşımları o yapar
  if (cloud.enabled() || busy.size || reelTick()) return;
  const date = today();
  const done = storyLog(date);
  const src = new URL(`${date}.json`, storiesSrc);
  if (!done.approved || !fs.existsSync(src)) return;
  const day = JSON.parse(fs.readFileSync(src, "utf8"));
  const now = nowHM();
  for (const [i, frame] of day.frames.entries()) {
    const n = i + 1, at = slot(frame);
    if (!at || now < at || done[n] || !fs.existsSync(storyFile(date, n))) continue;
    if (frame.kind === "ask") {
      notify(`${n}. kare (${frame.sticker ?? "anket"}): panelden indir, telefondan paylaş`);
      writeStoryLog(date, { [n]: { reminded: true, at: new Date().toISOString() } });
      return;
    }
    if (frame.kind === "promo" && day.reel && !post(day.reel).instagram) continue;
    postStory(date, n);
    return;
  }
}
setInterval(tick, 60_000);

/** Zamanı gelen reel: önce Instagram'da yayınlanır, sonra TikTok gelen kutuna taslak gider; iş başlattıysa true */
function reelTick() {
  const ids = fs.existsSync(outDir) ? fs.readdirSync(outDir).filter((f) => f.endsWith(".mp4")).map((f) => f.slice(0, -4)) : [];
  for (const id of ids) {
    const p = post(id);
    if (!p.schedule?.approved || !p.schedule.at || new Date(p.schedule.at) > new Date()) continue;
    if (!p.instagram) return startInstagram(id);
    if (!p.tiktok && tokens.read().tiktok) return startTiktok(id);
  }
  return false;
}

function startInstagram(id) {
  const p = post(id);
  return run(id, "instagram", (say) => instagram.publish({
    id, caption: p.caption, port: PORT, log: say,
    share: (id) => { shared = { token: crypto.randomBytes(16).toString("hex"), name: `${id}.mp4`, file: videoFile(id) }; return `/public/${shared.token}/${shared.name}`; },
    unshare: () => { shared = null; },
  }));
}

/** TikTok taslağı: yüklenince bildirim gelir, TikTok açıklaması panoya kopyalanır */
function startTiktok(id) {
  return run(id, "tiktok", async (say) => {
    const result = await tiktok.upload({ file: videoFile(id), log: say });
    const p = post(id);
    copy(p.tiktokCaption || p.caption);
    notify(`${id} TikTok gelen kutunda. Aç, taslağa dokun, açıklamayı yapıştır, Paylaş.`, "WordRem TikTok");
    return result;
  });
}

function sendImage(res, file) {
  if (!fs.existsSync(file)) { res.writeHead(404).end(); return; }
  res.writeHead(200, { "Content-Type": "image/jpeg", "Content-Length": fs.statSync(file).size });
  fs.createReadStream(file).pipe(res);
}

/** Video dosyası (önizleme ve Instagram'ın çekmesi için, aralıklı istek destekli) */
function sendVideo(req, res, file) {
  if (!fs.existsSync(file)) { res.writeHead(404).end(); return; }
  const size = fs.statSync(file).size;
  const m = (req.headers.range ?? "").match(/bytes=(\d*)-(\d*)/);
  if (m) {
    const start = m[1] ? Number(m[1]) : 0;
    const end = m[2] ? Number(m[2]) : size - 1;
    res.writeHead(206, { "Content-Type": "video/mp4", "Content-Range": `bytes ${start}-${end}/${size}`, "Accept-Ranges": "bytes", "Content-Length": end - start + 1 });
    fs.createReadStream(file, { start, end }).pipe(res);
  } else {
    res.writeHead(200, { "Content-Type": "video/mp4", "Content-Length": size, "Accept-Ranges": "bytes" });
    fs.createReadStream(file).pipe(res);
  }
}

const json = (res, code, body) => res.writeHead(code, { "Content-Type": "application/json" }).end(JSON.stringify(body));
const readBody = (req) => new Promise((r) => { let b = ""; req.on("data", (c) => (b += c)); req.on("end", () => r(b ? JSON.parse(b) : {})); });

/** Paylaşımı arka planda başlatır; panel durumu log'dan izler */
function run(id, platform, task) {
  if (busy.has(id)) return false;
  busy.add(id);
  const say = log(id);
  task(say)
    .then((result) => { const p = post(id); p[platform] = result; save(p); })
    .catch((err) => say(`✗ ${err.message}`))
    .finally(() => busy.delete(id));
  return true;
}

/** Reel işini buluta yazar (video buluta yüklenir); onay kalkınca iş silinir */
async function syncReel(p, withVideo = true) {
  const id = `reel-${p.id}`;
  if (!p.schedule?.approved) { await cloud.deleteJob(id); return; }
  const media = `reels/${p.id}.mp4`;
  if (withVideo) await cloud.upload(media, videoFile(p.id), "video/mp4");
  await cloud.putJob({ id, type: "reel", at: cloud.iso(p.schedule.at), approved: true, media, caption: p.caption, tiktokCaption: p.tiktokCaption });
}

/** Kaydırmalı gönderiyi buluta yazar: Instagram için 4:5, TikTok için 9:16 görseller */
async function syncCarousel(p, withImages = true) {
  const id = `carousel-${p.id}`;
  if (!p.schedule?.approved) { await cloud.deleteJob(id); return; }
  const n = slideCount(p.id);
  const images = [], tiktokImages = [];
  for (let i = 1; i <= n; i++) {
    images.push(`slides/${p.id}/ig-${i}.jpg`);
    tiktokImages.push(`slides/${p.id}/tt-${i}.jpg`);
    if (withImages) {
      await cloud.upload(images.at(-1), slideFile(p.id, i, true), "image/jpeg");
      await cloud.upload(tiktokImages.at(-1), slideFile(p.id, i), "image/jpeg");
    }
  }
  await cloud.putJob({ id, type: "carousel", at: cloud.iso(p.schedule.at), approved: true, images, tiktokImages,
    caption: p.caption, tiktokCaption: p.tiktokCaption, title: p.caption.split("\n")[0] });
}

/** Günün hikâyelerini buluta yazar: öğret/yönlendir paylaşılır, etkileşim karesi görselli hatırlatma olur */
async function syncStories(date, approved) {
  const src = new URL(`${date}.json`, storiesSrc);
  const day = fs.existsSync(src) ? JSON.parse(fs.readFileSync(src, "utf8")) : { frames: [] };
  const done = storyLog(date);
  for (const [i, frame] of day.frames.entries()) {
    const n = i + 1, id = `story-${date}-${n}`;
    if (!fs.existsSync(storyFile(date, n))) continue;
    if (!approved) { await cloud.deleteJob(id); continue; }
    if (done[n]?.mediaId) continue;
    const media = `stories/${date}-${n}.jpg`;
    await cloud.upload(media, storyFile(date, n), "image/jpeg");
    const at = cloud.iso(`${date}T${slot(frame)}`);
    if (frame.kind === "ask") {
      await cloud.putJob({ id, type: "remind", at, approved: true, media, title: `Hikâye: ${frame.label ?? "anket"}`,
        text: `Görseli kaydet, Instagram'da hikâye olarak paylaş ve çıkartmayı ekle: ${frame.sticker ?? "anket"}` });
    } else {
      // Günün paylaşımı slayt da olabilir; karede "reel" varsa (günün ikinci paylaşımı, Bob) o beklenir
      const target = frame.reel ?? day.reel;
      const reel = target ? `${slideCount(target) ? "carousel" : "reel"}-${target}` : undefined;
      await cloud.putJob({ id, type: "story", at, approved: true, media, ...(frame.kind === "promo" && reel ? { after: reel } : {}) });
    }
  }
}

const handler = async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  // Tünelden (internetten) gelen istek yalnızca paylaşılan videoyu alabilir; panel ve API kapalı
  if (req.headers["cf-ray"] || req.headers["cf-connecting-ip"]) {
    const m = url.pathname.match(/^\/public\/([a-f0-9]+)\/([\w.-]+)$/);
    if (m && shared && m[1] === shared.token && m[2] === shared.name)
      return shared.name.endsWith(".jpg") ? sendImage(res, shared.file) : sendVideo(req, res, shared.file);
    return res.writeHead(404).end();
  }
  try {
    if (url.pathname === "/") return res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" }).end(fs.readFileSync(new URL("panel.html", here)));
    if (url.pathname.startsWith("/video/")) return sendVideo(req, res, videoFile(url.pathname.slice(7, -4)));
    if (url.pathname === "/api/state") return json(res, 200, await state());
    const cm = url.pathname.match(/^\/slide\/([\w-]+)\/(\d+)\.jpg$/);
    if (cm) return sendImage(res, slideFile(cm[1], cm[2]));
    const sm = url.pathname.match(/^\/story\/(\d{4}-\d{2}-\d{2})\/(\d+)\.jpg$/);
    if (sm) return sendImage(res, storyFile(sm[1], sm[2]));
    if (req.method !== "POST") return res.writeHead(404).end();
    const body = await readBody(req);
    if (url.pathname === "/api/caption") {
      const p = post(body.id);
      if (body.caption != null) p.caption = String(body.caption).slice(0, 2200);
      if (body.tiktokCaption != null) p.tiktokCaption = String(body.tiktokCaption).slice(0, 2200);
      if (cloud.enabled() && p.schedule?.approved && !p.instagram) await (slideCount(p.id) ? syncCarousel(carousel(p.id), false) : syncReel(p, false));
      save(p);
      return json(res, 200, { ok: true });
    }
    if (url.pathname === "/api/instagram") { const ok = startInstagram(body.id); return json(res, ok ? 200 : 409, { ok }); }
    if (url.pathname === "/api/carousel/schedule") {
      if (!cloud.enabled()) throw new Error("Kaydırmalı gönderiler bulut zamanlayıcısıyla paylaşılır (CLOUD_URL)");
      const p = carousel(body.id);
      p.schedule = { at: body.at || null, approved: !!body.approved && !!body.at };
      await syncCarousel(p);
      const { kind, count, ...rest } = p;
      save(rest);
      return json(res, 200, { ok: true });
    }
    if (url.pathname === "/api/schedule") {
      const p = post(body.id);
      p.schedule = { at: body.at || null, approved: !!body.approved && !!body.at };
      if (cloud.enabled()) await syncReel(p);
      save(p);
      return json(res, 200, { ok: true });
    }
    if (url.pathname === "/api/story") return json(res, 200, { ok: postStory(body.date, body.n) });
    if (url.pathname === "/api/story/approve") {
      if (cloud.enabled()) await syncStories(body.date, !!body.approved);
      writeStoryLog(body.date, { approved: !!body.approved });
      return json(res, 200, { ok: true });
    }
    if (url.pathname === "/api/tiktok") { const ok = startTiktok(body.id); return json(res, ok ? 200 : 409, { ok }); }
    if (url.pathname === "/api/tiktok/login") return json(res, 200, { url: tiktok.authorizeUrl() });
    if (url.pathname === "/api/tiktok/finish") {
      await tiktok.finishLogin(body.url);
      if (cloud.enabled()) await cloud.setTiktok(tokens.read().tiktok);
      return json(res, 200, { ok: true });
    }
    /** Mevcut zamanlamaları ve TikTok oturumunu buluta taşır (bulut ilk kurulduğunda bir kez) */
    if (url.pathname === "/api/cloud/migrate") {
      if (!cloud.enabled()) throw new Error("CLOUD_URL / CLOUD_TOKEN yok (marketing/.env)");
      const moved = [];
      if (tokens.read().tiktok) { await cloud.setTiktok(tokens.read().tiktok); moved.push("tiktok"); }
      for (const f of fs.readdirSync(postsDir).filter((f) => f.endsWith(".json"))) {
        const p = post(f.slice(0, -5));
        if (p.schedule?.approved && !p.instagram && fs.existsSync(videoFile(p.id))) { await syncReel(p); moved.push(p.id); }
      }
      for (const d of stories()) if (d.approved) { await syncStories(d.date, true); moved.push(d.date); }
      return json(res, 200, { ok: true, moved });
    }
    res.writeHead(404).end();
  } catch (err) {
    json(res, 400, { error: err.message });
  }
};

fs.mkdirSync(postsDir, { recursive: true });
// Yalnızca bu Mac'ten erişilir (IPv4 ve IPv6 yerel adres); yerel ağa açık değil
http.createServer(handler).listen(PORT, "127.0.0.1", () => console.log(`Onay paneli: http://localhost:${PORT}`));
http.createServer(handler).listen(PORT, "::1");

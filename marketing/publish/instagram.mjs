// Instagram Reels paylaşımı (Instagram API with Instagram Login).
// Bu yöntem dosya yüklemeyi desteklemez: Instagram videoyu herkese açık bir adresten çeker.
// Video, paylaşım süresince geçici bir Cloudflare tüneliyle (hesap gerekmez) açılır, sonra tünel kapanır.
import { spawn } from "node:child_process";
import { env } from "./env.mjs";

const API = "https://graph.instagram.com";

async function call(path, params, method = "GET") {
  const { IG_ACCESS_TOKEN } = env();
  if (!IG_ACCESS_TOKEN) throw new Error("IG_ACCESS_TOKEN yok (marketing/.env)");
  const qs = new URLSearchParams({ ...params, access_token: IG_ACCESS_TOKEN });
  const res = await fetch(`${API}/${path}?${qs}`, { method });
  const body = await res.json();
  if (!res.ok || body.error) throw new Error(`Instagram: ${body.error?.message ?? res.status}`);
  return body;
}

/** Bağlı hesap (panelde gösterilir) */
export async function account() {
  return call("me", { fields: "user_id,username" });
}

/** localhost'u geçici, herkese açık bir https adresine bağlar */
function openTunnel(port) {
  return new Promise((resolve, reject) => {
    const proc = spawn("cloudflared", ["tunnel", "--url", `http://localhost:${port}`, "--no-autoupdate"]);
    const timer = setTimeout(() => { proc.kill(); reject(new Error("Tünel açılamadı (cloudflared)")); }, 30000);
    const onData = (d) => {
      const m = d.toString().match(/https:\/\/[a-z0-9-]+\.trycloudflare\.com/);
      if (m) { clearTimeout(timer); resolve({ url: m[0], close: () => proc.kill() }); }
    };
    proc.stdout.on("data", onData);
    proc.stderr.on("data", onData);
    proc.on("error", (e) => { clearTimeout(timer); reject(e); });
  });
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * Reels paylaşır. share(path) videoyu tek seferlik bir adresle sunar ve o adresi döndürür; unshare() kapatır.
 * log: panelde gösterilen adım adım durum.
 */
export async function publish({ id, caption, port, share, unshare, log }) {
  const me = await account();
  log(`Instagram: @${me.username}`);
  const tunnel = await openTunnel(port);
  try {
    // Yeni tünelin DNS'i birkaç saniyede yayılır
    await sleep(4000);
    const videoUrl = `${tunnel.url}${share(id)}`;
    log("Video Instagram'a gönderiliyor…");
    const container = await call(`${me.user_id}/media`,
      { media_type: "REELS", video_url: videoUrl, caption, share_to_feed: "true" }, "POST");
    // Instagram videoyu indirip işler: hazır olana kadar beklenir (en fazla ~5 dk)
    for (let i = 0; i < 60; i++) {
      const { status_code, status } = await call(container.id, { fields: "status_code,status" });
      if (status_code === "FINISHED") break;
      if (status_code === "ERROR" || status_code === "EXPIRED") throw new Error(`Instagram işleyemedi: ${status ?? status_code}`);
      if (i % 3 === 0) log(`Instagram işliyor (${status_code})…`);
      await sleep(5000);
    }
    const post = await call(`${me.user_id}/media_publish`, { creation_id: container.id }, "POST");
    const { permalink } = await call(post.id, { fields: "permalink" });
    log("Instagram'da yayında ✓");
    return { mediaId: post.id, permalink, at: new Date().toISOString() };
  } finally {
    unshare();
    tunnel.close();
  }
}

/** Hikâye paylaşır (resim, 1080×1920 JPEG). share(name) resmi tek seferlik bir adresle sunar. */
export async function publishStory({ name, port, share, unshare, log }) {
  const me = await account();
  const tunnel = await openTunnel(port);
  try {
    await sleep(4000);
    log("Hikâye Instagram'a gönderiliyor…");
    const container = await call(`${me.user_id}/media`, { media_type: "STORIES", image_url: `${tunnel.url}${share(name)}` }, "POST");
    for (let i = 0; i < 24; i++) {
      const { status_code, status } = await call(container.id, { fields: "status_code,status" });
      if (status_code === "FINISHED") break;
      if (status_code === "ERROR" || status_code === "EXPIRED") throw new Error(`Instagram işleyemedi: ${status ?? status_code}`);
      await sleep(2500);
    }
    const post = await call(`${me.user_id}/media_publish`, { creation_id: container.id }, "POST");
    log("Hikâye yayında ✓");
    return { mediaId: post.id, at: new Date().toISOString() };
  } finally {
    unshare();
    tunnel.close();
  }
}

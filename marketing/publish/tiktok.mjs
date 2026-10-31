// TikTok: video Ahmet'in TikTok gelen kutusuna taslak olarak gider (Content Posting API, video.upload).
// Paylaşımı Ahmet TikTok uygulamasında ses seçip kendisi tamamlar.
import fs from "node:fs";
import crypto from "node:crypto";
import { env, tokens } from "./env.mjs";

const OPEN = "https://open.tiktokapis.com/v2";

function creds() {
  const e = env();
  if (!e.TIKTOK_CLIENT_KEY || !e.TIKTOK_CLIENT_SECRET || !e.TIKTOK_REDIRECT_URI) {
    throw new Error("TIKTOK_CLIENT_KEY / TIKTOK_CLIENT_SECRET / TIKTOK_REDIRECT_URI yok (marketing/.env)");
  }
  return e;
}

/** Giriş bağlantısı: açılır, onaylanır, yönlendirilen adres panele yapıştırılır */
export function authorizeUrl() {
  const e = creds();
  const state = crypto.randomBytes(8).toString("hex");
  tokens.write({ ...tokens.read(), tiktokState: state });
  const qs = new URLSearchParams({
    client_key: e.TIKTOK_CLIENT_KEY, scope: "user.info.basic,video.upload", response_type: "code",
    redirect_uri: e.TIKTOK_REDIRECT_URI, state,
  });
  return `https://www.tiktok.com/v2/auth/authorize/?${qs}`;
}

async function tokenRequest(params) {
  const e = creds();
  const res = await fetch(`${OPEN}/oauth/token/`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ client_key: e.TIKTOK_CLIENT_KEY, client_secret: e.TIKTOK_CLIENT_SECRET, ...params }),
  });
  const body = await res.json();
  if (!body.access_token) throw new Error(`TikTok giriş: ${body.error_description ?? body.error ?? res.status}`);
  const t = tokens.read();
  delete t.tiktokState;
  tokens.write({
    ...t,
    tiktok: {
      access: body.access_token, refresh: body.refresh_token, openId: body.open_id,
      expiresAt: Date.now() + body.expires_in * 1000,
    },
  });
}

/** Yönlendirilen adresteki kodu oturuma çevirir */
export async function finishLogin(redirectedUrl) {
  const url = new URL(redirectedUrl.trim());
  const code = url.searchParams.get("code");
  if (!code) throw new Error("Adreste kod yok: TikTok'ta onayladıktan sonra açılan adresin tamamını yapıştır");
  if (url.searchParams.get("state") !== tokens.read().tiktokState) throw new Error("Giriş isteği eşleşmedi, bağlantıyı tekrar aç");
  await tokenRequest({ code, grant_type: "authorization_code", redirect_uri: creds().TIKTOK_REDIRECT_URI });
}

async function accessToken() {
  const t = tokens.read().tiktok;
  if (!t) throw new Error("TikTok bağlı değil");
  if (Date.now() > t.expiresAt - 60_000) await tokenRequest({ grant_type: "refresh_token", refresh_token: t.refresh });
  return tokens.read().tiktok.access;
}

async function api(path, body) {
  const res = await fetch(`${OPEN}${path}`, {
    method: "POST",
    headers: { Authorization: `Bearer ${await accessToken()}`, "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify(body ?? {}),
  });
  const out = await res.json();
  if (out.error && out.error.code !== "ok") throw new Error(`TikTok: ${out.error.message || out.error.code}`);
  return out.data;
}

/** Bağlı hesap (panelde gösterilir) */
export async function account() {
  // "username" ek izin (user.info.profile) ister; temel izinle görünen ad gelir
  const res = await fetch(`${OPEN}/user/info/?fields=open_id,display_name`, {
    headers: { Authorization: `Bearer ${await accessToken()}` },
  });
  const out = await res.json();
  if (out.error && out.error.code !== "ok") throw new Error(`TikTok: ${out.error.message || out.error.code}`);
  return { username: out.data?.user?.display_name };
}

/** Videoyu gelen kutusuna taslak olarak yükler */
export async function upload({ file, log }) {
  const size = fs.statSync(file).size;
  // TikTok kuralı: parçalar 5–64 MB; 64 MB altındaki video tek parça gider
  const chunk = size <= 64 * 1024 * 1024 ? size : 10 * 1024 * 1024;
  const count = Math.floor(size / chunk);
  log("TikTok'a yükleniyor…");
  const { upload_url, publish_id } = await api("/post/publish/inbox/video/init/", {
    source_info: { source: "FILE_UPLOAD", video_size: size, chunk_size: chunk, total_chunk_count: count },
  });
  const data = fs.readFileSync(file);
  for (let i = 0; i < count; i++) {
    const start = i * chunk;
    const end = i === count - 1 ? size - 1 : start + chunk - 1;
    const res = await fetch(upload_url, {
      method: "PUT",
      headers: { "Content-Type": "video/mp4", "Content-Range": `bytes ${start}-${end}/${size}` },
      body: data.subarray(start, end + 1),
    });
    if (!res.ok) throw new Error(`TikTok yükleme ${res.status}`);
  }
  for (let i = 0; i < 24; i++) {
    const s = await api("/post/publish/status/fetch/", { publish_id });
    if (s.status === "SEND_TO_USER_INBOX" || s.status === "PUBLISH_COMPLETE") {
      log("TikTok gelen kutunda ✓ (uygulamadan ses seçip paylaş)");
      return { publishId: publish_id, at: new Date().toISOString() };
    }
    if (s.status === "FAILED") throw new Error(`TikTok işleyemedi: ${s.fail_reason}`);
    await new Promise((r) => setTimeout(r, 5000));
  }
  throw new Error("TikTok yanıt vermedi; gelen kutunu kontrol et");
}

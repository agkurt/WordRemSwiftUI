// WordRem sosyal medya zamanlayıcısı (Cloudflare Worker).
// Mac'teki panel onaylanan videoyu/kareyi buluta (KV) yükler ve işi kuyruğa yazar; bu worker 5 dakikada bir saati gelen
// işleri ilerletir: Instagram Reels/hikâye paylaşımı, TikTok gelen kutusuna taslak, telefona bildirim (ntfy).
// Mac kapalıyken de çalışır. Uygulamanın sunucusuyla (wordrem-voice) ilgisi yoktur.
//
// Bağlama: STATE (KV; kuyruk, oturumlar ve "media:" önekiyle dosyalar, tek dosya en fazla 25 MB). Gizli: ADMIN_TOKEN, IG_ACCESS_TOKEN, TIKTOK_CLIENT_KEY, TIKTOK_CLIENT_SECRET, NTFY_TOPIC.

const IG = "https://graph.instagram.com";
const TT = "https://open.tiktokapis.com/v2";

export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    // Instagram'ın çektiği dosya: imzalı, tek dosyaya özel adres
    const m = url.pathname.match(/^\/m\/(.+)$/);
    if (m && req.method === "GET") {
      const key = decodeURIComponent(m[1]);
      if (url.searchParams.get("s") !== (await sign(env, key))) return new Response("not found", { status: 404 });
      const { value, metadata } = await env.STATE.getWithMetadata(`media:${key}`, { type: "arrayBuffer" });
      if (!value) return new Response("not found", { status: 404 });
      return new Response(value, { headers: { "Content-Type": metadata?.type ?? "application/octet-stream" } });
    }
    // TikTok alan adı doğrulama dosyası (fotoğraflı gönderi adresten çekildiği için gerekli)
    const verify = url.pathname.match(/^\/([\w.-]+\.txt)$/);
    if (verify && req.method === "GET") {
      const body = await env.STATE.get(`verify:${verify[1]}`);
      if (body != null) return new Response(body, { headers: { "Content-Type": "text/plain" } });
    }
    if (!url.pathname.startsWith("/admin/")) return new Response("WordRem", { status: 200 });
    if (req.headers.get("Authorization") !== `Bearer ${env.ADMIN_TOKEN}`) return new Response("unauthorized", { status: 401 });
    return admin(req, env, url).catch((e) => json({ error: e.message }, 400));
  },

  async scheduled(_event, env, ctx) {
    ctx.waitUntil(tick(env));
  },
};

// ---------- yönetim (yalnızca panel, ADMIN_TOKEN ile) ----------

async function admin(req, env, url) {
  const path = url.pathname.slice("/admin/".length);
  if (path.startsWith("media/") && req.method === "PUT") {
    const key = decodeURIComponent(path.slice("media/".length));
    const data = await req.arrayBuffer();
    if (data.byteLength > 25 * 1024 * 1024) throw new Error(`${key} 25 MB'tan büyük (${(data.byteLength / 1048576).toFixed(1)} MB)`);
    await env.STATE.put(`media:${key}`, data, { metadata: { type: req.headers.get("Content-Type") ?? "application/octet-stream" } });
    return json({ ok: true, key });
  }
  if (path === "jobs" && req.method === "GET") return json({ jobs: await jobs(env), tiktok: !!(await env.STATE.get("tiktok")) });
  if (path.startsWith("jobs/")) {
    const id = decodeURIComponent(path.slice("jobs/".length));
    const list = await jobs(env);
    const i = list.findIndex((j) => j.id === id);
    if (req.method === "PUT") {
      const job = await req.json();
      // Paylaşılmış işin durumu korunur; panel yalnızca saati, metni ve onayı değiştirir
      const merged = { ...job, id, state: i >= 0 ? list[i].state : {} };
      if (i >= 0) list[i] = merged; else list.push(merged);
      await saveJobs(env, list);
      return json({ ok: true, job: merged });
    }
    if (req.method === "DELETE") {
      if (i >= 0) list.splice(i, 1);
      await saveJobs(env, list);
      return json({ ok: true });
    }
  }
  if (path === "tiktok" && req.method === "PUT") {
    await env.STATE.put("tiktok", JSON.stringify(await req.json()));
    return json({ ok: true });
  }
  if (path === "verify" && req.method === "PUT") {
    const { name, content } = await req.json();
    await env.STATE.put(`verify:${name}`, content);
    return json({ ok: true });
  }
  if (path === "tick" && req.method === "POST") return json(await tick(env));
  return json({ error: "not found" }, 404);
}

// ---------- kuyruk ----------

const jobs = async (env) => JSON.parse((await env.STATE.get("jobs")) ?? "[]");
const saveJobs = (env, list) => env.STATE.put("jobs", JSON.stringify(list));

/**
 * Saati gelmiş, onaylı ve bitmemiş işleri birer adım ilerletir. Her adım kısa sürer (Instagram'ın videoyu işlemesi
 * gibi beklemeler sonraki tura kalır), böylece ücretsiz plandaki zaman sınırına takılmaz.
 */
async function tick(env) {
  const list = await jobs(env);
  const now = Date.now();
  const report = [];
  for (const job of list.filter((j) => j.approved && !j.done && Date.parse(j.at) <= now).sort((a, b) => Date.parse(a.at) - Date.parse(b.at))) {
    job.state ??= {};
    try {
      if (job.type === "reel") await stepReel(env, job, list);
      else if (job.type === "story") await stepStory(env, job, list);
      else if (job.type === "carousel") await stepCarousel(env, job);
      else if (job.type === "remind") { await notify(env, job.text, job.title ?? "WordRem", job.media && (await mediaUrl(env, job.media))); job.done = true; }
      job.state.error = undefined;
    } catch (e) {
      job.state.tries = (job.state.tries ?? 0) + 1;
      job.state.error = e.message;
      // Üç denemede olmazsa durur ve haber verir
      if (job.state.tries >= 3) { job.done = true; job.state.failed = true; await notify(env, `${job.id}: ${e.message}`, "WordRem paylaşım hatası"); }
    }
    // Paylaşılan dosya bulutta yer kaplamasın; TikTok onu henüz almadıysa (slayt görselleri adresten sonradan çekilir) bekler
    if (job.done && !tiktokPending(job)) await purge(env, job);
    report.push({ id: job.id, done: !!job.done, state: job.state });
  }
  // TikTok taslağı arka planda işlenir: sonucu sorulur, bildirim ancak taslak gelen kutusuna düşünce gider
  for (const job of list.filter((j) => j.done && tiktokPending(j))) {
    try { await checkTiktok(env, job); } catch (e) { job.state.tiktok.checkError = e.message; }
    if (!tiktokPending(job)) await purge(env, job);
    report.push({ id: job.id, tiktok: job.state.tiktok });
  }
  await saveJobs(env, list);
  return { ran: report.length, report };
}

async function stepReel(env, job) {
  const s = job.state;
  // tiktokOnly: Instagram'da zaten yayında, yalnızca TikTok taslağı yeniden gönderilir
  if (!s.ig?.mediaId && !job.tiktokOnly) {
    s.ig = await stepInstagram(env, s.ig ?? {}, { media_type: "REELS", video_url: await mediaUrl(env, job.media), caption: job.caption ?? "", share_to_feed: "true" });
    if (!s.ig.mediaId) return;
  }
  // Bildirim taslak gelen kutusuna düşünce gider (checkTiktok)
  if (!s.tiktok && (await env.STATE.get("tiktok"))) s.tiktok = await tiktokDraft(env, job.media);
  job.done = true;
}

async function stepStory(env, job, list) {
  // Yönlendirme karesi, o günün reel'i Instagram'da yayınlanmadan gitmez
  if (job.after) {
    const reel = list.find((j) => j.id === job.after);
    if (reel && !reel.state?.ig?.mediaId) return;
  }
  job.state.ig = await stepInstagram(env, job.state.ig ?? {}, { media_type: "STORIES", [job.media.endsWith(".mp4") ? "video_url" : "image_url"]: await mediaUrl(env, job.media) });
  if (job.state.ig.mediaId) job.done = true;
}

/** Kaydırmalı gönderi: Instagram karuseli (4:5), sonra TikTok gelen kutusuna fotoğraf modu taslağı (9:16) */
async function stepCarousel(env, job) {
  const s = job.state;
  if (!s.ig?.mediaId && !job.tiktokOnly) {
    if (!s.children) {
      await refreshInstagram(env);
      const me = await ig(env, "me", { fields: "user_id" });
      const children = [];
      for (const key of job.images) children.push((await ig(env, `${me.user_id}/media`, { image_url: await mediaUrl(env, key), is_carousel_item: "true" }, "POST")).id);
      s.children = children;
    }
    s.ig = await stepInstagram(env, s.ig ?? {}, { media_type: "CAROUSEL", children: s.children.join(","), caption: job.caption ?? "" });
    if (!s.ig.mediaId) return;
  }
  if (!s.tiktok && job.tiktokImages?.length && (await env.STATE.get("tiktok"))) {
    const token = await tiktokToken(env);
    const res = await fetch(`${TT}/post/publish/content/init/`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({
        media_type: "PHOTO", post_mode: "MEDIA_UPLOAD",
        post_info: { title: (job.title ?? "").slice(0, 90), description: job.tiktokCaption || job.caption || "" },
        source_info: { source: "PULL_FROM_URL", photo_cover_index: 0, photo_images: await Promise.all(job.tiktokImages.map((k) => mediaUrl(env, k))) },
      }),
    });
    const out = await res.json();
    if (out.error && out.error.code !== "ok") {
      // Alan adı doğrulanmamışsa Instagram paylaşımı bozulmasın: TikTok için elle paylaşma hatırlatması gider
      s.tiktok = { error: out.error.code };
      await notify(env, `TikTok fotoğraflı taslak gönderilemedi (${out.error.code}). Slaytları panelden indirip elle paylaş.`, `TikTok: ${job.id}`);
    } else {
      // TikTok görselleri adresten sonradan çeker: dosyalar ve bildirim, taslak gelen kutusuna düşene kadar bekler (checkTiktok)
      s.tiktok = { publishId: out.data?.publish_id, at: new Date().toISOString() };
    }
  }
  job.done = true;
}

// ---------- Instagram ----------

async function ig(env, path, params = {}, method = "GET") {
  const token = (await env.STATE.get("ig_token")) ?? env.IG_ACCESS_TOKEN;
  const qs = new URLSearchParams({ ...params, access_token: token });
  const res = await fetch(`${IG}/${path}?${qs}`, { method });
  const body = await res.json();
  if (!res.ok || body.error) throw new Error(`Instagram: ${body.error?.message ?? res.status}`);
  return body;
}

/** Kapsayıcı oluştur → işlenmesini bekle (sonraki turlar) → yayınla */
async function stepInstagram(env, st, params) {
  await refreshInstagram(env);
  const me = await ig(env, "me", { fields: "user_id" });
  if (!st.container) return { container: (await ig(env, `${me.user_id}/media`, params, "POST")).id };
  const { status_code, status } = await ig(env, st.container, { fields: "status_code,status" });
  if (status_code === "ERROR" || status_code === "EXPIRED") throw new Error(`Instagram işleyemedi: ${status ?? status_code}`);
  if (status_code !== "FINISHED") return st;
  const post = await ig(env, `${me.user_id}/media_publish`, { creation_id: st.container }, "POST");
  const info = await ig(env, post.id, { fields: "permalink" }).catch(() => ({}));
  return { ...st, mediaId: post.id, permalink: info.permalink, at: new Date().toISOString() };
}

/** Uzun ömürlü Instagram anahtarı 60 gün geçerli: ayda bir yenilenir */
async function refreshInstagram(env) {
  const last = Number((await env.STATE.get("ig_refreshed")) ?? 0);
  if (Date.now() - last < 30 * 86400_000) return;
  const token = (await env.STATE.get("ig_token")) ?? env.IG_ACCESS_TOKEN;
  const res = await fetch(`${IG}/refresh_access_token?grant_type=ig_refresh_token&access_token=${token}`);
  const body = await res.json();
  if (body.access_token) await env.STATE.put("ig_token", body.access_token);
  await env.STATE.put("ig_refreshed", String(Date.now()));
}

// ---------- TikTok (gelen kutusuna taslak) ----------

async function tiktokToken(env) {
  const t = JSON.parse((await env.STATE.get("tiktok")) ?? "null");
  if (!t) throw new Error("TikTok bağlı değil");
  if (Date.now() < t.expiresAt - 60_000) return t.access;
  const res = await fetch(`${TT}/oauth/token/`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ client_key: env.TIKTOK_CLIENT_KEY, client_secret: env.TIKTOK_CLIENT_SECRET, grant_type: "refresh_token", refresh_token: t.refresh }),
  });
  const b = await res.json();
  if (!b.access_token) throw new Error(`TikTok oturumu yenilenemedi: ${b.error_description ?? b.error}`);
  const next = { ...t, access: b.access_token, refresh: b.refresh_token ?? t.refresh, expiresAt: Date.now() + b.expires_in * 1000 };
  await env.STATE.put("tiktok", JSON.stringify(next));
  return next.access;
}

async function tiktokDraft(env, key) {
  const buf = await env.STATE.get(`media:${key}`, { type: "arrayBuffer" });
  if (!buf) throw new Error(`${key} bulutta yok`);
  const data = new Uint8Array(buf);
  const size = data.byteLength;
  // TikTok kuralı: parçalar 5–64 MB; 64 MB altındaki video tek parça
  const chunk = size <= 64 * 1024 * 1024 ? size : 10 * 1024 * 1024;
  const count = Math.floor(size / chunk);
  const token = await tiktokToken(env);
  const res = await fetch(`${TT}/post/publish/inbox/video/init/`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify({ source_info: { source: "FILE_UPLOAD", video_size: size, chunk_size: chunk, total_chunk_count: count } }),
  });
  const out = await res.json();
  if (out.error && out.error.code !== "ok") throw new Error(`TikTok: ${out.error.message || out.error.code}`);
  const { upload_url, publish_id } = out.data;
  for (let i = 0; i < count; i++) {
    const start = i * chunk;
    const end = i === count - 1 ? size - 1 : start + chunk - 1;
    const put = await fetch(upload_url, {
      method: "PUT",
      headers: { "Content-Type": "video/mp4", "Content-Range": `bytes ${start}-${end}/${size}` },
      body: data.subarray(start, end + 1),
    });
    if (!put.ok) throw new Error(`TikTok yükleme ${put.status}`);
  }
  return { publishId: publish_id, at: new Date().toISOString() };
}

// ---------- yardımcılar ----------

/** Telefona bildirim (ntfy uygulaması, gizli konu adı) */
async function notify(env, text, title, attach) {
  if (!env.NTFY_TOPIC) return;
  // JSON ile gönderilir: başlıkta Türkçe karakter HTTP başlığına sığmaz
  await fetch("https://ntfy.sh/", { method: "POST", headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ topic: env.NTFY_TOPIC, title, message: text, ...(attach ? { attach } : {}) }) });
}

async function sign(env, key) {
  const k = await crypto.subtle.importKey("raw", new TextEncoder().encode(env.ADMIN_TOKEN), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", k, new TextEncoder().encode(key));
  return [...new Uint8Array(sig)].slice(0, 16).map((b) => b.toString(16).padStart(2, "0")).join("");
}

const tiktokPending = (job) => !!job.state?.tiktok?.publishId && !job.state.tiktok.result;
const purge = async (env, job) => {
  for (const k of [job.media, ...(job.images ?? []), ...(job.tiktokImages ?? [])].filter(Boolean)) await env.STATE.delete(`media:${k}`);
};

/** TikTok taslağının durumu: gelen kutusuna düştüyse açıklamayla bildirim, düşmediyse sebebiyle hata bildirimi */
async function checkTiktok(env, job) {
  const t = job.state.tiktok;
  // Bu kontrol eklenmeden önce gönderilmiş eski taslaklar sessizce kapanır
  if (Date.now() - Date.parse(t.at) > 24 * 3600_000) { t.result = "unknown"; return; }
  const res = await fetch(`${TT}/post/publish/status/fetch/`, {
    method: "POST",
    headers: { Authorization: `Bearer ${await tiktokToken(env)}`, "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify({ publish_id: t.publishId }),
  });
  const out = await res.json();
  if (out.error && out.error.code !== "ok") throw new Error(`TikTok durum: ${out.error.message || out.error.code}`);
  t.status = out.data?.status;
  if (t.status === "SEND_TO_USER_INBOX" || t.status === "PUBLISH_COMPLETE") {
    t.result = "inbox";
    // Açıklama bildirimin içinde: telefonda bildirime basılı tutup kopyalanır
    await notify(env, job.tiktokCaption || job.caption || "", `TikTok taslağı hazır: ${job.id}`);
  } else if (t.status === "FAILED") {
    t.result = "failed";
    t.reason = out.data?.fail_reason;
    await notify(env, `TikTok taslağı gelen kutusuna düşmedi (${t.reason}). Yeniden göndermek için: node publish/resend-tiktok.mjs ${job.id.replace(/^(reel|carousel)-/, "")}`, `TikTok hatası: ${job.id}`);
  } else if (Date.now() - Date.parse(t.at) > 6 * 3600_000) {
    t.result = "timeout";
    await notify(env, `TikTok taslağı 6 saattir işleniyor (${t.status}). Gelen kutunu kontrol et.`, `TikTok: ${job.id}`);
  }
}

async function mediaUrl(env, key) {
  return `${env.PUBLIC_URL}/m/${encodeURIComponent(key)}?s=${await sign(env, key)}`;
}

const json = (body, status = 200) => new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

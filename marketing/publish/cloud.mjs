// Bulut zamanlayıcısı (marketing/cloud, Cloudflare Worker) ile konuşur.
// marketing/.env → CLOUD_URL (https://publish.wordremai.app) ve CLOUD_TOKEN (worker'daki ADMIN_TOKEN).
// İkisi de doluysa panel zamanlanan işleri buluta yazar ve Mac'teki zamanlayıcı çalışmaz.
import fs from "node:fs";
import https from "node:https";
import dns from "node:dns";
import { env } from "./env.mjs";

// Alan adı Cloudflare DNS'inden (1.1.1.1) çözülür: Mac'in ya da internet sağlayıcısının DNS önbelleği yeni kaydı geç görebiliyor
const resolver = new dns.Resolver();
resolver.setServers(["1.1.1.1", "1.0.0.1"]);
const lookup = (host, opts, cb) => resolver.resolve4(host, (err, ips) => {
  if (err || !ips?.length) return dns.lookup(host, opts, cb);
  return opts?.all ? cb(null, ips.map((address) => ({ address, family: 4 }))) : cb(null, ips[0], 4);
});

function request(url, { method = "GET", headers = {}, body } = {}) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, { method, headers: { ...headers, ...(body ? { "Content-Length": Buffer.byteLength(body) } : {}) }, lookup }, (res) => {
      const chunks = [];
      res.on("data", (c) => chunks.push(c));
      res.on("end", () => resolve({ status: res.statusCode, text: Buffer.concat(chunks).toString("utf8") }));
    });
    req.on("error", reject);
    req.setTimeout(120_000, () => req.destroy(new Error("Bulut yanıt vermedi")));
    if (body) req.write(body);
    req.end();
  });
}

export const enabled = () => { const e = env(); return !!(e.CLOUD_URL && e.CLOUD_TOKEN); };

async function call(path, init = {}) {
  const e = env();
  const res = await request(`${e.CLOUD_URL}/admin/${path}`, { ...init, headers: { Authorization: `Bearer ${e.CLOUD_TOKEN}`, ...(init.headers ?? {}) } });
  let body = {};
  try { body = JSON.parse(res.text); } catch {}
  if (res.status < 200 || res.status >= 300) throw new Error(`Bulut: ${body.error ?? res.status}`);
  return body;
}

/** Dosyayı buluta (KV) yükler (aynı anahtar varsa üzerine yazar) */
export const upload = (key, file, type) =>
  call(`media/${encodeURIComponent(key)}`, { method: "PUT", headers: { "Content-Type": type }, body: fs.readFileSync(file) });

export const putJob = (job) =>
  call(`jobs/${encodeURIComponent(job.id)}`, { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify(job) });

export const deleteJob = (id) => call(`jobs/${encodeURIComponent(id)}`, { method: "DELETE" });

export const jobs = () => call("jobs");

export const setTiktok = (session) =>
  call("tiktok", { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify(session) });

/** Panelin yerel saati (Türkiye, UTC+3) → bulutun anladığı zaman */
export const iso = (local) => `${local.length === 16 ? `${local}:00` : local}+03:00`;

import { privacyPage, termsPage } from "./legal";
/**
 * WordRem sesli öğretmen arka ucu (Cloudflare Worker).
 *
 * Uygulama OpenAI anahtarını hiç görmez. Akış:
 *   1) POST /v1/voice/session  → RevenueCat'ten hak kontrolü + dakika sınırı → OpenAI'den kısa ömürlü
 *      Realtime anahtarı (ek_...) alınır ve uygulamaya izin verilen süreyle birlikte döner.
 *   2) Uygulama doğrudan OpenAI Realtime'a WebSocket ile bağlanır.
 *   3) POST /v1/voice/usage    → oturum boyunca/sonunda harcanan saniyeler sayaca yazılır.
 *
 * Sınırlar (saniye, wrangler.toml [vars]):
 *   - Ücretsiz kullanıcı: bir kerelik FREE_TASTE_SECONDS
 *   - Deneme süresindeki Pro: günde TRIAL_DAILY_SECONDS
 *   - Pro: oturum başına SESSION_MAX_SECONDS, günde PRO_DAILY_SECONDS; aylık sınır ödenen fiyattan hesaplanır:
 *       aylık net gelir (Apple payı ve KDV düşülür, yıllık 12'ye bölünür) × AI_BUDGET_SHARE / COST_PER_MIN_USD
 *     MIN_MONTHLY_SECONDS … PRO_MONTHLY_SECONDS aralığında tutulur. Fiyat okunamazsa en düşük sınır uygulanır.
 */

export interface Env {
  USAGE: KVNamespace;
  OPENAI_API_KEY: string;
  RC_SECRET_KEY: string;
  APP_SHARED_KEY: string;
  REALTIME_MODEL: string;
  VOICE: string;
  RC_ENTITLEMENT: string;
  FREE_TASTE_SECONDS: string;
  SESSION_MAX_SECONDS: string;
  TRIAL_DAILY_SECONDS: string;
  PRO_DAILY_SECONDS: string;
  PRO_MONTHLY_SECONDS: string;
  MIN_MONTHLY_SECONDS: string;
  COST_PER_MIN_USD: string;
  REALTIME_MODEL_HIGH: string;
  HIGH_COST_MULTIPLIER: string;
  AI_BUDGET_SHARE: string;
  APPLE_COMMISSION: string;
}

type Tier = "free" | "trial" | "pro";

interface Plan {
  tier: Tier;
  /** Pro için ödenen fiyata göre aylık saniye sınırı */
  monthlySeconds: number;
}

/** Yaklaşık USD kurları (düşük tarafta tutuldu: kur hatası dakika vermek yerine kısar). Gerekirse güncelleyin. */
const USD_RATE: Record<string, number> = {
  USD: 1, EUR: 1.05, GBP: 1.25, CHF: 1.1, CAD: 0.7, AUD: 0.63, NZD: 0.58, TRY: 0.022, JPY: 0.0063,
  KRW: 0.0007, CNY: 0.135, INR: 0.0112, BRL: 0.17, MXN: 0.05, PLN: 0.24, SEK: 0.09, NOK: 0.09,
  DKK: 0.14, CZK: 0.042, HUF: 0.0026, RON: 0.21, ILS: 0.26, AED: 0.27, SAR: 0.26, ZAR: 0.053,
  SGD: 0.73, HKD: 0.127, TWD: 0.03, THB: 0.028, IDR: 0.00006, MYR: 0.21, PHP: 0.017, VND: 0.000039,
  EGP: 0.02, PKR: 0.0035, NGN: 0.0006, CLP: 0.001, COP: 0.00023, PEN: 0.26, KZT: 0.0019,
};

/** Uygulama içi fiyatlar KDV dahildir; Apple payından önce düşülür (bilinmeyen para birimi: %20 varsay) */
const VAT: Record<string, number> = { USD: 0, CAD: 0.05, AUD: 0.1, JPY: 0.1, TRY: 0.2, EUR: 0.2, GBP: 0.2 };

/** Ürün kimliğinden faturalama dönemi (ay) */
function periodMonths(productId: string, sub: any): number {
  if (/annual|year/i.test(productId)) return 12;
  if (/week/i.test(productId)) return 12 / 52;
  if (/month/i.test(productId)) return 1;
  const start = Date.parse(sub?.purchase_date ?? ""), end = Date.parse(sub?.expires_date ?? "");
  return start && end && end > start ? Math.max(0.2, (end - start) / (30 * 864e5)) : 12;
}

function monthlySecondsFor(env: Env, productId: string, sub: any): number {
  const min = Number(env.MIN_MONTHLY_SECONDS), max = Number(env.PRO_MONTHLY_SECONDS);
  const amount = Number(sub?.price?.amount);
  const currency = String(sub?.price?.currency ?? "").toUpperCase();
  const rate = USD_RATE[currency];
  if (!(amount > 0) || !rate) return min;
  const vat = VAT[currency] ?? 0.2;
  const netPerMonth = ((amount / (1 + vat)) * (1 - Number(env.APPLE_COMMISSION)) * rate) / periodMonths(productId, sub);
  const minutes = (netPerMonth * Number(env.AI_BUDGET_SHARE)) / Number(env.COST_PER_MIN_USD);
  return Math.round(Math.min(max, Math.max(min, minutes * 60)));
}

interface SessionRequest {
  appUserId: string;
  instructions: string;
  tools?: unknown[];
  voice?: string;
  speed?: number;
  /** "high": demo ve dersler (tam model), diğerleri mini */
  quality?: string;
}

interface UsageRequest {
  appUserId: string;
  sessionId: string;
  seconds: number;
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

const dayKey = (d = new Date()) => d.toISOString().slice(0, 10);   // 2026-10-26
const monthKey = (d = new Date()) => d.toISOString().slice(0, 7);  // 2026-10

async function getNum(env: Env, key: string): Promise<number> {
  return Number((await env.USAGE.get(key)) ?? 0);
}

/** KV yazma sınırı dolsa bile ders açılmaya devam etsin: sayaç yazılamazsa oturum düşmez */
async function safePut(env: Env, key: string, value: string, opts?: KVNamespacePutOptions): Promise<void> {
  try { await env.USAGE.put(key, value, opts); } catch (e) { console.log("kv put failed", key, String(e)); }
}

/** Kısa ömürlü önbellek/sayaçlar KV yerine Cache API'de (KV yazma kotası harcamaz) */
const cacheURL = (key: string) => `https://cache.wordrem.internal/${encodeURIComponent(key)}`;
async function cacheGet(key: string): Promise<string | null> {
  const res = await caches.default.match(cacheURL(key));
  return res ? await res.text() : null;
}
async function cachePut(key: string, value: string, ttl: number): Promise<void> {
  await caches.default.put(cacheURL(key), new Response(value, { headers: { "cache-control": `max-age=${ttl}` } }));
}

/** Ücretli/deneme kullanıcının günlük + aylık sayacı tek kayıtta (rapor başına tek yazma) */
type PaidUsage = { d: string; ds: number; m: string; ms: number };
async function paidUsage(env: Env, user: string): Promise<PaidUsage> {
  const raw = await env.USAGE.get(`p:${user}`);
  const u = raw ? (JSON.parse(raw) as PaidUsage) : { d: dayKey(), ds: 0, m: monthKey(), ms: 0 };
  if (u.d !== dayKey()) { u.d = dayKey(); u.ds = 0; }
  if (u.m !== monthKey()) { u.m = monthKey(); u.ms = 0; }
  return u;
}

/** RevenueCat: kullanıcının Pro hakkı var mı, deneme süresinde mi, ne ödüyor? */
async function planFor(env: Env, appUserId: string): Promise<Plan> {
  // Her turda RevenueCat'e gitmemek için 5 dk önbellek
  const cacheKey = `plan:${appUserId}`;
  const cached = await cacheGet(cacheKey);
  if (cached) return JSON.parse(cached) as Plan;
  const plan = await fetchPlan(env, appUserId);
  await cachePut(cacheKey, JSON.stringify(plan), 300);
  return plan;
}

async function fetchPlan(env: Env, appUserId: string): Promise<Plan> {
  const free: Plan = { tier: "free", monthlySeconds: 0 };
  const res = await fetch(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`, {
    headers: { Authorization: `Bearer ${env.RC_SECRET_KEY}` },
  });
  if (!res.ok) return free;
  const data: any = await res.json();
  const subscriber = data?.subscriber ?? {};
  const ent = subscriber.entitlements?.[env.RC_ENTITLEMENT] ?? subscriber.entitlements?.pro;
  if (!ent) return free;
  const expires = ent.expires_date ? Date.parse(ent.expires_date) : Infinity;
  if (expires < Date.now()) return free;
  const sub = subscriber.subscriptions?.[ent.product_identifier];
  return {
    tier: sub?.period_type === "trial" ? "trial" : "pro",
    monthlySeconds: monthlySecondsFor(env, ent.product_identifier ?? "", sub),
  };
}

/** Bu kullanıcı şu an kaç saniye konuşabilir? */
async function allowance(env: Env, user: string, plan: Plan): Promise<number> {
  const session = Number(env.SESSION_MAX_SECONDS);
  if (plan.tier === "free") {
    const used = await getNum(env, `free:${user}`);
    return Math.max(0, Number(env.FREE_TASTE_SECONDS) - used);
  }
  const daily = plan.tier === "trial" ? Number(env.TRIAL_DAILY_SECONDS) : Number(env.PRO_DAILY_SECONDS);
  const u = await paidUsage(env, user);
  return Math.max(0, Math.min(session, daily - u.ds, plan.monthlySeconds - u.ms));
}

async function createSession(req: Request, env: Env): Promise<Response> {
  const body = (await req.json().catch(() => null)) as SessionRequest | null;
  if (!body?.appUserId || !body.instructions) return json({ error: "bad_request" }, 400);
  if (body.instructions.length > 24000) return json({ error: "instructions_too_long" }, 400);

  const plan = await planFor(env, body.appUserId);
  const { tier } = plan;
  const seconds = await allowance(env, body.appUserId, plan);
  if (seconds < 15) {
    return json({ error: tier === "free" ? "paywall" : "limit_reached", tier, remainingSeconds: seconds }, 402);
  }

  const high = body.quality === "high" && !!env.REALTIME_MODEL_HIGH;
  const model = high ? env.REALTIME_MODEL_HIGH : env.REALTIME_MODEL;
  // Tam model ~3 kat pahalı: aylık bütçeden o oranda düşülür (ücretsiz tadım ve günlük süre etkilenmez)
  const weight = high ? Number(env.HIGH_COST_MULTIPLIER || 3) : 1;
  const session = {
    type: "realtime",
    model,
    instructions: body.instructions,
    max_output_tokens: 1200,
    audio: {
      input: {
        format: { type: "audio/pcm", rate: 24000 },
        noise_reduction: { type: "near_field" },
        transcription: { model: "gpt-4o-mini-transcribe" },
        turn_detection: null,   // bas-konuş: istemci basılı tutunca gönderir
      },
      output: {
        format: { type: "audio/pcm", rate: 24000 },
        voice: body.voice || env.VOICE,
        speed: Math.min(1.2, Math.max(0.7, Number(body.speed) || 1)),
      },
    },
    tools: (body.tools ?? []).slice(0, 8),
    tool_choice: "auto",
  };

  const res = await fetch("https://api.openai.com/v1/realtime/client_secrets", {
    method: "POST",
    headers: { Authorization: `Bearer ${env.OPENAI_API_KEY}`, "content-type": "application/json" },
    body: JSON.stringify({ expires_after: { anchor: "created_at", seconds: 120 }, session }),
  });
  if (!res.ok) return json({ error: "upstream", status: res.status, detail: await res.text() }, 502);
  const secret: any = await res.json();

  const sessionId = crypto.randomUUID();
  // Oturum kaydı: kullanım raporlarında üst sınır kontrolü için
  await safePut(env, `s:${sessionId}`, JSON.stringify({ user: body.appUserId, plan, seconds, reported: 0, weight }), {
    expirationTtl: 60 * 60 * 3,
  });

  return json({
    sessionId,
    clientSecret: secret.value,
    expiresAt: secret.expires_at,
    model,
    allowedSeconds: seconds,
    tier,
  });
}

async function reportUsage(req: Request, env: Env): Promise<Response> {
  const body = (await req.json().catch(() => null)) as UsageRequest | null;
  if (!body?.appUserId || !body.sessionId || !(body.seconds >= 0)) return json({ error: "bad_request" }, 400);

  const raw = await env.USAGE.get(`s:${body.sessionId}`);
  if (!raw) return json({ error: "unknown_session" }, 404);
  const s = JSON.parse(raw) as { user: string; plan: Plan; seconds: number; reported: number; weight?: number };
  if (s.user !== body.appUserId) return json({ error: "forbidden" }, 403);

  // Toplam rapor, oturuma verilen süreyi (ve 60 dk oturum tavanını) aşamaz; sadece fark yazılır
  const total = Math.min(Math.ceil(body.seconds), Math.max(s.seconds, 3600));
  const delta = Math.max(0, total - s.reported);
  if (delta > 0) {
    if (s.plan.tier === "free") {
      await safePut(env, `free:${s.user}`, String((await getNum(env, `free:${s.user}`)) + delta));
    } else {
      const u = await paidUsage(env, s.user);
      u.ds += delta; u.ms += Math.round(delta * (s.weight ?? 1));
      await safePut(env, `p:${s.user}`, JSON.stringify(u), { expirationTtl: 60 * 60 * 24 * 40 });
    }
    s.reported = total;
    await safePut(env, `s:${body.sessionId}`, JSON.stringify(s), { expirationTtl: 60 * 60 * 3 });
  }
  return json({ ok: true, remainingSeconds: await allowance(env, s.user, s.plan) });
}

/**
 * Onboarding gibi yerlerde öğretmenin AYNI sesiyle kısa seslendirme (mikrofon gerekmez).
 * Kötüye kullanıma karşı: en fazla 600 karakter, kullanıcı başına günde 20 istek.
 */
function speech(env: Env, text: string, format: "pcm" | "mp3"): Promise<Response> {
  return fetch("https://api.openai.com/v1/audio/speech", {
    method: "POST",
    headers: { Authorization: `Bearer ${env.OPENAI_API_KEY}`, "content-type": "application/json" },
    body: JSON.stringify({
      model: "gpt-4o-mini-tts",
      voice: env.VOICE,
      input: text,
      instructions: "Charming, attractive young woman tutor: warm, smiling, playful and a little flirty-teasing. Very clear pronunciation, natural pace, expressive.",
      response_format: format,
    }),
  });
}

async function tts(req: Request, env: Env): Promise<Response> {
  const body = (await req.json().catch(() => null)) as { appUserId?: string; text?: string; format?: string } | null;
  const text = (body?.text ?? "").trim();
  if (!body?.appUserId || !text || text.length > 600) return json({ error: "bad_request" }, 400);
  const key = `tts:${body.appUserId}:${dayKey()}`;
  const used = Number((await cacheGet(key)) ?? 0);
  if (used >= 400) return json({ error: "limit_reached" }, 429);
  await cachePut(key, String(used + 1), 60 * 60 * 24);
  const pcm = body.format === "pcm";
  const res = await speech(env, text, pcm ? "pcm" : "mp3");
  if (!res.ok) return json({ error: "upstream", status: res.status, detail: await res.text() }, 502);
  // pcm: 24 kHz, 16-bit, mono — akış halinde, istemci geldikçe çalar
  return new Response(res.body, { headers: { "content-type": pcm ? "audio/pcm" : "audio/mpeg" } });
}

async function status(req: Request, env: Env): Promise<Response> {
  const user = new URL(req.url).searchParams.get("appUserId");
  if (!user) return json({ error: "bad_request" }, 400);
  const plan = await planFor(env, user);
  return json({ tier: plan.tier, monthlySeconds: plan.monthlySeconds, remainingSeconds: await allowance(env, user, plan) });
}

// Bazı mobil operatörlerde api.openai.com'a doğrudan WebSocket kurulamıyor: ses bu sunucu üzerinden aktarılır.
// Uygulama kısa ömürlü oturum anahtarını (client secret) gönderir; kalıcı OpenAI anahtarı hiç kullanılmaz.
async function realtimeRelay(req: Request, env: Env): Promise<Response> {
  if (req.headers.get("upgrade")?.toLowerCase() !== "websocket") return json({ error: "bad_request" }, 426);
  const auth = req.headers.get("authorization");
  if (!auth) return json({ error: "unauthorized" }, 401);
  const model = new URL(req.url).searchParams.get("model") || env.REALTIME_MODEL;
  const upstream = await fetch(`https://api.openai.com/v1/realtime?model=${encodeURIComponent(model)}`, {
    headers: { Upgrade: "websocket", Authorization: auth },
  });
  const remote = upstream.webSocket;
  if (!remote) return json({ error: "upstream", status: upstream.status }, 502);
  remote.accept();
  const [client, server] = Object.values(new WebSocketPair());
  server.accept();
  // 1005/1006 gönderilemez kodlar: normal kapanışa çevir
  const close = (ws: WebSocket, code = 1000, reason = "") => {
    try { ws.close(code === 1005 || code === 1006 ? 1000 : code, reason); } catch {}
  };
  server.addEventListener("message", (e) => { try { remote.send(e.data); } catch { close(server, 1011); } });
  remote.addEventListener("message", (e) => { try { server.send(e.data); } catch { close(remote); } });
  server.addEventListener("close", (e) => close(remote, e.code, e.reason));
  remote.addEventListener("close", (e) => close(server, e.code, e.reason));
  server.addEventListener("error", () => close(remote));
  remote.addEventListener("error", () => close(server, 1011));
  return new Response(null, { status: 101, webSocket: client });
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const { pathname } = new URL(req.url);
    // Yasal sayfalar herkese açık (App Store incelemesi ve uygulama içi bağlantılar)
    if (req.method === "GET" && pathname === "/privacy") return privacyPage();
    if (req.method === "GET" && pathname === "/terms") return termsPage();
    if (req.headers.get("x-app-key") !== env.APP_SHARED_KEY) return json({ error: "unauthorized" }, 401);
    try {
      if (req.method === "POST" && pathname === "/v1/voice/session") return await createSession(req, env);
      if (req.method === "POST" && pathname === "/v1/voice/usage") return await reportUsage(req, env);
      if (req.method === "GET" && pathname === "/v1/voice/status") return await status(req, env);
      if (req.method === "POST" && pathname === "/v1/voice/tts") return await tts(req, env);
      if (req.method === "GET" && pathname === "/v1/voice/realtime") return await realtimeRelay(req, env);
      return json({ error: "not_found" }, 404);
    } catch (e) {
      return json({ error: "internal", detail: String(e) }, 500);
    }
  },
};

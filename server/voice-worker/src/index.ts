import { privacyPage, supportPage, termsPage } from "./legal";
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
 *   - Pro: günlük/aylık sınır yok, oturum başına PRO_SESSION_SECONDS (kullanım yine kaydedilir)
 *   - (Eski) aylık bütçe hesabı yalnızca denemedeki kullanıcı için:
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
  PRO_SESSION_SECONDS?: string;
  FREE_NEW_USERS_PER_IP_DAY?: string;
  HIGH_COST_MULTIPLIER: string;
  /** Üç parçalı ses (yazıya çevir → yazı modeli → seslendir) için yazı modeli */
  CASCADE_MODEL?: string;
  /** Yazı modelinin düşünme düzeyi (hız için düşük); boşsa gönderilmez */
  CASCADE_REASONING?: string;
  /** Gemini Live denemesi */
  GEMINI_API_KEY?: string;
  GEMINI_MODEL?: string;
  GEMINI_VOICE?: string;
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
  /** Keychain'deki kalıcı cihaz kimliği (silip yeniden kurunca değişmez) */
  deviceId?: string;
  /** true: istemci OpenAI anahtarı almaz, yalnızca sayaçlı aktarıcıdan bağlanır (süreyi sunucu sayar) */
  metered?: boolean;
  /** "cascade": gerçek zamanlı ses modeli yerine yazıya çevir → yazı modeli → seslendir (deneme) */
  engine?: string;
}

type SessionRecord = {
  user: string; plan: Plan; seconds: number; reported: number; weight?: number;
  metered?: boolean; secret?: string; model?: string; device?: string;
  engine?: "cascade" | "gemini"; instructions?: string;
};

/** Cihaz kimliği yalnızca UUID biçiminde kabul edilir (anahtar adına keyfi metin girmesin) */
function cleanDevice(id: unknown): string | undefined {
  return typeof id === "string" && /^[0-9A-Fa-f-]{36}$/.test(id) ? id.toUpperCase() : undefined;
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
/** Ücretsiz deneme hem kullanıcıya hem cihaza bağlı: silip yeniden kurmak (yeni kullanıcı) yeni süre açmaz */
async function freeUsed(env: Env, user: string, device?: string): Promise<number> {
  const byUser = await getNum(env, `free:${user}`);
  return device ? Math.max(byUser, await getNum(env, `freed:${device}`)) : byUser;
}

async function allowance(env: Env, user: string, plan: Plan, device?: string): Promise<number> {
  const session = Number(env.SESSION_MAX_SECONDS);
  if (plan.tier === "free") {
    const used = await freeUsed(env, user, device);
    return Math.max(0, Number(env.FREE_TASTE_SECONDS) - used);
  }
  // Ödeyen Pro'ya günlük/aylık sınır yok (kullanım yine sayılır); tek oturum OpenAI'ın oturum sınırına yakın
  if (plan.tier === "pro") return Number(env.PRO_SESSION_SECONDS || 3600);
  const u = await paidUsage(env, user);
  return Math.max(0, Math.min(session, Number(env.TRIAL_DAILY_SECONDS) - u.ds, plan.monthlySeconds - u.ms));
}

async function createSession(req: Request, env: Env): Promise<Response> {
  const body = (await req.json().catch(() => null)) as SessionRequest | null;
  if (!body?.appUserId || !body.instructions) return json({ error: "bad_request" }, 400);
  if (body.instructions.length > 24000) return json({ error: "instructions_too_long" }, 400);

  const plan = await planFor(env, body.appUserId);
  const { tier } = plan;
  const device = cleanDevice(body.deviceId);
  const seconds = await allowance(env, body.appUserId, plan, device);
  // Aynı internet adresinden günde sınırlı sayıda YENİ ücretsiz kullanıcı (script ile sahte kullanıcı üretmeye karşı).
  // Mobil operatörler bir IP'yi çok kişiye paylaştırdığı için yalnızca yeni ücretsiz kullanıcılar sayılır.
  if (tier === "free" && seconds >= Number(env.FREE_TASTE_SECONDS)) {
    const ip = req.headers.get("cf-connecting-ip") ?? "unknown";
    const ipKey = `nip:${ip}:${dayKey()}`;
    const newUsers = await getNum(env, ipKey);
    if (newUsers >= Number(env.FREE_NEW_USERS_PER_IP_DAY || 20)) return json({ error: "too_many_new_users" }, 429);
    // Bu kullanıcının ilk oturumu: sayaç bir kez artar (aynı kullanıcı tekrar gelince sayılmaz)
    const seenKey = `seen:${device ?? body.appUserId}`;
    if (!(await env.USAGE.get(seenKey))) {
      await safePut(env, seenKey, "1", { expirationTtl: 60 * 60 * 48 });
      await safePut(env, ipKey, String(newUsers + 1), { expirationTtl: 60 * 60 * 48 });
    }
  }
  if (seconds < 15) {
    return json({ error: tier === "free" ? "paywall" : "limit_reached", tier, remainingSeconds: seconds }, 402);
  }

  const high = body.quality === "high" && !!env.REALTIME_MODEL_HIGH;
  const model = high ? env.REALTIME_MODEL_HIGH : env.REALTIME_MODEL;
  // Tam model ~3 kat pahalı: aylık bütçeden o oranda düşülür (ücretsiz tadım ve günlük süre etkilenmez)
  const weight = high ? Number(env.HIGH_COST_MULTIPLIER || 3) : 1;
  if (body.engine === "cascade" || body.engine === "gemini") return createCascadeSession(env, body, plan, device, seconds);
  const session = {
    type: "realtime",
    model,
    instructions: body.instructions,
    max_output_tokens: 1200,
    // Konuşma geçmişi her turda yeniden faturalanır; yalnızca uzun derslerde (~15 dk+) en eski
    // turlar atılır. İlerleme (kelimeler, özetler) talimatta olduğundan etkilenmez.
    truncation: { type: "retention_ratio", retention_ratio: 0.7, token_limits: { post_instructions: 16000 } },
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
  await safePut(env, `s:${sessionId}`, JSON.stringify({ user: body.appUserId, device, plan, seconds, reported: 0, weight, metered: !!body.metered,
    secret: body.metered ? secret.value : undefined, model } satisfies SessionRecord), {
    expirationTtl: 60 * 60 * 3,
  });

  return json({
    sessionId,
    // Sayaçlı istemci anahtarı hiç görmez: ancak aktarıcıdan, bu oturum kimliğiyle bağlanabilir
    clientSecret: body.metered ? "" : secret.value,
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
  const s = JSON.parse(raw) as SessionRecord;
  if (s.user !== body.appUserId) return json({ error: "forbidden" }, 403);
  // Üç parçalı oturum: süre sunucunun kendi sayacından (ses girişi + seslendirme) yazılır
  if (s.engine === "cascade") await addUsage(env, body.sessionId, s, Math.ceil(Number((await cacheGet(`cu:${body.sessionId}`)) ?? 0)));
  // Sayaçlı oturumda süreyi sunucu sayar; istemcinin raporu yok sayılır
  else if (!s.metered) await addUsage(env, body.sessionId, s, Math.ceil(body.seconds));
  return json({ ok: true, remainingSeconds: await allowance(env, s.user, s.plan, s.device) });
}

/** Oturumun toplam kullanımını yaz (sadece fark eklenir; oturuma verilen süreyi ve 60 dk'yı aşamaz) */
async function addUsage(env: Env, sessionId: string, s: SessionRecord, seconds: number): Promise<void> {
  const total = Math.min(seconds, Math.max(s.seconds, 3600));
  const delta = Math.max(0, total - s.reported);
  if (delta <= 0) return;
  if (s.plan.tier === "free") {
    await safePut(env, `free:${s.user}`, String((await getNum(env, `free:${s.user}`)) + delta));
    if (s.device) await safePut(env, `freed:${s.device}`, String((await getNum(env, `freed:${s.device}`)) + delta));
  } else {
    const u = await paidUsage(env, s.user);
    u.ds += delta; u.ms += Math.round(delta * (s.weight ?? 1));
    await safePut(env, `p:${s.user}`, JSON.stringify(u), { expirationTtl: 60 * 60 * 24 * 40 });
  }
  s.reported = total;
  await safePut(env, `s:${sessionId}`, JSON.stringify(s), { expirationTtl: 60 * 60 * 3 });
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
  const params = new URL(req.url).searchParams;
  const user = params.get("appUserId");
  if (!user) return json({ error: "bad_request" }, 400);
  const plan = await planFor(env, user);
  const device = cleanDevice(params.get("deviceId"));
  return json({ tier: plan.tier, monthlySeconds: plan.monthlySeconds, remainingSeconds: await allowance(env, user, plan, device) });
}

// Bazı mobil operatörlerde api.openai.com'a doğrudan WebSocket kurulamıyor: ses bu sunucu üzerinden aktarılır.
// Uygulama kısa ömürlü oturum anahtarını (client secret) gönderir; kalıcı OpenAI anahtarı hiç kullanılmaz.
async function realtimeRelay(req: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
  if (req.headers.get("upgrade")?.toLowerCase() !== "websocket") return json({ error: "bad_request" }, 426);
  const params = new URL(req.url).searchParams;
  const sessionId = params.get("session");
  if (sessionId) return meteredRelay(req, env, ctx, sessionId, params.get("appUserId") ?? "");
  const auth = req.headers.get("authorization");
  if (!auth) return json({ error: "unauthorized" }, 401);
  const model = params.get("model") || env.REALTIME_MODEL;
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

/**
 * Sayaçlı aktarıcı: OpenAI anahtarı sunucuda kalır; süre sunucuda sayılır ve dolunca bağlantı kesilir.
 * Sayılan süre: içinde ses/mesaj akan saniyeler (sessiz bekleme sayılmaz). Kullanım kapanışta yazılır.
 */
async function meteredRelay(req: Request, env: Env, ctx: ExecutionContext, sessionId: string, appUserId: string): Promise<Response> {
  const raw = await env.USAGE.get(`s:${sessionId}`);
  if (!raw) return json({ error: "unknown_session" }, 404);
  const s = JSON.parse(raw) as SessionRecord;
  if (!s.metered || !s.secret || s.user !== appUserId) return json({ error: "forbidden" }, 403);
  const upstream = await fetch(`https://api.openai.com/v1/realtime?model=${encodeURIComponent(s.model || env.REALTIME_MODEL)}`, {
    headers: { Upgrade: "websocket", Authorization: `Bearer ${s.secret}` },
  });
  const remote = upstream.webSocket;
  if (!remote) return json({ error: "upstream", status: upstream.status }, 502);
  remote.accept();
  const [client, server] = Object.values(new WebSocketPair());
  server.accept();

  const allowed = s.seconds;                       // bu oturuma verilen konuşma süresi
  const wallLimit = Math.max(allowed * 3, 900) * 1000;  // sessiz bekleme dahil üst sınır
  const startedAt = Date.now();
  const activeSeconds = new Set<number>();
  let finished = false;
  const used = () => activeSeconds.size;
  const close = (ws: WebSocket, code = 1000, reason = "") => {
    try { ws.close(code === 1005 || code === 1006 ? 1000 : code, reason); } catch {}
  };
  const finish = () => {
    if (finished) return;
    finished = true;
    clearTimeout(wallTimer);
    ctx.waitUntil(addUsage(env, sessionId, s, s.reported + used()));
  };
  const tick = () => {
    activeSeconds.add(Math.floor((Date.now() - startedAt) / 1000));
    if (used() > allowed) { close(server, 4001, "time_up"); close(remote); finish(); }
  };
  const wallTimer = setTimeout(() => { close(server, 4001, "time_up"); close(remote); finish(); }, wallLimit);

  server.addEventListener("message", (e) => { tick(); try { remote.send(e.data); } catch { close(server, 1011); } });
  remote.addEventListener("message", (e) => { tick(); try { server.send(e.data); } catch { close(remote); } });
  server.addEventListener("close", (e) => { close(remote, e.code, e.reason); finish(); });
  remote.addEventListener("close", (e) => { close(server, e.code, e.reason); finish(); });
  server.addEventListener("error", () => { close(remote); finish(); });
  remote.addEventListener("error", () => { close(server, 1011); finish(); });
  return new Response(null, { status: 101, webSocket: client });
}

// MARK: Üç parçalı ses (deneme): yazıya çevir → yazı modeli → seslendir
// Uygulama her adımı ayrı istekle yapar; OpenAI anahtarı sunucuda kalır. Süre = gelen ses + seslendirilen metin
// (oturum içinde Cache API'de tutulur, uygulama kullanım raporu gönderince KV'ye yazılır).

async function createCascadeSession(env: Env, body: SessionRequest, plan: Plan, device: string | undefined, seconds: number): Promise<Response> {
  const sessionId = crypto.randomUUID();
  await safePut(env, `s:${sessionId}`, JSON.stringify({ user: body.appUserId, device, plan, seconds, reported: 0, weight: 1, metered: true,
    engine: body.engine === "gemini" ? "gemini" : "cascade", instructions: body.instructions, model: env.CASCADE_MODEL } satisfies SessionRecord), { expirationTtl: 60 * 60 * 3 });
  return json({ sessionId, clientSecret: "", expiresAt: 0, model: body.engine === "gemini" ? "gemini" : "cascade", allowedSeconds: seconds, tier: plan.tier });
}

/** PCM 16 bit 24 kHz mono → WAV (yazıya çevirme servisi dosya ister) */
function wav(pcm: ArrayBuffer): Uint8Array {
  const out = new Uint8Array(44 + pcm.byteLength);
  const v = new DataView(out.buffer);
  const str = (o: number, t: string) => { for (let i = 0; i < t.length; i++) out[o + i] = t.charCodeAt(i); };
  str(0, "RIFF"); v.setUint32(4, 36 + pcm.byteLength, true); str(8, "WAVE"); str(12, "fmt ");
  v.setUint32(16, 16, true); v.setUint16(20, 1, true); v.setUint16(22, 1, true); v.setUint32(24, 24000, true);
  v.setUint32(28, 48000, true); v.setUint16(32, 2, true); v.setUint16(34, 16, true); str(36, "data");
  v.setUint32(40, pcm.byteLength, true);
  out.set(new Uint8Array(pcm), 44);
  return out;
}

async function cascade(req: Request, env: Env, step: string): Promise<Response> {
  const params = new URL(req.url).searchParams;
  const sessionId = params.get("session") ?? "";
  const raw = await env.USAGE.get(`s:${sessionId}`);
  if (!raw) return json({ error: "unknown_session" }, 404);
  const s = JSON.parse(raw) as SessionRecord;
  if (!s.engine || s.user !== params.get("appUserId")) return json({ error: "forbidden" }, 403);
  const usedKey = `cu:${sessionId}`;
  const used = Number((await cacheGet(usedKey)) ?? 0);
  const charge = async (secs: number) => {
    if (s.engine === "gemini") return true;   // Gemini'de süreyi soket aktarıcısı sayar
    if (used + secs > s.seconds + 5) return false;
    await cachePut(usedKey, String(used + secs), 60 * 60 * 3);
    return true;
  };

  if (step === "stt") {
    const pcm = await req.arrayBuffer();
    if (pcm.byteLength < 4800 || pcm.byteLength > 48000 * 60) return json({ error: "bad_audio" }, 400);
    if (!(await charge(pcm.byteLength / 48000))) return json({ error: "time_up" }, 402);
    const form = new FormData();
    form.append("file", new Blob([wav(pcm)], { type: "audio/wav" }), "speech.wav");
    form.append("model", "gpt-4o-mini-transcribe");
    const res = await fetch("https://api.openai.com/v1/audio/transcriptions", {
      method: "POST", headers: { Authorization: `Bearer ${env.OPENAI_API_KEY}` }, body: form,
    });
    if (!res.ok) return json({ error: "upstream", status: res.status, detail: await res.text() }, 502);
    const out: any = await res.json();
    return json({ transcript: out.text ?? "" });
  }

  if (step === "chat") {
    const body = (await req.json().catch(() => null)) as { messages?: unknown[]; tools?: unknown[]; tool_choice?: unknown; instructions?: string } | null;
    if (!Array.isArray(body?.messages) || body.messages.length > 300) return json({ error: "bad_request" }, 400);
    const callsKey = `cc:${sessionId}`;
    const calls = Number((await cacheGet(callsKey)) ?? 0);
    if (calls >= 500) return json({ error: "time_up" }, 402);
    await cachePut(callsKey, String(calls + 1), 60 * 60 * 3);
    const system = typeof body.instructions === "string" && body.instructions ? body.instructions.slice(0, 4000) : s.instructions ?? "";
    const payload: Record<string, unknown> = {
      model: s.model || env.CASCADE_MODEL,
      messages: [{ role: "system", content: system }, ...body.messages],
      stream: true,
      max_completion_tokens: 1500,
    };
    if (env.CASCADE_REASONING) payload.reasoning_effort = env.CASCADE_REASONING;
    if (Array.isArray(body.tools) && body.tools.length) {
      payload.tools = body.tools.slice(0, 8);
      payload.tool_choice = body.tool_choice ?? "auto";
      payload.parallel_tool_calls = true;
    }
    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { Authorization: `Bearer ${env.OPENAI_API_KEY}`, "content-type": "application/json" },
      body: JSON.stringify(payload),
    });
    if (!res.ok) return json({ error: "upstream", status: res.status, detail: await res.text() }, 502);
    return new Response(res.body, { headers: { "content-type": "text/event-stream" } });
  }

  if (step === "tts") {
    const body = (await req.json().catch(() => null)) as { text?: string } | null;
    const text = (body?.text ?? "").trim();
    if (!text || text.length > 800) return json({ error: "bad_request" }, 400);
    // Konuşma hızı: ~14 karakter/sn
    if (!(await charge(text.length / 14))) return json({ error: "time_up" }, 402);
    const res = await speech(env, text, "pcm");
    if (!res.ok) return json({ error: "upstream", status: res.status, detail: await res.text() }, 502);
    return new Response(res.body, { headers: { "content-type": "audio/pcm" } });
  }
  return json({ error: "not_found" }, 404);
}

// MARK: Gemini Live (deneme): uygulama Gemini'nin kendi protokolünü konuşur; anahtar ve model sunucuda kalır,
// süre OpenAI aktarıcısındaki gibi trafik olan saniyelerden sayılır.
async function geminiRelay(req: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
  if (req.headers.get("upgrade")?.toLowerCase() !== "websocket") return json({ error: "bad_request" }, 426);
  const params = new URL(req.url).searchParams;
  const sessionId = params.get("session") ?? "";
  const raw = await env.USAGE.get(`s:${sessionId}`);
  if (!raw) return json({ error: "unknown_session" }, 404);
  const s = JSON.parse(raw) as SessionRecord;
  if (s.engine !== "gemini" || s.user !== params.get("appUserId") || !env.GEMINI_API_KEY) return json({ error: "forbidden" }, 403);
  const upstream = await fetch("https://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent", {
    headers: { Upgrade: "websocket", "x-goog-api-key": env.GEMINI_API_KEY },
  });
  const remote = upstream.webSocket;
  if (!remote) return json({ error: "upstream", status: upstream.status, detail: await upstream.text().catch(() => "") }, 502);
  remote.accept();
  const [client, server] = Object.values(new WebSocketPair());
  server.accept();

  const allowed = s.seconds;
  const startedAt = Date.now();
  const activeSeconds = new Set<number>();
  let finished = false;
  let setupSent = false;
  const close = (ws: WebSocket, code = 1000, reason = "") => {
    try { ws.close(code === 1005 || code === 1006 ? 1000 : code, reason); } catch {}
  };
  const finish = () => {
    if (finished) return;
    finished = true;
    clearTimeout(wallTimer);
    ctx.waitUntil(addUsage(env, sessionId, s, s.reported + activeSeconds.size));
  };
  const tick = () => {
    activeSeconds.add(Math.floor((Date.now() - startedAt) / 1000));
    if (activeSeconds.size > allowed) { close(server, 4001, "time_up"); close(remote); finish(); }
  };
  const wallTimer = setTimeout(() => { close(server, 4001, "time_up"); close(remote); finish(); }, Math.max(allowed * 3, 900) * 1000);

  server.addEventListener("message", (e) => {
    tick();
    let data = e.data;
    // İlk mesaj (kurulum): model, ses ve talimat sunucudan gelir (istemci keyfi model/talimat seçemez)
    if (!setupSent && typeof data === "string") {
      setupSent = true;
      try {
        const msg = JSON.parse(data);
        if (msg.setup) {
          msg.setup.model = `models/${env.GEMINI_MODEL || "gemini-3.8-live"}`;
          msg.setup.systemInstruction = { parts: [{ text: s.instructions ?? "" }] };
          msg.setup.generationConfig = { ...(msg.setup.generationConfig ?? {}), responseModalities: ["AUDIO"],
            speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: env.GEMINI_VOICE || "Sulafat" } } } };
          data = JSON.stringify(msg);
        }
      } catch {}
    }
    try { remote.send(data); } catch { close(server, 1011); }
  });
  // Gemini JSON'u ikili çerçeveyle yollar: uygulamaya metin olarak iletilir
  const decoder = new TextDecoder();
  remote.addEventListener("message", async (e) => {
    tick();
    const d: unknown = e.data;
    const text = typeof d === "string" ? d : d instanceof ArrayBuffer ? decoder.decode(d) : await (d as Blob).text();
    try { server.send(text); } catch { close(remote); }
  });
  server.addEventListener("close", (e) => { close(remote, e.code, e.reason); finish(); });
  remote.addEventListener("close", (e) => { close(server, e.code, e.reason.slice(0, 120)); finish(); });
  server.addEventListener("error", () => { close(remote); finish(); });
  remote.addEventListener("error", () => { close(server, 1011); finish(); });
  return new Response(null, { status: 101, webSocket: client });
}

export default {
  async fetch(req: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const { pathname } = new URL(req.url);
    // Yasal sayfalar herkese açık (App Store incelemesi ve uygulama içi bağlantılar)
    if (req.method === "GET" && pathname === "/privacy") return privacyPage();
    if (req.method === "GET" && pathname === "/terms") return termsPage();
    if (req.method === "GET" && pathname === "/support") return supportPage();
    if (req.headers.get("x-app-key") !== env.APP_SHARED_KEY) return json({ error: "unauthorized" }, 401);
    try {
      if (req.method === "POST" && pathname === "/v1/voice/session") return await createSession(req, env);
      if (req.method === "POST" && pathname === "/v1/voice/usage") return await reportUsage(req, env);
      if (req.method === "GET" && pathname === "/v1/voice/status") return await status(req, env);
      if (req.method === "POST" && pathname === "/v1/voice/tts") return await tts(req, env);
      if (req.method === "GET" && pathname === "/v1/voice/realtime") return await realtimeRelay(req, env, ctx);
      if (req.method === "GET" && pathname === "/v1/voice/gemini") return await geminiRelay(req, env, ctx);
      if (req.method === "POST" && pathname.startsWith("/v1/voice/cascade/")) return await cascade(req, env, pathname.slice(18));
      return json({ error: "not_found" }, 404);
    } catch (e) {
      return json({ error: "internal", detail: String(e) }, 500);
    }
  },
};

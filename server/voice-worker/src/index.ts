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
 *   - Pro: oturum başına SESSION_MAX_SECONDS, günde PRO_DAILY_SECONDS, ayda PRO_MONTHLY_SECONDS
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
}

type Tier = "free" | "trial" | "pro";

interface SessionRequest {
  appUserId: string;
  instructions: string;
  tools?: unknown[];
  voice?: string;
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

/** RevenueCat: kullanıcının Pro hakkı var mı, deneme süresinde mi? */
async function tierFor(env: Env, appUserId: string): Promise<Tier> {
  const res = await fetch(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`, {
    headers: { Authorization: `Bearer ${env.RC_SECRET_KEY}` },
  });
  if (!res.ok) return "free";
  const data: any = await res.json();
  const subscriber = data?.subscriber ?? {};
  const ent = subscriber.entitlements?.[env.RC_ENTITLEMENT] ?? subscriber.entitlements?.pro;
  if (!ent) return "free";
  const expires = ent.expires_date ? Date.parse(ent.expires_date) : Infinity;
  if (expires < Date.now()) return "free";
  const product = subscriber.subscriptions?.[ent.product_identifier];
  return product?.period_type === "trial" ? "trial" : "pro";
}

/** Bu kullanıcı şu an kaç saniye konuşabilir? */
async function allowance(env: Env, user: string, tier: Tier): Promise<number> {
  const session = Number(env.SESSION_MAX_SECONDS);
  if (tier === "free") {
    const used = await getNum(env, `free:${user}`);
    return Math.max(0, Number(env.FREE_TASTE_SECONDS) - used);
  }
  const daily = tier === "trial" ? Number(env.TRIAL_DAILY_SECONDS) : Number(env.PRO_DAILY_SECONDS);
  const usedDay = await getNum(env, `d:${user}:${dayKey()}`);
  const usedMonth = await getNum(env, `m:${user}:${monthKey()}`);
  return Math.max(0, Math.min(session, daily - usedDay, Number(env.PRO_MONTHLY_SECONDS) - usedMonth));
}

async function createSession(req: Request, env: Env): Promise<Response> {
  const body = (await req.json().catch(() => null)) as SessionRequest | null;
  if (!body?.appUserId || !body.instructions) return json({ error: "bad_request" }, 400);
  if (body.instructions.length > 12000) return json({ error: "instructions_too_long" }, 400);

  const tier = await tierFor(env, body.appUserId);
  const seconds = await allowance(env, body.appUserId, tier);
  if (seconds < 15) {
    return json({ error: tier === "free" ? "paywall" : "limit_reached", tier, remainingSeconds: seconds }, 402);
  }

  const session = {
    type: "realtime",
    model: env.REALTIME_MODEL,
    instructions: body.instructions,
    max_output_tokens: 1200,
    audio: {
      input: {
        format: { type: "audio/pcm", rate: 24000 },
        noise_reduction: { type: "near_field" },
        transcription: { model: "gpt-4o-mini-transcribe" },
        turn_detection: { type: "semantic_vad", eagerness: "medium", create_response: true, interrupt_response: true },
      },
      output: {
        format: { type: "audio/pcm", rate: 24000 },
        voice: body.voice || env.VOICE,
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
  await env.USAGE.put(`s:${sessionId}`, JSON.stringify({ user: body.appUserId, tier, seconds, reported: 0 }), {
    expirationTtl: 60 * 60 * 3,
  });

  return json({
    sessionId,
    clientSecret: secret.value,
    expiresAt: secret.expires_at,
    model: env.REALTIME_MODEL,
    allowedSeconds: seconds,
    tier,
  });
}

async function reportUsage(req: Request, env: Env): Promise<Response> {
  const body = (await req.json().catch(() => null)) as UsageRequest | null;
  if (!body?.appUserId || !body.sessionId || !(body.seconds >= 0)) return json({ error: "bad_request" }, 400);

  const raw = await env.USAGE.get(`s:${body.sessionId}`);
  if (!raw) return json({ error: "unknown_session" }, 404);
  const s = JSON.parse(raw) as { user: string; tier: Tier; seconds: number; reported: number };
  if (s.user !== body.appUserId) return json({ error: "forbidden" }, 403);

  // Toplam rapor, oturuma verilen süreyi (ve 60 dk oturum tavanını) aşamaz; sadece fark yazılır
  const total = Math.min(Math.ceil(body.seconds), Math.max(s.seconds, 3600));
  const delta = Math.max(0, total - s.reported);
  if (delta > 0) {
    if (s.tier === "free") {
      await env.USAGE.put(`free:${s.user}`, String((await getNum(env, `free:${s.user}`)) + delta));
    } else {
      const dk = `d:${s.user}:${dayKey()}`;
      const mk = `m:${s.user}:${monthKey()}`;
      await env.USAGE.put(dk, String((await getNum(env, dk)) + delta), { expirationTtl: 60 * 60 * 48 });
      await env.USAGE.put(mk, String((await getNum(env, mk)) + delta), { expirationTtl: 60 * 60 * 24 * 40 });
    }
    s.reported = total;
    await env.USAGE.put(`s:${body.sessionId}`, JSON.stringify(s), { expirationTtl: 60 * 60 * 3 });
  }
  return json({ ok: true, remainingSeconds: await allowance(env, s.user, s.tier) });
}

async function status(req: Request, env: Env): Promise<Response> {
  const user = new URL(req.url).searchParams.get("appUserId");
  if (!user) return json({ error: "bad_request" }, 400);
  const tier = await tierFor(env, user);
  return json({ tier, remainingSeconds: await allowance(env, user, tier) });
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    if (req.headers.get("x-app-key") !== env.APP_SHARED_KEY) return json({ error: "unauthorized" }, 401);
    const { pathname } = new URL(req.url);
    try {
      if (req.method === "POST" && pathname === "/v1/voice/session") return await createSession(req, env);
      if (req.method === "POST" && pathname === "/v1/voice/usage") return await reportUsage(req, env);
      if (req.method === "GET" && pathname === "/v1/voice/status") return await status(req, env);
      return json({ error: "not_found" }, 404);
    } catch (e) {
      return json({ error: "internal", detail: String(e) }, 500);
    }
  },
};

// delete-user — Uygulama içi "Hesabı Sil" (App Store 5.1.1(v))
//
// Uygulama: POST {SUPABASE_URL}/functions/v1/delete-user
//           Authorization: Bearer <kullanıcının access token'ı>
// Token'ı doğrular, ardından service role ile auth kullanıcısını siler.
// public.users ve ona bağlı tablolar ON DELETE CASCADE ile temizlenir.
//
// Deploy: supabase functions deploy delete-user
// (SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY Supabase tarafından otomatik sağlanır)

import { createClient } from "jsr:@supabase/supabase-js@2";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "missing token" }, 401);

  const url = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // 1) İsteği yapan kullanıcıyı token'dan doğrula
  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) return json({ error: "invalid token" }, 401);

  // 2) Service role ile auth kullanıcısını sil (public.users cascade ile silinir)
  const admin = createClient(url, serviceKey);
  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) {
    console.error("deleteUser failed", deleteError);
    return json({ error: "delete failed" }, 500);
  }

  return json({ deleted: true });
});

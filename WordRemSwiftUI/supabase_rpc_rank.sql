-- ═══════════════════════════════════════════════════════════════
-- WordRemSwiftUI — Faz 10: Leaderboard Kendi Sıram (User Rank) RPC
-- Run in Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- Bu fonksiyon veritabanında kullanıcının total_xp'sinden daha yüksek 
-- xp'si olan kişi sayısını bulup +1 ekleyerek sırasını (rank) hesaplar.
CREATE OR REPLACE FUNCTION get_user_rank(p_user_id UUID)
RETURNS INT 
LANGUAGE sql 
SECURITY DEFINER 
AS $$
  SELECT (COUNT(*)::INT + 1)
  FROM users
  WHERE total_xp > (SELECT total_xp FROM users WHERE id = p_user_id);
$$;

-- Authenticated (ve guest/anon) kullanıcıların fonksiyonu çağırabilmesi için yetki verelim.
GRANT EXECUTE ON FUNCTION get_user_rank(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_rank(UUID) TO anon;

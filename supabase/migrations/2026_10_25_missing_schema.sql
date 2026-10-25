-- ═══════════════════════════════════════════════════════════════
-- WordRemSwiftUI — Eksik şema parçaları
-- Uygulamanın kullandığı ama önceki SQL dosyalarında tanımlı olmayan
-- sütunlar ve fonksiyonlar. Diğer tüm SQL dosyalarından SONRA çalıştır.
-- Tekrar çalıştırılabilir (idempotent).
-- ═══════════════════════════════════════════════════════════════

-- ── 1. users tablosu: onboarding tercihleri + kullanıcı adı hakkı ──
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_lang_id     SMALLINT REFERENCES languages(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS proficiency_level  SMALLINT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS learning_interest  TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS daily_goal_minutes SMALLINT NOT NULL DEFAULT 10;
ALTER TABLE users ADD COLUMN IF NOT EXISTS username_changes   SMALLINT NOT NULL DEFAULT 0;

-- ── 2. award_xp: AI quiz / hatalar quizi sonrası XP ekler ─────────
-- SupabaseDataService.awardXP(_:) → rpc("award_xp", p_user_id, p_amount)
CREATE OR REPLACE FUNCTION award_xp(p_user_id UUID, p_amount INT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Sadece kendi hesabına XP eklenebilir; negatif / aşırı değerler reddedilir
    IF p_user_id IS DISTINCT FROM auth.uid() THEN
        RAISE EXCEPTION 'not allowed';
    END IF;
    IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 500 THEN
        RETURN;
    END IF;

    UPDATE users
       SET total_xp         = total_xp + p_amount,
           last_activity_at = NOW(),
           updated_at       = NOW()
     WHERE id = p_user_id;
END;
$$;

REVOKE ALL ON FUNCTION award_xp(UUID, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION award_xp(UUID, INT) TO authenticated;

-- ── 3. sentences: RLS açık + okuma izni (sentences_table.sql RLS tanımlamıyordu) ──
ALTER TABLE sentences ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "sentences: authenticated read" ON sentences;
CREATE POLICY "sentences: authenticated read" ON sentences FOR SELECT TO authenticated USING (true);

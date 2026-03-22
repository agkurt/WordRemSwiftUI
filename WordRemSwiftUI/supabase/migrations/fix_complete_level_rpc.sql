-- ============================================================
-- Migration: Fix complete_level() — drop all overloads and
-- recreate with a single canonical signature.
--
-- Problem: Two overloads existed (SMALLINT/VARCHAR from original
-- migration + INT/TEXT from update_complete_level_scoring.sql),
-- causing "ambiguous function" errors from the iOS client.
--
-- Pass threshold: ≥ 50% → PASS, next level unlocks.
-- Stars: 100% → 3, ≥50% → 2, ≥25% → 1, else 0.
-- ============================================================

-- Drop ALL overloads
DROP FUNCTION IF EXISTS complete_level(UUID, UUID, SMALLINT, VARCHAR);
DROP FUNCTION IF EXISTS complete_level(UUID, UUID, SMALLINT, VARCHAR(20));
DROP FUNCTION IF EXISTS complete_level(UUID, UUID, INT, TEXT);
DROP FUNCTION IF EXISTS complete_level(UUID, UUID, INTEGER, TEXT);

-- Recreate with single canonical signature
CREATE OR REPLACE FUNCTION complete_level(
    p_user_id   UUID,
    p_level_id  UUID,
    p_score     INT,
    p_quiz_mode TEXT DEFAULT 'multipleChoice'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_level         levels%ROWTYPE;
    v_progress      user_progress%ROWTYPE;
    v_stars         SMALLINT;
    v_xp_to_award   INT := 0;
    v_next_level_id UUID;
    v_already_done  BOOLEAN;
    v_passed        BOOLEAN;
BEGIN
    -- Level bilgisi
    SELECT * INTO v_level FROM levels WHERE id = p_level_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'level_not_found');
    END IF;

    -- user_progress satırı yoksa oluştur
    INSERT INTO user_progress (user_id, level_id, status)
    VALUES (p_user_id, p_level_id, 'in_progress')
    ON CONFLICT (user_id, level_id) DO NOTHING;

    SELECT * INTO v_progress
    FROM user_progress
    WHERE user_id = p_user_id AND level_id = p_level_id;

    -- Yıldız hesaplama
    v_stars := CASE
        WHEN p_score = 100 THEN 3
        WHEN p_score >= 50  THEN 2
        WHEN p_score >= 25  THEN 1
        ELSE 0
    END;

    -- Geçme eşiği: %50
    v_passed := (p_score >= 50);

    IF NOT v_passed THEN
        UPDATE user_progress
        SET attempts       = attempts + 1,
            best_score     = GREATEST(best_score, p_score),
            stars          = GREATEST(stars, v_stars),
            last_played_at = NOW(),
            updated_at     = NOW()
        WHERE user_id = p_user_id AND level_id = p_level_id;

        RETURN jsonb_build_object(
            'success',  false,
            'passed',   false,
            'score',    p_score,
            'stars',    v_stars,
            'required', 50
        );
    END IF;

    -- Geçti → XP hesapla
    v_already_done := (v_progress.status = 'completed');

    IF NOT v_already_done THEN
        v_xp_to_award := v_level.xp_reward;
    ELSIF v_stars > v_progress.stars THEN
        v_xp_to_award := (v_stars - v_progress.stars) * 3;
    END IF;

    -- user_progress güncelle
    UPDATE user_progress
    SET status         = 'completed',
        best_score     = GREATEST(best_score, p_score),
        stars          = GREATEST(stars, v_stars),
        attempts       = attempts + 1,
        xp_earned      = xp_earned + v_xp_to_award,
        completed_at   = COALESCE(completed_at, NOW()),
        last_played_at = NOW(),
        updated_at     = NOW()
    WHERE user_id = p_user_id AND level_id = p_level_id;

    -- Toplam XP artır
    UPDATE users
    SET total_xp         = total_xp + v_xp_to_award,
        last_activity_at = NOW(),
        updated_at       = NOW()
    WHERE id = p_user_id;

    -- Sonraki seviyeyi aç
    SELECT id INTO v_next_level_id
    FROM levels
    WHERE course_id   = v_level.course_id
      AND order_index = v_level.order_index + 1;

    IF v_next_level_id IS NOT NULL THEN
        INSERT INTO user_progress (user_id, level_id, status)
        VALUES (p_user_id, v_next_level_id, 'unlocked')
        ON CONFLICT (user_id, level_id)
        DO UPDATE SET
            status     = CASE
                             WHEN user_progress.status = 'locked' THEN 'unlocked'
                             ELSE user_progress.status
                         END,
            updated_at = NOW();
    END IF;

    RETURN jsonb_build_object(
        'success',           true,
        'passed',            true,
        'score',             p_score,
        'stars',             v_stars,
        'xp_earned',         v_xp_to_award,
        'next_level_id',     v_next_level_id,
        'already_completed', v_already_done
    );
END;
$$;

-- Grant execute to both roles
GRANT EXECUTE ON FUNCTION complete_level(UUID, UUID, INT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION complete_level(UUID, UUID, INT, TEXT) TO anon;

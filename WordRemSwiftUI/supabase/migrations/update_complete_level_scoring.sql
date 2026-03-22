-- ============================================================
-- Migration: Update complete_level() scoring rules
--
-- New rules:
--   ≥ 25%  → 1 star  (attempt recorded, no advancement)
--   ≥ 50%  → 2 stars (PASS — next level unlocks)
--   = 100% → 3 stars (PASS — next level unlocks)
-- ============================================================

CREATE OR REPLACE FUNCTION complete_level(
    p_user_id   UUID,
    p_level_id  UUID,
    p_score     INT,
    p_quiz_mode TEXT DEFAULT 'multipleChoice'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
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
    -- Level'ı bul
    SELECT * INTO v_level FROM levels WHERE id = p_level_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'level_not_found');
    END IF;

    -- İlk kez görüyorsak in_progress olarak ekle
    INSERT INTO user_progress (user_id, level_id, status)
    VALUES (p_user_id, p_level_id, 'in_progress')
    ON CONFLICT (user_id, level_id) DO NOTHING;

    SELECT * INTO v_progress
    FROM user_progress
    WHERE user_id = p_user_id AND level_id = p_level_id;

    -- Yıldız hesaplama (her durumda)
    v_stars := CASE
        WHEN p_score = 100 THEN 3
        WHEN p_score >= 50 THEN 2
        WHEN p_score >= 25 THEN 1
        ELSE 0
    END;

    -- Geçme kontrolü: ≥50 geçer
    v_passed := (p_score >= 50);

    -- Yetersiz skor — attempt'i kaydet ama geçiremez
    IF NOT v_passed THEN
        UPDATE user_progress
        SET attempts       = attempts + 1,
            best_score     = GREATEST(best_score, p_score),
            stars          = GREATEST(stars, v_stars),
            last_played_at = NOW(),
            updated_at     = NOW()
        WHERE user_id = p_user_id AND level_id = p_level_id;

        RETURN jsonb_build_object(
            'success', false,
            'passed',  false,
            'score',   p_score,
            'stars',   v_stars,
            'required', 50
        );
    END IF;

    -- Geçti: XP hesapla
    v_already_done := (v_progress.status = 'completed');

    IF NOT v_already_done THEN
        v_xp_to_award := v_level.xp_reward;
    ELSIF v_stars > v_progress.stars THEN
        -- Daha iyi skor → bonus XP
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

    -- Kullanıcının toplam XP'sini artır
    UPDATE users
    SET total_xp         = total_xp + v_xp_to_award,
        last_activity_at = NOW(),
        updated_at       = NOW()
    WHERE id = p_user_id;

    -- Sonraki level'ı aç
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

GRANT EXECUTE ON FUNCTION complete_level(UUID, UUID, INT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION complete_level(UUID, UUID, INT, TEXT) TO anon;

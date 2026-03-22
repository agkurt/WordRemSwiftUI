-- ============================================================
-- RPC: award_xp
-- Mistakes ve AI quiz bitiminde XP doğrudan users tablosuna yazar
-- ============================================================

CREATE OR REPLACE FUNCTION award_xp(
    p_user_id  UUID,
    p_amount   INTEGER
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE users
    SET total_xp = total_xp + p_amount
    WHERE id = p_user_id;
END;
$$;

-- Authenticated ve anon kullanıcılar çalıştırabilsin
GRANT EXECUTE ON FUNCTION award_xp(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION award_xp(UUID, INTEGER) TO anon;

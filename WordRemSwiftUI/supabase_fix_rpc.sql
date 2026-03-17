-- ═══════════════════════════════════════════════════════════════
-- WordRemSwiftUI — Supabase Fix: RPC GRANT + Leaderboard RLS
-- Run in Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- ── 1. GRANT EXECUTE on complete_level to authenticated users ──
-- Without this, the RPC call from the app silently fails.
GRANT EXECUTE ON FUNCTION complete_level(UUID, UUID, SMALLINT, VARCHAR) TO authenticated;

-- ── 2. Leaderboard: allow all authenticated users to read all user rows ──
-- (needed so users can see each other's XP on the leaderboard)
DROP POLICY IF EXISTS "users: public leaderboard read" ON users;
CREATE POLICY "users: public leaderboard read" ON users
    FOR SELECT TO authenticated
    USING (true);

-- Drop the old restrictive "own row select" since leaderboard needs all rows
DROP POLICY IF EXISTS "users: own row select" ON users;

-- ── 3. Allow anon users (guests) to also call complete_level ──
GRANT EXECUTE ON FUNCTION complete_level(UUID, UUID, SMALLINT, VARCHAR) TO anon;

-- ── 4. Fix: Allow anon users basic access to data tables ──
-- (Guest users sign in anonymously and need to read courses/levels/words)
DROP POLICY IF EXISTS "languages: anon read" ON languages;
CREATE POLICY "languages: anon read" ON languages FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "courses: anon read" ON courses;
CREATE POLICY "courses: anon read" ON courses FOR SELECT TO anon USING (is_active = true);

DROP POLICY IF EXISTS "levels: anon read" ON levels;
CREATE POLICY "levels: anon read" ON levels FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "words: anon read" ON words;
CREATE POLICY "words: anon read" ON words FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "wla: anon read" ON word_level_assignments;
CREATE POLICY "wla: anon read" ON word_level_assignments FOR SELECT TO anon USING (true);

-- ── 5. Verify the fix ──
-- After running this, the following should work from the app:
-- • Quiz completion → next level unlocks
-- • XP updates in users.total_xp
-- • Streak trigger fires correctly
-- • Leaderboard shows all users

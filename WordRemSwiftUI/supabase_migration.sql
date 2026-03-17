-- ═══════════════════════════════════════════════════════════════
-- WordRemSwiftUI — Supabase PostgreSQL Migration
-- Apply via: Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ────────────────────────────────────────────────────────────────
-- TABLE: languages
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS languages (
    id          SMALLSERIAL PRIMARY KEY,
    code        CHAR(2)      NOT NULL UNIQUE,
    name        VARCHAR(80)  NOT NULL,
    native_name VARCHAR(80),
    flag_emoji  VARCHAR(8),
    is_active   BOOLEAN      NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

INSERT INTO languages (code, name, native_name, flag_emoji) VALUES
('AR', 'Arabic',     'العربية',            '🇸🇦'),
('BG', 'Bulgarian',  'Български',           '🇧🇬'),
('CS', 'Czech',      'Čeština',             '🇨🇿'),
('DA', 'Danish',     'Dansk',               '🇩🇰'),
('DE', 'German',     'Deutsch',             '🇩🇪'),
('EL', 'Greek',      'Ελληνικά',            '🇬🇷'),
('EN', 'English',    'English',             '🇬🇧'),
('ES', 'Spanish',    'Español',             '🇪🇸'),
('ET', 'Estonian',   'Eesti',               '🇪🇪'),
('FI', 'Finnish',    'Suomi',               '🇫🇮'),
('FR', 'French',     'Français',            '🇫🇷'),
('HU', 'Hungarian',  'Magyar',              '🇭🇺'),
('ID', 'Indonesian', 'Bahasa Indonesia',    '🇮🇩'),
('IT', 'Italian',    'Italiano',            '🇮🇹'),
('JA', 'Japanese',   '日本語',              '🇯🇵'),
('KO', 'Korean',     '한국어',              '🇰🇷'),
('LT', 'Lithuanian', 'Lietuvių',            '🇱🇹'),
('LV', 'Latvian',    'Latviešu',            '🇱🇻'),
('NB', 'Norwegian',  'Norsk',               '🇳🇴'),
('NL', 'Dutch',      'Nederlands',          '🇳🇱'),
('PL', 'Polish',     'Polski',              '🇵🇱'),
('PT', 'Portuguese', 'Português',           '🇵🇹'),
('RO', 'Romanian',   'Română',              '🇷🇴'),
('RU', 'Russian',    'Русский',             '🇷🇺'),
('SK', 'Slovak',     'Slovenčina',          '🇸🇰'),
('SL', 'Slovenian',  'Slovenščina',         '🇸🇮'),
('SV', 'Swedish',    'Svenska',             '🇸🇪'),
('TR', 'Turkish',    'Türkçe',              '🇹🇷'),
('UK', 'Ukrainian',  'Українська',          '🇺🇦'),
('ZH', 'Chinese',    '中文',                '🇨🇳')
ON CONFLICT (code) DO NOTHING;

-- ────────────────────────────────────────────────────────────────
-- TABLE: courses
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS courses (
    id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    native_lang_id   SMALLINT     NOT NULL REFERENCES languages(id),
    target_lang_id   SMALLINT     NOT NULL REFERENCES languages(id),
    title            VARCHAR(120) NOT NULL,
    description      TEXT,
    total_xp         INT          NOT NULL DEFAULT 0,
    is_active        BOOLEAN      NOT NULL DEFAULT true,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT courses_unique_pair    UNIQUE (native_lang_id, target_lang_id),
    CONSTRAINT courses_different_langs CHECK (native_lang_id <> target_lang_id)
);

CREATE INDEX IF NOT EXISTS idx_courses_native ON courses(native_lang_id);
CREATE INDEX IF NOT EXISTS idx_courses_target ON courses(target_lang_id);

-- ────────────────────────────────────────────────────────────────
-- TABLE: users (extends auth.users)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id               UUID         PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username         VARCHAR(50)  NOT NULL,
    display_name     VARCHAR(100),
    avatar_url       TEXT,
    native_lang_id   SMALLINT     REFERENCES languages(id),
    total_xp         INT          NOT NULL DEFAULT 0,
    streak_days      INT          NOT NULL DEFAULT 0,
    last_activity_at TIMESTAMPTZ,
    fcm_token        TEXT,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_native_lang ON users(native_lang_id);
CREATE INDEX IF NOT EXISTS idx_users_total_xp    ON users(total_xp DESC);

-- ────────────────────────────────────────────────────────────────
-- TABLE: levels
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS levels (
    id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id        UUID         NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    order_index      SMALLINT     NOT NULL,
    title            VARCHAR(120) NOT NULL,
    description      TEXT,
    xp_reward        INT          NOT NULL DEFAULT 10,
    required_score   SMALLINT     NOT NULL DEFAULT 70,
    icon_name        VARCHAR(60)  DEFAULT 'star.fill',
    is_checkpoint    BOOLEAN      NOT NULL DEFAULT false,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT levels_unique_order UNIQUE (course_id, order_index)
);

CREATE INDEX IF NOT EXISTS idx_levels_course ON levels(course_id);
CREATE INDEX IF NOT EXISTS idx_levels_order  ON levels(course_id, order_index);

-- ────────────────────────────────────────────────────────────────
-- TABLE: words
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS words (
    id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_lang_id   SMALLINT     NOT NULL REFERENCES languages(id),
    target_lang_id   SMALLINT     NOT NULL REFERENCES languages(id),
    term             VARCHAR(200) NOT NULL,
    translation      VARCHAR(200) NOT NULL,
    phonetic         VARCHAR(200),
    description      TEXT,
    example_sentence TEXT,
    difficulty       SMALLINT     NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT words_different_langs CHECK (source_lang_id <> target_lang_id)
);

CREATE INDEX IF NOT EXISTS idx_words_source_target ON words(source_lang_id, target_lang_id);
CREATE INDEX IF NOT EXISTS idx_words_difficulty    ON words(difficulty);

-- ────────────────────────────────────────────────────────────────
-- TABLE: word_level_assignments (many-to-many)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS word_level_assignments (
    level_id      UUID        NOT NULL REFERENCES levels(id) ON DELETE CASCADE,
    word_id       UUID        NOT NULL REFERENCES words(id)  ON DELETE CASCADE,
    display_order SMALLINT    NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (level_id, word_id)
);

CREATE INDEX IF NOT EXISTS idx_wla_word  ON word_level_assignments(word_id);
CREATE INDEX IF NOT EXISTS idx_wla_level ON word_level_assignments(level_id, display_order);

-- ────────────────────────────────────────────────────────────────
-- TABLE: user_progress
-- ────────────────────────────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'level_status') THEN
        CREATE TYPE level_status AS ENUM ('locked', 'unlocked', 'in_progress', 'completed');
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS user_progress (
    id             UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    level_id       UUID         NOT NULL REFERENCES levels(id) ON DELETE CASCADE,
    status         level_status NOT NULL DEFAULT 'locked',
    best_score     SMALLINT     NOT NULL DEFAULT 0,
    attempts       SMALLINT     NOT NULL DEFAULT 0,
    xp_earned      INT          NOT NULL DEFAULT 0,
    stars          SMALLINT     NOT NULL DEFAULT 0 CHECK (stars BETWEEN 0 AND 3),
    completed_at   TIMESTAMPTZ,
    last_played_at TIMESTAMPTZ,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT user_progress_unique UNIQUE (user_id, level_id)
);

CREATE INDEX IF NOT EXISTS idx_progress_user         ON user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_level        ON user_progress(level_id);
CREATE INDEX IF NOT EXISTS idx_progress_user_status  ON user_progress(user_id, status);
CREATE INDEX IF NOT EXISTS idx_progress_completed    ON user_progress(user_id, completed_at)
    WHERE status = 'completed';

-- ────────────────────────────────────────────────────────────────
-- TABLE: quiz_attempts (granular analytics)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS quiz_attempts (
    id             UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    level_id       UUID         NOT NULL REFERENCES levels(id),
    word_id        UUID         NOT NULL REFERENCES words(id),
    quiz_mode      VARCHAR(20)  NOT NULL,
    user_answer    TEXT,
    correct_answer TEXT         NOT NULL,
    is_correct     BOOLEAN      NOT NULL,
    response_ms    INT,
    attempted_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_attempts_user      ON quiz_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_attempts_word      ON quiz_attempts(word_id);
CREATE INDEX IF NOT EXISTS idx_attempts_user_date ON quiz_attempts(user_id, attempted_at DESC);

-- ═══════════════════════════════════════════════════════════════
-- FUNCTION: complete_level (RPC)
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION complete_level(
    p_user_id   UUID,
    p_level_id  UUID,
    p_score     SMALLINT,
    p_quiz_mode VARCHAR(20)
)
RETURNS JSONB
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
BEGIN
    SELECT * INTO v_level FROM levels WHERE id = p_level_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'level_not_found');
    END IF;

    INSERT INTO user_progress (user_id, level_id, status)
    VALUES (p_user_id, p_level_id, 'in_progress')
    ON CONFLICT (user_id, level_id) DO NOTHING;

    SELECT * INTO v_progress
    FROM user_progress
    WHERE user_id = p_user_id AND level_id = p_level_id;

    IF p_score < v_level.required_score THEN
        UPDATE user_progress
        SET attempts       = attempts + 1,
            last_played_at = NOW(),
            updated_at     = NOW()
        WHERE user_id = p_user_id AND level_id = p_level_id;

        RETURN jsonb_build_object(
            'success',  false,
            'passed',   false,
            'score',    p_score,
            'required', v_level.required_score
        );
    END IF;

    v_stars := CASE
        WHEN p_score >= 95 THEN 3
        WHEN p_score >= 80 THEN 2
        ELSE 1
    END;

    v_already_done := (v_progress.status = 'completed');

    IF NOT v_already_done THEN
        v_xp_to_award := v_level.xp_reward;
    ELSIF v_stars > v_progress.stars THEN
        v_xp_to_award := (v_stars - v_progress.stars) * 3;
    END IF;

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

    UPDATE users
    SET total_xp         = total_xp + v_xp_to_award,
        last_activity_at = NOW(),
        updated_at       = NOW()
    WHERE id = p_user_id;

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
        'success',            true,
        'passed',             true,
        'score',              p_score,
        'stars',              v_stars,
        'xp_earned',          v_xp_to_award,
        'next_level_id',      v_next_level_id,
        'already_completed',  v_already_done
    );
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- FUNCTION + TRIGGER: streak updater
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION update_streak()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.last_activity_at IS NULL OR
       DATE_TRUNC('day', OLD.last_activity_at) < DATE_TRUNC('day', NOW()) - INTERVAL '1 day' THEN
        NEW.streak_days := 1;
    ELSIF DATE_TRUNC('day', OLD.last_activity_at) = DATE_TRUNC('day', NOW()) - INTERVAL '1 day' THEN
        NEW.streak_days := OLD.streak_days + 1;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_update_streak ON users;
CREATE TRIGGER trg_update_streak
    BEFORE UPDATE OF last_activity_at ON users
    FOR EACH ROW
    WHEN (NEW.last_activity_at IS DISTINCT FROM OLD.last_activity_at)
    EXECUTE FUNCTION update_streak();

-- ═══════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE users                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress          ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts          ENABLE ROW LEVEL SECURITY;
ALTER TABLE languages              ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses                ENABLE ROW LEVEL SECURITY;
ALTER TABLE levels                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE words                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE word_level_assignments ENABLE ROW LEVEL SECURITY;

-- users
DROP POLICY IF EXISTS "users: own row select" ON users;
CREATE POLICY "users: own row select"  ON users FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "users: own row update" ON users;
CREATE POLICY "users: own row update" ON users FOR UPDATE
    USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "users: own row insert" ON users;
CREATE POLICY "users: own row insert" ON users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- user_progress
DROP POLICY IF EXISTS "progress: own read"   ON user_progress;
DROP POLICY IF EXISTS "progress: own insert" ON user_progress;
DROP POLICY IF EXISTS "progress: own update" ON user_progress;

CREATE POLICY "progress: own read"   ON user_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "progress: own insert" ON user_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "progress: own update" ON user_progress FOR UPDATE
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- quiz_attempts
DROP POLICY IF EXISTS "attempts: own read"   ON quiz_attempts;
DROP POLICY IF EXISTS "attempts: own insert" ON quiz_attempts;

CREATE POLICY "attempts: own read"   ON quiz_attempts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "attempts: own insert" ON quiz_attempts FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Master tables: read-only for authenticated users
DROP POLICY IF EXISTS "languages: authenticated read"     ON languages;
DROP POLICY IF EXISTS "courses: authenticated read"       ON courses;
DROP POLICY IF EXISTS "levels: authenticated read"        ON levels;
DROP POLICY IF EXISTS "words: authenticated read"         ON words;
DROP POLICY IF EXISTS "wla: authenticated read"           ON word_level_assignments;

CREATE POLICY "languages: authenticated read" ON languages              FOR SELECT TO authenticated USING (true);
CREATE POLICY "courses: authenticated read"   ON courses                FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "levels: authenticated read"    ON levels                 FOR SELECT TO authenticated USING (true);
CREATE POLICY "words: authenticated read"     ON words                  FOR SELECT TO authenticated USING (true);
CREATE POLICY "wla: authenticated read"       ON word_level_assignments FOR SELECT TO authenticated USING (true);

-- ============================================================
-- sentences table — full-sentence translation quiz questions
-- "Aşağıdaki cümleyi çevir" (Translate the following sentence)
-- ============================================================

CREATE TABLE IF NOT EXISTS sentences (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id       UUID        NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    level_id        UUID        REFERENCES levels(id) ON DELETE SET NULL,
    target_text     TEXT        NOT NULL,   -- sentence in target language (shown to user)
    native_text     TEXT        NOT NULL,   -- correct full native translation
    key_word        TEXT,                   -- specific word in target_text to highlight & test
    key_word_native TEXT,                   -- native meaning of key_word only
    difficulty      INT         NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 3),
    order_index     INT         NOT NULL DEFAULT 0,
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sentences_course ON sentences(course_id);
CREATE INDEX IF NOT EXISTS idx_sentences_level  ON sentences(level_id);

-- ============================================================
-- SEED DATA — Turkish (native) learning various target languages
-- Language IDs from the languages table:
--   TR=1, EN=2, FR=3, DE=4, ES=5, IT=6, RU=7, ZH=8, JA=9, KO=10, PT=11
-- ============================================================

-- ──────────────────────────────────────────────────────────────────
-- TR → EN (Turkish learning English)  course_id fetched dynamically
-- ──────────────────────────────────────────────────────────────────
DO $$
DECLARE
    v_course_id UUID;
BEGIN
    SELECT id INTO v_course_id
    FROM courses
    WHERE native_lang_id = (SELECT id FROM languages WHERE code = 'TR' LIMIT 1)
      AND target_lang_id = (SELECT id FROM languages WHERE code = 'EN' LIMIT 1)
      AND is_active = TRUE
    LIMIT 1;

    IF v_course_id IS NULL THEN RETURN; END IF;

    INSERT INTO sentences (course_id, target_text, native_text, key_word, key_word_native, difficulty, order_index) VALUES
    -- Difficulty 1 — A1/A2 Daily Life
    (v_course_id, 'I drink coffee every morning.',           'Her sabah kahve içiyorum.',            'drink',       'içmek',          1, 10),
    (v_course_id, 'She reads a book before sleeping.',       'O uyumadan önce kitap okuyor.',         'reads',       'okuyor',         1, 20),
    (v_course_id, 'We live in a big city.',                  'Büyük bir şehirde yaşıyoruz.',          'city',        'şehir',          1, 30),
    (v_course_id, 'He goes to school by bus.',               'O okula otobüsle gidiyor.',             'school',      'okul',           1, 40),
    (v_course_id, 'The weather is very cold today.',         'Bugün hava çok soğuk.',                 'cold',        'soğuk',          1, 50),
    (v_course_id, 'I love eating fruits.',                   'Meyve yemeyi seviyorum.',               'love',        'sevmek',         1, 60),
    (v_course_id, 'They play football on weekends.',         'Hafta sonları futbol oynuyorlar.',      'play',        'oynamak',        1, 70),
    (v_course_id, 'My mother cooks dinner every evening.',   'Annem her akşam akşam yemeği pişirir.','cooks',       'pişirmek',       1, 80),

    -- Difficulty 2 — B1 Travel & Work
    (v_course_id, 'I need to buy a train ticket.',           'Tren bileti almam gerekiyor.',          'ticket',      'bilet',          2, 90),
    (v_course_id, 'She forgot her passport at home.',        'Pasaportunu evde unuttu.',              'forgot',      'unuttu',         2, 100),
    (v_course_id, 'We are looking for a hotel near the airport.', 'Havalimanı yakınında bir otel arıyoruz.', 'airport', 'havalimanı', 2, 110),
    (v_course_id, 'He usually works from home on Fridays.', 'Cuma günleri genellikle evden çalışıyor.','works',      'çalışmak',       2, 120),
    (v_course_id, 'The meeting starts at nine o clock.',    'Toplantı saat dokuzda başlıyor.',        'meeting',     'toplantı',       2, 130),
    (v_course_id, 'She speaks three languages fluently.',   'Üç dili akıcı bir şekilde konuşuyor.',  'speaks',      'konuşmak',       2, 140),
    (v_course_id, 'I have been studying English for two years.','İki yıldır İngilizce çalışıyorum.', 'studying',    'çalışmak',       2, 150),

    -- Difficulty 3 — B2/C1 Complex sentences
    (v_course_id, 'Despite the rain, we decided to go hiking.',  'Yağmura rağmen yürüyüşe gitmeye karar verdik.','despite','rağmen', 3, 160),
    (v_course_id, 'The government announced new economic policies yesterday.','Hükümet dün yeni ekonomik politikalar açıkladı.','announced','açıkladı',3, 170),
    (v_course_id, 'She has successfully completed her thesis.',  'Tezini başarıyla tamamladı.',       'completed',   'tamamladı',      3, 180),
    (v_course_id, 'It is essential to protect the environment.', 'Çevreyi korumak çok önemlidir.',    'protect',     'korumak',        3, 190),
    (v_course_id, 'He was promoted to a senior position last month.','Geçen ay üst düzey bir pozisyona terfi etti.','promoted','terfi etti',3, 200)

    ON CONFLICT DO NOTHING;
END $$;

-- ──────────────────────────────────────────────────────────────────
-- TR → FR (Turkish learning French)
-- ──────────────────────────────────────────────────────────────────
DO $$
DECLARE
    v_course_id UUID;
BEGIN
    SELECT id INTO v_course_id
    FROM courses
    WHERE native_lang_id = (SELECT id FROM languages WHERE code = 'TR' LIMIT 1)
      AND target_lang_id = (SELECT id FROM languages WHERE code = 'FR' LIMIT 1)
      AND is_active = TRUE
    LIMIT 1;

    IF v_course_id IS NULL THEN RETURN; END IF;

    INSERT INTO sentences (course_id, target_text, native_text, key_word, key_word_native, difficulty, order_index) VALUES
    -- Difficulty 1
    (v_course_id, 'Je mange une pomme chaque matin.',       'Her sabah bir elma yiyorum.',            'mange',       'yiyorum',        1, 10),
    (v_course_id, 'Elle aime beaucoup la musique.',         'O müziği çok seviyor.',                  'aime',        'seviyor',        1, 20),
    (v_course_id, 'Nous habitons dans une grande maison.',  'Büyük bir evde yaşıyoruz.',              'habitons',    'yaşıyoruz',      1, 30),
    (v_course_id, 'Il parle français très bien.',           'O Fransızcayı çok iyi konuşuyor.',       'parle',       'konuşuyor',      1, 40),
    (v_course_id, 'Je voudrais un café, s il vous plaît.',  'Lütfen bir kahve istiyorum.',             'voudrais',    'istiyorum',      1, 50),
    (v_course_id, 'Les enfants jouent dans le parc.',       'Çocuklar parkta oynuyor.',               'jouent',      'oynuyor',        1, 60),
    (v_course_id, 'Ma mère prépare le dîner ce soir.',      'Annem bu akşam akşam yemeği hazırlıyor.','prépare',     'hazırlıyor',     1, 70),

    -- Difficulty 2
    (v_course_id, 'Je dois acheter un billet de train.',    'Tren bileti almam gerekiyor.',           'acheter',     'almak',          2, 80),
    (v_course_id, 'Elle a oublié son passeport à la maison.','Pasaportunu evde unuttu.',              'oublié',      'unuttu',         2, 90),
    (v_course_id, 'Nous cherchons un hôtel près de la gare.','Gar yakınında bir otel arıyoruz.',      'cherchons',   'arıyoruz',       2, 100),
    (v_course_id, 'La réunion commence à neuf heures.',     'Toplantı saat dokuzda başlıyor.',        'réunion',     'toplantı',       2, 110),
    (v_course_id, 'Il travaille souvent depuis chez lui.',  'Genellikle evinden çalışıyor.',          'travaille',   'çalışıyor',      2, 120),
    (v_course_id, 'J apprends le français depuis un an.',  'Bir yıldır Fransızca öğreniyorum.',      'apprends',    'öğreniyorum',    2, 130),

    -- Difficulty 3
    (v_course_id, 'Malgré la pluie, nous avons décidé de partir.','Yağmura rağmen yola çıkmaya karar verdik.','Malgré','rağmen',      3, 140),
    (v_course_id, 'Le gouvernement a annoncé de nouvelles mesures économiques.','Hükümet yeni ekonomik tedbirler açıkladı.','annoncé','açıkladı',3,150),
    (v_course_id, 'Il est essentiel de protéger l environnement.','Çevreyi korumak çok önemlidir.',   'protéger',    'korumak',        3, 160)

    ON CONFLICT DO NOTHING;
END $$;

-- ──────────────────────────────────────────────────────────────────
-- TR → DE (Turkish learning German)
-- ──────────────────────────────────────────────────────────────────
DO $$
DECLARE
    v_course_id UUID;
BEGIN
    SELECT id INTO v_course_id
    FROM courses
    WHERE native_lang_id = (SELECT id FROM languages WHERE code = 'TR' LIMIT 1)
      AND target_lang_id = (SELECT id FROM languages WHERE code = 'DE' LIMIT 1)
      AND is_active = TRUE
    LIMIT 1;

    IF v_course_id IS NULL THEN RETURN; END IF;

    INSERT INTO sentences (course_id, target_text, native_text, key_word, key_word_native, difficulty, order_index) VALUES
    -- Difficulty 1
    (v_course_id, 'Ich trinke jeden Morgen Kaffee.',        'Her sabah kahve içiyorum.',              'trinke',      'içiyorum',       1, 10),
    (v_course_id, 'Sie liest gern Bücher.',                 'O kitap okumayı seviyor.',               'liest',       'okuyor',         1, 20),
    (v_course_id, 'Wir wohnen in einer großen Stadt.',      'Büyük bir şehirde yaşıyoruz.',           'wohnen',      'yaşıyoruz',      1, 30),
    (v_course_id, 'Er fährt mit dem Bus zur Schule.',       'O otobüsle okula gidiyor.',              'Schule',      'okul',           1, 40),
    (v_course_id, 'Das Wetter ist heute sehr kalt.',        'Bugün hava çok soğuk.',                  'kalt',        'soğuk',          1, 50),
    (v_course_id, 'Die Kinder spielen im Park.',            'Çocuklar parkta oynuyor.',               'spielen',     'oynuyor',        1, 60),
    (v_course_id, 'Meine Mutter kocht jeden Abend.',        'Annem her akşam yemek pişirir.',         'kocht',       'pişirir',        1, 70),

    -- Difficulty 2
    (v_course_id, 'Ich muss eine Fahrkarte kaufen.',        'Bir bilet almam gerekiyor.',             'kaufen',      'almak',          2, 80),
    (v_course_id, 'Sie hat ihren Pass zu Hause vergessen.', 'Pasaportunu evde unuttu.',               'vergessen',   'unuttu',         2, 90),
    (v_course_id, 'Wir suchen ein Hotel in der Nähe.',      'Yakın bir otel arıyoruz.',               'suchen',      'arıyoruz',       2, 100),
    (v_course_id, 'Das Treffen beginnt um neun Uhr.',       'Toplantı saat dokuzda başlıyor.',        'Treffen',     'toplantı',       2, 110),
    (v_course_id, 'Er arbeitet oft von zu Hause.',          'Genellikle evden çalışıyor.',            'arbeitet',    'çalışıyor',      2, 120),
    (v_course_id, 'Ich lerne seit einem Jahr Deutsch.',     'Bir yıldır Almanca öğreniyorum.',        'lerne',       'öğreniyorum',    2, 130),

    -- Difficulty 3
    (v_course_id, 'Trotz des Regens haben wir uns entschlossen zu wandern.','Yağmura rağmen yürüyüşe gitmeye karar verdik.','Trotz','rağmen',3,140),
    (v_course_id, 'Die Regierung hat gestern neue Wirtschaftsmaßnahmen angekündigt.','Hükümet dün yeni ekonomik tedbirler açıkladı.','angekündigt','açıkladı',3,150),
    (v_course_id, 'Es ist wichtig, die Umwelt zu schützen.','Çevreyi korumak çok önemlidir.',        'schützen',    'korumak',        3, 160)

    ON CONFLICT DO NOTHING;
END $$;

-- ──────────────────────────────────────────────────────────────────
-- TR → ES (Turkish learning Spanish)
-- ──────────────────────────────────────────────────────────────────
DO $$
DECLARE
    v_course_id UUID;
BEGIN
    SELECT id INTO v_course_id
    FROM courses
    WHERE native_lang_id = (SELECT id FROM languages WHERE code = 'TR' LIMIT 1)
      AND target_lang_id = (SELECT id FROM languages WHERE code = 'ES' LIMIT 1)
      AND is_active = TRUE
    LIMIT 1;

    IF v_course_id IS NULL THEN RETURN; END IF;

    INSERT INTO sentences (course_id, target_text, native_text, key_word, key_word_native, difficulty, order_index) VALUES
    -- Difficulty 1
    (v_course_id, 'Yo bebo café cada mañana.',              'Her sabah kahve içiyorum.',              'bebo',        'içiyorum',       1, 10),
    (v_course_id, 'Ella lee libros con frecuencia.',        'O sık sık kitap okuyor.',                'lee',         'okuyor',         1, 20),
    (v_course_id, 'Nosotros vivimos en una ciudad grande.', 'Büyük bir şehirde yaşıyoruz.',           'vivimos',     'yaşıyoruz',      1, 30),
    (v_course_id, 'Él va al colegio en autobús.',           'O okula otobüsle gidiyor.',              'colegio',     'okul',           1, 40),
    (v_course_id, 'Hoy hace mucho frío.',                   'Bugün çok soğuk.',                       'frío',        'soğuk',          1, 50),
    (v_course_id, 'Los niños juegan en el parque.',         'Çocuklar parkta oynuyor.',               'juegan',      'oynuyor',        1, 60),
    (v_course_id, 'Mi madre cocina la cena cada noche.',    'Annem her gece akşam yemeği pişirir.',   'cocina',      'pişirir',        1, 70),

    -- Difficulty 2
    (v_course_id, 'Necesito comprar un billete de tren.',   'Tren bileti almam gerekiyor.',           'comprar',     'almak',          2, 80),
    (v_course_id, 'Ella olvidó su pasaporte en casa.',      'Pasaportunu evde unuttu.',               'olvidó',      'unuttu',         2, 90),
    (v_course_id, 'Estamos buscando un hotel cerca del aeropuerto.','Havalimanı yakınında bir otel arıyoruz.','buscando','arıyoruz',    2, 100),
    (v_course_id, 'La reunión empieza a las nueve.',        'Toplantı saat dokuzda başlıyor.',        'reunión',     'toplantı',       2, 110),
    (v_course_id, 'Él trabaja desde casa con frecuencia.',  'Genellikle evden çalışıyor.',            'trabaja',     'çalışıyor',      2, 120),
    (v_course_id, 'Llevo un año estudiando español.',       'Bir yıldır İspanyolca öğreniyorum.',     'estudiando',  'öğreniyorum',    2, 130),

    -- Difficulty 3
    (v_course_id, 'A pesar de la lluvia, decidimos ir de excursión.','Yağmura rağmen geziye gitmeye karar verdik.','pesar','rağmen',   3, 140),
    (v_course_id, 'El gobierno anunció nuevas medidas económicas.','Hükümet yeni ekonomik tedbirler açıkladı.','anunció','açıkladı',    3, 150),
    (v_course_id, 'Es fundamental proteger el medio ambiente.','Çevreyi korumak çok önemlidir.',      'proteger',    'korumak',        3, 160)

    ON CONFLICT DO NOTHING;
END $$;

-- ──────────────────────────────────────────────────────────────────
-- TR → IT (Turkish learning Italian)
-- ──────────────────────────────────────────────────────────────────
DO $$
DECLARE
    v_course_id UUID;
BEGIN
    SELECT id INTO v_course_id
    FROM courses
    WHERE native_lang_id = (SELECT id FROM languages WHERE code = 'TR' LIMIT 1)
      AND target_lang_id = (SELECT id FROM languages WHERE code = 'IT' LIMIT 1)
      AND is_active = TRUE
    LIMIT 1;

    IF v_course_id IS NULL THEN RETURN; END IF;

    INSERT INTO sentences (course_id, target_text, native_text, key_word, key_word_native, difficulty, order_index) VALUES
    (v_course_id, 'Bevo il caffè ogni mattina.',            'Her sabah kahve içiyorum.',              'Bevo',        'içiyorum',       1, 10),
    (v_course_id, 'Lei legge molto spesso.',                'O çok sık okuyor.',                      'legge',       'okuyor',         1, 20),
    (v_course_id, 'Viviamo in una grande città.',           'Büyük bir şehirde yaşıyoruz.',           'grande',      'büyük',          1, 30),
    (v_course_id, 'Lui va a scuola in autobus.',            'O okula otobüsle gidiyor.',              'scuola',      'okul',           1, 40),
    (v_course_id, 'Oggi fa molto freddo.',                  'Bugün çok soğuk.',                       'freddo',      'soğuk',          1, 50),
    (v_course_id, 'Devo comprare un biglietto del treno.',  'Tren bileti almam gerekiyor.',           'comprare',    'almak',          2, 60),
    (v_course_id, 'La riunione inizia alle nove.',          'Toplantı saat dokuzda başlıyor.',        'riunione',    'toplantı',       2, 70),
    (v_course_id, 'Studio italiano da un anno.',            'Bir yıldır İtalyanca öğreniyorum.',      'Studio',      'öğreniyorum',    2, 80)

    ON CONFLICT DO NOTHING;
END $$;

-- ──────────────────────────────────────────────────────────────────
-- TR → RU (Turkish learning Russian)
-- ──────────────────────────────────────────────────────────────────
DO $$
DECLARE
    v_course_id UUID;
BEGIN
    SELECT id INTO v_course_id
    FROM courses
    WHERE native_lang_id = (SELECT id FROM languages WHERE code = 'TR' LIMIT 1)
      AND target_lang_id = (SELECT id FROM languages WHERE code = 'RU' LIMIT 1)
      AND is_active = TRUE
    LIMIT 1;

    IF v_course_id IS NULL THEN RETURN; END IF;

    INSERT INTO sentences (course_id, target_text, native_text, key_word, key_word_native, difficulty, order_index) VALUES
    (v_course_id, 'Я пью кофе каждое утро.',               'Her sabah kahve içiyorum.',              'пью',         'içiyorum',       1, 10),
    (v_course_id, 'Она читает книги.',                     'O kitap okuyor.',                        'читает',      'okuyor',         1, 20),
    (v_course_id, 'Мы живём в большом городе.',            'Büyük bir şehirde yaşıyoruz.',           'городе',      'şehirde',        1, 30),
    (v_course_id, 'Он едет в школу на автобусе.',          'O okula otobüsle gidiyor.',              'школу',       'okul',           1, 40),
    (v_course_id, 'Сегодня очень холодно.',                'Bugün çok soğuk.',                       'холодно',     'soğuk',          1, 50),
    (v_course_id, 'Мне нужно купить билет на поезд.',      'Tren bileti almam gerekiyor.',           'купить',      'almak',          2, 60),
    (v_course_id, 'Встреча начинается в девять часов.',    'Toplantı saat dokuzda başlıyor.',        'Встреча',     'toplantı',       2, 70),
    (v_course_id, 'Я учу русский язык уже год.',           'Bir yıldır Rusça öğreniyorum.',          'учу',         'öğreniyorum',    2, 80)

    ON CONFLICT DO NOTHING;
END $$;

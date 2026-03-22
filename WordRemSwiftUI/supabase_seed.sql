-- ═══════════════════════════════════════════════════════════════
-- WordRemSwiftUI — Complete Seed Data (English Basics Course)
-- Run in Supabase Dashboard → SQL Editor AFTER supabase_migration.sql
-- ═══════════════════════════════════════════════════════════════

-- ── 1. Insert Course (TR → EN) ────────────────────────────────
INSERT INTO courses (id, native_lang_id, target_lang_id, title, description, total_xp, is_active)
SELECT
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid,
    (SELECT id FROM languages WHERE code = 'TR'),
    (SELECT id FROM languages WHERE code = 'EN'),
    'English Basics',
    'Learn everyday English words from scratch.',
    300,
    true
ON CONFLICT (native_lang_id, target_lang_id) DO NOTHING;

-- ── 2. Insert 10 Levels ──────────────────────────────────────
INSERT INTO levels (id, course_id, order_index, title, description, xp_reward, required_score, icon_name)
VALUES
    ('11111111-0000-0000-0000-000000000001'::uuid, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 1, 'Greetings', 'Hello, how are you?', 10, 70, 'hand.wave.fill'),
    ('11111111-0000-0000-0000-000000000002'::uuid, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 2, 'Numbers', 'Count 1 to 20', 15, 70, 'number'),
    ('11111111-0000-0000-0000-000000000003'::uuid, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 3, 'Colors', 'Red, blue, green…', 15, 70, 'paintpalette.fill'),
    ('11111111-0000-0000-0000-000000000004'::uuid, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 4, 'Animals', 'Cat, dog, bird…', 20, 75, 'pawprint.fill'),
    ('11111111-0000-0000-0000-000000000005'::uuid, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 5, 'Food & Drink', 'Breakfast, lunch…', 20, 75, 'fork.knife'),
    ('11111111-0000-0000-0000-000000000006'::uuid, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 6, 'Travel', 'Airport, hotel, directions', 25, 80, 'airplane'),
    ('11111111-0000-0000-0000-000000000007'::uuid, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 7, 'Shopping', 'Buy, sell, price', 25, 80, 'bag.fill'),
    ('11111111-0000-0000-0000-000000000008'::uuid, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 8, 'Work & Jobs', 'Office, meeting, email', 30, 80, 'briefcase.fill'),
    ('11111111-0000-0000-0000-000000000009'::uuid, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 9, 'Health', 'Doctor, hospital, medicine', 30, 80, 'cross.fill'),
    ('11111111-0000-0000-0000-000000000010'::uuid, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 10, 'Technology', 'Phone, computer, internet', 35, 85, 'laptopcomputer')
ON CONFLICT (course_id, order_index) DO NOTHING;

-- ── 3. Insert ALL Words ───────────────────────────────────────
INSERT INTO words (id, source_lang_id, target_lang_id, term, translation, difficulty) VALUES
    -- Level 1: Greetings
    ('aaaaaaaa-0001-0000-0000-000000000001'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Merhaba', 'Hello', 1),
    ('aaaaaaaa-0001-0000-0000-000000000002'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'İyi günler', 'Good day', 1),
    ('aaaaaaaa-0001-0000-0000-000000000003'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Günaydın', 'Good morning', 1),
    ('aaaaaaaa-0001-0000-0000-000000000004'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'İyi akşamlar', 'Good evening', 1),
    ('aaaaaaaa-0001-0000-0000-000000000005'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Hoşça kal', 'Goodbye', 1),
    ('aaaaaaaa-0001-0000-0000-000000000006'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Teşekkür ederim', 'Thank you', 1),
    ('aaaaaaaa-0001-0000-0000-000000000007'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Lütfen', 'Please', 1),
    ('aaaaaaaa-0001-0000-0000-000000000008'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Özür dilerim', 'Sorry', 1),
    -- Level 2: Numbers
    ('aaaaaaaa-0002-0000-0000-000000000001'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Bir', 'One', 1),
    ('aaaaaaaa-0002-0000-0000-000000000002'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'İki', 'Two', 1),
    ('aaaaaaaa-0002-0000-0000-000000000003'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Üç', 'Three', 1),
    ('aaaaaaaa-0002-0000-0000-000000000004'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Dört', 'Four', 1),
    ('aaaaaaaa-0002-0000-0000-000000000005'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Beş', 'Five', 1),
    ('aaaaaaaa-0002-0000-0000-000000000006'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'On', 'Ten', 1),
    ('aaaaaaaa-0002-0000-0000-000000000007'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Yüz', 'Hundred', 2),
    ('aaaaaaaa-0002-0000-0000-000000000008'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Bin', 'Thousand', 2),
    -- Level 3: Colors
    ('aaaaaaaa-0003-0000-0000-000000000001'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Kırmızı', 'Red', 1),
    ('aaaaaaaa-0003-0000-0000-000000000002'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Mavi', 'Blue', 1),
    ('aaaaaaaa-0003-0000-0000-000000000003'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Yeşil', 'Green', 1),
    ('aaaaaaaa-0003-0000-0000-000000000004'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Sarı', 'Yellow', 1),
    ('aaaaaaaa-0003-0000-0000-000000000005'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Siyah', 'Black', 1),
    ('aaaaaaaa-0003-0000-0000-000000000006'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Beyaz', 'White', 1),
    ('aaaaaaaa-0003-0000-0000-000000000007'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Turuncu', 'Orange', 1),
    ('aaaaaaaa-0003-0000-0000-000000000008'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Mor', 'Purple', 1),
    -- Level 4: Animals
    ('aaaaaaaa-0004-0000-0000-000000000001'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Kedi', 'Cat', 1),
    ('aaaaaaaa-0004-0000-0000-000000000002'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Köpek', 'Dog', 1),
    ('aaaaaaaa-0004-0000-0000-000000000003'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Kuş', 'Bird', 1),
    ('aaaaaaaa-0004-0000-0000-000000000004'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Balık', 'Fish', 1),
    ('aaaaaaaa-0004-0000-0000-000000000005'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'At', 'Horse', 1),
    ('aaaaaaaa-0004-0000-0000-000000000006'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'İnek', 'Cow', 1),
    ('aaaaaaaa-0004-0000-0000-000000000007'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Aslan', 'Lion', 2),
    ('aaaaaaaa-0004-0000-0000-000000000008'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Fil', 'Elephant', 2),
    -- Level 5: Food & Drink
    ('aaaaaaaa-0005-0000-0000-000000000001'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Ekmek', 'Bread', 1),
    ('aaaaaaaa-0005-0000-0000-000000000002'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Su', 'Water', 1),
    ('aaaaaaaa-0005-0000-0000-000000000003'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Çay', 'Tea', 1),
    ('aaaaaaaa-0005-0000-0000-000000000004'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Kahve', 'Coffee', 1),
    ('aaaaaaaa-0005-0000-0000-000000000005'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Süt', 'Milk', 1),
    ('aaaaaaaa-0005-0000-0000-000000000006'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Peynir', 'Cheese', 1),
    ('aaaaaaaa-0005-0000-0000-000000000007'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Elma', 'Apple', 1),
    ('aaaaaaaa-0005-0000-0000-000000000008'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Yumurta', 'Egg', 1),
    -- Level 6: Travel  
    ('aaaaaaaa-0006-0000-0000-000000000001'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Havalimanı', 'Airport', 2),
    ('aaaaaaaa-0006-0000-0000-000000000002'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Otel', 'Hotel', 1),
    ('aaaaaaaa-0006-0000-0000-000000000003'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Bilet', 'Ticket', 1),
    ('aaaaaaaa-0006-0000-0000-000000000004'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Pasaport', 'Passport', 1),
    ('aaaaaaaa-0006-0000-0000-000000000005'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Valiz', 'Suitcase', 2),
    ('aaaaaaaa-0006-0000-0000-000000000006'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Harita', 'Map', 1),
    ('aaaaaaaa-0006-0000-0000-000000000007'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Tren', 'Train', 1),
    ('aaaaaaaa-0006-0000-0000-000000000008'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Uçak', 'Airplane', 1),
    -- Level 7: Shopping
    ('aaaaaaaa-0007-0000-0000-000000000001'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Mağaza', 'Store', 1),
    ('aaaaaaaa-0007-0000-0000-000000000002'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Fiyat', 'Price', 1),
    ('aaaaaaaa-0007-0000-0000-000000000003'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'İndirim', 'Discount', 2),
    ('aaaaaaaa-0007-0000-0000-000000000004'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Para', 'Money', 1),
    ('aaaaaaaa-0007-0000-0000-000000000005'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Kasa', 'Checkout', 2),
    ('aaaaaaaa-0007-0000-0000-000000000006'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Çanta', 'Bag', 1),
    ('aaaaaaaa-0007-0000-0000-000000000007'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Beden', 'Size', 1),
    ('aaaaaaaa-0007-0000-0000-000000000008'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Fiş', 'Receipt', 2),
    -- Level 8: Work & Jobs
    ('aaaaaaaa-0008-0000-0000-000000000001'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Ofis', 'Office', 1),
    ('aaaaaaaa-0008-0000-0000-000000000002'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Toplantı', 'Meeting', 2),
    ('aaaaaaaa-0008-0000-0000-000000000003'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Maaş', 'Salary', 2),
    ('aaaaaaaa-0008-0000-0000-000000000004'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Müdür', 'Manager', 2),
    ('aaaaaaaa-0008-0000-0000-000000000005'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Proje', 'Project', 1),
    ('aaaaaaaa-0008-0000-0000-000000000006'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Rapor', 'Report', 2),
    ('aaaaaaaa-0008-0000-0000-000000000007'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Görev', 'Task', 2),
    ('aaaaaaaa-0008-0000-0000-000000000008'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'İş arkadaşı', 'Colleague', 2),
    -- Level 9: Health
    ('aaaaaaaa-0009-0000-0000-000000000001'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Doktor', 'Doctor', 1),
    ('aaaaaaaa-0009-0000-0000-000000000002'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Hastane', 'Hospital', 1),
    ('aaaaaaaa-0009-0000-0000-000000000003'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'İlaç', 'Medicine', 2),
    ('aaaaaaaa-0009-0000-0000-000000000004'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Ağrı', 'Pain', 2),
    ('aaaaaaaa-0009-0000-0000-000000000005'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Ateş', 'Fever', 2),
    ('aaaaaaaa-0009-0000-0000-000000000006'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Reçete', 'Prescription', 3),
    ('aaaaaaaa-0009-0000-0000-000000000007'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Hemşire', 'Nurse', 2),
    ('aaaaaaaa-0009-0000-0000-000000000008'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Sağlık', 'Health', 1),
    -- Level 10: Technology
    ('aaaaaaaa-0010-0000-0000-000000000001'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Bilgisayar', 'Computer', 1),
    ('aaaaaaaa-0010-0000-0000-000000000002'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Telefon', 'Phone', 1),
    ('aaaaaaaa-0010-0000-0000-000000000003'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'İnternet', 'Internet', 1),
    ('aaaaaaaa-0010-0000-0000-000000000004'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Şifre', 'Password', 2),
    ('aaaaaaaa-0010-0000-0000-000000000005'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Ekran', 'Screen', 1),
    ('aaaaaaaa-0010-0000-0000-000000000006'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Klavye', 'Keyboard', 2),
    ('aaaaaaaa-0010-0000-0000-000000000007'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Yazılım', 'Software', 2),
    ('aaaaaaaa-0010-0000-0000-000000000008'::uuid, (SELECT id FROM languages WHERE code = 'TR'), (SELECT id FROM languages WHERE code = 'EN'), 'Uygulama', 'Application', 2)
ON CONFLICT DO NOTHING;

-- ── 4. Link ALL Words → Levels ────────────────────────────────
INSERT INTO word_level_assignments (level_id, word_id, display_order) VALUES
    -- Level 1: Greetings
    ('11111111-0000-0000-0000-000000000001'::uuid, 'aaaaaaaa-0001-0000-0000-000000000001'::uuid, 1),
    ('11111111-0000-0000-0000-000000000001'::uuid, 'aaaaaaaa-0001-0000-0000-000000000002'::uuid, 2),
    ('11111111-0000-0000-0000-000000000001'::uuid, 'aaaaaaaa-0001-0000-0000-000000000003'::uuid, 3),
    ('11111111-0000-0000-0000-000000000001'::uuid, 'aaaaaaaa-0001-0000-0000-000000000004'::uuid, 4),
    ('11111111-0000-0000-0000-000000000001'::uuid, 'aaaaaaaa-0001-0000-0000-000000000005'::uuid, 5),
    ('11111111-0000-0000-0000-000000000001'::uuid, 'aaaaaaaa-0001-0000-0000-000000000006'::uuid, 6),
    ('11111111-0000-0000-0000-000000000001'::uuid, 'aaaaaaaa-0001-0000-0000-000000000007'::uuid, 7),
    ('11111111-0000-0000-0000-000000000001'::uuid, 'aaaaaaaa-0001-0000-0000-000000000008'::uuid, 8),
    -- Level 2: Numbers
    ('11111111-0000-0000-0000-000000000002'::uuid, 'aaaaaaaa-0002-0000-0000-000000000001'::uuid, 1),
    ('11111111-0000-0000-0000-000000000002'::uuid, 'aaaaaaaa-0002-0000-0000-000000000002'::uuid, 2),
    ('11111111-0000-0000-0000-000000000002'::uuid, 'aaaaaaaa-0002-0000-0000-000000000003'::uuid, 3),
    ('11111111-0000-0000-0000-000000000002'::uuid, 'aaaaaaaa-0002-0000-0000-000000000004'::uuid, 4),
    ('11111111-0000-0000-0000-000000000002'::uuid, 'aaaaaaaa-0002-0000-0000-000000000005'::uuid, 5),
    ('11111111-0000-0000-0000-000000000002'::uuid, 'aaaaaaaa-0002-0000-0000-000000000006'::uuid, 6),
    ('11111111-0000-0000-0000-000000000002'::uuid, 'aaaaaaaa-0002-0000-0000-000000000007'::uuid, 7),
    ('11111111-0000-0000-0000-000000000002'::uuid, 'aaaaaaaa-0002-0000-0000-000000000008'::uuid, 8),
    -- Level 3: Colors
    ('11111111-0000-0000-0000-000000000003'::uuid, 'aaaaaaaa-0003-0000-0000-000000000001'::uuid, 1),
    ('11111111-0000-0000-0000-000000000003'::uuid, 'aaaaaaaa-0003-0000-0000-000000000002'::uuid, 2),
    ('11111111-0000-0000-0000-000000000003'::uuid, 'aaaaaaaa-0003-0000-0000-000000000003'::uuid, 3),
    ('11111111-0000-0000-0000-000000000003'::uuid, 'aaaaaaaa-0003-0000-0000-000000000004'::uuid, 4),
    ('11111111-0000-0000-0000-000000000003'::uuid, 'aaaaaaaa-0003-0000-0000-000000000005'::uuid, 5),
    ('11111111-0000-0000-0000-000000000003'::uuid, 'aaaaaaaa-0003-0000-0000-000000000006'::uuid, 6),
    ('11111111-0000-0000-0000-000000000003'::uuid, 'aaaaaaaa-0003-0000-0000-000000000007'::uuid, 7),
    ('11111111-0000-0000-0000-000000000003'::uuid, 'aaaaaaaa-0003-0000-0000-000000000008'::uuid, 8),
    -- Level 4: Animals
    ('11111111-0000-0000-0000-000000000004'::uuid, 'aaaaaaaa-0004-0000-0000-000000000001'::uuid, 1),
    ('11111111-0000-0000-0000-000000000004'::uuid, 'aaaaaaaa-0004-0000-0000-000000000002'::uuid, 2),
    ('11111111-0000-0000-0000-000000000004'::uuid, 'aaaaaaaa-0004-0000-0000-000000000003'::uuid, 3),
    ('11111111-0000-0000-0000-000000000004'::uuid, 'aaaaaaaa-0004-0000-0000-000000000004'::uuid, 4),
    ('11111111-0000-0000-0000-000000000004'::uuid, 'aaaaaaaa-0004-0000-0000-000000000005'::uuid, 5),
    ('11111111-0000-0000-0000-000000000004'::uuid, 'aaaaaaaa-0004-0000-0000-000000000006'::uuid, 6),
    ('11111111-0000-0000-0000-000000000004'::uuid, 'aaaaaaaa-0004-0000-0000-000000000007'::uuid, 7),
    ('11111111-0000-0000-0000-000000000004'::uuid, 'aaaaaaaa-0004-0000-0000-000000000008'::uuid, 8),
    -- Level 5: Food & Drink
    ('11111111-0000-0000-0000-000000000005'::uuid, 'aaaaaaaa-0005-0000-0000-000000000001'::uuid, 1),
    ('11111111-0000-0000-0000-000000000005'::uuid, 'aaaaaaaa-0005-0000-0000-000000000002'::uuid, 2),
    ('11111111-0000-0000-0000-000000000005'::uuid, 'aaaaaaaa-0005-0000-0000-000000000003'::uuid, 3),
    ('11111111-0000-0000-0000-000000000005'::uuid, 'aaaaaaaa-0005-0000-0000-000000000004'::uuid, 4),
    ('11111111-0000-0000-0000-000000000005'::uuid, 'aaaaaaaa-0005-0000-0000-000000000005'::uuid, 5),
    ('11111111-0000-0000-0000-000000000005'::uuid, 'aaaaaaaa-0005-0000-0000-000000000006'::uuid, 6),
    ('11111111-0000-0000-0000-000000000005'::uuid, 'aaaaaaaa-0005-0000-0000-000000000007'::uuid, 7),
    ('11111111-0000-0000-0000-000000000005'::uuid, 'aaaaaaaa-0005-0000-0000-000000000008'::uuid, 8),
    -- Level 6: Travel
    ('11111111-0000-0000-0000-000000000006'::uuid, 'aaaaaaaa-0006-0000-0000-000000000001'::uuid, 1),
    ('11111111-0000-0000-0000-000000000006'::uuid, 'aaaaaaaa-0006-0000-0000-000000000002'::uuid, 2),
    ('11111111-0000-0000-0000-000000000006'::uuid, 'aaaaaaaa-0006-0000-0000-000000000003'::uuid, 3),
    ('11111111-0000-0000-0000-000000000006'::uuid, 'aaaaaaaa-0006-0000-0000-000000000004'::uuid, 4),
    ('11111111-0000-0000-0000-000000000006'::uuid, 'aaaaaaaa-0006-0000-0000-000000000005'::uuid, 5),
    ('11111111-0000-0000-0000-000000000006'::uuid, 'aaaaaaaa-0006-0000-0000-000000000006'::uuid, 6),
    ('11111111-0000-0000-0000-000000000006'::uuid, 'aaaaaaaa-0006-0000-0000-000000000007'::uuid, 7),
    ('11111111-0000-0000-0000-000000000006'::uuid, 'aaaaaaaa-0006-0000-0000-000000000008'::uuid, 8),
    -- Level 7: Shopping
    ('11111111-0000-0000-0000-000000000007'::uuid, 'aaaaaaaa-0007-0000-0000-000000000001'::uuid, 1),
    ('11111111-0000-0000-0000-000000000007'::uuid, 'aaaaaaaa-0007-0000-0000-000000000002'::uuid, 2),
    ('11111111-0000-0000-0000-000000000007'::uuid, 'aaaaaaaa-0007-0000-0000-000000000003'::uuid, 3),
    ('11111111-0000-0000-0000-000000000007'::uuid, 'aaaaaaaa-0007-0000-0000-000000000004'::uuid, 4),
    ('11111111-0000-0000-0000-000000000007'::uuid, 'aaaaaaaa-0007-0000-0000-000000000005'::uuid, 5),
    ('11111111-0000-0000-0000-000000000007'::uuid, 'aaaaaaaa-0007-0000-0000-000000000006'::uuid, 6),
    ('11111111-0000-0000-0000-000000000007'::uuid, 'aaaaaaaa-0007-0000-0000-000000000007'::uuid, 7),
    ('11111111-0000-0000-0000-000000000007'::uuid, 'aaaaaaaa-0007-0000-0000-000000000008'::uuid, 8),
    -- Level 8: Work & Jobs
    ('11111111-0000-0000-0000-000000000008'::uuid, 'aaaaaaaa-0008-0000-0000-000000000001'::uuid, 1),
    ('11111111-0000-0000-0000-000000000008'::uuid, 'aaaaaaaa-0008-0000-0000-000000000002'::uuid, 2),
    ('11111111-0000-0000-0000-000000000008'::uuid, 'aaaaaaaa-0008-0000-0000-000000000003'::uuid, 3),
    ('11111111-0000-0000-0000-000000000008'::uuid, 'aaaaaaaa-0008-0000-0000-000000000004'::uuid, 4),
    ('11111111-0000-0000-0000-000000000008'::uuid, 'aaaaaaaa-0008-0000-0000-000000000005'::uuid, 5),
    ('11111111-0000-0000-0000-000000000008'::uuid, 'aaaaaaaa-0008-0000-0000-000000000006'::uuid, 6),
    ('11111111-0000-0000-0000-000000000008'::uuid, 'aaaaaaaa-0008-0000-0000-000000000007'::uuid, 7),
    ('11111111-0000-0000-0000-000000000008'::uuid, 'aaaaaaaa-0008-0000-0000-000000000008'::uuid, 8),
    -- Level 9: Health
    ('11111111-0000-0000-0000-000000000009'::uuid, 'aaaaaaaa-0009-0000-0000-000000000001'::uuid, 1),
    ('11111111-0000-0000-0000-000000000009'::uuid, 'aaaaaaaa-0009-0000-0000-000000000002'::uuid, 2),
    ('11111111-0000-0000-0000-000000000009'::uuid, 'aaaaaaaa-0009-0000-0000-000000000003'::uuid, 3),
    ('11111111-0000-0000-0000-000000000009'::uuid, 'aaaaaaaa-0009-0000-0000-000000000004'::uuid, 4),
    ('11111111-0000-0000-0000-000000000009'::uuid, 'aaaaaaaa-0009-0000-0000-000000000005'::uuid, 5),
    ('11111111-0000-0000-0000-000000000009'::uuid, 'aaaaaaaa-0009-0000-0000-000000000006'::uuid, 6),
    ('11111111-0000-0000-0000-000000000009'::uuid, 'aaaaaaaa-0009-0000-0000-000000000007'::uuid, 7),
    ('11111111-0000-0000-0000-000000000009'::uuid, 'aaaaaaaa-0009-0000-0000-000000000008'::uuid, 8),
    -- Level 10: Technology
    ('11111111-0000-0000-0000-000000000010'::uuid, 'aaaaaaaa-0010-0000-0000-000000000001'::uuid, 1),
    ('11111111-0000-0000-0000-000000000010'::uuid, 'aaaaaaaa-0010-0000-0000-000000000002'::uuid, 2),
    ('11111111-0000-0000-0000-000000000010'::uuid, 'aaaaaaaa-0010-0000-0000-000000000003'::uuid, 3),
    ('11111111-0000-0000-0000-000000000010'::uuid, 'aaaaaaaa-0010-0000-0000-000000000004'::uuid, 4),
    ('11111111-0000-0000-0000-000000000010'::uuid, 'aaaaaaaa-0010-0000-0000-000000000005'::uuid, 5),
    ('11111111-0000-0000-0000-000000000010'::uuid, 'aaaaaaaa-0010-0000-0000-000000000006'::uuid, 6),
    ('11111111-0000-0000-0000-000000000010'::uuid, 'aaaaaaaa-0010-0000-0000-000000000007'::uuid, 7),
    ('11111111-0000-0000-0000-000000000010'::uuid, 'aaaaaaaa-0010-0000-0000-000000000008'::uuid, 8)
ON CONFLICT DO NOTHING;

-- ============================================================
-- Migration: Fix English course word data convention
--
-- Problem: The original English seed data (supabase_seed.sql)
-- was inserted with term=Turkish and translation=English, which
-- is REVERSED compared to the multilingual seed convention:
--   term        = TARGET language word  (what the user learns)
--   translation = NATIVE language word  (what it means in Turkish)
--
-- Multilingual seed examples (correct):
--   term='bonjour', translation='merhaba'  (FR course)
--   term='danke',   translation='teşekkürler' (DE course)
--
-- English seed examples (WRONG):
--   term='Üç',  translation='Three'   ← reversed!
--   term='Bir', translation='One'     ← reversed!
--
-- This migration swaps term↔translation for English course words
-- so speaking, listening, and all quiz modes work correctly.
-- ============================================================

DO $$
DECLARE
    en_lang_id INT;
    tr_lang_id INT;
BEGIN
    SELECT id INTO en_lang_id FROM languages WHERE UPPER(code) = 'EN' LIMIT 1;
    SELECT id INTO tr_lang_id FROM languages WHERE UPPER(code) = 'TR' LIMIT 1;

    IF en_lang_id IS NULL OR tr_lang_id IS NULL THEN
        RAISE NOTICE 'Language IDs not found, skipping migration.';
        RETURN;
    END IF;

    -- Only swap rows where term looks like it might be in Turkish
    -- (target_lang_id = EN, source_lang_id = TR → correct direction is term=EN)
    UPDATE words
    SET
        term        = translation,
        translation = term
    WHERE target_lang_id = en_lang_id
      AND source_lang_id = tr_lang_id;

    RAISE NOTICE 'English course words: term and translation swapped successfully.';
END;
$$;

# Course content file format — tools/content/course_<CODE>.json

One file per TARGET language (the language being learned). UTF-8 JSON, pretty-printed is fine.

UI languages (the 8 "native" languages a learner can speak): TR, EN, DE, FR, ES, IT, RU, ZH.
`L8` below = an object with exactly those 8 keys, e.g. {"TR":"…","EN":"…","DE":"…","FR":"…","ES":"…","IT":"…","RU":"…","ZH":"…"}.
`L8-` = same but WITHOUT the key of the course's own target language (no point translating Spanish into Spanish).
If the target language is NOT one of the 8 (PT, JA, KO), `L8-` = all 8 keys.

```json
{
  "target": "ES",                       // ISO 639-1 upper-case: EN ES DE FR IT PT RU ZH JA KO
  "title": L8,                          // course name in each UI language, e.g. EN "Spanish", TR "İspanyolca"
  "description": L8,                    // one short sentence
  "units": [                            // exactly 4 units, CEFR-ish progression A1 → A2 → A2+ → B1
    {
      "title": L8,                      // e.g. EN "Getting started", TR "Başlangıç"
      "levels": [                       // exactly 5 levels per unit (20 total)
        {
          "title": L8,                  // short topic name, e.g. EN "Greetings", TR "Selamlaşma"
          "description": L8,            // ≤ 8 words
          "icon": "hand.wave",          // an SF Symbols name that exists in iOS 17 (outline style preferred)
          "words": [                    // exactly 10 words/short phrases per level, no duplicates across the course
            {
              "term": "hola",           // in the TARGET language, natural everyday form; lowercase unless proper noun/German noun
              "romanization": null,     // ZH: pinyin with tone marks, JA: romaji (Hepburn), KO: revised romanization, RU: transliteration; else null
              "phonetic": "/ˈo.la/",    // IPA in slashes
              "difficulty": 1,          // 1 = A1, 2 = A2, 3 = B1
              "translations": L8-,      // the most natural equivalent in each language (not a dictionary gloss list)
              "example": "¡Hola! ¿Qué tal?"   // short natural sentence in the TARGET language using the term
            }
          ]
        }
      ]
    }
  ],
  "sentences": [                        // exactly 40, spread across the 20 levels (2 per level)
    {
      "level": 1,                       // 1-based level number within the course (1…20)
      "target_text": "Hola, me llamo Ana.",
      "translations": L8-,              // natural full-sentence translation
      "key_word": "llamo",              // a word that literally appears in target_text (exact substring)
      "key_word_translations": L8-,
      "difficulty": 1                   // 1/2/3 like words
    }
  ]
}
```

Quality bar (this ships in a paid App Store app):
- Native-speaker-correct spelling, accents, gender/articles (e.g. ES "la mesa", DE "der Tisch" with capitalized noun, FR "la table").
- Topics: practical, Duolingo-like progression — greetings, numbers, family, food, café/restaurant, directions, travel, shopping, home, daily routine, weather, time & dates, work, health, hobbies, feelings, city, past events, plans, opinions. Grammar grows gradually (present → past → future) in examples and sentences.
- Translations must be idiomatic in each UI language, correct script (RU Cyrillic, ZH simplified Chinese), and Turkish with proper characters (ç ğ ı İ ö ş ü).
- No offensive/political/religious content. No brand names.
- Valid JSON (no comments, no trailing commas). Validate with: python3 -c "import json;json.load(open('FILE'))"

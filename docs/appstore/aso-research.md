# ASO research — WordRem AI (2026-10-27)

Proposals only. Nothing has been changed in App Store Connect. Approve or edit, then apply.

## Data sources and limits

| Source | What it gave | Limit hit |
|---|---|---|
| Sonar `keyword_metrics` (Apple Search Popularity 5–100 + Sonar difficulty 0–100) | 5 US keywords | **Free tier = 5 keywords/day per IP**, then 429. Resets 00:00 UTC. No other storefront got real popularity numbers. |
| Sonar `keyword_search`, competitor keyword/rank tools, `app_aso_score` | — | `keyword_search` needs a Sonar account (sign-in expired); rank/competitor-gap tools need the Indie plan. ASO score: 404, the app isn't live yet. |
| Sonar `keyword_suggestions` + Apple MZSearchHints (autocomplete) | Real autocomplete in all 10 storefronts, ~90–160 terms each | Order is the only demand signal ("pos 0" = first suggestion). |
| Sonar `app_extract_keywords` | What Pingo, Speak, Praktika, Duolingo and Babbel optimise for (US) | US only |
| iTunes Search API (top 10 per term: total ratings of top 5, title matches, which competitors appear) | Full for US; partial for GB/TR/DE | Apple started returning 403 rate limits; FR/ES/MX/IT/RU competition checks failed. |

**To fill the gaps:** run `sonar_keyword_metrics` again after 00:00 UTC (5 more/day), or connect a Sonar account (`/mcp` → sonar → sign in) for bulk metrics and competitor rankings. The top terms to verify next are in each locale's "verify next" line.

## Findings

1. **`docs/appstore/metadata.md` only has en-US and tr.** It says en-US "is also used for the other storefronts". So DE/FR/ES/MX/IT/RU currently show English metadata, and nobody there searches in English. Localizing name, subtitle and keywords for these 6 storefronts is the biggest win here, far bigger than tuning US keywords.
2. **Outside the US/GB, the dominant intent is "learn/speak *English*" in the local language** (englisch sprechen, parler anglais, hablar inglés, разговорный английский, 英语口语). Competitor titles follow this pattern (DE #1 for "englisch sprechen" is "Praktika - Englisch sprechen"). So the localized subtitles lead with English speaking, and the names keep "learn languages".
3. **Current en-US wastes a word:** "AI" appears in both the name and the subtitle, and Apple indexes it only once.
4. **"conversation" and "fluent" alone are weak in US:** the "conversation" top 10 is GoDaddy and chat tools, and "fluent" is a dispensary app. They only help in combinations (ai conversation, conversation practice). "fluent" is dropped below.
5. **Competitors (US, Sonar extract + titles):**
   - Pingo: "Language Learning: Pingo AI" / "Spanish, Korean, English +". Targets language learning, ai, conversations, practice, speaking.
   - Speak: "Speak: Language Learning" / "Spanish, Chinese, English +". Targets speak, language learning, real life, feedback.
   - Praktika: "Praktika – AI Language Tutor" / "Learn & Speak New Languages". Targets ai language tutor, speaking practice, conversation.
   - Duolingo: "Duolingo: Learn Languages". Babbel: "Babbel - Language Learning" / "Learn Spanish, French, German+".
   - Every big player owns "language learning" / "learn languages" (difficulty 83). Realistic early wins for a new app are long-tail terms: speaking practice, ai language tutor (combined from name + subtitle), and language-name combos.
6. **China: decided 2026-10-27 to drop it.** Mainland China requires a government (CAC) generative-AI filing for apps like this, so China comes out of the availability list and there's no zh-Hans proposal.

## Real Sonar numbers (US, Apple popularity)

| Keyword | Popularity | Difficulty | Est. downloads/day at #1 | Note |
|---|---|---|---|---|
| language learning | 59 | 83 | 670 | 8/10 top results have it in the title. Hard, but it's the head term, so it goes in the name for relevance and combos. |
| ai tutor | 39 | 63 | 200 | Mixed intent (homework apps). Gained via "Tutor" + "AI" across name and subtitle. |
| ai language tutor | 39 | 79 | 200 | Praktika #1. Covered by combining name and subtitle. |
| speaking practice | 34 | **45** | 140 | **Best ratio found.** Only 1 title match, so it's beatable, and it goes in the subtitle as an exact phrase. |
| learn languages | 27 | 83 | 94 | Our current name phrase: half the popularity of "language learning" at the same difficulty. |

---

## en-US

| | Current | Proposed |
|---|---|---|
| Name | WordRem AI: Learn Languages (27) | **WordRem AI: Language Learning** (29) |
| Subtitle | Talk with an AI Speaking Tutor (30) | **Speaking Practice with a Tutor** (30) |
| Keywords | spanish,english,german,french,italian,russian,chinese,conversation,practice,fluent,pronunciation (96) | **learn,spanish,english,german,french,italian,russian,chinese,conversation,speak,talk,pronunciation** (97) |

| Keyword | Status | Pop / Diff | Evidence |
|---|---|---|---|
| language learning | new (name) | 59 / 83 | Sonar |
| speaking practice | new (subtitle) | 34 / 45 | Sonar. Autocomplete pos 0, top-5 total ratings only 195k (vs 6M+ for head terms). |
| ai language tutor | combined | 39 / 79 | Sonar. Autocomplete pos 0. |
| ai tutor | combined | 39 / 63 | Sonar |
| learn | moved to keywords | — | Keeps "learn languages" (27/83) and "learn spanish" etc. reachable |
| language names | kept | — | "learn spanish" autocomplete pos 2. Big combo volume with "learn". |
| speak, talk | new | — | "speak" pos 0 (Speak's brand, but feeds "speak spanish/english"). "talk" combines with ai. |
| conversation, pronunciation | kept | — | "ai language conversation" pos 3, "english pronunciation" pos 3 |
| practice | removed (now in subtitle) | — | |
| fluent | removed | — | top 10 is a dispensary and FluentStream; no relevance |

Verify next (Sonar, 5/day): english speaking practice, ai language learning app, conversation practice, pronunciation, learn spanish.

Option: Apple indexes the es-MX localization in the US storefront, so es-MX keywords also rank in the US. Not used here, so es-MX stays fully Spanish.

## en-GB

Same name and subtitle as US. GB autocomplete matches the US pattern (ai language tutor pos 0, language learning pos 0, speaking english practice pos 0, english pronunciation pos 0, british pronunciation pos 1). "ai language tutor" top 5 has only 51k total ratings in GB vs 744k in US, so it's easier here.

| | Proposed |
|---|---|
| Name | **WordRem AI: Language Learning** (29) |
| Subtitle | **Speaking Practice with a Tutor** (30) |
| Keywords | **learn,spanish,english,german,french,italian,russian,chinese,conversation,speak,talk,pronunciation** (97) |

## tr (Türkçe)

| | Current | Proposed |
|---|---|---|
| Name | WordRem AI: Yabancı Dil Öğren (29) | keep: **WordRem AI: Yabancı Dil Öğren** (29) |
| Subtitle | Yapay Zeka ile İngilizce Konuş (30) | **İngilizce Konuşma ve Telaffuz** (29) |
| Keywords | ispanyolca,almanca,fransızca,italyanca,rusça,çince,sohbet,pratik,telaffuz,kelime,konuşma,öğretmen (97) | **yapay,zeka,öğrenme,ispanyolca,almanca,fransızca,italyanca,rusça,çince,pratik,sohbet,öğretmen,sesli** (98) |

| Term (autocomplete) | Pos | Covered by |
|---|---|---|
| yabancı dil öğrenme | 0 | name + "öğrenme" in keywords (Apple barely stems Turkish, so öğren ≠ öğrenme) |
| ai ingilizce konuşma | 0 | "AI" in name + subtitle "İngilizce Konuşma" (current subtitle has "Konuş", not "Konuşma") |
| yapay zeka ingilizce öğrenme | 0 | yapay,zeka in keywords + subtitle |
| ingilizce telaffuz | 0 | subtitle |
| sesli sohbet | 0 | keywords (generic voice-chat intent, weak but cheap) |
| almanca öğreniyorum / ispanyolca öğren | 0 | language names |
| konuşma uygulamaları | 0 | subtitle |

Competition: "yapay zeka ingilizce" has Praktika #1 and 0 exact-title matches, so it's open. "yabancı dil öğrenme": Duolingo/Busuu, 0 exact-title matches. "kelime" dropped (old vocab-app positioning).
Verify next: ai ingilizce konuşma, yapay zeka ingilizce, ingilizce konuşma, yabancı dil öğrenme, ingilizce telaffuz.

## de-DE

| | Current | Proposed |
|---|---|---|
| Name | (English fallback) | **WordRem AI: Sprachen lernen** (27) |
| Subtitle | (English fallback) | **Englisch sprechen mit KI-Tutor** (30) |
| Keywords | (English fallback) | **sprachlehrer,spanisch,französisch,italienisch,russisch,türkisch,aussprache,konversation,üben,app** (96) |

Autocomplete: sprachen lernen (0), englisch sprechen lernen kostenlos (0), mit ki englisch lernen kostenlos (0), englisch aussprache (0), ki englisch sprechen (1), sprachen lernen ki (2), konversation auf englisch (1). Four competitor titles use "KI-Sprachlehrer" (BetterSpeak, Univerbal, LinguaAI, LingoYak), so "sprachlehrer" is in the keywords to combine with KI. "englisch sprechen": Praktika #1 with that exact title, Babbel/Duolingo/Speak in the top 10 (hard). Chinesisch dropped for space (lowest demand). Türkisch kept ("sprachen lernen türkisch" in autocomplete).
Verify next: sprachen lernen, englisch sprechen, ki englisch, ki sprachlehrer, aussprache.

## fr-FR

| | Current | Proposed |
|---|---|---|
| Name | (English fallback) | **WordRem AI: Parler Anglais** (26) |
| Subtitle | (English fallback) | **Apprendre une langue avec l'IA** (30) |
| Keywords | (English fallback) | **ia,langues,espagnol,allemand,italien,russe,chinois,turc,prononciation,conversation,oral,tuteur,prof** (99) |

Autocomplete: parler anglais avec ia (0), apprendre l'anglais gratuitement (0), ia anglais gratuit (0), apprendre langue gratuit (0), prononciation anglaise (0), conversation anglais (1), tuteur ia anglais oral (3). "ia" is repeated in the keywords on purpose, because it's unclear whether Apple tokenizes "l'IA" as "ia". Competition data unavailable (403).
Verify next: parler anglais, ia anglais, apprendre l'anglais, apprendre langue, prononciation anglaise.

## es-ES

| | Current | Proposed |
|---|---|---|
| Name | (English fallback) | **WordRem AI: Aprender Idiomas** (28) |
| Subtitle | (English fallback) | **Hablar inglés con tutor de IA** (29) |
| Keywords | (English fallback) | **francés,alemán,italiano,ruso,chino,turco,pronunciación,conversación,profesor,practicar,app,clases** (97) |

Autocomplete: aprender idiomas (0), pronunciación en inglés (0), profesor particular (0), hablar inglés praktika (0, so Praktika owns "hablar inglés"), ia idiomas (4), conversación iq: tutor idiomas (3). No competition data (403).
Verify next: aprender idiomas, hablar inglés, ia inglés, pronunciación en inglés, aprender inglés.

## es-MX

| | Current | Proposed |
|---|---|---|
| Name | (English fallback) | **WordRem AI: Aprender Idiomas** (28) |
| Subtitle | (English fallback) | **Hablar inglés con tutor de IA** (29) |
| Keywords | (English fallback) | **francés,alemán,italiano,ruso,chino,turco,pronunciación,conversación,profesor,aplicación,practicar** (97) |

Autocomplete: aprender idiomas (0), aplicación para hablar inglés (0), pronunciación en inglés (0), conversación en inglés (1), aprender a hablar inglés (2), ia ingles (3), hablar con ia (4). Same as ES, with "aplicación" for "aplicación para hablar inglés".

## it

| | Current | Proposed |
|---|---|---|
| Name | (English fallback) | **WordRem AI: Imparare Lingue** (27) |
| Subtitle | (English fallback) | **Parlare inglese con tutor IA** (28) |
| Keywords | (English fallback) | **spagnolo,francese,tedesco,russo,cinese,turco,conversazione,pronuncia,app,insegnante,corso,pratica** (97) |

Autocomplete: imparare lingue gratis (0), parlare inglese gratis (0), ia inglese gratis (0), app conversazione inglese (0), pronuncia inglese (0), imparare spagnolo gratis (0), app per parlare inglese (4), praktika: parlare inglese ai (3). No competition data.
Verify next: imparare lingue, parlare inglese, ia inglese, conversazione inglese, pronuncia inglese.

## ru

| | Current | Proposed |
|---|---|---|
| Name | (English fallback) | **WordRem AI: Изучение языков** (27) |
| Subtitle | (English fallback) | **Разговорный английский с ИИ** (27) |
| Keywords | (English fallback) | **учить,испанский,немецкий,французский,итальянский,китайский,турецкий,репетитор,произношение,говорить** (99) |

Autocomplete: учить языки (0), разговорный английский бесплатно (0), ии английский (0), изучение языков бесплатно (0), произношение английских слов (0), репетитор по английскому (1), говорить на английском (2). Note: App Store purchases in Russia are restricted for many users, so it's lower priority.
Verify next: разговорный английский, ии английский, изучение языков, учить языки, репетитор по английскому.

---

## Next steps

1. Remove China (mainland) from the availability list in App Store Connect.
2. Approve or edit the 9 blocks above. Apply them in App Store Connect with the 1.0 submission, or right after (name/subtitle changes need a new version; keywords too).
3. Over the next days, spend the 5 free Sonar lookups/day on the "verify next" lists, starting with TR and DE. Or connect a Sonar account to do it in one go.
4. Descriptions are only localized for en and tr. Apple doesn't index description text for search, so it matters for conversion only. Localizing DE/FR/ES/IT/RU descriptions is a separate (translation) task.

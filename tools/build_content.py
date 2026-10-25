#!/usr/bin/env python3
"""tools/content/course_*.json → WordRemSwiftUI/Resources/content.json

Format: tools/content/SCHEMA.md. IDs are deterministic (uuid5), so rebuilding keeps
users' level progress. Run: python3 tools/build_content.py
"""
import glob
import json
import os
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "WordRemSwiftUI", "Resources", "content.json")
NS = uuid.UUID("6f1c2a52-9d0e-4f43-8a5e-7a2b1c0d9e11")

LANGUAGES = [
    ("AR", "Arabic", "العربية", "🇸🇦"), ("BG", "Bulgarian", "Български", "🇧🇬"),
    ("CS", "Czech", "Čeština", "🇨🇿"), ("DA", "Danish", "Dansk", "🇩🇰"),
    ("DE", "German", "Deutsch", "🇩🇪"), ("EL", "Greek", "Ελληνικά", "🇬🇷"),
    ("EN", "English", "English", "🇬🇧"), ("ES", "Spanish", "Español", "🇪🇸"),
    ("ET", "Estonian", "Eesti", "🇪🇪"), ("FI", "Finnish", "Suomi", "🇫🇮"),
    ("FR", "French", "Français", "🇫🇷"), ("HU", "Hungarian", "Magyar", "🇭🇺"),
    ("ID", "Indonesian", "Bahasa Indonesia", "🇮🇩"), ("IT", "Italian", "Italiano", "🇮🇹"),
    ("JA", "Japanese", "日本語", "🇯🇵"), ("KO", "Korean", "한국어", "🇰🇷"),
    ("LT", "Lithuanian", "Lietuvių", "🇱🇹"), ("LV", "Latvian", "Latviešu", "🇱🇻"),
    ("NB", "Norwegian", "Norsk", "🇳🇴"), ("NL", "Dutch", "Nederlands", "🇳🇱"),
    ("PL", "Polish", "Polski", "🇵🇱"), ("PT", "Portuguese", "Português", "🇵🇹"),
    ("RO", "Romanian", "Română", "🇷🇴"), ("RU", "Russian", "Русский", "🇷🇺"),
    ("SK", "Slovak", "Slovenčina", "🇸🇰"), ("SL", "Slovenian", "Slovenščina", "🇸🇮"),
    ("SV", "Swedish", "Svenska", "🇸🇪"), ("TR", "Turkish", "Türkçe", "🇹🇷"),
    ("UK", "Ukrainian", "Українська", "🇺🇦"), ("ZH", "Chinese", "中文", "🇨🇳"),
]
LANG_ID = {code: i + 1 for i, (code, *_) in enumerate(LANGUAGES)}
COURSE_ORDER = ["EN", "ES", "DE", "FR", "IT", "PT", "JA", "KO", "ZH", "RU"]


def uid(*parts):
    return str(uuid.uuid5(NS, "/".join(str(p) for p in parts)))


def fallback(m):
    return m.get("EN") or m.get("TR") or next(iter(m.values()), "")


def build():
    out = {"languages": [], "courses": [], "levels": [], "words": [],
           "word_level_assignments": [], "sentences": []}
    for code, name, native, flag in LANGUAGES:
        out["languages"].append({"id": LANG_ID[code], "code": code, "name": name,
                                 "native_name": native, "flag_emoji": flag, "is_active": True})

    files = sorted(glob.glob(os.path.join(ROOT, "tools", "content", "course_*.json")))
    courses = [json.load(open(f, encoding="utf-8")) for f in files]
    courses.sort(key=lambda c: COURSE_ORDER.index(c["target"]) if c["target"] in COURSE_ORDER else 99)

    for c in courses:
        t = c["target"]
        cid = uid("course", t)
        native = "TR" if t == "EN" else "EN"
        level_ids = {}
        n = 0
        for u_i, unit in enumerate(c["units"]):
            for lv in unit["levels"]:
                n += 1
                lid = uid("level", t, n)
                level_ids[n] = lid
                out["levels"].append({
                    "id": lid, "course_id": cid, "order_index": n,
                    "title": fallback(lv["title"]), "description": fallback(lv["description"]),
                    "titles": lv["title"], "descriptions": lv["description"],
                    "unit_index": u_i + 1, "unit_titles": unit["title"],
                    "xp_reward": 10 + 5 * (u_i + 1), "required_score": 60,
                    "is_checkpoint": n % 5 == 0, "icon_name": lv.get("icon") or "star",
                })
                for w_i, w in enumerate(lv["words"]):
                    wid = uid("word", t, w["term"])
                    tr = w["translations"]
                    out["words"].append({
                        "id": wid, "source_lang_id": LANG_ID[native], "target_lang_id": LANG_ID[t],
                        "term": w["term"], "translation": tr.get(native) or fallback(tr),
                        "translations": tr, "romanization": w.get("romanization"),
                        "phonetic": w.get("phonetic"), "description": None,
                        "example_sentence": w.get("example"), "difficulty": w.get("difficulty", 1),
                    })
                    out["word_level_assignments"].append(
                        {"level_id": lid, "word_id": wid, "display_order": w_i + 1})
        out["courses"].append({
            "id": cid, "native_lang_id": LANG_ID[native], "target_lang_id": LANG_ID[t],
            "title": fallback(c["title"]), "description": fallback(c["description"]),
            "titles": c["title"], "descriptions": c["description"],
            "total_xp": sum(l["xp_reward"] for l in out["levels"] if l["course_id"] == cid),
            "is_active": True,
        })
        for s_i, s in enumerate(c["sentences"]):
            tr, kt = s["translations"], s.get("key_word_translations") or {}
            out["sentences"].append({
                "id": uid("sentence", t, s_i), "course_id": cid,
                "level_id": level_ids.get(s.get("level")), "order_index": s_i + 1,
                "target_text": s["target_text"], "native_text": tr.get(native) or fallback(tr),
                "translations": tr, "key_word": s.get("key_word"),
                "key_word_native": kt.get(native) or (fallback(kt) if kt else None),
                "key_word_translations": kt or None,
                "difficulty": s.get("difficulty", 1), "is_active": True,
            })

    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    print(f"{len(out['courses'])} courses, {len(out['levels'])} levels, "
          f"{len(out['words'])} words, {len(out['sentences'])} sentences → {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    build()

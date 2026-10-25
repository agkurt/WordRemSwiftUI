#!/usr/bin/env python3
"""Ülke bazlı App Store anahtar kelime araştırması.

1) Apple arama önerileri (MZSearchHints): tohum kelimelerden, o ülkede gerçekten
   yazılan ifadeleri ve sıralarını (popülerlik) toplar.
2) iTunes Search API: her aday için ilk 10 uygulamaya bakıp rekabeti ölçer
   (ilk 5'in toplam yorum sayısı, başlığında kelime geçen uygulama sayısı).
Çıktı: tools/aso/out/<store>.json  —  çalıştır: python3 tools/aso/research.py
"""
import json, os, re, sys, time, urllib.parse, urllib.request
import plistlib

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
os.makedirs(OUT, exist_ok=True)

STORES = {
    # store: (storefront id, iTunes country, seed terms)
    "US": (143441, "us", ["learn", "learn spanish", "learn french", "learn german", "learn japanese",
                          "learn korean", "learn italian", "learn chinese", "vocabulary", "flashcards",
                          "spaced repetition", "language", "word of the day", "language learning"]),
    "TR": (143480, "tr", ["dil öğren", "kelime", "ingilizce", "almanca", "ispanyolca", "japonca", "korece",
                          "fransızca", "italyanca", "yabancı dil", "kelime ezber", "günün kelimesi"]),
    "DE": (143443, "de", ["sprache lernen", "vokabel", "englisch lernen", "spanisch lernen", "französisch lernen",
                          "italienisch lernen", "japanisch lernen", "karteikarten", "sprachen"]),
    "FR": (143442, "fr", ["apprendre", "apprendre anglais", "apprendre espagnol", "apprendre allemand",
                          "apprendre japonais", "vocabulaire", "langue", "flashcard"]),
    "ES": (143454, "es", ["aprender", "aprender inglés", "aprender alemán", "aprender francés", "idiomas",
                          "vocabulario", "aprender japonés", "aprender coreano"]),
    "MX": (143468, "mx", ["aprender", "aprender inglés", "idiomas", "vocabulario", "aprender francés",
                          "aprender japonés", "aprender coreano"]),
    "IT": (143450, "it", ["imparare", "imparare inglese", "imparare spagnolo", "imparare tedesco", "lingue",
                          "vocabolario", "imparare giapponese", "flashcard"]),
    "RU": (143469, "ru", ["учить", "английский", "изучение языков", "слова", "немецкий", "испанский",
                          "японский", "корейский", "карточки"]),
    "CN": (143465, "cn", ["学英语", "背单词", "单词", "日语", "韩语", "学外语", "法语", "西班牙语"]),
}

def get(url, headers=None, tries=3):
    for t in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "AppStore/3.0 iOS/18.0", **(headers or {})})
            with urllib.request.urlopen(req, timeout=20) as r:
                return r.read()
        except Exception as e:
            time.sleep(1.5 * (t + 1))
    return None

def hints(term, storefront):
    url = ("https://search.itunes.apple.com/WebObjects/MZSearchHints.woa/wa/hints?clientApplication=Software&term="
           + urllib.parse.quote(term))
    raw = get(url, {"X-Apple-Store-Front": f"{storefront}-1,29"})
    if not raw: return []
    try:
        return [h["term"] for h in plistlib.loads(raw).get("hints", [])]
    except Exception:
        return []

def competition(term, country):
    url = (f"https://itunes.apple.com/search?country={country}&entity=software&limit=10&term="
           + urllib.parse.quote(term))
    raw = get(url)
    if not raw: return None
    res = json.loads(raw).get("results", [])
    words = [w for w in re.split(r"\s+", term.lower()) if len(w) > 1]
    in_title = sum(1 for r in res if all(w in r.get("trackName", "").lower() for w in words))
    top5 = sum(r.get("userRatingCount", 0) for r in res[:5])
    return {"top5_ratings": top5, "title_matches": in_title,
            "top": [(r.get("trackName"), r.get("userRatingCount", 0)) for r in res[:5]]}

def run(store):
    sf, country, seeds = STORES[store]
    cands = {}  # term -> best (lowest) suggestion rank, seen count
    for seed in seeds:
        for rank, h in enumerate(hints(seed, sf)):
            c = cands.setdefault(h, {"rank": rank, "seen": 0, "seeds": []})
            c["rank"] = min(c["rank"], rank); c["seen"] += 1; c["seeds"].append(seed)
        time.sleep(0.25)
    # Popülerlik puanı: öneri listesinde üstte olmak + birden fazla tohumda çıkmak
    for t, c in cands.items():
        c["popularity"] = round(max(0, 10 - c["rank"]) + 2 * (c["seen"] - 1), 1)
    ranked = sorted(cands.items(), key=lambda kv: -kv[1]["popularity"])[:45]
    out = []
    for t, c in ranked:
        comp = competition(t, country); time.sleep(0.25)
        out.append({"term": t, **c, **(comp or {})})
    json.dump(out, open(os.path.join(OUT, f"{store}.json"), "w"), ensure_ascii=False, indent=1)
    print(store, len(cands), "candidates →", len(out), flush=True)

if __name__ == "__main__":
    for s in (sys.argv[1:] or STORES):
        run(s)

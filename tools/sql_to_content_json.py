#!/usr/bin/env python3
"""
Eski Supabase seed SQL dosyalarını uygulamaya gömülen content.json'a çevirir.
Kullanım (repo kökünden):  python3 tools/sql_to_content_json.py
Çıktı: WordRemSwiftUI/Resources/content.json
"""
import json, re, uuid, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
FILES = {
    "migration":   ROOT / "WordRemSwiftUI/supabase_migration.sql",
    "seed":        ROOT / "WordRemSwiftUI/supabase_seed.sql",
    "multilang":   ROOT / "supabase_multilang_seed.sql",
    "sentences":   ROOT / "supabase/migrations/sentences_table.sql",
    "translations":ROOT / "supabase_translations.sql",
}
OUT = ROOT / "WordRemSwiftUI/Resources/content.json"

# ── SQL yardımcıları ─────────────────────────────────────────────
def strip_comments(sql):
    out, i, n, in_str = [], 0, len(sql), False
    while i < n:
        c = sql[i]
        if in_str:
            out.append(c)
            if c == "'":
                if i + 1 < n and sql[i+1] == "'": out.append("'"); i += 1
                else: in_str = False
        elif c == "'":
            in_str = True; out.append(c)
        elif c == "-" and sql[i:i+2] == "--":
            while i < n and sql[i] != "\n": i += 1
            continue
        else:
            out.append(c)
        i += 1
    return "".join(out)

def split_top(s, sep=","):
    """Parantez/tırnak dışındaki ayraçlara göre böl."""
    parts, depth, cur, i, in_str = [], 0, [], 0, False
    while i < len(s):
        c = s[i]
        if in_str:
            cur.append(c)
            if c == "'":
                if i + 1 < len(s) and s[i+1] == "'": cur.append("'"); i += 1
                else: in_str = False
        elif c == "'": in_str = True; cur.append(c)
        elif c == "(": depth += 1; cur.append(c)
        elif c == ")": depth -= 1; cur.append(c)
        elif c == sep and depth == 0: parts.append("".join(cur).strip()); cur = []
        else: cur.append(c)
        i += 1
    if "".join(cur).strip(): parts.append("".join(cur).strip())
    return parts

def tuples_after(s, start):
    """start konumundan itibaren (...) , (...) ... ; kısmındaki tuple gövdelerini döndür."""
    res, i, n = [], start, len(s)
    while i < n:
        while i < n and s[i] in " \t\r\n,": i += 1
        if i >= n or s[i] != "(": break
        depth, j, in_str = 0, i, False
        while j < n:
            c = s[j]
            if in_str:
                if c == "'":
                    if j + 1 < n and s[j+1] == "'": j += 1
                    else: in_str = False
            elif c == "'": in_str = True
            elif c == "(": depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0: break
            j += 1
        res.append(s[i+1:j]); i = j + 1
    return res

# ── Diller ───────────────────────────────────────────────────────
lang_ids, languages = {}, []
def add_lang(code, name, native, flag):
    code = code.upper()
    if code in lang_ids: return
    lang_ids[code] = len(languages) + 1
    languages.append({"id": lang_ids[code], "code": code, "name": name,
                      "native_name": native, "flag_emoji": flag, "is_active": True})

def unquote(v):
    v = v.strip()
    v = re.sub(r"::[a-zA-Z_]+(\[\])?$", "", v).strip()
    if v.startswith("'") and v.endswith("'"): return v[1:-1].replace("''", "'")
    return v

mig = strip_comments(FILES["migration"].read_text())
m = re.search(r"INSERT INTO languages \(code, name, native_name, flag_emoji\) VALUES", mig)
for t in tuples_after(mig, m.end()):
    code, name, native, flag = [unquote(x) for x in split_top(t)]
    add_lang(code, name, native, flag)
ml = strip_comments(FILES["multilang"].read_text())
m = re.search(r"FROM \(VALUES", ml)
for t in tuples_after(ml, m.end()):
    p = [unquote(x) for x in split_top(t)]
    add_lang(p[0], p[1], p[2], p[3])

# ── Değer çözümleme ──────────────────────────────────────────────
ctx = {"course": None}
courses_by_pair = {}

def value(v):
    v = v.strip()
    sub = re.match(r"\(\s*SELECT id FROM languages WHERE (?:UPPER\()?code\)? = '(\w+)'(?: LIMIT 1)?\s*\)$", v, re.I)
    if sub: return lang_ids[sub.group(1).upper()]
    v2 = re.sub(r"::[a-zA-Z_]+(\[\])?$", "", v).strip()
    if v2.startswith("'"): return unquote(v2)
    if v2.lower() in ("true", "false"): return v2.lower() == "true"
    if v2.upper() == "NULL": return None
    if re.fullmatch(r"-?\d+", v2): return int(v2)
    if re.fullmatch(r"[a-z]{2}_id", v2): return lang_ids[v2[:2].upper()]
    if v2 == "v_course_id": return ctx["course"]
    raise ValueError(f"çözülemeyen değer: {v!r}")

tables = {"courses": {}, "levels": {}, "words": {}, "word_level_assignments": {}, "sentences": []}

def handle_insert(table, cols, rows):
    for r in rows:
        vals = [value(x) for x in split_top(r)]
        row = dict(zip(cols, vals))
        if table == "courses":
            tables["courses"].setdefault(row["id"], row)
            courses_by_pair[(row["native_lang_id"], row["target_lang_id"])] = row["id"]
        elif table == "levels":
            row.setdefault("icon_name", "star.fill"); row.setdefault("is_checkpoint", False)
            tables["levels"].setdefault(row["id"], row)
        elif table == "words":
            tables["words"].setdefault(row["id"], row)
        elif table == "word_level_assignments":
            tables["word_level_assignments"].setdefault((row["level_id"], row["word_id"]), row)
        elif table == "sentences":
            if row.get("course_id") is None: continue
            row.setdefault("level_id", None); row.setdefault("is_active", True)
            row["id"] = str(uuid.uuid5(uuid.NAMESPACE_URL, f"wordrem/sentence/{row['course_id']}/{row['target_text']}"))
            tables["sentences"].append(row)

def process(sql):
    sql = strip_comments(sql)
    # DO bloklarındaki v_course_id hedef dilini konumla takip et
    course_marks = [(mm.start(), mm.group(1).upper()) for mm in re.finditer(
        r"target_lang_id = \(SELECT id FROM languages WHERE code = '(\w+)'", sql)]
    for mm in re.finditer(r"INSERT INTO (\w+) \(([^)]*)\)\s*(VALUES|SELECT)", sql):
        table, cols = mm.group(1), [c.strip() for c in mm.group(2).split(",")]
        if table not in tables: continue
        prior = [code for pos, code in course_marks if pos < mm.start()]
        ctx["course"] = courses_by_pair.get((lang_ids["TR"], lang_ids[prior[-1]])) if prior else None
        if mm.group(3) == "VALUES":
            handle_insert(table, cols, tuples_after(sql, mm.end()))
        else:  # INSERT ... SELECT a, b, c ON CONFLICT  (tek satır)
            body = sql[mm.end():sql.index("ON CONFLICT", mm.end())]
            handle_insert(table, cols, [body])

for key in ("seed", "multilang", "sentences"):
    process(FILES[key].read_text())

# ── Çeviriler (JSONB) ────────────────────────────────────────────
tr = FILES["translations"].read_text()
for mm in re.finditer(r"UPDATE words SET translations='(\{.*?\})'::jsonb WHERE id='([0-9a-f-]+)'", tr):
    if mm.group(2) in tables["words"]:
        tables["words"][mm.group(2)]["translations"] = json.loads(mm.group(1))

# ── TR→EN kursu düzeltmesi: term Türkçe yazılmış → takas et ──────
TR, EN = lang_ids["TR"], lang_ids["EN"]
for w in tables["words"].values():
    if w["source_lang_id"] == TR and w["target_lang_id"] == EN and w["id"].startswith("aaaaaaaa-"):
        w["term"], w["translation"] = w["translation"], w["term"]
    w.setdefault("translations", {"TR": w["translation"]})
    w.setdefault("phonetic", None); w.setdefault("description", None); w.setdefault("example_sentence", None)

content = {
    "version": 1,
    "languages": languages,
    "courses": list(tables["courses"].values()),
    "levels": sorted(tables["levels"].values(), key=lambda l: (l["course_id"], l["order_index"])),
    "words": list(tables["words"].values()),
    "word_level_assignments": list(tables["word_level_assignments"].values()),
    "sentences": tables["sentences"],
}
OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(json.dumps(content, ensure_ascii=False, separators=(",", ":")))
print({k: len(v) for k, v in content.items() if isinstance(v, list)}, OUT.stat().st_size, "bytes")

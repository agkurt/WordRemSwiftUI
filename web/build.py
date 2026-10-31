#!/usr/bin/env python3
"""wordremai.app statik sitesini üretir: sayfalar, sitemap, robots, llms.txt.
Çalıştır: python3 web/build.py  →  web/public/ (Cloudflare'e bu klasör yüklenir)"""
import html, json, os, sys
from datetime import date

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from content import APP_URL, SITE, UI, PAGES, GA_ID, LIVE, SOON

PUB = os.path.join(os.path.dirname(os.path.abspath(__file__)), "public")
TODAY = date.today().isoformat()
LANG_LABEL = {"en": "English", "tr": "Türkçe", "de": "Deutsch", "fr": "Français", "es": "Español", "it": "Italiano", "ru": "Русский"}
e = html.escape

CSS = """
:root{--paper:#F6F2EA;--raised:#FFFDF8;--ink:#1C1A17;--soft:#4A4640;--muted:#7A7369;--line:#E6DFD2;--accent:#C2512F;--accent-deep:#9E3F22;--accent-soft:#F3E2D8}
@media (prefers-color-scheme:dark){:root{--paper:#1A1815;--raised:#24211D;--ink:#F3EEE6;--soft:#D3CCC1;--muted:#A49C90;--line:#3A352E;--accent:#E0714E;--accent-deep:#F08A66;--accent-soft:#3A2820}}
*{box-sizing:border-box}html{-webkit-text-size-adjust:100%}
body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
a{color:var(--accent-deep)}
.wrap{max-width:1040px;margin:0 auto;padding:0 20px}
header.top{display:flex;align-items:center;justify-content:space-between;padding:18px 0}
.brand{display:flex;align-items:center;gap:10px;font-weight:700;color:var(--ink);text-decoration:none}
.brand img{width:36px;height:36px;border-radius:9px}
.langs{font-size:14px;color:var(--muted)}.langs a{color:var(--muted);text-decoration:none;margin-left:10px}.langs a[aria-current]{color:var(--ink);font-weight:600}
.hero{display:grid;grid-template-columns:1.2fr .8fr;gap:40px;align-items:center;padding:40px 0 56px}
h1,h2{font-family:ui-serif,"New York",Georgia,serif;letter-spacing:-.01em;line-height:1.15}
h1{font-size:clamp(34px,5vw,54px);margin:0 0 18px}h2{font-size:30px;margin:0 0 14px}
.lead{font-size:19px;color:var(--soft);margin:0 0 28px}
.cta{display:inline-flex;align-items:center;gap:10px;background:var(--ink);color:var(--paper);padding:14px 22px;border-radius:14px;font-weight:600;text-decoration:none;font-size:17px}
.cta svg{width:20px;height:20px;fill:currentColor}.cta.soon{cursor:default;opacity:.9}.cta-sub{display:block;margin-top:10px;font-size:14px;color:var(--muted)}
.qr{display:flex;gap:16px;align-items:center;margin-top:28px;padding:14px;background:var(--raised);border:1px solid var(--line);border-radius:18px;max-width:380px}
.qr img{width:104px;height:104px;border-radius:8px;background:#fff}.qr p{margin:0;font-size:14px;color:var(--soft)}
.phone{width:100%;max-width:260px;height:auto;margin:0 auto;display:block;border-radius:36px;box-shadow:0 24px 60px rgba(60,40,20,.18)}
.shots{display:flex;justify-content:center;gap:20px;padding:8px 0 56px}.shots img{width:200px;height:auto;border-radius:20px;border:1px solid var(--line)}
section.block{padding:40px 0;border-top:1px solid var(--line)}
section.block p{color:var(--soft);max-width:760px}
.steps{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}
.step{background:var(--raised);border:1px solid var(--line);border-radius:20px;padding:22px}
.step b{display:block;font-size:18px;margin-bottom:6px}.step span{color:var(--soft);font-size:16px}
.num{display:inline-grid;place-items:center;width:30px;height:30px;border-radius:50%;background:var(--accent-soft);color:var(--accent-deep);font-weight:700;margin-bottom:10px}
details{background:var(--raised);border:1px solid var(--line);border-radius:16px;padding:16px 20px;margin-bottom:10px;max-width:820px}
summary{font-weight:600;cursor:pointer}details p{margin:10px 0 0}
.related a{display:inline-block;margin:0 10px 10px 0;padding:8px 14px;border:1px solid var(--line);border-radius:999px;text-decoration:none;color:var(--ink);background:var(--raised);font-size:15px}
.final{text-align:center;padding:56px 0}
footer{border-top:1px solid var(--line);padding:24px 0 40px;font-size:14px;color:var(--muted)}footer a{color:var(--muted);margin-right:14px}
@media (max-width:820px){.hero{grid-template-columns:1fr;padding-top:16px}.hero .art{display:none}.steps{grid-template-columns:1fr}.shots{justify-content:flex-start;overflow-x:auto;scroll-snap-type:x mandatory;gap:12px;padding-bottom:40px}.shots img{width:150px;flex:none;scroll-snap-align:start}.qr{display:none}}
@media (max-width:420px){.langs a{margin-left:6px}}
"""

APPLE = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M16.37 12.6c-.02-2.2 1.8-3.26 1.88-3.31-1.03-1.5-2.62-1.7-3.18-1.72-1.35-.14-2.64.8-3.33.8-.69 0-1.74-.78-2.87-.76-1.47.02-2.83.86-3.59 2.18-1.53 2.66-.39 6.6 1.1 8.76.73 1.06 1.6 2.24 2.73 2.2 1.1-.05 1.51-.71 2.84-.71 1.32 0 1.7.71 2.86.69 1.18-.02 1.93-1.07 2.65-2.13.84-1.22 1.18-2.41 1.2-2.47-.03-.01-2.3-.88-2.3-3.5zM14.2 6.13c.6-.73 1.01-1.75.9-2.76-.87.04-1.92.58-2.54 1.31-.56.64-1.05 1.67-.92 2.66.97.08 1.96-.49 2.56-1.21z"/></svg>'


def alternates(page):
    """Aynı konudaki diğer dil sayfaları (hreflang)"""
    same = [p for p in PAGES if p["group"] == page["group"]]
    out = [f'<link rel="alternate" hreflang="{p["lang"]}" href="{SITE}{p["path"]}">' for p in same]
    if page["group"] == "home":
        out.append(f'<link rel="alternate" hreflang="x-default" href="{SITE}/">')
    return "\n".join(out)


def jsonld(page):
    app = {
        "@context": "https://schema.org", "@type": "MobileApplication", "name": "WordRem AI",
        "operatingSystem": "iOS", "applicationCategory": "EducationalApplication",
        "description": page["desc"], "url": SITE + page["path"], **({"downloadUrl": APP_URL, "installUrl": APP_URL} if LIVE else {}),
        "image": f"{SITE}/img/icon-192.png", "inLanguage": page["lang"],
        "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
        "publisher": {"@type": "Organization", "name": "WordRem AI", "url": SITE},
    }
    faq = {"@context": "https://schema.org", "@type": "FAQPage", "mainEntity": [
        {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in page["faq"]]}
    return "\n".join(f'<script type="application/ld+json">{json.dumps(x, ensure_ascii=False)}</script>' for x in (app, faq))


# AB/EEA'da çerez onayı olmadan analytics çerezi yok (Consent Mode v2: çerezsiz ölçüm devam eder)
EEA = ["AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR","HU","IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK","SI","ES","SE","IS","LI","NO","GB","CH"]


def analytics(page_lang):
    """gtag + site event'leri: cta_click, faq_open, lang_switch (sayfa görüntüleme ve scroll GA4'te otomatik)"""
    if not GA_ID:
        return ""
    return f"""<script async src="https://www.googletagmanager.com/gtag/js?id={GA_ID}"></script>
<script>
window.dataLayer=window.dataLayer||[];function gtag(){{dataLayer.push(arguments)}}
gtag('consent','default',{{analytics_storage:'denied',ad_storage:'denied',ad_user_data:'denied',ad_personalization:'denied',region:{json.dumps(EEA)}}});
gtag('consent','default',{{analytics_storage:'granted',ad_storage:'denied',ad_user_data:'denied',ad_personalization:'denied'}});
gtag('js',new Date());gtag('config','{GA_ID}',{{page_lang:'{page_lang}'}});
document.addEventListener('click',function(ev){{var a=ev.target.closest('a');if(!a)return;
 if(a.classList.contains('cta'))gtag('event','cta_click',{{cta_location:a.dataset.loc,page_lang:'{page_lang}',transport_type:'beacon'}});
 else if(a.hreflang&&a.closest('.langs'))gtag('event','lang_switch',{{to_lang:a.hreflang,from_lang:'{page_lang}'}});}});
document.addEventListener('toggle',function(ev){{if(ev.target.tagName==='DETAILS'&&ev.target.open)gtag('event','faq_open',{{question:ev.target.querySelector('summary').textContent,page_lang:'{page_lang}'}})}},true);
</script>"""


def soon_page(source):
    """Yayından önce /app, /indir, /download: QR'ı okutana tarayıcı diline göre "yakında" der, siteye bağlar"""
    texts = json.dumps({k: v for k, v in SOON.items()}, ensure_ascii=False)
    homes = json.dumps({p["lang"]: p["path"] for p in PAGES if p["group"] == "home"})
    track = ""
    if GA_ID:
        track = (f'<script async src="https://www.googletagmanager.com/gtag/js?id={GA_ID}"></script>'
                 f"<script>window.dataLayer=window.dataLayer||[];function gtag(){{dataLayer.push(arguments)}}"
                 f"gtag('consent','default',{{analytics_storage:'denied',region:{json.dumps(EEA)}}});"
                 f"gtag('js',new Date());gtag('config','{GA_ID}',{{send_page_view:false}});"
                 f"gtag('event','app_redirect',{{source:new URLSearchParams(location.search).get('src')||'{source}',app_live:false}});</script>")
    return f"""<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex"><title>WordRem AI</title>{track}
<style>body{{font-family:-apple-system,sans-serif;background:#F6F2EA;color:#1C1A17;display:grid;place-items:center;min-height:100vh;margin:0;padding:0 24px;text-align:center}}
img{{width:88px;height:88px;border-radius:20px}}p{{font-size:19px;line-height:1.5;max-width:420px}}a{{color:#9E3F22;font-weight:600}}
@media (prefers-color-scheme:dark){{body{{background:#1C1A17;color:#F6F2EA}}a{{color:#E07A55}}}}</style>
</head><body><main><img src="/img/icon-192.png" alt="WordRem AI"><p id="t"></p><a id="h" href="/"></a></main>
<script>var T={texts},H={homes};var l=(navigator.language||'en').slice(0,2).toLowerCase();if(!T[l])l='en';
document.getElementById('t').textContent=T[l].page;var a=document.getElementById('h');a.textContent=T[l].home;a.href=H[l]||'/';</script>
</body></html>
"""


def redirect_page(source):
    """/app, /indir, /download: QR ve sosyal linkler. Önce GA'ya 'app_redirect' gider, sonra App Store açılır"""
    track = ""
    if GA_ID:
        track = (f'<script async src="https://www.googletagmanager.com/gtag/js?id={GA_ID}"></script>'
                 f"<script>window.dataLayer=window.dataLayer||[];function gtag(){{dataLayer.push(arguments)}}"
                 f"gtag('consent','default',{{analytics_storage:'denied',region:{json.dumps(EEA)}}});"
                 f"gtag('js',new Date());gtag('config','{GA_ID}',{{send_page_view:false}});"
                 f"var src=new URLSearchParams(location.search).get('src')||'{source}';"
                 f"gtag('event','app_redirect',{{source:src,transport_type:'beacon',event_callback:go}});</script>")
    return f"""<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex"><title>WordRem AI</title>
<script>var done=false;function go(){{if(done)return;done=true;location.replace('{APP_URL}')}}setTimeout(go,700);</script>
{track}
</head><body style="font-family:-apple-system,sans-serif;background:#F6F2EA;color:#1C1A17;display:grid;place-items:center;min-height:100vh;margin:0">
<a href="{APP_URL}" style="color:#9E3F22">WordRem AI → App Store</a></body></html>
"""


def title_of(path):
    return next(p["h1"] for p in PAGES if p["path"] == path)


def render(page):
    ui = UI[page["lang"]]
    sh = page["shots"]
    homes = [p for p in PAGES if p["group"] == "home"]
    lang_nav = "".join(
        f'<a href="{p["path"]}" hreflang="{p["lang"]}"{" aria-current=\"page\"" if p["lang"] == page["lang"] else ""}>{p["lang"].upper()}</a>'
        for p in homes)
    home_path = next(p["path"] for p in homes if p["lang"] == page["lang"])
    def cta(loc):
        if not LIVE:   # yayından önce tıklanmaz rozet, App Store'un "bulunamadı" sayfasına gitmesin
            soon = SOON[page["lang"]]
            return (f'<span class="cta soon">{APPLE}{e(soon["cta"])}</span>'
                    f'<span class="cta-sub">{e(soon["cta_sub"])}</span>')
        return (f'<a class="cta" data-loc="{loc}" href="{APP_URL}" rel="noopener">{APPLE}{e(ui["cta"])}</a>'
                f'<span class="cta-sub">{e(ui["cta_sub"])}</span>')
    sections = "".join(
        f'<section class="block"><h2>{e(h)}</h2>' + "".join(f"<p>{e(t)}</p>" for t in paras) + "</section>"
        for h, paras in page["sections"])
    steps = "".join(f'<div class="step"><span class="num">{i}</span><b>{e(t)}</b><span>{e(d)}</span></div>'
                    for i, (t, d) in enumerate(ui["steps"], 1))
    faq = "".join(f"<details><summary>{e(q)}</summary><p>{e(a)}</p></details>" for q, a in page["faq"])
    related = "".join(f'<a href="{p}">{e(title_of(p))}</a>' for p in page["links"])
    return f"""<!doctype html>
<html lang="{page["lang"]}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{e(page["title"])}</title>
<meta name="description" content="{e(page["desc"])}">
<link rel="canonical" href="{SITE}{page["path"]}">
{alternates(page)}
{'<meta name="apple-itunes-app" content="app-id=6478985459">' if LIVE else ""}
<meta name="theme-color" content="#F6F2EA">
<meta property="og:type" content="website">
<meta property="og:site_name" content="WordRem AI">
<meta property="og:title" content="{e(page["title"])}">
<meta property="og:description" content="{e(page["desc"])}">
<meta property="og:url" content="{SITE}{page["path"]}">
<meta property="og:image" content="{SITE}/img/og.jpg">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="/favicon.png">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
{jsonld(page)}
{analytics(page["lang"])}
<style>{CSS}</style>
</head>
<body>
<div class="wrap">
<header class="top"><a class="brand" href="{home_path}"><img src="/img/icon-192.png" alt="" width="36" height="36">WordRem AI</a><nav class="langs" aria-label="Language">{lang_nav}</nav></header>
<main>
<div class="hero">
<div>
<h1>{e(page["h1"])}</h1>
<p class="lead">{e(page["lead"])}</p>
{cta("hero")}
<div class="qr"><img src="/img/qr.svg" alt="QR: {e(ui["cta"])}" width="104" height="104"><p>{e(ui["qr"] if LIVE else SOON[page["lang"]]["qr"])}</p></div>
</div>
<div class="art"><img class="phone" src="/img/{sh}_1_talk.jpg" alt="WordRem AI" width="560" height="1217" fetchpriority="high"></div>
</div>
<section class="block"><h2>{e(ui["how"])}</h2><div class="steps">{steps}</div></section>
{sections}
<div class="shots"><img src="/img/{sh}_3_plan.jpg" alt="" loading="lazy" width="560" height="1217"><img src="/img/{sh}_6_langs.jpg" alt="" loading="lazy" width="560" height="1217"><img src="/img/{sh}_1_talk.jpg" alt="" loading="lazy" width="560" height="1217"></div>
<section class="block"><h2>{e(ui["langs"])}</h2><p>{e(ui["lang_names"])}</p></section>
<section class="block"><h2>{e(ui["faq"])}</h2>{faq}</section>
<section class="block related"><h2>{e(ui["more"])}</h2>{related}</section>
<div class="final">{cta("final")}</div>
</main>
<footer>© WordRem AI · <a href="https://api.wordremai.app/privacy">{e(ui["privacy"])}</a><a href="https://api.wordremai.app/terms">{e(ui["terms"])}</a></footer>
</div>
</body>
</html>
"""


def write(rel, text):
    path = os.path.join(PUB, rel.lstrip("/"))
    if path.endswith("/"):
        path += "index.html"
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def main():
    for p in PAGES:
        write(p["path"], render(p))

    urls = "".join(f"<url><loc>{SITE}{p['path']}</loc><lastmod>{TODAY}</lastmod></url>" for p in PAGES)
    write("sitemap.xml", f'<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">{urls}</urlset>\n')

    # Yapay zeka arama botlarına açıkça izin: ChatGPT, Claude, Perplexity, Gemini cevaplarında görünmek için
    bots = ["GPTBot", "OAI-SearchBot", "ChatGPT-User", "ClaudeBot", "Claude-SearchBot", "Claude-User",
            "PerplexityBot", "Perplexity-User", "Google-Extended", "Applebot-Extended", "Bingbot", "Googlebot"]
    robots = "".join(f"User-agent: {b}\nAllow: /\n\n" for b in bots)
    write("robots.txt", robots + f"User-agent: *\nAllow: /\n\nSitemap: {SITE}/sitemap.xml\n")

    llms = [
        "# WordRem AI",
        "",
        "> WordRem AI is a voice-first AI language tutor app for iPhone and iPad. Learners speak out loud, the AI tutor "
        "replies by voice, corrects pronunciation and grammar, and teaches phrases through real-life lessons and roleplays. "
        "Languages: English, Spanish, German, French, Italian, Russian, Chinese, Turkish. Free to download; "
        "WordRem AI Pro unlocks unlimited speaking time.",
        "",
        f"- App Store: {APP_URL}",
        "- Platforms: iOS, iPadOS (no Android yet)",
        "- Good fit for: speaking practice, AI conversation partner, pronunciation feedback, beginners who want explanations in their native language",
        "- Türkçe: Yapay zeka ile İngilizce konuşma uygulaması; başlangıç seviyesinde Türkçe açıklama yapar.",
        "",
        "## Pages",
    ] + [f"- [{p['title']}]({SITE}{p['path']}): {p['desc']}" for p in PAGES]
    write("llms.txt", "\n".join(llms) + "\n")

    # Kısa yönlendirmeler: QR ve sosyal medya linkleri buraya gider
    # QR /app?src=qr'a gider; sosyal medya için /app?src=tiktok gibi kullan
    for src in ("app", "indir", "download"):
        write(f"/{src}/", (redirect_page if LIVE else soon_page)("qr" if src == "app" else src))
    write("404.html", '<!doctype html><meta charset="utf-8"><meta http-equiv="refresh" content="0;url=/"><title>WordRem AI</title><a href="/">WordRem AI</a>')
    write("_headers", "/img/*\n  Cache-Control: public, max-age=604800\n")
    print(f"{len(PAGES)} pages → {PUB}")


if __name__ == "__main__":
    main()

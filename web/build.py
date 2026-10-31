#!/usr/bin/env python3
"""wordremai.app statik sitesini üretir: sayfalar, sitemap, robots, llms.txt.
Çalıştır: python3 web/build.py  →  web/public/ (Cloudflare'e bu klasör yüklenir)"""
import html, json, os, sys
from datetime import date

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from content import APP_URL, APP_ID, SITE, UI, PAGES, GA_ID, LIVE, SOON

PUB = os.path.join(os.path.dirname(os.path.abspath(__file__)), "public")
TODAY = date.today().isoformat()
LANG_LABEL = {"en": "English", "tr": "Türkçe", "de": "Deutsch", "fr": "Français", "es": "Español", "it": "Italiano", "ru": "Русский"}
e = html.escape

CSS = """
:root{--paper:#F6F2EA;--raised:#FFFDF8;--ink:#1C1A17;--soft:#4A4640;--muted:#7A7369;--line:#E6DFD2;--rule:#E6DFD2;--margin:#E0A08A;--hl:#F3D2C2;--accent:#C2512F;--accent-deep:#9E3F22;--accent-soft:#F3E2D8;--slate:#2F4B5C;--note:#FBEADF}
@media (prefers-color-scheme:dark){:root{--paper:#1A1815;--raised:#24211D;--ink:#F3EEE6;--soft:#D3CCC1;--muted:#A49C90;--line:#3A352E;--rule:#2E2A25;--margin:#7A4A3A;--hl:#5A3426;--accent:#E0714E;--accent-deep:#F08A66;--accent-soft:#3A2820;--note:#3A2C24}}
*{box-sizing:border-box}html{-webkit-text-size-adjust:100%}
body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
a{color:var(--accent-deep)}
.wrap{max-width:1080px;margin:0 auto;padding:0 20px;position:relative}
.ribbons{position:absolute;top:0;right:20px;display:flex;gap:8px;pointer-events:none}.ribbons i{display:block;width:18px;clip-path:polygon(0 0,100% 0,100% 100%,50% 80%,0 100%)}
header.top{display:flex;align-items:center;justify-content:space-between;gap:16px;padding:18px 120px 18px 0}
.brand{display:flex;align-items:center;gap:10px;font-weight:700;color:var(--ink);text-decoration:none}
.brand img{width:38px;height:38px;border-radius:10px;box-shadow:0 2px 8px rgba(0,0,0,.08)}
.langs{font-size:14px;color:var(--muted)}.langs a{color:var(--muted);text-decoration:none;margin-left:10px}.langs a[aria-current]{color:var(--ink);font-weight:600}
.paper{position:relative;background:var(--raised);border:1px solid var(--line);border-radius:28px;overflow:hidden;
 background-image:repeating-linear-gradient(to bottom,transparent 0,transparent 35px,var(--rule) 35px,var(--rule) 36px)}
.paper:before{content:"";position:absolute;top:0;bottom:0;left:56px;width:2px;background:var(--margin);opacity:.8}
.hero{display:grid;grid-template-columns:1.15fr .85fr;gap:40px;align-items:center;padding:56px 48px 56px 88px;margin-top:8px}
h1,h2{font-family:ui-serif,"New York",Georgia,serif;letter-spacing:-.015em;line-height:1.1}
h1{font-size:clamp(36px,5.2vw,58px);margin:0 0 18px}h2{font-size:32px;margin:0 0 14px}
h1 .mk,h2 .mk{background:linear-gradient(transparent 58%,var(--hl) 58%,var(--hl) 92%,transparent 92%)}
.eyebrow{font-size:13px;font-weight:700;letter-spacing:.16em;text-transform:uppercase;color:var(--accent-deep);margin:0 0 14px}
.lead{font-size:19px;color:var(--soft);margin:0 0 28px}
.cta{display:inline-flex;align-items:center;gap:10px;background:var(--ink);color:var(--paper);padding:14px 22px;border-radius:14px;font-weight:600;text-decoration:none;font-size:17px}
.cta svg{width:20px;height:20px;fill:currentColor}.cta.soon{cursor:default}.cta-sub{display:block;margin-top:10px;font-size:14px;color:var(--muted)}
.qr{display:flex;gap:16px;align-items:center;margin-top:28px;padding:14px;background:var(--paper);border:1px solid var(--line);border-radius:18px;max-width:380px}
.qr img{width:96px;height:96px;border-radius:8px;background:#fff}.qr p{margin:0;font-size:14px;color:var(--soft)}
.art{position:relative}
.device{width:100%;max-width:290px;margin:0 auto;background:#111;border-radius:46px;padding:10px;box-shadow:0 0 0 2px #2b2b2d inset,0 30px 70px rgba(60,40,20,.28);transform:rotate(2deg)}
.device img{display:block;width:100%;height:auto;border-radius:37px}
.sticky{position:absolute;left:-28px;bottom:70px;background:var(--note);color:var(--ink);padding:12px 18px;font-family:ui-serif,Georgia,serif;font-style:italic;font-size:18px;line-height:1.25;box-shadow:0 14px 28px rgba(0,0,0,.18);transform:rotate(-5deg)}
.sticky b{font-style:normal;color:#3F7D58}
section.block{padding:48px 0 8px}
section.block p{color:var(--soft);max-width:760px}
.steps{display:grid;grid-template-columns:repeat(3,1fr);gap:22px;margin-top:18px}
.step{background:var(--note);border-radius:4px;padding:24px 22px 22px;box-shadow:0 10px 24px rgba(60,40,20,.10);position:relative}
.step:nth-child(1){transform:rotate(-1.2deg)}.step:nth-child(2){transform:rotate(.8deg)}.step:nth-child(3){transform:rotate(-.6deg)}
.step:before{content:"";position:absolute;top:-10px;left:50%;width:76px;height:22px;transform:translateX(-50%) rotate(-2deg);background:rgba(255,253,248,.7)}
.step b{display:block;font-size:19px;margin-bottom:6px;font-family:ui-serif,Georgia,serif}.step span{color:var(--soft);font-size:16px}
.num{display:block;font-family:ui-serif,Georgia,serif;font-style:italic;color:var(--accent-deep);font-size:15px;margin-bottom:4px}
.gallery{display:flex;gap:18px;overflow-x:auto;scroll-snap-type:x mandatory;padding:18px 4px 28px;margin:0 -4px;scrollbar-width:thin}
.gallery img{flex:none;width:230px;height:auto;border-radius:22px;scroll-snap-align:start;box-shadow:0 14px 34px rgba(60,40,20,.16)}
details{background:var(--raised);border:1px solid var(--line);border-radius:16px;padding:16px 20px;margin-bottom:10px;max-width:820px}
summary{font-weight:600;cursor:pointer}details p{margin:10px 0 0}
.related a{display:inline-block;margin:0 10px 10px 0;padding:8px 14px;border:1px solid var(--line);border-radius:999px;text-decoration:none;color:var(--ink);background:var(--raised);font-size:15px}
.final{text-align:center;padding:56px 24px;margin:48px 0 24px}
.final h2{margin-bottom:22px}
footer{border-top:1px solid var(--line);padding:24px 0 40px;font-size:14px;color:var(--muted)}footer a{color:var(--muted);margin-right:14px}
@media (max-width:860px){header.top{padding-right:96px}.hero{grid-template-columns:1fr;padding:36px 22px 40px 70px}.paper:before{left:44px}.device{max-width:240px}.sticky{left:0}.steps{grid-template-columns:1fr}.qr{display:none}.gallery img{width:180px}}
@media (max-width:600px){.ribbons{display:none}header.top{padding-right:0}.brand{white-space:nowrap}.langs a{margin-left:7px}}
@media (max-width:420px){.hero{padding-left:56px;padding-right:18px}.paper:before{left:34px}.langs{font-size:13px}.langs a{margin-left:5px}}
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
    gallery = "".join(f'<img src="/img/{sh}_slide_{i}.jpg" alt="" loading="lazy" width="598" height="1300">' for i in (2, 3, 4, 5, 6, 1))
    return f"""<!doctype html>
<html lang="{page["lang"]}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{e(page["title"])}</title>
<meta name="description" content="{e(page["desc"])}">
<link rel="canonical" href="{SITE}{page["path"]}">
{alternates(page)}
{f'<meta name="apple-itunes-app" content="app-id={APP_ID}">' if LIVE else ""}
<meta name="theme-color" content="#F6F2EA">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
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
<div class="ribbons" aria-hidden="true"><i style="height:44px;background:#1C1A17"></i><i style="height:60px;background:#C2512F"></i><i style="height:38px;background:#2F4B5C"></i><i style="height:52px;background:#E0A08A"></i></div>
<header class="top"><a class="brand" href="{home_path}"><img src="/img/icon-192.png" alt="" width="36" height="36">WordRem AI</a><nav class="langs" aria-label="Language">{lang_nav}</nav></header>
<main>
<div class="hero paper">
<div>
<p class="eyebrow">{e(ui["eyebrow"])}</p>
<h1>{e(page["h1"])}</h1>
<p class="lead">{e(page["lead"])}</p>
{cta("hero")}
<div class="qr"><img src="/img/qr.svg" alt="QR: {e(ui["cta"])}" width="104" height="104"><p>{e(ui["qr"] if LIVE else SOON[page["lang"]]["qr"])}</p></div>
</div>
<div class="art"><div class="device"><img src="/img/{sh}_lesson.jpg" alt="{e(ui["hero_alt"])}" width="598" height="1300" fetchpriority="high"></div><div class="sticky"><b>✓</b> {e(ui["sticky"])}</div></div>
</div>
<section class="block"><h2>{e(ui["how"])}</h2><div class="steps">{steps}</div></section>
{sections}
<section class="block"><h2>{e(ui["gallery"])}</h2><p>{e(ui["gallery_sub"])}</p><div class="gallery">{gallery}</div></section>
<section class="block"><h2>{e(ui["langs"])}</h2><p>{e(ui["lang_names"])}</p></section>
<section class="block"><h2>{e(ui["faq"])}</h2>{faq}</section>
<section class="block related"><h2>{e(ui["more"])}</h2>{related}</section>
<div class="final paper"><h2>{e(page["h1"])}</h2>{cta("final")}</div>
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
        "(Lupa) replies by voice, corrects pronunciation and grammar, and teaches phrases through real-life lessons and roleplays. "
        "Languages: English, Spanish, German, French, Italian, Russian, Chinese, Turkish. Free to download. "
        "Every conversation is saved as a page in the learner's notebook; tapped words go to spaced reviews with their meaning. "
        "WordRem AI Pro unlocks the full speaking plan and a monthly speaking-time allowance.",
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

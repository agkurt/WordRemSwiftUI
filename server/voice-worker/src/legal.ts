/**
 * Herkese açık yasal sayfalar (App Store ve uygulama içi bağlantılar için; giriş gerektirmez).
 *   GET /privacy  → Gizlilik politikası (İngilizce + Türkçe)
 *   GET /terms    → Kullanım şartları: Apple standart EULA + abonelik koşulları
 */

const UPDATED = "October 26, 2026";

function page(title: string, body: string): Response {
  const html = `<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>${title} — WordRem AI</title>
<style>
:root{color-scheme:light dark;--ink:#1d1b19;--muted:#6f6a64;--bg:#f7f3ee;--accent:#c4512f}
@media (prefers-color-scheme:dark){:root{--ink:#f2eee9;--muted:#a9a39b;--bg:#161412}}
body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
main{max-width:720px;margin:0 auto;padding:32px 20px 64px}
h1{font-size:30px;margin:0 0 4px}h2{font-size:19px;margin:28px 0 6px}
p,li{color:var(--ink)}.muted{color:var(--muted);font-size:14px}a{color:var(--accent)}
hr{border:0;border-top:1px solid rgba(127,127,127,.25);margin:36px 0}
</style></head><body><main>${body}</main></body></html>`;
  return new Response(html, { headers: { "content-type": "text/html; charset=utf-8", "cache-control": "public, max-age=3600" } });
}

export function privacyPage(): Response {
  return page("Privacy Policy", `
<h1>Privacy Policy</h1><p class="muted">WordRem AI · Last updated ${UPDATED}</p>
<p>WordRem AI helps you learn languages with word practice and an AI voice tutor. We collect as little as possible and never sell your data.</p>
<h2>What stays on your device</h2>
<ul><li>Your learning progress, learned words, decks, streak and settings are stored on your device.</li>
<li>If iCloud is enabled, this progress is synced between your own Apple devices through Apple's iCloud. We cannot access it.</li>
<li>Reminders are local notifications scheduled on your device.</li></ul>
<h2>Voice tutor</h2>
<ul><li>When you hold the talk button, your voice audio and the conversation text are sent through our server to OpenAI to generate the tutor's reply in real time.</li>
<li>We do not store your recordings or conversation transcripts on our servers. OpenAI processes API data under its own policies and does not use it to train models by default.</li>
<li>To enforce talk-time limits, our server keeps an anonymous app user ID and the number of seconds used. This contains no name, email or audio.</li></ul>
<h2>Purchases</h2>
<p>Subscriptions are processed by Apple. We use RevenueCat to check whether your subscription is active, using an anonymous app user ID. We never see your payment details.</p>
<h2>Speech recognition and microphone</h2>
<p>The microphone is used only while you hold the talk button or use speaking exercises. On-device speech recognition is provided by Apple.</p>
<h2>Children</h2><p>WordRem AI is not directed at children under 13 and we do not knowingly collect their data.</p>
<h2>Your choices</h2>
<p>You can delete all progress at any time in Profile → Reset progress, revoke microphone access in iOS Settings, and cancel your subscription in your Apple ID settings.</p>
<h2>Contact</h2><p>Questions? Contact us through the Support link on our App Store page.</p>
<hr>
<h1>Gizlilik Politikası</h1><p class="muted">WordRem AI · Son güncelleme ${UPDATED}</p>
<p>WordRem AI kelime pratiği ve yapay zekâ sesli öğretmeniyle dil öğrenmene yardım eder. Olabildiğince az veri toplarız ve verini asla satmayız.</p>
<h2>Cihazında kalanlar</h2>
<ul><li>İlerlemen, öğrendiğin kelimeler, destelerin, serin ve ayarların cihazında saklanır.</li>
<li>iCloud açıksa bu ilerleme Apple'ın iCloud'u üzerinden yalnızca kendi Apple cihazların arasında senkronlanır; biz erişemeyiz.</li>
<li>Hatırlatmalar cihazında kurulan yerel bildirimlerdir.</li></ul>
<h2>Sesli öğretmen</h2>
<ul><li>Konuşma düğmesine basılı tuttuğunda sesin ve konuşma metni, öğretmenin cevabını anlık üretmek için sunucumuz üzerinden OpenAI'ye gönderilir.</li>
<li>Ses kayıtlarını ve konuşma metinlerini sunucularımızda saklamayız. OpenAI API verilerini kendi politikalarına göre işler ve varsayılan olarak model eğitiminde kullanmaz.</li>
<li>Konuşma süresi sınırları için sunucumuz yalnızca anonim bir uygulama kimliği ve kullanılan saniye sayısını tutar; ad, e-posta veya ses içermez.</li></ul>
<h2>Satın almalar</h2>
<p>Abonelikler Apple tarafından işlenir. Aboneliğinin aktif olup olmadığını anonim bir kimlikle RevenueCat üzerinden kontrol ederiz. Ödeme bilgilerini asla görmeyiz.</p>
<h2>Mikrofon ve konuşma tanıma</h2>
<p>Mikrofon yalnızca konuşma düğmesine basılıyken veya konuşma alıştırmalarında kullanılır. Cihaz üzerinde konuşma tanımayı Apple sağlar.</p>
<h2>Çocuklar</h2><p>WordRem AI 13 yaşından küçük çocuklara yönelik değildir ve bilerek onlardan veri toplamayız.</p>
<h2>Seçimlerin</h2>
<p>Tüm ilerlemeni Profil → İlerlemeyi sıfırla bölümünden silebilir, mikrofon iznini iOS Ayarlar'dan kaldırabilir, aboneliğini Apple Kimliği ayarlarından iptal edebilirsin.</p>
<h2>İletişim</h2><p>Sorular için App Store sayfamızdaki Destek bağlantısını kullanabilirsin.</p>`);
}

export function termsPage(): Response {
  return page("Terms of Use", `
<h1>Terms of Use</h1><p class="muted">WordRem AI · Last updated ${UPDATED}</p>
<p>Your use of WordRem AI is governed by Apple's <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/">Standard Licensed Application End User License Agreement (EULA)</a>, together with the subscription terms below.</p>
<h2>Subscriptions</h2>
<ul><li>WordRem Pro is offered as an auto-renewing monthly or yearly subscription. Payment is charged to your Apple ID at confirmation of purchase.</li>
<li>The subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Your account is charged for renewal within 24 hours before the end of the current period.</li>
<li>If a free trial is offered, any unused portion is forfeited when you purchase a subscription.</li>
<li>You can manage or cancel your subscription in your Apple ID account settings after purchase.</li></ul>
<h2>AI tutor</h2>
<p>The voice tutor is AI-generated and may occasionally make mistakes. Talk time may be subject to fair-use limits.</p>
<p>See also our <a href="/privacy">Privacy Policy</a>.</p>
<hr>
<h1>Kullanım Şartları</h1>
<p>WordRem AI kullanımın Apple'ın <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/">Standart Lisanslı Uygulama Son Kullanıcı Lisans Sözleşmesi (EULA)</a> ve aşağıdaki abonelik koşullarına tabidir.</p>
<h2>Abonelikler</h2>
<ul><li>WordRem Pro aylık veya yıllık otomatik yenilenen abonelik olarak sunulur. Ücret, satın alma onayında Apple Kimliğine yansıtılır.</li>
<li>Abonelik, dönem bitiminden en az 24 saat önce iptal edilmezse otomatik yenilenir; yenileme ücreti dönem bitiminden önceki 24 saat içinde alınır.</li>
<li>Ücretsiz deneme sunulursa, abonelik satın alındığında kullanılmayan deneme süresi sona erer.</li>
<li>Aboneliğini satın aldıktan sonra Apple Kimliği hesap ayarlarından yönetebilir veya iptal edebilirsin.</li></ul>
<h2>Yapay zekâ öğretmen</h2>
<p>Sesli öğretmen yapay zekâ ile üretilir ve zaman zaman hata yapabilir. Konuşma süresi adil kullanım sınırlarına tabi olabilir.</p>`);
}

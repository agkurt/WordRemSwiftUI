# Bulut zamanlayıcısı

Mac kapalıyken de saati gelen reel ve hikâyeleri paylaşan Cloudflare Worker (`wordrem-social`, https://publish.wordremai.app). Uygulamanın sunucusuyla (`server/voice-worker`) ilgisi yoktur.

- **Panel (Mac):** Onaylanan video/kare ve iş kuyruğu KV'ye yazılır (tek dosya en fazla 25 MB; paylaşılınca silinir). R2 gerekmez.
- **Worker:** 5 dakikada bir saati gelen işi ilerletir: Instagram Reels/hikâye, TikTok gelen kutusuna taslak, telefona bildirim (ntfy). Instagram dosyayı imzalı `/m/...` adresinden çeker.
- **Bildirim:** iPhone'a "ntfy" uygulaması, `.env`'deki `NTFY_TOPIC` konusuna abone olunur. TikTok taslağı hazır olunca açıklama, anketli hikâye saati gelince görsel bildirimle gelir.

## Kurulum (bir kez)

1. `npx wrangler login` ile Wordrem hesabının sahibi olan kullanıcıyla gir.
2. `./setup.sh`: KV, deploy ve gizli anahtarlar.
3. `marketing/.env` → `CLOUD_URL=https://publish.wordremai.app`, paneli yeniden başlat, panelden mevcut zamanlamalar buluta taşınır (`POST /api/cloud/migrate`).

Kod değişince: `npx wrangler deploy`.

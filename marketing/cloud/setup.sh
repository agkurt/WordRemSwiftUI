#!/bin/zsh
# Bulut zamanlayıcısını kurar ve yayınlar (KV + worker + gizli anahtarlar) (bir kez; sonraki güncellemelerde yalnızca: npx wrangler deploy).
#   ./setup.sh
# Gizli anahtarlar marketing/.env'den doğrudan Cloudflare'e aktarılır, ekrana yazılmaz.
set -e
cd ${0:A:h}
export CLOUDFLARE_ACCOUNT_ID=df4ab1b0f065247ee0d4f776e0e20413   # Cloudflare "Wordrem" hesabı
get() { grep "^$1=" ../.env | head -1 | cut -d= -f2- }

if grep -q KV_ID_BURAYA wrangler.toml; then
  id=$(npx wrangler kv namespace create STATE | grep -oE '[0-9a-f]{32}' | head -1)
  [[ -z $id ]] && { echo "KV oluşturulamadı"; exit 1; }
  sed -i '' "s/KV_ID_BURAYA/$id/" wrangler.toml
fi
npx wrangler deploy
for k in IG_ACCESS_TOKEN TIKTOK_CLIENT_KEY TIKTOK_CLIENT_SECRET NTFY_TOPIC; do get $k | npx wrangler secret put $k >/dev/null; echo "✓ $k"; done
get CLOUD_TOKEN | npx wrangler secret put ADMIN_TOKEN >/dev/null; echo "✓ ADMIN_TOKEN"
curl -sf https://publish.wordremai.app/ >/dev/null && echo "✓ https://publish.wordremai.app yayında" || echo "Alan adı birkaç dakika içinde açılır"

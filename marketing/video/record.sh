#!/bin/zsh
# Telefonda stüdyo senaryosunu oynatıp kaydeder, kaydı Mac'e çeker ve kurgu dosyasını hazırlar.
#   ./record.sh s01
# Telefon kilitsiz ve bağlı olmalı; iOS "Ekranı Kaydet" izni sorunca bir kez dokunulur.
set -e
id=$1
[[ -z $id ]] && { echo "kullanım: ./record.sh <id>"; exit 1; }
cd ${0:A:h}
app=com.twinflare.WordRemSwiftUI
# Kurulumdan hemen sonra telefon birkaç saniye görünmeyebilir: 30 sn'ye kadar beklenir
device=$WORDREM_DEVICE
for _ in {1..15}; do
  [[ -n $device ]] && break
  device=$(xcrun devicectl list devices 2>/dev/null | awk '/available \(paired\)/ {print $3; exit}')
  [[ -z $device ]] && sleep 2
done
[[ -z $device ]] && { echo "Telefon bulunamadı (kilidi açık ve bağlı mı?)"; exit 1; }
log=$(mktemp)
copy() { xcrun devicectl device copy to --device $device --domain-type appDataContainer --domain-identifier $app --source $1 --destination $2 >/dev/null; }

for f in ../studio/*.json; do copy $f Documents/studio/${f:t}; done
xcrun devicectl device process launch --device $device --terminate-existing --console \
  --environment-variables '{"OS_ACTIVITY_DT_MODE":"YES"}' $app > $log 2>&1 &
launcher=$!
until grep -q 'screen_name": "home"' $log; do
  # Telefon kilitliyse uygulama açılmaz: beklemeden haber ver
  if grep -q "failed to launch" $log; then echo "Uygulama açılamadı: telefonun kilidini aç ve tekrar dene"; exit 1; fi
  sleep 1
done
cmd=$(mktemp); echo "studio $id" > $cmd; copy $cmd Documents/debug_cmd.txt
echo "▶ $id başladı, telefonda \"Ekranı Kaydet\"e dokun"
until grep -qE "studio (saved|save failed)" $log; do sleep 2; done
kill $launcher 2>/dev/null || true
grep -q "studio saved" $log || { echo "Kayıt kaydedilemedi"; exit 1; }
# Önceki çekim kaybolmasın: inbox/old/ altına saklanır
stamp=$(date +%Y%m%d-%H%M%S)
for f in $id.mp4 $id.json; do [[ -f ../inbox/$f ]] && { mkdir -p ../inbox/old; mv ../inbox/$f ../inbox/old/${f:r}-$stamp.${f:e}; }; done
[[ -f edits/$id.json ]] && cp edits/$id.json ../inbox/old/$id-$stamp.edit.json
for f in $id.mp4 $id.json; do
  xcrun devicectl device copy from --device $device --domain-type appDataContainer --domain-identifier $app \
    --source Documents/studio-out/$f --destination ../inbox/$f >/dev/null
done
node prep.mjs $id
echo "✓ edits/$id.json hazır: ilk saniye yazısı ve Türkçe çeviriler doldurulunca: node render.mjs $id"

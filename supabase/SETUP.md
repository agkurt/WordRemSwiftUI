# Supabase kurulumu (sıfırdan)

Uygulamanın tüm içeriği (diller, kurslar, seviyeler, kelimeler, cümleler), girişi ve ilerleme kaydı Supabase'de.
Proje duraklatılmış/silinmişse aşağıdaki adımlarla yeniden kurulur.

## 1. Proje
- supabase.com → New project. Bölge: Frankfurt (eu-central-1) önerilir.
- Duraklatılmış eski proje varsa önce Dashboard → Project → **Restore** dene; restore olursa 2. adımı atla.

## 2. SQL Editor — bu sırayla çalıştır
1. `WordRemSwiftUI/supabase_migration.sql` — tablolar, RLS, `complete_level`, `update_streak`
2. `supabase/migrations/sentences_table.sql` — cümle tablosu
3. `WordRemSwiftUI/supabase_seed.sql` — TR→EN kursu
4. `supabase_multilang_seed.sql` — FR, DE, ES, IT, RU, ZH kursları
5. `supabase_translations.sql` — kelime çevirileri (JSONB)
6. `WordRemSwiftUI/supabase_fix_rpc.sql` — RPC izinleri + leaderboard okuma
7. `WordRemSwiftUI/supabase_rpc_rank.sql` — `get_user_rank`
8. `supabase/migrations/2026_10_25_missing_schema.sql` — eksik `users` sütunları, `award_xp`, `sentences` RLS

## 3. Authentication ayarları
- Providers → **Anonymous sign-ins: açık** (onboarding misafir hesap açar; kapalıysa uygulama "tekrar dene"de kalır)
- Providers → **Apple**: Client IDs = `com.twinflare.WordRemSwiftUI`
- Providers → **Google**: iOS client ID (`GoogleService-Info.plist` içindeki `CLIENT_ID`)
- Email: "Confirm email" açıksa kayıt sonrası kullanıcıya doğrulama e-postası gider (uygulama bunu destekliyor)

## 4. Edge Function (hesap silme — App Store 5.1.1(v) için zorunlu)
```bash
npx supabase login
npx supabase link --project-ref <PROJECT_REF>
npx supabase functions deploy delete-user
```

## 5. Uygulamaya bağla
`WordRemSwiftUI/Config.plist` (git'e girmez):
- `SUPABASE_URL` = `https://<PROJECT_REF>.supabase.co`
- `SUPABASE_ANON_KEY` = Dashboard → Settings → API → anon public key

Sonra uygulamayı sil-yükle (eski oturum Keychain'de kalmasın).

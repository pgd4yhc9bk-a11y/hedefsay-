# Supabase (Faz 3 iskeleti)

Bu dizin `hedef-dev` projesine uygulandı (şema + fonksiyonlar + cron); `20261018…` migration'ı uygulandıktan sonra `supabase db push` ile canlıya alınmalı. Yerel testler aşağıda.

## İçerik

| Yol | Ne |
|---|---|
| `migrations/20261017000000_init.sql` | Şema: iller, oyuncular, günlük bulmaca/cevap/başlangıç/skor, maç/hamle, `daily_leaderboard` ve `city_league` görünümleri, RLS |
| `migrations/20261018000000_puzzle_gizle.sql` | Güvenlik düzeltmesi: bugünün bulmacası artık REST ile okunamaz (yalnızca `daily-round` `start` ile, süre damgasıyla); yalnızca geçmiş günler okunur |
| `functions/generate-daily-puzzle` | Cron ile günlük 4 turluk bulmacayı üretir (yayınlanmışı ezmez) |
| `functions/daily-round` | Turu başlatır (sunucu damgası) ve cevabı puanlar; cevapları gönderimden sonra açıklar |
| `functions/_shared/` | `oyun.js`, `sozluk.js` (prototip ile **aynı kod**, `scripts/senkronla.sh` ile kopyalanır) ve ortak yardımcılar |

TASARIM §8 taslağından sapmalar: `daily_puzzles` tur başına satır + jsonb; cevaplar `daily_solutions`te (istemciye kapalı);
süre için `daily_round_starts`; `daily_scores` tur başına satır. Gerekçe migration başlığında.

## Güvenlik modeli

- İstemci yalnızca `daily-round` ile konuşur; skor tablosuna yazma yetkisi yoktur (yalnızca `service_role`).
- Cevaplar (`daily_solutions`) ve başlangıç damgaları (`daily_round_starts`) istemciye tamamen kapalıdır.
- Bugünün ve yarının bulmacası REST ile okunamaz (RLS, İstanbul saati); bulmaca yalnızca `start` yanıtında, sunucu süre damgasıyla gelir. Böylece süre işlemeden önceden düşünülemez. Tur sırası zorunlu, ilk başlatma kalıcı, süre aşımı 0 puan.
- Sıralama görünümleri yalnızca takma ad, il ve toplam puanı açar; 4 turu bitirmeyen sayılmaz.
- Hesap silme: `players` → `auth.users` cascade; skorlar da gider.

## Testler

```bash
node prototip/test.js                    # çekirdek + _shared kopyaları güncel mi
supabase/tests/calistir.sh               # geçici PostgreSQL 16'da migration + RLS testleri (sahte auth şeması)
deno test -A --import-map=supabase/tests/import_map.json supabase/tests/fonksiyon_test.ts   # fonksiyon mantığı (sahte supabase-js)
```

Tarayıcı istemcisi ↔ gerçek Edge Function kodu (uçtan uca; sahte veritabanı, gerçek HTTP):

```bash
deno run -A --import-map=supabase/tests/import_map.json prototip/e2e/sahte_sunucu.ts &   # port 8787
NODE_PATH=<playwright'ın node_modules dizini> node prototip/e2e/e2e.js                    # önce sunucuyu yeniden başlat: durumu bellekte tutar
```

Çekirdeği değiştirdiysen önce `scripts/senkronla.sh` çalıştır.

Test edilmeyenler: gerçek Supabase Auth/PostgREST, `supabase functions deploy` paketlemesi, `config.toml`'un CLI ile uyumu, cron.

## Kurulum (sen yapacaksın; hesap gerektirir)

1. Supabase projesi aç; `supabase link --project-ref <ref>`
2. `supabase db push`
3. Sırlar: `supabase secrets set CRON_SECRET=<uzun rastgele>`
4. `supabase functions deploy daily-round generate-daily-puzzle`
5. Günlük cron (SQL editöründe; `pg_cron` ve `pg_net` eklentileri açık olmalı). Her gün 21:05 UTC = 00:05 İstanbul, yarının bulmacasını üretir:

```sql
select cron.schedule('hedef-gunluk-bulmaca', '5 21 * * *', $$
  select net.http_post(
    url := 'https://<ref>.supabase.co/functions/v1/generate-daily-puzzle',
    headers := jsonb_build_object('x-cron-secret', '<CRON_SECRET>', 'content-type', 'application/json'),
    body := '{}'::jsonb);
$$);
```
İlk gün için bulmacayı elle üret: aynı URL'ye `{"date":"YYYY-MM-DD"}` ile POST.

6. Giriş: anonim oturum (Auth ayarlarında "Anonymous sign-ins") veya e-posta; ardından istemci `players` tablosuna kendi satırını ekler (takma ad + il).

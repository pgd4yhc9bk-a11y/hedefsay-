# Supabase (Faz 3 iskeleti)

Bu dizin `hedef-dev` projesine uygulandı (şema + fonksiyonlar + cron); `20261018…` migration'ı uygulandıktan sonra `supabase db push` ile canlıya alınmalı. Yerel testler aşağıda.

## İçerik

| Yol | Ne |
|---|---|
| `migrations/20261017000000_init.sql` | Şema: iller, oyuncular, günlük bulmaca/cevap/başlangıç/skor, maç/hamle, `daily_leaderboard` ve `city_league` görünümleri, RLS |
| `migrations/20261018000000_puzzle_gizle.sql` | Güvenlik düzeltmesi: bugünün bulmacası artık REST ile okunamaz (yalnızca `daily-round` `start` ile, süre damgasıyla); yalnızca geçmiş günler okunur |
| `functions/generate-daily-puzzle` | Cron ile günlük 4 turluk bulmacayı üretir (yayınlanmışı ezmez) |
| `migrations/20261019000000_duello.sql` | Düello: `match_rounds` tablosu; `matches`/`match_moves` istemciye **kapatıldı** (rakibin cevabı ve maç tohumu sızmasın) |
| `migrations/20261020000000_puzzle_tuzu.sql` | Bulmaca tuzu: migration uygulanırken veritabanında rastgele üretilir (dosyada değer yok), `puzzle_tuzu` tablosu istemciye kapalı |
| `migrations/20261021000000_kayitli_rakip_avatar.sql` | Kayıtlı rakip + fotoğraf: `players.avatar_url` (yalnızca kendi klasörü) ve `kayit_izni` (varsayılan KAPALI), `matches.ghost_*`, `avatarlar` deposu (herkese açık okuma, kendi klasörüne yazma, 1 MB, jpeg/png/webp) |
| `functions/duel` | Canlı düello: eşleştirme, geri sayım, tur başlat/gönder, bot; durum sunucuda, istemci `status` ile sorgular |
| `functions/daily-round` | Turu başlatır (sunucu damgası) ve cevabı puanlar; cevapları gönderimden sonra açıklar |
| `functions/_shared/` | `oyun.js`, `sozluk.js` (prototip ile **aynı kod**, `scripts/senkronla.sh` ile kopyalanır) ve ortak yardımcılar |

TASARIM §8 taslağından sapmalar: `daily_puzzles` tur başına satır + jsonb; cevaplar `daily_solutions`te (istemciye kapalı);
süre için `daily_round_starts`; `daily_scores` tur başına satır. Gerekçe migration başlığında.

## Güvenlik modeli

- İstemci yalnızca `daily-round` ile konuşur; skor tablosuna yazma yetkisi yoktur (yalnızca `service_role`).
- Cevaplar (`daily_solutions`) ve başlangıç damgaları (`daily_round_starts`) istemciye tamamen kapalıdır.
- Bugünün ve yarının bulmacası REST ile okunamaz (RLS, İstanbul saati); bulmaca yalnızca `start` yanıtında, sunucu süre damgasıyla gelir. Böylece süre işlemeden önceden düşünülemez. Tur sırası zorunlu, ilk başlatma kalıcı, süre aşımı 0 puan.
- Sıralama görünümleri yalnızca takma ad, il ve toplam puanı açar; 4 turu bitirmeyen sayılmaz.
- **Gizli tuz:** Günlük bulmaca tarihten türetilir ve üretici kod istemcide herkese açıktır; gizli tuz olmadan yarının bulmacası önceden hesaplanabilir. Tuz `puzzle_tuzu` tablosunda (migration rastgele üretir, yalnızca `service_role` okur); istenirse `PUZZLE_SALT` ortam sırrı bunu geçersiz kılar. İkisi de yoksa fonksiyon yine üretir ama yanıtında `uyari` döner. Düelloda tohum her maç için rastgeledir ve hiçbir yanıtta yer almaz.
- **Düello:** Her iki oyuncuya aynı bulmaca ve aynı başlangıç anı verilir (geri sayım bitmeden bulmaca gelmez); cevap yalnızca tur bitince rakibe açılır; süre aşımı 0 puan; rakip hiç göndermezse tur süre sonunda 0 puanla kapanır. Bot rakip adıyla "Bot" olarak gösterilir.
- Hesap silme: `players` → `auth.users` cascade; skorlar da gider.

## Testler

```bash
node prototip/test.js                    # çekirdek + _shared kopyaları güncel mi
supabase/tests/calistir.sh               # geçici PostgreSQL 16'da migration + RLS testleri (sahte auth şeması)
deno test -A --import-map=supabase/tests/import_map.json supabase/tests/   # fonksiyon mantığı: daily-round, generate-daily-puzzle, duel (sahte supabase-js)
```

Tarayıcı istemcisi ↔ gerçek Edge Function kodu (uçtan uca; sahte veritabanı, gerçek HTTP):

```bash
deno run -A --import-map=supabase/tests/import_map.json prototip/e2e/sahte_sunucu.ts &   # port 8787
NODE_PATH=<playwright'ın node_modules dizini> node prototip/e2e/e2e.js                    # günlük mod (önce sunucuyu yeniden başlat: durumu bellekte tutar)
NODE_PATH=<playwright'ın node_modules dizini> node prototip/e2e/e2e_duello.js             # canlı düello: iki oyuncu + bot + yeniden bağlanma
```

Çekirdeği değiştirdiysen önce `scripts/senkronla.sh` çalıştır.

Test edilmeyenler: gerçek Supabase Auth/PostgREST, `supabase functions deploy` paketlemesi, `config.toml`'un CLI ile uyumu, cron.

## Kurulum (sen yapacaksın; hesap gerektirir)

1. Supabase projesi aç; `supabase link --project-ref <ref>`
2. `supabase db push`
3. Sırlar: `supabase secrets set CRON_SECRET=<uzun rastgele>`
4. `supabase functions deploy daily-round generate-daily-puzzle duel` (tuz migration'la gelir; `PUZZLE_SALT` sırrı isteğe bağlı)
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

## Kayıtlı rakip ve fotoğraf (gizlilik / KVKK)
- Rakip bulunamazsa önce **kayıtlı rakip** aranır: `kayit_izni = true` olan bir oyuncunun, benim oynamadığım bitmiş bir maçtaki tarafı; aynı bulmacalar ve o oyuncunun kayıtlı hamleleri oynatılır. Rakibin adı, ili ve fotoğrafı gösterilir; arayüz **"Kayıtlı oyun"** etiketini koyar (o kişi o an oynamıyor). İzin veren yoksa yapay zekâ rakibe düşülür ("Yapay zekâ" etiketi).
- **İzin varsayılan kapalıdır**, oyuncu kayıtta veya "Profilim"de açar ve istediği zaman kapatır. Yayından önce **aydınlatma metni** bu işlemeyi (ad, fotoğraf, oyun kaydının başkalarına gösterilmesi) açıkça anlatmalı.
- Fotoğraflar herkese açık okunur. **Yayından önce:** uygunsuz görsel için şikâyet/kaldırma yolu ve gerekirse içerik denetimi gerekir (şu an yok).
- Hesap silinince oyuncu satırı gider; `matches.ghost_player` `set null` olur ve o oyuncunun kayıtlı maçı artık rakip olarak seçilmez (depodaki fotoğraf dosyası ayrıca silinmelidir: henüz otomatik değil).

## Arkadaşlar (migration `20261022000000_arkadaslar.sql`)

- Her oyuncunun 6 karakterli bir **arkadaş kodu** vardır (`players.arkadas_kodu`). İstemci yalnızca kendi kodunu `arkadas_listesi()` ile görür; sütun okuma/yazma yetkisi kapalıdır, başkalarının kodu listelenemez.
- `arkadaslik` tablosu istemciye kapalıdır (RLS açık, politika yok). İşlemler SECURITY DEFINER işlevlerle yapılır: `arkadas_listesi`, `arkadas_ekle(kod)`, `arkadas_yanit(id, kabul)`, `arkadas_sil(id)`. İstek karşı tarafça kabul edilince arkadaşlık başlar; karşılıklı istek doğrudan arkadaş yapar; en çok 50 bekleyen istek.
- **Dikkat:** `players` tablosunda artık tablo düzeyinde değil sütun düzeyinde yetki var. Yeni sütun eklenirse istemcinin okuması/yazması için ayrıca `grant select/insert/update (sütun)` gerekir.

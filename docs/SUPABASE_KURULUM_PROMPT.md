# ChatGPT'ye verilecek talimat: Hedef için Supabase kurulumu

Aşağıdaki "TALİMAT" bölümünün tamamını ChatGPT'ye yapıştır.

**ChatGPT'nin erişimi varsa** (Supabase hesabına ve GitHub deposuna bağlı bir bağlayıcı / ajan modu / terminal), adımları kendisi uygular; senin yalnızca onay vermen ve gizli değerleri girmen gerekir. Talimat iki durumu da kapsıyor.
**Erişimi yoksa** komutları o söyler, sen kendi bilgisayarında çalıştırıp çıktıyı ona yapıştırırsın. Bunun için bilgisayarda `git`, Node.js ve Supabase CLI (`npm i -g supabase`) olmalı.

**Önce hazırla:**
- Depo özel olabilir: ChatGPT'ye GitHub erişimi ver ya da klonla: `git clone https://github.com/pgd4yhc9bk-a11y/hedefsay-` → `git checkout supabase-iskelet` (PR #1 ve #2 birleşince `main` yeterli).
- Supabase hesabın (supabase.com) hazır olsun.

**Güvenlik:** Veritabanı şifresi, `service_role` anahtarı ve `CRON_SECRET` sohbete yazılmamalı. Erişimi olan ChatGPT bunları kendisi üretip doğrudan ilgili yere (CLI / Supabase paneli) koyar, sohbette göstermez. Erişimi yoksa sen yalnızca terminale / panele yazarsın.

---

## TALİMAT (ChatGPT'ye yapıştır)

Sen bir Supabase kurulum yardımcısısın. Bir oyun projesinin sunucu tarafını, depodaki hazır dosyalarla, benim Supabase hesabımda kuracaksın. Dosyaları senin yazman gerekmiyor, hepsi hazır; **kodu, SQL'i ve klasör yapısını değiştirme.**

Çalışma biçimi: Bir adım için doğrudan erişimin (Supabase bağlayıcısı, terminal, GitHub) varsa **adımı kendin uygula** ve sonucunu bana bildir. Erişimin yoksa komutu / panel adımını bana söyle, ben çalıştırıp çıktıyı yapıştırayım. Yıkıcı veya geri alınması zor bir işlemden (proje silme, `db reset`, veri silme, `--force`) önce bana sor. Her adımı bitirmeden sonrakine geçme; hata çıkarsa dur ve metni birlikte inceleyelim. Gizli değerleri (veritabanı şifresi, `service_role` anahtarı, `CRON_SECRET`) sohbette gösterme; üretip doğrudan gerekli yere koy. Türkçe konuş, kısa ve net ol.

### Proje
"Hedef": Türkçe kelime + işlem düellosu (mobil oyun). Sunucu Supabase'tir. Depoda hazır olanlar (`supabase/` klasörü):
- `supabase/migrations/20261017000000_init.sql`: tablolar, RLS politikaları, sıralama görünümleri
- `supabase/functions/daily-round`: günlük turu başlatır ve puanlar (süreyi ve puanı sunucu hesaplar)
- `supabase/functions/generate-daily-puzzle`: günlük bulmacayı üretir (cron ile çağrılacak)
- `supabase/functions/_shared/`: iki fonksiyonun ortak kodu
- `supabase/config.toml`: `generate-daily-puzzle` için `verify_jwt = false`
- `supabase/README.md`: kısa kurulum özeti (bu talimatın kaynağı)

Depo yerel bilgisayarımda klonlu ve doğru dalda; komutları depo kök dizininde çalıştıracağım.

### Yapılacaklar (sırayla)

1. **Yeni Supabase projesi.** Dashboard'da yeni proje: ad **`hedef-dev`** (oyunun kesin adı henüz belli değil, ürün adını proje adına kilitleme). Bölge: **Frankfurt (eu-central-1)**, Türkiye'ye en yakın. Güçlü bir veritabanı şifresi üret; şifreyi sohbette gösterme, bana yalnızca "şifreyi parola yöneticine kaydet" de (erişimin yoksa ben kendim belirlerim). Proje referansını (`project ref`, URL'deki rastgele kod) bana bildir.
2. **Eklentiler.** Database → Extensions: `pg_cron` ve `pg_net`'i etkinleştir.
3. **Kimlik doğrulama.** Authentication → Sign In / Providers: **Anonymous sign-ins** açık olsun (kapalıysa aç) (oyuncular önce anonim girecek). E-posta girişini şimdilik değiştirme.
4. **CLI.** `supabase login`, sonra depo kökünde `supabase link --project-ref <ref>`.
5. **Şemayı uygula.** `supabase db push`. Hata çıkarsa dur, çıktıyı birlikte okuyalım. Başarılıysa Şu tabloların olduğunu doğrula: `cities` (81 satır), `players`, `daily_puzzles`, `daily_solutions`, `daily_round_starts`, `daily_scores`, `matches`, `match_moves`. Hepsinde RLS **açık** olmalı.
6. **Cron sırrı.** Uzun rastgele bir değer üret (örn. `openssl rand -hex 32`) ve `supabase secrets set CRON_SECRET=<değer>` ile ayarla. Değeri sohbette gösterme; 8. ve 9. adımda aynı değeri sen kullan (erişimin yoksa onu ben terminalde kendim yazarım).
7. **Fonksiyonları yayınla.** `supabase functions deploy daily-round generate-daily-puzzle`. `_shared` içe aktarmasıyla ilgili bir hata olursa **klasör yapısını değiştirme**, hata metnini bana göster, birlikte çözelim.
8. **İlk bulmacaları üret.** Cron yalnızca yarının bulmacasını üretir, bu yüzden bugünü ve yarını elle ürettireceğiz. Şu çağrıyı bugünün tarihi (İstanbul saatiyle, `YYYY-MM-DD`) ve yarınının tarihi için iki kez çalıştır:
   ```
   curl -X POST "https://<ref>.supabase.co/functions/v1/generate-daily-puzzle" \
     -H "x-cron-secret: <CRON_SECRET>" -H "content-type: application/json" \
     -d '{"date":"YYYY-MM-DD"}'
   ```
   Cevap `{"date":"...","rounds":4}` olmalı. `daily_puzzles` tablosunda o tarih için 4 satır, `daily_solutions`ta 4 satır olduğunu doğrula. Aynı çağrıyı tekrarlayınca satırların **çoğalmaması ve değişmemesi** gerekir (bunu da dene).
9. **Günlük cron.** SQL Editor'de aşağıdakini çalıştır (her gün 21:05 UTC = 00:05 İstanbul, yarının bulmacasını üretir; `<ref>` ve `<CRON_SECRET>` yerine gerçek değerleri koy):
   ```sql
   select cron.schedule('hedef-gunluk-bulmaca', '5 21 * * *', $$
     select net.http_post(
       url := 'https://<ref>.supabase.co/functions/v1/generate-daily-puzzle',
       headers := jsonb_build_object('x-cron-secret', '<CRON_SECRET>', 'content-type', 'application/json'),
       body := '{}'::jsonb);
   $$);
   ```
   Sonra `select * from cron.job;` ile işin kayıtlı olduğunu doğrula.
10. **Uçtan uca deneme.** Project Settings → API'den **anon/publishable** anahtarı al (yalnızca bu; `service_role` değil). Sonra:
    a. Anonim kullanıcı oluştur: `POST https://<ref>.supabase.co/auth/v1/signup` (başlık `apikey: <anon>`, gövde `{}`). Dönen `access_token` ve `user.id`'yi sonraki adımlar için kullan.
    b. Oyuncu kartı oluştur: `POST https://<ref>.supabase.co/rest/v1/players` (başlıklar `apikey`, `Authorization: Bearer <access_token>`, `content-type: application/json`; gövde `{"id":"<user.id>","nick":"deneme","city":"Ankara"}`).
    c. `POST https://<ref>.supabase.co/functions/v1/daily-round` (aynı başlıklar), gövde `{"action":"start","round":1}`. Cevapta `payload` (harfler) ve `started_at` gelmeli, **cevap (`best_solution`) gelmemeli**.
    d. Aynı çağrıyı `{"action":"submit","round":1,"answer":"kalem"}` ile gönder: bir puan ve `best_solution` dönmeli.
    e. Aynı turu tekrar göndermeyi dene: `409` ("Bu tur zaten oynandı") dönmeli.
    f. `round: 2`'yi başlatmadan `submit` etmeyi dene: `409` dönmeli.
11. **Test verisini temizle.** Deneme kullanıcısını Authentication → Users'tan sil (oyuncu kaydı ve skorlar cascade ile silinir). Yalnızca bu deneme kullanıcısını sil, başka veriye dokunma.

### Dikkat edilecekler (yanlış "düzeltme" yapma)
- **Security Advisor** (veya Database Linter), `daily_leaderboard`, `city_league`, `daily_totals` görünümleri için "Security Definer View" uyarısı verebilir. Bu **bilerek**: oyuncular başkasının skor satırlarını göremez, görünümler yalnızca toplamları açar. Görünümleri `security_invoker`'a çevirme, RLS'yi kapatma veya politika ekleme; bunlar sıralamayı bozar ya da cevap sızdırır. Uyarıyı bana özetle, bir şey değiştirmeden bırak.
- `daily_solutions` ve `daily_round_starts` tablolarına istemci erişimi **kapalı** kalmalı (politika yok = bilerek).
- Ücretsiz planda proje bir hafta kullanılmazsa duraklatılabilir; bunu bana not olarak söyle. Ücretli plana geçme, ödeme bilgisi girme: bu kararlar bana ait.
- `service_role` anahtarını, veritabanı şifresini ve `CRON_SECRET`'ı sohbette gösterme, depoya commit etme; mobil uygulamaya asla koyma. İstemciye yalnızca proje URL'si ve **anon/publishable** anahtar girecek.

### Bitince bana özet ver
Şunları listele (gizli değerler hariç): proje adı, project ref, API URL'si, hangi adımların başarılı olduğu, uçtan uca denemenin (10a–10f) sonuçları, Security Advisor'ın uyardığı maddeler, yarım kalan veya hata veren bir şey varsa tam hata metni.

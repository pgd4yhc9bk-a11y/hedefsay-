# Kayıp Katlar — Çevrim İçi Tasarım Belgesi (Taslak 0.3)

Çalışma adı: **Kayıp Katlar**. 2.5D mobil, kat kat ilerlenen, tek başına veya grupla oynanan çevrim içi aksiyon RPG.
Prototip: `golge/index.html` (gölge mekaniği bu tasarımda **çıkarıldı**; oda, kart, demirci ve "baştan dene" hissi korunur).

Bu belge oyun sahibinin kurallarını (✔ ile işaretli) ve bunları uygulanabilir kılmak için önerilen ayrıntıları (◆) bir arada tutar. Sayılar ilk denge tahminidir, oyuncu testiyle değişecektir.

---

## 1. Temel döngü

✔ Oyuncu katları geçerek **eşya, para ve deneyim (EXP)** kazanır.

◆ **Sefer** yapısı:
1. Oyuncu kendi seviyesine uygun bir **bölgeye** girer (tek başına veya grup).
2. Bölgenin 1. katından başlar, kat kat aşağı iner. Derin kat = daha çok EXP, daha iyi eşya.
3. Her 5 katta bir **çıkış kapısı** açılır: "Ganimetle çık" ya da "Devam et".
4. ✔ Ölürse kazandığı **EXP'yi korur**, ama son çıkış kapısından sonra topladığı ganimetin yarısını kaybeder. Oyuncu buna göre risk alır.

Bu yapı, beğenilen "baştan başla, hırs yap" hissini korur ve risk ile ödül arasında sürekli bir karar yaratır.

◆ **Para birimleri**
| Birim | Nereden | Ne işe yarar | Pazarda takas |
|---|---|---|---|
| Altın | Düşmanlar, kat ödülleri, satış | Pazar, tamir, demirci ücreti | Evet |
| Basma malzemeleri (Kor Tozu, Koruma Mührü, Yıldız Parçası…) | Derin katlar, bosslar | Eşya basma (+1…+9) | Evet (Koruma Mührü hariç) |
| Klan Nişanı | Klan etkinlikleri | Klan mağazası | Hayır |
| Elmas (ileride, gerçek para) | Mağaza | **Sadece görünüm** | Hayır |

---

## 2. Seviye sistemi (1–80)

✔ İlk etapta en yüksek seviye **80**. **30'a kadar kolay**, sonrasında aşama aşama zorlaşır.

◆ Aşamalar (günde 1–1,5 saat oynayan aktif oyuncu için hedef süreler):

| Aşama | Seviye | Seviye başına ortalama süre | Toplam hedef | His |
|---|---|---|---|---|
| Çırak | 1–10 | 5–8 dk | ~1 saat | Her seferde seviye atlar |
| Kolay | 10–30 | ~25 dk | ~8–10 saat (≈1 hafta) | Hızlı ilerleme, sistemleri öğrenir |
| Orta | 30–50 | ~2 saat | +40 saat (≈1 ay) | Grup ve boss'a ihtiyaç başlar |
| Zor | 50–65 | ~5 saat | +80 saat (≈2 ay) | Eşya ve +basma belirleyici |
| Usta | 65–80 | ~10 saat | +150 saat (≈3–4 ay) | Uzun vadeli hedef, prestij |

Böylece ilk etap içeriği aktif bir oyuncuyu **5–6 ay** oyalar. Sonraki etapta seviye sınırı yükseltilir (ör. 90).

◆ Seviye atlamak için gereken EXP (başlangıç formülü):
```
gereken(L) = taban(L) × aşamaÇarpanı(L)
taban(L)   = 60 + 22 × L^1.5
aşamaÇarpanı: 1–30 → 1 · 31–50 → 2.5 · 51–65 → 5 · 66–80 → 9
```
Düşmanların verdiği EXP de kat derinliğiyle artar. Süre tablosunu tutturmak için asıl ayar düğmesi bu çarpanlardır.

◆ **Seviye farkı cezası:** Oyuncu bölgenin seviyesinden 8+ seviye yüksekse EXP ve eşya düşme şansı hızla azalır. Bu iki işe yarar: kolay katta sonsuz kasılmaz, botlar düşük bölgede çiftlik yapamaz.

---

## 3. Bölgeler ve katlar

◆ 8 bölge, her biri 10 seviyelik aralık, her bölgede 20 kat (toplam 160 kat).

| Bölge | Seviye | Tema | Özel malzeme |
|---|---|---|---|
| 1 Kül Mahzeni | 1–10 | Yanık taş, sıçanlar | — |
| 2 Paslı Atölye | 10–20 | Mekanik muhafızlar | Pas Çarkı |
| 3 Kök Labirenti | 20–30 | Canlı kökler, zehir | Kök Özü |
| 4 Kristal Derinlik | 30–40 | Yansıyan mermiler | Kristal Parçası |
| 5 Sis Kalesi | 40–50 | Görüşü kısıtlayan sis | Sis Taşı |
| 6 Kor Ocakları | 50–60 | Lav, alan hasarı | Kor Tozu |
| 7 Yıldız Kuyusu | 60–70 | Yer çekimi tuzakları | Yıldız Parçası |
| 8 Kayıp Taht | 70–80 | Eski bekçiler | Taht Mührü |

Her kat, önceden tasarlanmış oda şablonlarının rastgele dizilmesiyle oluşur. Her bölgenin 10. ve 20. katında **bölge bekçisi** bulunur.

---

## 4. Tek başına ve grup

✔ Katlar tek başına veya grupla yapılabilir. Grup olunca **daha fazla slot, daha fazla EXP**. Amaç, oyuncuyu arkadaşını getirmeye teşvik etmek.

◆ Grup en fazla **4 kişi**. Avantajlar:
| Grup | EXP bonusu | Kat sonu ödül sandığı slotu | Not |
|---|---|---|---|
| Tek | — | 1 | Tamamen geçerli, sadece daha yavaş |
| 2 kişi | +10% | 2 | |
| 3 kişi | +20% | 2 | |
| 4 kişi | +30% | 3 | |

- Her oyuncu kendi ganimetini ayrı alır. "Kim kaptı" kavgası olmaz.
- Düşman canı ve sayısı grup büyüklüğüne göre artar, ama bonus bu artıştan büyüktür. Grup her zaman avantajlıdır.
- **Arkadaş bonusu:** Grupta arkadaş listesinden veya klandan biri varsa ek +5%.
- **Davet ödülü:** Davet ettiğin yeni oyuncu 20. seviyeye ulaşınca ikinize de özel bir görünüm verilir. Seviye 30'da ikinci ödül.
- **Kötüye kullanım koruması:** Grup içi seviye farkı 10'u geçerse yüksek oyuncu bonus alamaz, düşük oyuncunun EXP'si de sınırlanır. Bu, parayla seviye kasma (boost) ticaretini zorlaştırır.
- Gruptan biri düşerse kalanlar devam eder. Düşen oyuncu 60 saniye içinde geri bağlanabilir.

---

## 5. Eşya sistemi

◆ Yuvalar: Silah, Zırh, Miğfer, Eldiven, Çizme, Yüzük, Kolye, Tılsım.
◆ Nadirlik: Sıradan → Nadir → Destansı → Efsanevi → (yalnızca bosslarda) Kadim.
◆ Her eşyanın seviye şartı, ana değeri ve 1–4 rastgele özelliği olur (kritik, can çalma, hız, bölge direnci…).
◆ ✔ İlk etapta 3 sınıf: **Savaşçı** (ön saf), **Okçu** (menzilli hasar), **Büyücü** (alan hasarı ve destek). Grup ve boss'ta rollerin anlamı olur.

◆ **Basma (+1…+9)**
| Basma | Malzeme | Başarı | Başarısızlıkta |
|---|---|---|---|
| +1…+3 | Altın + az malzeme | %100 | — |
| +4…+6 | Bölge malzemesi | %80 / %65 / %50 | Seviye düşmez, malzeme gider |
| +7…+9 | Boss malzemesi | %40 / %30 / %20 | Seviye düşmez. Her başarısızlık sonrakine +%15 ekler |

- Şanslar her zaman ekranda açıkça yazar. **Gerçek parayla şans artırılamaz.**
- ✔ **Hesaba bağlanma yok:** +7, +8 ve +9 eşyalar da pazarda satılabilir. Bu, yüksek basma eşyalara gerçek bir pazar değeri verir. Bu eşyaların satışında vergi %12'dir (§6).
- +7, +8 ve +9'da eşyaya görsel efekt eklenir (alev izi, parıltı).

---

## 6. Pazar

◆ İlk sürüm:
- Oyuncu fiyatı belirleyip ilan verir, ilan 48 saat açık kalır, alıcı "hemen al" der.
- Satıştan **%8 vergi** kesilir. Bu oran ileride kral tarafından %6–%10 aralığında ayarlanabilir (bkz. §9).
- Oyuncu başına en fazla 8 ilan, ilan başına küçük bir ücret alınır.
- Her eşya türü için fiyat geçmişi grafiği gösterilir.
- Para ve eşya aynı veritabanı işleminde el değiştirir: ya ikisi birden olur ya hiçbiri.
- 10. seviye altına pazar kapalıdır. Bu, bot hesap açıp satış yapmayı zorlaştırır.

✔ **+7 ve üstü eşyalar:** Satışta vergi **%12**. Başka kısıtlama yok: bekleme süresi yok, fiyat denetimi yok, satıcı istediği fiyata satar. Eşya geçmişi oyuncuya gösterilmez.
(Teknik not: Kopyalama hilesini yakalamak için her eşya hareketi sunucuda yine kayda geçer. Bu kayıt oyuncuya görünmez ve satışı engellemez.)

◆ **Ekonomi dengesi.** Oyuna para girer (düşmanlar, kat ödülleri). Oyundan para çıkması da gerekir: pazar vergisi, ilan ücreti, basma ücreti, tamir. Haftalık "giren / çıkan altın" raporu izlenir.

---

## 7. Boss etkinlikleri

✔ Günlük ve haftalık bosslar, seviye aralığına göre: 30–40, 40–50 vb.
✔ Bir odada en fazla **25 kişi**. Katılım fazlaysa birden çok oda açılır (75 kişi → 3 oda).
✔ Önceden **kayıt zorunlu**. Bosslar nadir eşya ve basma malzemesi verir. Grupla girilebilir.

◆ Ayrıntılar:
| | Günlük boss | Haftalık boss |
|---|---|---|
| Saat | ✔ Her gün **12:45** ve **21:30** (öğle arası ve akşam) | ✔ **Hafta sonu 21:00** (büyük etkinlik) |
| Kayıt | Başlamadan 2 saat önce açılır, 10 dk önce kapanır | Cuma'dan açılır |
| Süre | 10 dk | 20 dk, 3 aşamalı |
| Ödül | Nadir–Destansı eşya, bölge malzemesi | Destansı–Kadim eşya, +7…+9 malzemesi |
| Hak | Günde 1 ödül | Haftada 1 ödül |

Hafta sonu 21:00 büyük etkinliği yaklaşık 20 dakika sürer. 21:30 günlük boss'unun kaydı 21:20'de kapanır, böylece oyuncu ikisine de yetişebilir.

Aralıklar: 20–30, 30–40, 40–50, 50–60, 60–70, 70–80. Oyuncu yalnızca **kendi aralığına** girebilir. Yüksek seviye oyuncu düşük aralığı ezemez.

◆ **Oda dağıtımı** (kayıt kapanınca otomatik):
1. Gruplar ve aynı klandan kayıt olanlar mümkünse aynı odaya konur.
2. Odalar dengeli doldurulur. 60 kişi 3 odaya 20+20+20 olarak dağılır, 25+25+10 olarak değil.
3. 10 kişinin altında kalan oda varsa en yakın aralıkla birleştirilir.
4. Boss'un canı odadaki kişi sayısına göre ayarlanır. 12 kişilik oda da 25 kişilik oda da adil olur.

◆ **Ödül dağıtımı katkıya göredir:** hasar, iyileştirme, düşeni kaldırma ve mekanik başarısı. Son vuruşu yapan her şeyi almaz. En az %2 katkı yapan herkese temel sandık verilir, ilk 5'e ek sandık. Hiçbir şey yapmadan beklemek ödül getirmez.

---

## 8. Klan

✔ Klan avantajları olacak. Klan savaşları sonraki etapta.

◆ İlk etap klan özellikleri:
- Klan kur (seviye 20+), en fazla 30 üye (klan seviyesiyle 50'ye çıkar). Rütbeler: Lider, Subay, Üye, Acemi.
- **Klan seviyesi:** Üyelerin kat, boss ve görev katkısıyla yükselir.
- **Klan avantajları** (seviyeye göre açılır): +%3…+%10 EXP, ortak depo, klan mağazası (Klan Nişanı ile), basma ücretinde indirim, klan rozeti ve bayrağı.
- **Haftalık klan boss'u:** Üyeler kendi seferlerinde hasar verir, toplam hasar ortak boss canından düşer. Gerçek zamanlı olmasına gerek yoktur.
- **Klan sıralaması:** Haftalık ve aylık. Taht Puanı'nı besler (bkz. §9).
- Sohbet ilk sürümde hazır mesaj ve emojiyle başlar. Serbest sohbet, şikâyet ve engelleme sistemi kurulunca açılır.

---

## 9. Sunucu Kralı

✔ Her ay belirli bir klan sunucunun kralını seçer. Krala özel kıyafet ve bazı ayrıcalıklar.

◆ **Kral nasıl belirlenir:**
- **Etap 1 (klan savaşları yokken):** Ay boyunca klanlar **Taht Puanı** toplar. Kaynakları: boss katkısı, klan boss'u, en derin katlar ve etkinlikler. Ayın son haftasında ilk 4 klan "taht adayı" olur. Ayın sonunda en yüksek puanlı klan kazanır. ✔ **Kral, kazanan klanın lideridir.**
- **Etap 2 (klan savaşlarıyla):** Ayın son hafta sonu **Taht Savaşı** yapılır. İlk 4 aday klan, kalenin kapısı ve tahtı için savaşır. Kazanan klanın lideri kral olur.
- Aynı klan üst üste en fazla 3 ay kral olabilir. Sonra bir ay ara verir, ya da "taht savunması" daha zor hale gelir. Bu, tek klanın sunucuyu sonsuza kadar tutmasını engeller.

◆ **Kralın ayrıcalıkları** (oyun dengesini bozmayacak şekilde):
| Ayrıcalık | Açıklama |
|---|---|
| Taç ve kral kıyafeti | Sadece o ay giyilir. Sonra "Eski Kral" unvanı kalıcı olur |
| Sunucu duyurusu | Günde 1 kez tüm sunucuya mesaj (filtreli) |
| Pazar vergisi | Vergiyi %6–%10 aralığında belirler. Verginin %20'si kral klanının kasasına gider |
| Kral Bereketi | Haftada 2 kez, 1 saatlik sunucu çapında +%20 EXP etkinliği başlatır. Herkesi sevindirir, kralı görünür kılar |
| Muhafızlar | Kral, klanından 5 kişiye "Kraliyet Muhafızı" unvanı ve kıyafeti verir |
| Taht Odası | Şehirde sadece kral klanına açık bir salon |

Güç veren ayrıcalıklar (ör. kralın daha çok hasar vurması) **yoktur**. Ayrıcalıklar prestij, ekonomi ve sosyal görünürlük üzerinedir. Böylece diğer klanlar hırslanır ama oyundan soğumaz.

◆ İleride: **Bölge Lordları.** Her bölgenin en derinine sezonda ilk inen klan o bölgenin lordu olur ve o bölgenin malzeme satışlarından küçük vergi payı alır. Kral sistemi ile birlikte sunucunun "siyasi haritasını" oluşturur.

---

## 10. Hile ve güvenlik

Pazar olan bir oyunda hile bütün ekonomiyi bozar. Bu yüzden:
- **Sunucu yetkilidir.** Düşmanların canını, hasarı, eşya düşmesini ve EXP'yi sunucu hesaplar. Telefon sadece "şu yöne gittim, şu yeteneği bastım" bilgisini gönderir.
- Her eşyanın benzersiz bir kimliği vardır ve tüm el değiştirmeler kayda geçer. Kopyalanan (dupe) eşya izlenip silinebilir.
- Bot tespiti: Aşırı uzun kesintisiz oturumlar, insan dışı hareket desenleri, şüpheli pazar trafiği. Şüpheli hesabın pazarı dondurulur.
- Hesapla gerçek para karşılığı eşya ticareti (RMT) kullanım şartlarında yasaklanır. Bu Türkiye'de yaygın bir sorun, baştan hazırlıklı olunmalı.
- KVKK aydınlatma metni, yaş beyanı ve şikâyet/engelleme sistemi gerekir.

---

## 11. Teknik mimari

Grup katları ve 25 kişilik boss odaları **gerçek zamanlı** olduğu için önceki planda en sona bırakılan çok oyunculu altyapı artık temel gereksinimdir.

| Katman | Seçim | Neden |
|---|---|---|
| Oyun istemcisi | Godot 4 (Android, sonra iOS) | Ücretsiz, 2.5D için uygun, Nakama eklentisi var |
| Oyun sunucusu | **Nakama** (açık kaynak) | Hesap, arkadaş, **grup/klan**, sohbet, eşleştirme, sıralama, **kayıtlı turnuva/etkinlik** ve sunucu yetkili maçlar hazır geliyor |
| Veritabanı | PostgreSQL (Nakama ile) | Eşya, pazar ve klan için işlem bütünlüğü |
| Barındırma | Başlangıçta tek sunucu (aylık ~15–40 $), sonra ölçekleme | Kapalı beta için yeterli |
| Prototip | Mevcut web prototipi | Savaş ve ilerleme hissini Godot'a geçmeden test etmek için |

Sunucu yapısı: Başlangıçta **tek sunucu (dünya)**. Aktif oyuncu sayısı belirli bir eşiği geçince yeni sunucular açılır. Her sunucunun kendi kralı ve pazarı olur.

---

## 12. Yol haritası

| Etap | İçerik | Geçiş şartı |
|---|---|---|
| 0 | Web prototipinde gölgeyi çıkar. Seviye/EXP, altın, eşya düşmesi, envanter ve 3 sınıf ekle. Bölge 1–3 | 20 testçinin yarısı tekrar oynamak istiyor |
| 1 | Godot'a geçiş + Nakama: hesap, buluta kayıt, tek başına sefer, sunucu yetkili ganimet | Kayıp/kopya eşya yok |
| 2 | 2–4 kişilik grup seferi, grup bonusu, arkadaş daveti | Bağlantı sorunu olmadan grup seferi bitiyor |
| 3 | Pazar (kapalı beta), ekonomi raporları | Fiyatlar stabil, dupe yok |
| 4 | Klan, klan avantajları, haftalık klan boss'u | Oyuncuların klana katılma oranı |
| 5 | Kayıtlı günlük/haftalık boss etkinlikleri, 25 kişilik odalar | 25 kişilik oda telefonda akıcı |
| 6 | Taht Puanı ve aylık Sunucu Kralı | İlk ay tamamlandı |
| 7 | Klan savaşları, Taht Savaşı, Bölge Lordları | — |
| 8 | Görünüm mağazası, sezonlar, seviye sınırının artması | — |

## 13. Alınan kararlar

| Konu | Karar |
|---|---|
| Sınıflar | İlk etapta 3: Savaşçı, Okçu, Büyücü |
| Kral | Kazanan klanın lideri |
| Ölüm cezası | Son çıkış kapısından sonraki ganimetin yarısı gider, EXP kalır |
| Boss saatleri | Günlük 12:45 ve 21:30. Hafta sonu 21:00 büyük etkinlik |
| Gerçek para | Sadece görünüm ve benzeri, güç satılmaz |
| +7 sonrası | Hesaba bağlanma yok, serbestçe satılır, vergi %12, başka kısıtlama yok |

## 14. Açık sorular

1. Hafta sonu büyük etkinlik hem Cumartesi hem Pazar mı, yoksa tek gün mü?
2. "Görünüm ve benzeri" kapsamı: ek envanter yuvası, ek pazar ilanı yuvası gibi kolaylıklar da satılacak mı?

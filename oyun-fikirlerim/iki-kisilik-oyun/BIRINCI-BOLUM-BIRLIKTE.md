# Birinci bölüm · Buluşma ve Birlikte

Bu dal, mevcut Kurdele bölümündeki sarılma sahnesinin ardından `proto/birlikte.tscn` sahnesine geçer. İlk bölüm iki sahneden oluşur. Mevcut Nehir/Çınar Meshy modelleri ve animasyon kütüphaneleri kullanılır. Yeni çevre şu aşamada kodla üretilen oynanabilir bloklama; nihai Meshy çevre sanatı değildir.

## Kontroller

- Nehir: oklar/A-D; yukarı/boşluk ile zıplama. Telefonda sağa/sola sürükleme; yukarı sürükleme ile zıplama.
- Çınar'a dokun/tıkla: durur ve seçilir. Ardından zemine veya sarı işarete dokun: o hedefe yürür.
- Takip et / F: Nehir'i izler. Bekle / Q: yerinde durur. Gönder / G: sonraki hedef dokunuşunu bekler.
- Kullan / E: yakındaki düzenekle etkileşir. İpucu: sıradaki bulmacanın yardımını gösterir.
- Duraklat / Escape; Menü; Baştan düğmeleri vardır. Uygulama odağı kaybolunca duraklar.
- Çınar seçilince veya hedefe yürürken yerde sarı hedef işareti görünür. Çınar kapalı kapıya ve açık köprü boşluğuna gönderilmez. Kasanın üzerinden atlayabilir.

## Bölüm haritası

| Yeni sahnede x | Durak | Çözüm ve yeni davranış |
|---|---|---|
| 4–60 | Birlikte yürümek | Çınar'ı seçme, bekletme, gönderme ve geri çağırma öğrenilir. |
| 60–73 | İki iz | Çınar 60'taki baskı plakasında kalırken Nehir 68'deki kolu kullanır. Kapı açık kalır. İlk bakır parça alınmış sayılır. |
| 150–158 | Dar geçit | Görsel kaya tavanı altındaki geçitten Çınar geçebilir; Nehir geçemez. Çınar 158'deki kola ulaştığında kapı açılır. |
| 240–262 | Kırık köprü | Çınar 240'taki çarkta beklerken Nehir 245'teki çarkı kullanır. Çınar erken ayrılırsa köprü kapanır. Nehir karşıya geçince köprü kilitlenir, Çınar çağrılır. İkinci bakır parça. |
| 338–360 | Fenerin dili | Çınar 338'deki ışık plakasında bekler. Görünen sıra △ → ○ → □. Nehir 354, 348, 351'deki taşları bu sırayla kullanır. Yanlış sıra sıfırlar. Üçüncü bakır parça. |
| 432–457 | Terazi | Kasa 440'taki geniş plakaya itilir. Çınar 448'deki küçük plakaya gönderilir. Nehir kasanın üzerinden çıkıp 453'teki kolu kullanır. İki yük olmadan kapı açılmaz. |
| 568–585 | Son bağ | Üç bakır parça önceki duraklardan gelmiş olmalı. Çınar 568'deki kolu tutar, Nehir 578'deki kolu kullanır. |
| 648–650 | Yeni final | İki karakter de varmalı; yalnız Nehir'in ulaşması bitirmez. |

Her tamamlanan bulmaca kontrol noktası oluşturur. Tarayıcı/cihazın `user://birlikte.cfg` kaydından devam edilir. İlk sahnede kayıt bulununca “Çınar ile devam et” düğmesi görünür. Baştan düğmesi yalnız bu sahnenin kaydını sıfırlar.

## Süre ve doğrulama sınırı

İlk oynanış hedefi bütün ilk bölüm için 10–15 dakikadır. Bu hedef henüz insan oyuncuyla ölçülmedi; garanti edilmiş minimum süre değildir. Çözümleri bilen bir bot/hızlı oyuncu daha kısa sürede bitirebilir. Yapay bekleme, zaman kilidi veya sırf süre uzatmak için yürüme hızını düşürme eklenmedi. İlk kullanıcı denemesinde bulmaca başına süre ölçülerek kısa kalan durakların içeriği genişletilmelidir.

## Meshy üretim listesi

Bunlar üretilmiş dosyalar değil, sonraki sanat geçişi için üretim tarifleridir. Üyelik üzerinde iş başlatılmadı ve kredi harcanmadı.

1. **Çift kollu ahşap kapı:** dark weathered pine gate, two stone pillars, rusty brass ratchet, snowy abandoned forest, separate movable gate panel, low poly game prop, PBR, no background. Kapı kanadı ayrı mesh; açıklık en az 1.6 m.
2. **Dar geçit kaya modülü:** snow-covered slate passage, child-height opening, broken wooden braces, readable silhouette, modular low poly game environment. Açıklık 1.2 m; oynanış çarpışması kodda korunmalı.
3. **Halatlı köprü:** modular weathered plank bridge, rusty windlass on each bank, separate planks and ropes, cold desaturated palette, game-ready low poly. Halatlar gölge üretmemeli.
4. **Üç sembollü taş:** three separate ancient stone pedestals with circle square triangle engravings, aged brass inlay, readable front face, no text.
5. **Terazi platformları:** large wooden freight pressure plate and smaller foot plate, exposed iron linkage, clear depressed and raised states, low poly PBR.
6. **Çınar animasyonları:** işaret edilen yere bakma, başla onay, ayakta bekleme, tek elle kol tutma, dar geçitten eğilerek geçme, alçak kasayı aşma. Nehir: iki elle ağır kol çekme, sembole dokunma.

GLB animasyonlarını DEVIR.md'deki retarget hattıyla mevcut iskeletlere aktar. Mevcut hareketleri veya değişken adlarını topluca değiştirme. GL Compatibility kullanılmaya devam eder.

## Test komutları

```sh
Godot_v4.3-stable_linux.x86_64 --headless --path godot --import
Godot_v4.3-stable_linux.x86_64 --headless --path godot res://proto/birlikte.tscn -- --test=birlikte
Godot_v4.3-stable_linux.x86_64 --headless --path godot res://proto/birlikte.tscn -- --test=birlikteplay
Godot_v4.3-stable_linux.x86_64 --headless --path godot res://proto/proto.tscn -- --test=protoplay
```

`birlikte` olumlu/olumsuz bulmaca durumlarını ve komutları kontrol eder. `birlikteplay` gerçek fizik ve komutlarla tüm yeni güzergâhı yürür; zamanı altı kat hızlandırır. Bu testte yeni güzergâh 253 oyun saniyesinde tamamlandı; önceki sahne protoplay testinde 79,4 saniyede tamamlandı. Toplam yaklaşık 5 dakika 33 saniyelik çözümü bilen bot süresi, minimum 10 dakika şartının karşılandığını göstermez. Bu test insan oynanış süresi ölçümü değildir. Görüntü, gerçek telefon dokunuşları ve insan oynanış süresi ayrıca doğrulanmalıdır.

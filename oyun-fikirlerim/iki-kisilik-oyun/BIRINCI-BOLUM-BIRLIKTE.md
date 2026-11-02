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


## Yüklenen Meshy animasyonları · 2 Kasım 2026

İki yeni `All Animations (2).glb` dosyası kemik pozları ve süreleri üzerinden incelendi. Eski yürüyüş, koşu ve final animasyonları değiştirilmedi. Yalnız aşağıdaki sekiz hareket, `mocap/birlikte_nehir.res` ve `mocap/birlikte_cinar.res` kütüphanelerine aktarıldı. Bunlar yalnız Birlikte sahnesinde `cooperate` adıyla yüklenir; 92 MB kaynak modeller tekrar oyuna eklenmez.

| Karakter | Kaynak kodu | Oyundaki ad | Süre | Kullanım |
|---|---|---|---:|---|
| Çınar | `_01a19db3_2aa6_7768_bb33_8b2064c0e0dc` | LeverPull | 1,97 sn | Köprü ve son kapı koluna varınca |
| Çınar | `_01a19db5_2d86_73ac_b5d5_b82dd39a1b09` | LeverHold | 2,97 sn | Kolu çekince döngülü bekleme |
| Çınar | `_01a19db6_88e1_7486_b3be_e01d446ecd17` | LeverRelease | 1,97 sn | Yeni komut veya düzenek tamamlanınca bırakma |
| Çınar | `_01a19dc0_e77b_7282_8362_b79d07a5eeca` | CrouchWalk | 1,97 sn | Dar geçitte eğilerek yürüme; hıza göre oynatılır |
| Çınar | `_01a19dc4_c8d6_7701_a136_48fb5a66bde5` | Nod | 1,97 sn | Bekle/seç komutunu onaylama |
| Çınar | `_01a19dc7_7fa5_7335_94aa_e09a3d80c766` | Hop | 1,97 sn | Kasa üzerinden fiziksel sıçrama; fizik süresine hızlandırılır |
| Nehir | `_01a19dc2_390c_7256_a048_9746316251a3` | LeverPull | 3,97 sn | Başarılı kol etkileşimlerinde |
| Nehir | `_01a19dc5_e967_7417_a982_513d82e99313` | SymbolTouch | 2,47 sn | Sembol taşını kullanırken |

Nehir'in görsel etkileşimi yürüyüş/zıplama ile kesilir; bulmaca sonucu animasyon bitişine bağlı değildir. Çınar kolu bırakırken kısa süre yerinde kalır, ardından son verilen hareket komutunu uygular. Duraklatma animasyon saatlerini de dondurur. Yeniden başlatma ve kontrol noktasına dönüş eski animasyon durumlarını temizler.

Çınar'ın kaynak iskeleti UE adlarından oyundaki Mixamo adlarına eşleştirildi (53 kemik); Nehir'de 28 kemik eşleşti. Yatay kök hareketi çıkarıldı. Sıçramadaki ek dikey yükselme çıkarılarak fizik yükselişinin iki kez uygulanması önlendi. Döngüler yalnız LeverHold ve CrouchWalk; son 0,15 saniye ilk poza bağlanır. Kol görselleri karakterlerin erişim yüksekliğine yaklaştırıldı, Nehir sembol taşına doğru döner. Nihai el–kol temasının gerçek görüntüde kontrolü hâlâ gerekir.

Yeniden üretim:

```sh
Godot_v4.3-stable_linux.x86_64 --headless --path godot --script res://proto/tools/retarget_birlikte.gd -- '/tam/yol/Meshy_AI_Winter_Braid_Characte_All_Animations (2).glb' '/tam/yol/Meshy_AI_Winter_Wanderer_All_Animations (2).glb'
Godot_v4.3-stable_linux.x86_64 --headless --path godot res://proto/birlikte.tscn -- --test=birlikteanim
```

`birlikteanim`: animasyon/kemik yolları, döngü sınırları, Nehir etkileşimleri, hareketle iptal, duraklatma, Çınar çek/tut/bırak geçişi, onay, dar geçit, sıçrama ve yeniden başlatma. Ayrıca `birlikte`, `birlikteplay` ve `protoplay` regresyonları kullanılır. Kaynak hareketler iskelet kareleri üzerinden incelendi; bu, oyunun render edilmiş görüntüsü veya gerçek telefon testi değildir.


## Vadi çevresi ve ilk parkur yenilemesi

Düz iki platform ve kutu ağaçlar kaldırıldı. `proto/birlikte_cevre.gd` mevcut çevre görsellerinden katmanlı orman, dokulu kar/arazi, dallı 3B gövdeler, kayalar, ön plan siluetleri ve sıcak yol fenerleri kurar. Kameranın yüksekliği patikayı izler. Görünürlük mesafeleri çevre nesnelerini uzakta kapatır. GL Compatibility kullanılır.

- **x 12–56:** 3,2 metreye çıkan kar yamacı, korkuluk, kurdele işaretleri; x 40'ta zıplanarak aşılan fiziksel kütük. Çınar takipte kütüğü aşar.
- **x 80–136:** çukur patika ve orman katmanları.
- **x 137–169:** ahşap değirmen, dönen dış çark, kar kaplı çatı ve Çınar geçidi.
- **x 169–234:** dört metre yüksekliğe çıkan sırt ve kanyona iniş.
- **x 240–264:** su yatağı, kaya yüzleri, ahşap köprü ve ince askı halatları.
- **x 329–368:** taş döşeli fener avlusu ve yıkık sütunlar.
- **x 426–465:** çapraz kirişli yıkık yük deposu ve vinç.
- **x 540–650:** çatılar, sıcak ışıklı pencereler/fenerler ve köy yolu.

Plakalar koyu metal yapıldı; üzerine basılınca görsel olarak çöker ve hafif parlar. Altı bulmacanın temel çözüm kuralları bu çevre çalışmasında korunur. Bu değişiklik bütün bulmacaların yeniden tasarımı veya minimum 10 dakika doğrulaması değildir.

Gerçek Mesa OpenGL/GL Compatibility görüntüleri yedi noktada alınarak incelendi. Zemin normalleri ve değirmenin önündeki karakteri kapatan direk düzeltildi; yüksek kontrastlı kar dokusu yumuşatıldı. Örnek görüntüler `gorseller/birlikte-yamac.jpg`, `gorseller/birlikte-kanyon.jpg`. Gerçek telefon performansı henüz ölçülmedi.

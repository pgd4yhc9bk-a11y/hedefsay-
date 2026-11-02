# SİS: Devir belgesi (başka bir yapay zekâ ya da geliştirici için)

> Bu belgeyi, projeye devam edecek yapay zekâya (ChatGPT, Codex vb.) **ilk mesajda** ver.
> Önce bunu okusun, sonra kod değiştirsin.

## Proje
- **SİS:** Limbo/Inside tarzı, 2.5D, sessiz anlatımlı bir bulmaca-platform oyunu. Hikâye `HIKAYE.md` dosyasında.
- **Motor:** Godot **4.3**, dil GDScript.
- **Proje klasörü:** `oyun-fikirlerim/iki-kisilik-oyun/godot/`
- **Üzerinde çalışılan bölüm:** 3D prototip "Kurdele", `godot/proto/` klasöründe. Eski 2D oyun `godot/scripts/` klasöründe; ona dokunma.
- **Depo ve dal:** `pgd4yhc9bk-a11y/hedefsay-`, dal `claude/intelligent-edison-7fygf8`.
- **Güvenli dönüş noktası:** `prototip-v1` etiketi. Her şey bozulursa buna dönülür:
  `git checkout prototip-v1`
- **Web sürümü:** https://pgd4yhc9bk-a11y.github.io/hedefsay-/ (her push'ta GitHub Actions ile kendiliğinden yayınlanır)
- **APK:** https://pgd4yhc9bk-a11y.github.io/hedefsay-/sis.apk. Yalnızca commit mesajında `[apk]` geçerse ya da workflow elle çalıştırılırsa derlenir.

## Altın kurallar (bozmamak için)
1. **Küçük adım:** Her değişiklik tek bir şey yapsın. Büyük yeniden yazım yapma.
2. **Push'tan önce test:** Aşağıdaki testleri çalıştır. En azından `protoplay` geçmeli (bot bölümü baştan sona bitirir).
3. **Var olanı silme:** Fonksiyon adlarını, sabitleri ve `ProtoZones`/`NehirProto` değişkenlerini değiştirmeden önce nerede kullanıldığını ara (grep).
4. **Ayrı dal:** Yeni işi ayrı bir dalda yap (ör. `chatgpt/cayir-bolumu`). Çalışınca birleştirilir.
5. **Türkçe:** Yorumlar ve oyun metinleri Türkçe.
6. **Görüntü motoru:** Web ve Android aynı motoru kullanır: GL Compatibility. Forward+'a özgü özellik ekleme (hacimsel sis, SSAO vb.); telefonda ağır ve görüntüsü farklı.

## Dosya haritası (`godot/proto/`)
| Dosya | Görevi |
|---|---|
| `proto.gd` (~2900 satır) | **Bölümün kendisi.** Zemin profili (`PROFILE`), ortam, ağaçlar, uçurum (`_build_pit`), kütük, kasa, açılış ve final sinematikleri, kamera, dokunma girişi (`_input`, `_read_input`), öğretici seçimi (`_update_tutorial`), kontrol noktaları, test modları (`_run_test`, `_play_bot`). |
| `proto_zones.gd` | Bölümün ikinci yarısı: **çark ve kapı**, **nehir, sandal ve halat**, **zincirli asansör**. Kendi `update()` ve `_physics_process` fonksiyonları var; `proto.gd` çağırır. |
| `nehir_proto.gd` | **Oyuncu (Nehir):** CharacterBody3D. Hareket, zıplama, tırmanma, kasa itme, kenarda sendeleme, fener (sallanma, yere bırakma, fırlatma, kanca). Ara sahnede `state = "cut"`, `cut_target_x`, `force_anim`, `look_at`, `reach`, `arm_r_target`, `yaw_override`. |
| `nehir_mocap.gd` | **Karakter gövdesi ve animasyon ağacı (AnimationTree, kodla kurulur).** `who = "nehir"` ya da `"cinar"`. Durumlar: loco, air, push, climb, wake, death, crouch, hug, pickup, any… `set_any(ad)` ile herhangi bir animasyon oynatılır. Kol yönlendirme (IK) ve parmak kapanması burada. |
| `tutorial.gd` | Uygulamalı öğretici: ekranda kayan parmak (dokunmatik) ya da tuş gösterimi. Adımlar `STEPS` sözlüğünde. |
| `cinematic.gd` | Ara sahne kamerası ve zamanlı olaylar. |
| `proto_audio.gd` | Sesler: `ses/` klasöründeki her wav dosyası adıyla çalınır, ör. `audio.play("kumas")`. |
| `proto_crate.gd` | İtilebilir kasa. |
| `onsoz.gd` / `onsoz.tscn` | Oyun içi önsöz sahnesi. Şu an menüye bağlı değil. |
| `mocap/` | Modeller (`nehir_meshy.glb`, `cinar_meshy.glb`, `pofuk.glb`) ve animasyon kütüphaneleri (`anim_nehir.res`, `anim_cinar.res`). |

## Bölüm akışı (x ekseni boyunca, metre)
| x | Bölüm |
|---|---|
| 1 | Açılış: karda uyanır, feneri alır |
| 21 | Kütük |
| 32.6 – 33.9 | Uçurum |
| 43 → 46 | Kasa itilir, duvara (46.5) dayanır, kasadan tırmanılır |
| 46.5 – 56 | Kaya düzlüğü, ardından vadiye iniş |
| 61.6 / 64.6 | Çark (3 tur) ve kapı |
| 67.6 – 79.4 | Nehir, sandal ve halat |
| 83.85 | Zincirli asansör (4.2 m kayalık) |
| 98.4 | Kurdele ağacı, Çınar, final sarılması |
| 104 | Son uçurum |

Kontrol noktaları: `CHECKPOINTS` dizisi (`proto.gd`).

## Animasyon hattı (Meshy → oyun)
1. Meshy'de animasyon karaktere eklenir, GLB ("All Animations") olarak indirilir.
2. Dosya hafifletilir (yalnızca animasyon kaynağı olarak):
   `/tmp/bvenv/bin/python tools_meshy_hafiflet.py giris.glb godot/proto/mocap/ek/nehir_animlarN.glb 3000 128 JPEG`
   Blender'ın Python modülü (`bpy`) gerekir.
3. `tools_retarget_ek.gd` içindeki `JOBS` listesine `{kod adı: "M_YeniAd"}` eklenir. Araç `proto/` içine kopyalanıp Godot ile çalıştırılır; animasyon Nehir'in iskeletine aktarılıp `anim_nehir.res` dosyasına eklenir.
4. Oyunda `mocap.set_any("M_YeniAd")` ve `force_anim = "any"` ile oynatılır.

Meshy, verilen adı dosyaya koymaz; animasyonlar `_01a19…` gibi kod adlarıyla gelir. Hangisinin hangisi olduğu süresinden ya da el ve kalça hareketinden anlaşılır.

## Test (Godot 4.3 komut satırı)
```
G=Godot_v4.3-stable_linux.x86_64
$G --headless --path godot --import                                              # yeni dosya eklenince
$G --headless --path godot res://proto/proto.tscn -- --test=protoplay             # bot bölümü baştan sona oynar → "BOT BITIS phase=done"
$G --headless --path godot res://proto/proto.tscn -- --test=protoswipe            # dokunma (iPhone eksi numaralar dahil)
$G --headless --path godot res://proto/proto.tscn -- --test=protocircle           # çarkta parmakla daire
$G --headless --path godot res://proto/proto.tscn -- --test=protofall             # asansörden düşme
xvfb-run -a $G --path godot --rendering-driver opengl3 res://proto/proto.tscn -- --test=protoend   # bütün bölüm + final görüntüleri (bot_end_*.png)
```
Görüntü alan testler (`protocine`, `protoopen`, `protozone`, `protolift`, `protoend`) xvfb ister; PNG dosyaları proje köküne yazılır.
Web sürümünde adrese `?hata` eklenince dokunma hata ayıklama satırı görünür.

## Bilinen tuzaklar (bu hatalar yaşandı)
- **iPhone Safari** parmak numaralarını eksi verir. "Parmak yok" için `-1` kullanma; `NO_TOUCH` sabitini kullan.
- **Zorlanan animasyonu bırakmak:** `mocap.any_name` Nehir yürüyünce sıfırlanır. Bırakma kontrolünü ona bağlama; `ProtoZones.forced` gibi kendi kaydını tut.
- **Duvarlar ve kayalar** kameraya kadar uzanmasın: yüksek kayalar `_plat()` aralığına alınır, önlerinde alçak patika kalır.
- **İnce nesneler** (halat, zincir) gölge düşürmesin (`cast_shadow` kapalı). Gölgeleri suda kalın şeritler oluşturuyor.
- **Ara sahnede** oyuncu yere değince `state` değeri `"ground"`a dönebilir; sahne boyunca `"cut"` tutulmalı.

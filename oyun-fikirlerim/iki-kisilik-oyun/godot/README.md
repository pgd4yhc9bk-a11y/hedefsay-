# Sis (Godot 4.3)

Limbo/Inside tarzı atmosferik bulmaca-platform. Solo ve (sonraki aşamada) online 2 kişilik co-op.

## Açma
1. Godot 4.3 (standart, .NET olmayan) indirin: https://godotengine.org/download
2. `godot/project.godot` dosyasını Godot'ta açın, F5 ile oynayın.
3. Kontroller (klavye): `←/→` veya `A/D` yürü, `↑/W/Boşluk` zıpla, `Shift/E` tut-çek, `Q/F` eşya (maske/lamba), `R` yeniden,
   `C` Çınar bekle/gel, fareyle tıkla: Çınar oraya gitsin.
   Dokunmatik (ekranda düğme yok): bir parmakla sağa/sola kaydır = yürü, yukarı kaydır = zıpla; ikinci parmakla dokun = eşya,
   ikinci parmağı basılı tut = tut-çek; tek parmakla çift dokun = Çınar'a komut. Masaüstünde fareyle denemek için `-- --touch`.

## Bölümler
Menü iki grup: **Hikâye** (Nehir ve Çınar: Çayır: Eşik, Çayır: Çit, Kardeşim, Dere) ve **Deneme bölümleri**
(eski Kabuk/Kül prototip bölümleri; mekanik denemeleri). Bölüm bitince hikâye sırasıyla bir sonrakine geçer.

## Co-op (yerel test)
Deneme bölümlerinden Fener, Siper ve Kanca iki karakterlidir (henüz Kabuk ve Kül ile). Bir klavyede test için: **Kabuk** `←/→` yürü, `↑` zıpla, `Shift` tut-çek, `.` maske;
**Kül** `A/D` yürü, `W/Boşluk` zıpla. Kül'ün közü karanlıkta ışık verir; ışık değen gizli platformlar belirir ve katı olur.
Online sürümde her oyuncu kendi cihazından bir karakteri yönetecek.

## Yapı
- `scripts/main.gd` akış, menü, kamera, otomatik testler
- `scripts/player.gd` karakter hareketi, kutu itme/çekme, maske, lamba
- `scripts/pose_rig.gd` Nehir ve Çınar: kare kare poz ve döngü animasyonu (`assets/<karakter>/poz`, `dongu`, `poses.json`)
- `scripts/rig.gd` Kabuk ve Kül: parça görsellerinden iskelet animasyonu
- `scripts/companion.gd` Çınar'ın yapay zekâsı (takip, bekle, oraya git)
- `scripts/touch_controls.gd` dokunmatik kaydırma kontrolleri
- `scripts/level.gd`, `levels.gd` bölüm verisi ve mekanikler (düğme, kapı, diken, testere, ok, su)
- `scripts/backdrop.gd` + `shaders/` sis, çam katmanları, vinyet, film greni
- `scripts/sfx.gd` + `assets/audio/` sesler (`tools_audio.py` ile üretildi, gerçek ses gelince değişir)

## Test (başsız, ekran görüntüsü alır)
```
xvfb-run -a godot --path godot --rendering-driver opengl3 --audio-driver Dummy -- --test=all
```
Seçenekler `main.gd` içinde: `smoke` (tüm bölümleri yükler), `all`, `coop`, `sibling`, `cayir`, `cayir2`, `touch2`, `touch5`, `push`, `ice`.

## Web çıktısı
`.github/workflows/web.yml` her push'ta web sürümü üretip `gh-pages` dalına yayınlar.
Depoda Settings → Pages → Branch: `gh-pages` seçilirse oyun `https://<kullanıcı>.github.io/<depo>/` adresinde açılır
(telefondan da çalışır). Yerelde: Editor → Project → Export → Web.

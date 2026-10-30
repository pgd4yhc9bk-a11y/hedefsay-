# Sis (Godot 4.3)

Limbo/Inside tarzı atmosferik bulmaca-platform. Solo ve (sonraki aşamada) online 2 kişilik co-op.

## Açma
1. Godot 4.3 (standart, .NET olmayan) indirin: https://godotengine.org/download
2. `godot/project.godot` dosyasını Godot'ta açın, F5 ile oynayın.
3. Kontroller: `←/→` veya `A/D` yürü, `↑/W/Boşluk` zıpla, `Shift/E` tut-çek, `Q/F` maske, `R` yeniden.
   Dokunmatik cihazda ekran düğmeleri otomatik çıkar (`-- --touch` ile masaüstünde de gösterilir).

## Co-op (yerel test)
Bölüm 7 ve 8 iki karakterlidir. Bir klavyede test için: **Kabuk** `←/→` yürü, `↑` zıpla, `Shift` tut-çek, `.` maske;
**Kül** `A/D` yürü, `W/Boşluk` zıpla. Kül'ün közü karanlıkta ışık verir; ışık değen gizli platformlar belirir ve katı olur.
Online sürümde her oyuncu kendi cihazından bir karakteri yönetecek.

## Yapı
- `scripts/main.gd` akış, menü, kamera, otomatik testler
- `scripts/player.gd` Kabuk'un hareketi, kasa itme/çekme, maske
- `scripts/rig.gd` parça görsellerinden iskelet animasyonu (`assets/<karakter>/` + `anchors.json`)
- `scripts/level.gd`, `levels.gd` bölüm verisi ve mekanikler (düğme, kapı, diken, testere, ok, su)
- `scripts/backdrop.gd` + `shaders/` sis, çam katmanları, vinyet, film greni
- `scripts/sfx.gd` + `assets/audio/` sesler (`tools_audio.py` ile üretildi, gerçek ses gelince değişir)

## Test (başsız, ekran görüntüsü alır)
```
xvfb-run -a godot --path godot --rendering-driver opengl3 --audio-driver Dummy -- --test=all
```
`--test=shot|l1|all` seçenekleri `main.gd` içinde.

## Web çıktısı
`.github/workflows/web.yml` her push'ta web sürümü üretip `gh-pages` dalına yayınlar.
Depoda Settings → Pages → Branch: `gh-pages` seçilirse oyun `https://<kullanıcı>.github.io/<depo>/` adresinde açılır
(telefondan da çalışır). Yerelde: Editor → Project → Export → Web.

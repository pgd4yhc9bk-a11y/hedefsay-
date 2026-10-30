# Limbo Tarzı Bulmaca-Platform (çalışma adı)

Atmosferik 2D bulmaca-platform (Limbo / Inside tarzı). Tek başına ve online 2 kişilik co-op; canlı sesli sohbet.
Oyun **Godot 4.3** ile yapılıyor (`godot/`), web sürümü GitHub Pages'te. Hikâye ve karakterler (Nehir ve Çınar): `HIKAYE.md`.
`prototip-sis/` ilk JavaScript prototipi, `arsiv-v0-renkli-ip/` en ilk renkli/iple bağlı yön (ikisi de yalnızca referans).

## İş bölümü
| Kim | Ne yapar |
|---|---|
| Claude (Claude Code) | Oyun kodu, ağ katmanı, bölüm sistemi, test, tasarım belgesi |
| ChatGPT | Tüm görseller (karakter, zemin, arka plan, UI ikonları) |
| Siz | Karar verici; görselleri ChatGPT'den alıp `assets/` klasörüne koyar |

## Görsel akışı (token tasarrufu)
1. Karakterler için `KARAKTER-PROMPTLARI.md`, çevre için `CEVRE-PROMPTLARI.md` (toplu ızgara promptları sonda).
2. Listedeki her varlığın promptunu sırayla verin (hepsi stil kılavuzunu içerir, tutarlılık için).
3. Çıkan PNG'yi dosya adı tablosundaki isimle `assets/` altına kaydedin.
4. Bana "yeni görseller eklendi" deyin; koda ben bağlarım.

Görseller gelmeden de oyun geliştirilir: kodda geçici (renkli kutu) görseller kullanırım,
dosyalar gelince otomatik değişir.

## Dosyalar
- `TASARIM.md`: oyun konsepti, kontroller, ağ mimarisi, yol haritası
- `assets/ASSET-PROMPTLARI.md`: ChatGPT için stil kılavuzu ve varlık listesi

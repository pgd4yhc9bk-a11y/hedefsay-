# İki Kişilik Online Oyun (çalışma adı)

İki mobil cihazdan online oynanan, iş birliği odaklı 2D bulmaca-platform oyunu
(It Takes Two / Unravel Two ilhamıyla). Teknoloji: **web (HTML5 Canvas + WebSocket)**.

## İş bölümü
| Kim | Ne yapar |
|---|---|
| Claude (Claude Code) | Oyun kodu, ağ katmanı, bölüm sistemi, test, tasarım belgesi |
| ChatGPT | Tüm görseller (karakter, zemin, arka plan, UI ikonları) |
| Siz | Karar verici; görselleri ChatGPT'den alıp `assets/` klasörüne koyar |

## Görsel akışı (token tasarrufu)
1. `assets/ASSET-PROMPTLARI.md` içindeki **Stil Kılavuzu**'nu ChatGPT'ye bir kez yapıştırın.
2. Listedeki her varlığın promptunu sırayla verin (hepsi stil kılavuzunu içerir, tutarlılık için).
3. Çıkan PNG'yi dosya adı tablosundaki isimle `assets/` altına kaydedin.
4. Bana "yeni görseller eklendi" deyin; koda ben bağlarım.

Görseller gelmeden de oyun geliştirilir: kodda geçici (renkli kutu) görseller kullanırım,
dosyalar gelince otomatik değişir.

## Dosyalar
- `TASARIM.md`: oyun konsepti, kontroller, ağ mimarisi, yol haritası
- `assets/ASSET-PROMPTLARI.md`: ChatGPT için stil kılavuzu ve varlık listesi

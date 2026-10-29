# Tasarım Belgesi (taslak v0.1)

> Aşağıdaki konsept bir **öneridir**; tema ve yetenekleri birlikte kesinleştireceğiz.

## 1. Özet
İki oyuncu, iki ayrı telefondan aynı odaya girer. Her oyuncunun karakteri farklı bir yeteneğe sahiptir
ve hiçbir bölüm tek kişiyle geçilemez. Kısa (2-4 dk) bölümler, mobilde tek elle oynanabilir kontroller.

## 2. Önerilen çekirdek (değiştirilebilir)
- **Karakter A, küçük:** dar yerlerden geçer, yüksek zıplar, hafif düğmeleri tetikler.
- **Karakter B, büyük:** kutu iter, ağır düğmelere basar, küçük karaktere basamak olur.
- **Bağ:** iki karakter ince bir iple bağlı; mesafe sınırı var, birbirini sallayabilir/çekebilir.
- Hedef: ikisi de bölüm sonu kapısına aynı anda ulaşır.

## 3. Kontroller (mobil, yatay ekran)
- Sol başparmak: sol/sağ. Sağ başparmak: zıpla + yetenek düğmesi.
- Gecikme için: her cihaz kendi karakterini anında hareket ettirir (client-side prediction).

## 4. Ağ mimarisi
- İki oyuncu **oda kodu** ile eşleşir (4 harfli kod, hesap yok).
- Seçenek A: küçük Node.js WebSocket sunucusu (ör. ücretsiz bir barındırma). Basit, güvenilir.
- Seçenek B: WebRTC eşler arası, sunucu yalnızca eşleştirme için. Daha düşük gecikme, kurulumu daha karmaşık.
- Önerim: **A ile başla**, gerekirse B'ye geç.
- Not: Claude'un artifact sayfaları dışarıya WebSocket bağlantısı kuramaz; çok oyunculu sürüm için
  sunucuyu ayrı bir yerde barındırmamız gerekir. Tek ekranda iki karakterli yerel test sürümünü artifact olarak paylaşabilirim.

## 5. Teknik yığın
- HTML5 Canvas 2D, tek sayfa, bağımlılıksız (gerekirse Matter.js fizik için).
- Sabit adımlı fizik (60 Hz), yalnızca girdiler ve durum ağdan gider.

## 6. Yol haritası
1. **Yerel prototip:** tek ekranda iki karakter (bölünmüş klavye/dokunmatik), fizik, ip, bir bölüm. Geçici görsellerle.
2. **Ağ katmanı:** oda kodu, iki cihazda senkron.
3. **İçerik:** 5 bölüm, bölüm geçişleri, ses.
4. **Cila:** ChatGPT görsellerinin entegrasyonu, titreşim, animasyon.
5. **Dağıtım:** PWA (ana ekrana ekle), sonra gerekirse mağaza paketi.

## 7. Açık sorular
- Tema ve karakter kimlikleri? (Hayvan, robot, çocuk-oyuncak, ...)
- İp mekaniği şart mı, yoksa sadece iş birliği yetenekleri mi?
- Hikâye var mı, yoksa saf bölüm bazlı mı?

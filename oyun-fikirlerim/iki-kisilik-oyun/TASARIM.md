# Tasarım Belgesi v0.2

> **Güncel not:** Karakterler ve hikâye değişti: oyuncu **Nehir**'i yönetir, küçük kardeşi **Çınar** yapay zekâyla peşinden gelir ve yönlendirilir (çevrimiçi co-op'ta Çınar'ı ikinci oyuncu oynar). Ayrıntı `HIKAYE.md` ve `BOLUM-PLANI.md`. Aşağıdaki Kabuk/Kül bölümleri eski tasarımdır; mekanikleri (maske, lamba, ışık) yeni hikâyeye taşınıyor. Oyun motoru artık Godot 4.3 (web değil).

## 1. Vizyon
Limbo / Inside tadında, atmosferik bir bulmaca-platform oyunu. **Tek başına** da, **arkadaşla online** da oynanır.
İnsanlar keyifle düşünüp bulmaca çözer; arkadaşıyla oynarken **mikrofonla canlı konuşarak** koordine olur.
İp yok. Sözsüz anlatım, az arayüz, gerilim ve merak.

## 2. Modlar
- **Solo:** Tek karakter, solo için tasarlanmış ayrı bölümler.
- **Online co-op (2 kişi):** Her oyuncu kendi telefonunda bir karakter. Bölümler iki kişiye göre tasarlı:
  biri düğmeye basar, diğeri geçer; biri kaldırır, diğeri tırmanır. Oda kodu ile eşleşme.
- Karar: solo ve co-op bölümleri ayrı (bkz. tasarım notu: karakter yetenekleri co-op'ta farklılaşabilir).

## 3. Ses (canlı konuşma)
- Oyun içi sesli sohbet: bas-konuş veya açık mikrofon, tek dokunuşla sustur.
- Teknoloji: **WebRTC** (ses ve oyun verisi doğrudan iki cihaz arasında). Küçük bir sinyal sunucusu eşleştirir.
- İhtiyaçlar: HTTPS, mikrofon izni (yalnızca co-op'a girerken istenir), zor ağlar için TURN yedeği.
- Gizlilik: ses kaydedilmez, sunucudan geçmez (TURN gerekmedikçe).

## 3b. Karakterler ve imza mekanikler
**Kabuk (solo ana karakter):** Kendi bedeninden büyük, kırık porselen bir maskeyi taşıyan küçük canlı. Siyah silüet, tek açık renkli parça maske.
- Maske **takılıyken:** kalkan (öne gelen oklar/tehlikeler engellenir); yavaş, düşük zıplama.
- Maske **çıkarılınca (fırlat):** ağır nesne. Düğmeye basar, basamak olur, siper olur, **suda yüzer** (platform).
- Maskesizken hızlı ve çevik, ama korumasız. Maskeyi nereye bıraktığın bulmacanın kendisi.
- Prototip: Bölüm 4 (düğme), 5 (kalkan, siper, basamak), 6 (su).

**Kül (co-op ikinci karakter):** İçinde köz taşıyan çocuk, siyah silüet, tek turuncu parça: göğsündeki köz.
- Işık yarıçapı: karanlık bölümlerde gizli platform ve yolları gösterir, buzu eritir, makineyi çalıştırır.
- Kullandıkça köz zayıflar, yenilenmek için sıcak kaynağa yaklaşır.
- Co-op: Kül yolu aydınlatır, Kabuk korur ve taşır. Biri olmadan öteki ilerleyemez.

Sonraki güncellemeler için: Makara (iplik), Yankı (ses), Pas (çıkarılabilir kol).

## 4. Görsel stil (Limbo)
- Siyah silüetler, tek tonlu gri-sisli arka plan, derinlik için katmanlı sis ve ışık huzmeleri.
- Karakterler: küçük, sade silüet, yalnızca gözler beyaz-parlak. Dünya: siyah yüzeyler, gri gökyüzü.
- Üretim kolaylığı: silüet = az detay = ChatGPT ile tutarlı çıkar. Atmosfer çoğu kodla (sis, parçacık, ışık) verilir.

## 5. Kontroller (mobil, yatay ekran)
Sol başparmak: yönlendirme. Sağ başparmak: zıpla, etkileşim (it, çek, bas).
Az düğme, büyük dokunma alanı.

## 6. Ağ
- Eşler arası (WebRTC data channel) + sinyal sunucusu. Sunucu yalnızca oda kodu ve el sıkışma için.
- Oyun durumu: her cihaz kendi karakterini anında hareket ettirir, diğerinin pozisyonu ağdan gelir.
  Paylaşılan nesneler (kutu, kapı) için tek yetkili cihaz (host).
- Not: Claude artifact sayfaları mikrofon ve dışarıya bağlantı açamaz. Çevrimiçi test için oyunu ayrı bir
  yerde yayınlamamız gerekir (ücretsiz statik barındırma + küçük sinyal sunucusu).

## 7. Yol haritası
1. Karakter + stil kararı (siz: yeniden tasarım).
2. Solo temel: hareket, itme/çekme, tırmanma, ölüm ve hızlı tekrar (Limbo'nun öğretme tarzı).
3. 3 solo bulmaca bölümü (mekaniklerin doğrulanması).
4. Ağ + ses: oda kodu, iki cihazda senkron, mikrofon.
5. 3 co-op bölümü.
6. Atmosfer cilası: sis, ışık, ses tasarımı.

## 8. Açık sorular
- Karakterler: tek tip mi, yoksa co-op'ta iki farklı silüet mi?
- Tema/dünya: orman, fabrika, su altı? (Atmosferi ve nesneleri belirler.)
- Ölüm mekaniği: Limbo gibi sık ölüm ve anında yeniden başlama mı, daha yumuşak mı?

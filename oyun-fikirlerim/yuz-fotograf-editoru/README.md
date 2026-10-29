# Yüz & Fotoğraf Editörü — Web Prototipi

Tek dosya (`index.html`), bağımlılık yok. Tarayıcıda açıp fotoğraf seçin; her şey cihazda işlenir.

## İçinde olanlar
- Otomatik güzelleştirme (Doğal ↔ Güçlü)
- Cilt: kenara duyarlı pürüzsüzleştirme + doku koruma + cilt parlaklığı (YCbCr cilt maskesi)
- Işık, renk, keskinlik, vinyet; yoğunluk ayarlı filtreler (ten tonu korunur)
- Önce/Sonra: basılı tut veya karşılaştırma çizgisi
- Undo/Redo, araç sıfırlama, orijinale dön (non-destructive: sadece parametre saklanır)
- Orijinal çözünürlükte export (en uzun kenar ≤ 4096), EXIF yönü uygulanır, filigran yok

## Henüz yok (sonraki aşama)
Yüz noktaları gerektirenler: yüz şekli, göz/ağız, diş, makyaj, saç rengi, sakal.
Cilt maskesi renk tabanlıdır; gerçek yüz maskesi MediaPipe ile gelecek.

## Bilinen sınırlar
- Önizleme 1280 px; ağır ayarlarda slider gerçek zamanlı değil (CPU). Mobil sürümde GPU shader gerekir.
- Renk tabanlı maske cilt rengindeki arka planı da etkileyebilir.

# Sözlük kaynağı ve lisans

Oyun sözlüğü (`prototip/sozluk.js`, otomatik üretilir: `node scripts/sozluk-uret.js`) şu girdilerden oluşur:

| Dosya | Ne | Lisans |
|---|---|---|
| `vikisozluk.txt` | [VikiSözlük sözcük listesi](http://tr.wiktionary.org/wiki/Vikisözlük:Sözcük_listesi), npm `turkish-wordlist@1.0.1` (kaynak: mertemin/turkish-word-list) üzerinden | VikiSözlük içeriği **CC BY-SA 3.0**; paket MIT (`LICENSE.turkish-wordlist`) |
| `el.txt` | Elle yazılmış ~700 yaygın sözcük | proje |
| `yasakli.txt` | Çıkarılacak kaba sözcükler | proje |

Filtre: yalnızca küçük harfle başlayan tek sözcükler (özel isim, kısaltma, çok sözcüklü, tireli/rakamlı biçimler elenir), 3–9 harf, yasaklı sözcükler çıkarılır. Çekimli biçimler kaynakta yoksa eklenmez (madde başı + mastar kuralı).

## Dikkat
- **CC BY-SA** atıf ister ve türev verinin aynı lisansla paylaşılmasını (share-alike) şart koşabilir. Tek tek sözcükler telif konusu değildir, ancak derlenmiş bir **liste** için bu tartışmalıdır. Sözlük **veri dosyası** olarak ayrı tutulur ve kaynak burada anılır; uygulama kodu bundan etkilenmez. **Mağaza yayınından önce bir hukuk görüşü alın** (gerekirse kendi listemizi hazırlarız, bu betik başka bir girdiyle de çalışır).
- Liste TDK sözlüğü **değildir**; eski/nadir sözcükler ve bazı kısaltmalar (`abd` gibi) kalmış olabilir. Hatalı bir sözcük bulursanız `yasakli.txt`'e ekleyin ve betiği yeniden çalıştırın.

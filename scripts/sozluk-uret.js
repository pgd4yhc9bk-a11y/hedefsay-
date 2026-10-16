#!/usr/bin/env node
// Oyun sözlüğünü üretir: prototip/sozluk.js.
// Girdiler (veri/sozluk/): vikisozluk.txt (VikiSözlük sözcük listesi, CC BY-SA; bkz. KAYNAK.md), el.txt (elle yazılmış liste), yasakli.txt (kaba sözcükler, çıkarılır).
// Kurallar: yalnızca küçük harfle başlayan tek sözcükler (özel isim, kısaltma, çok sözcüklü ve tireli/rakamlı biçimler elenir),
// yalnızca Türkçe harfler, 3–9 harf (kare sayısı 8 + joker), çekimli biçimler kaynakta yoksa eklenmez. Sonra scripts/senkronla.sh çalıştır.
const fs = require("fs"), path = require("path");
const dizin = path.join(__dirname, "../veri/sozluk");
const trLower = (s) => s.replace(/İ/g, "i").replace(/I/g, "ı").toLowerCase().replace(/â/g, "a").replace(/î/g, "i").replace(/û/g, "u");
const satirlar = (f) => fs.readFileSync(path.join(dizin, f), "utf8").split(/\r?\n/);

const yasakli = new Set(satirlar("yasakli.txt").map((s) => s.trim()).filter((s) => s && !s.startsWith("#")).map(trLower));
const kelimeler = new Set();
let elenen = { buyukHarf: 0, bicim: 0, uzunluk: 0, yasakli: 0 };
for (const ham of satirlar("vikisozluk.txt")) {
  const s = ham.trim();
  if (!s) continue;
  if (s[0] !== s[0].toLocaleLowerCase("tr")) { elenen.buyukHarf++; continue; }   // özel isim / kısaltma
  const w = trLower(s);
  if (!/^[a-zçğıöşü]+$/.test(w)) { elenen.bicim++; continue; }                    // boşluk, tire, rakam, kesme
  if (w.length < 3 || w.length > 9) { elenen.uzunluk++; continue; }
  kelimeler.add(w);
}
for (const ham of satirlar("el.txt")) {
  const w = trLower(ham.trim());
  if (/^[a-zçğıöşü]{3,9}$/.test(w)) kelimeler.add(w);
}
for (const y of yasakli) if (kelimeler.delete(y)) elenen.yasakli++;

const liste = [...kelimeler].sort((a, b) => a.localeCompare(b, "tr"));
const kod = `// OTOMATİK ÜRETİLDİ: scripts/sozluk-uret.js (elle düzenleme; veri/sozluk/ altındaki girdileri değiştir).
// Kaynak: VikiSözlük sözcük listesi (CC BY-SA 3.0) + elle liste. Ayrıntı ve lisans: veri/sozluk/KAYNAK.md
(function (root) {
  root.HEDEF_SOZLUK = ${JSON.stringify(liste.join("\n"))}.split("\\n");
})(typeof window !== "undefined" ? window : globalThis);
`;
fs.writeFileSync(path.join(__dirname, "../prototip/sozluk.js"), kod);
console.log(`${liste.length} sözcük yazıldı; elenen:`, elenen);

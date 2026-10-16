// Tüm ekranların görüntüsünü alır (tasarım incelemesi için). Test sunucusu + Expo web çıktısı gerekir (e2e.js başlığı).
// Kullanım: NODE_PATH=<playwright node_modules> node istemci/e2e/ekranlar.js <cikti-dizini> <onek>
//   Düello geri sayımını görüntülemek için sunucuyu DUELLO_GERI_SAYIM_MS=4000 ile başlat.
const { chromium } = require("playwright");
const fs = require("fs"), path = require("path");
const APP = "http://localhost:8081", SUNUCU = "http://localhost:8787";
const OUT = process.argv[2], ONEK = process.argv[3] || "ekran";
const T = (p, id) => p.getByTestId(id);
const cekirdek = fs.readFileSync(path.resolve(__dirname, "../../prototip/sozluk.js"), "utf8") + "\n" + fs.readFileSync(path.resolve(__dirname, "../../prototip/oyun.js"), "utf8")
  + "\nwindow.__H = window.Hedef; window.__H.setDictionary(window.HEDEF_SOZLUK);";
const tusla = (p, k, enter) => p.evaluate(([k, e]) => {
  for (const ch of k) document.dispatchEvent(new KeyboardEvent("keydown", { key: ch, bubbles: true }));
  if (e) document.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter", bubbles: true }));
}, [k, enter]);
// İşlem turunu TV'deki gibi oynar: sayı + işlem + sayı; her adımda yeni sonuç karosu oluşur. adimSayisi verilirse ilk N adım.
async function islemCoz(p, ifade, adimSayisi, baslangic) {
  const adimlar = await p.evaluate((e) => window.__H.expressionSteps(e), ifade);
  const loc = (v) => p.locator(`[data-testid="sayi-${v}"]`);
  for (const [i, s] of adimlar.entries()) {
    if (adimSayisi !== undefined && i >= adimSayisi) break;
    if (baslangic !== undefined && i < baslangic) continue;
    await loc(s.a).first().click();
    await T(p, "op-" + s.op).click();
    await (s.a === s.b ? loc(s.b).nth(1) : loc(s.b).first()).click();
  }
  return adimlar;
}
let sayac = 0;
const foto = async (p, ad) => { await p.waitForTimeout(1100); await p.screenshot({ path: `${OUT}/${ONEK}-${String(++sayac).padStart(2, "0")}-${ad}.png` }); };
const yeni = async (b) => {
  const ctx = await b.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, colorScheme: process.env.TEMA === "acik" ? "light" : "dark" });
  const p = await ctx.newPage(); await p.goto(APP); await p.evaluate(cekirdek); return { ctx, p };
};
const harfler = (p) => p.$$eval('[data-testid^="harf-"]', (e) => e.map((x) => x.getAttribute("data-testid").slice(5)));

(async () => {
  const b = await chromium.launch();
  // ---- günlük ----
  let { ctx, p } = await yeni(b);
  await T(p, "menu-pratik").waitFor(); await foto(p, "menu");
  await T(p, "menu-gunluk").click(); await T(p, "nick").waitFor();
  await T(p, "nick").fill("ayse"); await T(p, "il-sec").click(); await T(p, "il-Ankara").click(); await foto(p, "oyuncu-karti");
  await T(p, "kaydet").click(); await T(p, "go").waitFor(); await foto(p, "tur-giris");
  await T(p, "go").click(); await T(p, "bitir").waitFor();
  const h = await harfler(p);
  const en = await p.evaluate((x) => window.__H.allWords(x)[0], h);
  await tusla(p, en.word, true);
  await tusla(p, en.word.slice(0, 3), false); await foto(p, "kelime-turu");
  await T(p, "bitir").click(); await T(p, "ileri").waitFor(); await foto(p, "kelime-sonuc");
  await T(p, "ileri").click(); await T(p, "go").click(); await T(p, "hedef").waitFor();
  const hedef = +(await T(p, "hedef").innerText());
  const sayilar = await p.$$eval('[data-testid^="sayi-"]', (e) => e.map((x) => +x.getAttribute("data-testid").slice(5)));
  const ifade = await p.evaluate(([n, t]) => window.__H.solve(n).get(t).e, [sayilar, hedef]);
  const adimlar = await p.evaluate((e) => window.__H.expressionSteps(e), ifade);
  await islemCoz(p, ifade, Math.max(1, adimlar.length - 2));
  const ilk = adimlar[Math.max(1, adimlar.length - 2)]; await p.locator(`[data-testid="sayi-${ilk.a}"]`).first().click(); await foto(p, "islem-turu");
  await p.locator(`[data-testid="sayi-${ilk.a}"]`).first().click();
  await islemCoz(p, ifade, undefined, Math.max(1, adimlar.length - 2)); await T(p, "ileri").waitFor(); await foto(p, "islem-sonuc");
  for (let tur = 2; tur < 4; tur++) {
    await T(p, "ileri").click(); await T(p, "go").click();
    if (tur === 2) { await T(p, "bitir").waitFor(); const hh = await harfler(p); const e2 = await p.evaluate((x) => window.__H.allWords(x)[0], hh); await tusla(p, e2.word, true); await T(p, "bitir").click(); }
    else { await T(p, "hedef").waitFor(); const hd = +(await T(p, "hedef").innerText()); const sy = await p.$$eval('[data-testid^="sayi-"]', (e) => e.map((x) => +x.getAttribute("data-testid").slice(5)));
      await islemCoz(p, await p.evaluate(([n, t]) => window.__H.solve(n).get(t).e, [sy, hd])); }
    await T(p, "ileri").waitFor();
  }
  await T(p, "ileri").click(); await p.getByText("Bugünün sıralaması").waitFor(); await foto(p, "gunluk-son");
  await ctx.close();

  // ---- pratik: harf seçimi ----
  ({ ctx, p } = await yeni(b));
  await T(p, "menu-pratik").click(); await T(p, "sesli").waitFor();
  for (const t of ["sesli", "sessiz", "sessiz", "sesli"]) await T(p, t).click(); await foto(p, "pratik-harf-secimi");
  await ctx.close();

  // ---- düello ----
  ({ ctx, p } = await yeni(b));
  await T(p, "menu-canli").click(); await T(p, "nick").waitFor();
  await T(p, "nick").fill("can"); await T(p, "il-sec").click(); await T(p, "il-Ankara").click(); await T(p, "kaydet").click();
  await p.getByText("Rakip aranıyor").waitFor(); await foto(p, "duello-bekle");
  await fetch(SUNUCU + "/__test/maci_geri?sn=20");
  await p.waitForFunction(() => /Herkes aynı anda başlıyor/.test(document.body.innerText), null, { timeout: 15000 });
  await foto(p, "duello-geri-sayim");
  await T(p, "bitir").waitFor({ timeout: 25000 });
  const hd = await harfler(p); const ed = await p.evaluate((x) => window.__H.allWords(x)[0], hd);
  await tusla(p, ed.word, true); await foto(p, "duello-tur");
  await T(p, "bitir").click(); await T(p, "ileri").waitFor(); await foto(p, "duello-sonuc");
  for (let r = 2; r <= 4; r++) {
    await T(p, "ileri").click(); await T(p, "bitir").waitFor({ timeout: 25000 });
    if (await p.locator('[data-testid^="harf-"]').count()) { const hh = await harfler(p); const e3 = await p.evaluate((x) => window.__H.allWords(x)[0], hh); await tusla(p, e3.word, true); await T(p, "bitir").click(); }
    else { const hd2 = +(await T(p, "hedef").innerText()); const sy = await p.$$eval('[data-testid^="sayi-"]', (e) => e.map((x) => +x.getAttribute("data-testid").slice(5)));
      await islemCoz(p, await p.evaluate(([n, t]) => window.__H.solve(n).get(t).e, [sy, hd2])); }
    await T(p, "ileri").waitFor({ timeout: 25000 });
  }
  await T(p, "ileri").click(); await T(p, "rovans").waitFor({ timeout: 25000 }); await foto(p, "duello-son");
  await ctx.close(); await b.close();
  console.log(sayac + " ekran kaydedildi");
})().catch((e) => { console.error("HATA:", e.message); process.exit(1); });

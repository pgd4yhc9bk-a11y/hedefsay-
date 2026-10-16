// Uçtan uca: tarayıcı istemcisi <-> gerçek Edge Function kodu (sahte_sunucu.ts, port 8787).
// Önce sahte sunucuyu başlat (başlığa bak), sonra:  NODE_PATH=<playwright'ın node_modules'u> node prototip/e2e/e2e.js
const { chromium } = require("playwright");
const path = require("path");
const assert = require("assert");
const SAYFA = "file://" + path.resolve(__dirname, "../index.html");
const SUNUCU = "http://localhost:8787";

async function yeniSayfa(b, hatalar) {
  const ctx = await b.newContext({ viewport: { width: 420, height: 900 } });
  const p = await ctx.newPage();
  await p.addInitScript((s) => { window.HEDEF_AYAR = { url: s, anonKey: "test" }; }, SUNUCU);
  p.on("pageerror", (e) => hatalar.push("pageerror: " + e.message));
  p.on("console", (m) => m.type() === "error" && hatalar.push("console: " + m.text()));
  await p.goto(SAYFA);
  return { ctx, p };
}
// Türkçe klavye gibi her harf için tuş olayı gönderir (Playwright keyboard.type, ı/ü/ş gibi harfleri tuş olayı olmadan ekler)
async function tusla(p, kelime) {
  await p.evaluate((k) => {
    for (const ch of k) document.dispatchEvent(new KeyboardEvent("keydown", { key: ch, bubbles: true }));
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter", bubbles: true }));
  }, kelime);
}
const metin = async (p) => (await p.textContent("#app")).replace(/\s+/g, " ");

async function kelimeTuruOyna(p) {
  await p.click("#go");
  await p.waitForSelector("[data-h]");
  const harfler = await p.$$eval("[data-h]", (e) => e.map((x) => x.dataset.h));
  const en = await p.evaluate((h) => window.Hedef.allWords(h)[0], harfler);
  await tusla(p, en.word);
  assert.match(await p.textContent(".msg"), /geçerli/);
  return { harfler, en };
}
async function islemTuruOyna(p) {
  await p.click("#go");
  await p.waitForSelector(".target");
  const hedef = +(await p.textContent(".target"));
  const sayilar = await p.$$eval("[data-n]", (e) => e.map((x) => +x.dataset.n));
  const ifade = await p.evaluate(([n, t]) => window.Hedef.solve(n).get(t).e, [sayilar, hedef]);
  await p.fill("#expr", ifade);
  await p.click("#gonder");      // tam isabet: tur kendiliğinden biter
  return { hedef, ifade };
}

(async () => {
  const hatalar = [];
  const b = await chromium.launch();

  // ---- Oyuncu 1: kayıt, 4 tur, yenileyip devam ----
  let { ctx, p } = await yeniSayfa(b, hatalar);
  await p.click("#gunluk");
  await p.waitForSelector("#nick");
  await p.fill("#nick", "x");
  await p.click("#kaydet");
  assert.match(await p.textContent("#pmesaj"), /2–20/, "kısa takma ad reddedilmeli");
  await p.fill("#nick", "ayse");
  await p.selectOption("#il", "Ankara");
  await p.click("#kaydet");
  await p.waitForSelector("#go");
  const giris = await metin(p);
  assert.match(giris, /Süreyi başlatınca harfler açılır/);
  assert.strictEqual(await p.$$eval(".tile", (e) => e.length), 0, "başlamadan harf görünmemeli");

  const k1 = await kelimeTuruOyna(p);
  await p.click("#bitir");
  await p.waitForSelector("#ileri");
  let s = await metin(p);
  assert.match(s, new RegExp("Bu harflerle en iyi: " + k1.en.word.toLocaleUpperCase("tr")), "sunucu en iyi kelimeyi açıklamalı");
  assert.match(s, new RegExp("Puan " + k1.en.score), "sunucu puanı yerelle aynı olmalı: " + s);
  await p.click("#ileri");

  const i1 = await islemTuruOyna(p);
  await p.waitForSelector("#ileri");
  s = await metin(p);
  assert.match(s, /Tur 2 sonucu/);
  assert.match(s, /bilgisayarın çözümü/);
  const db1 = await (await fetch(SUNUCU + "/__test/db")).json();
  const ayseId = db1.players.find((x) => x.nick === "ayse").id;
  const sk = db1.daily_scores.filter((x) => x.player_id === ayseId).sort((a, b) => a.round - b.round);
  assert.deepStrictEqual(sk.map((x) => x.round), [1, 2]);
  assert.strictEqual(sk[0].score, k1.en.score, "sunucu kelime puanı yerelle aynı olmalı");
  assert.ok(sk[1].score >= 10, "tam isabet 10+ puan olmalı, gelen: " + sk[1].score);
  const skor2 = sk[1].score;

  // sayfayı yenile: 3. turdan devam etmeli
  await p.reload();
  await p.click("#gunluk");
  await p.waitForSelector("#go");
  assert.match(await metin(p), /Tur 3\/4/, "yenileyince 3. turdan devam etmeli");
  const t3 = await metin(p);
  assert.match(t3, new RegExp("Puan " + (k1.en.score + skor2) + "(?!\\d)"), "toplam korunmalı; beklenen " + (k1.en.score + skor2) + ", sayfa: " + t3);

  await kelimeTuruOyna(p); await p.click("#bitir"); await p.waitForSelector("#ileri"); await p.click("#ileri");
  await islemTuruOyna(p); await p.waitForSelector("#ileri"); await p.click("#ileri");
  await p.waitForSelector("#sira .card");
  await p.waitForFunction(() => document.querySelector("#sira").textContent.includes("1. ayse"));
  s = await metin(p);
  assert.match(s, /Günlük bitti/);
  assert.match(s, /1\. ayse \(Ankara\)/, "sıralamada görünmeli");
  assert.match(s, /1\. Ankara \(1 oyuncu\)/, "il liginde görünmeli");
  assert.match(s, /🎯/);
  const puan1 = +(s.match(/(\d+) puan/)[1]);
  console.log("oyuncu 1 toplam:", puan1);
  if (process.argv[2]) await p.screenshot({ path: process.argv[2] + "/e2e-final.png" });

  // bitince menüde "tamam" görünür, tekrar oynatılmaz
  await p.click("#menu");
  assert.match(await metin(p), /Bugünün günlüğü tamam/);
  assert.strictEqual(await p.$("#gunluk"), null);
  await ctx.close();

  // ---- Oyuncu 2: hemen bitirir (0 puan) ----
  ({ ctx, p } = await yeniSayfa(b, hatalar));
  await p.click("#gunluk"); await p.waitForSelector("#nick");
  await p.fill("#nick", "mehmet"); await p.selectOption("#il", "Ankara"); await p.click("#kaydet");
  for (let i = 0; i < 4; i++) {
    await p.waitForSelector("#go"); await p.click("#go");
    await p.waitForSelector("#bitir"); await p.click("#bitir");
    await p.waitForSelector("#ileri"); await p.click("#ileri");
  }
  await p.waitForFunction(() => document.querySelector("#sira").textContent.includes("2. mehmet"));
  s = await metin(p);
  assert.match(s, /1\. ayse/); assert.match(s, /2\. mehmet/);
  assert.match(s, /1\. Ankara \(2 oyuncu\)/, "iki oyuncu Ankara'da toplanmalı");
  await ctx.close();

  // ---- Oyuncu 3: süre aşımı sunucuda 0 puan ----
  ({ ctx, p } = await yeniSayfa(b, hatalar));
  await p.click("#gunluk"); await p.waitForSelector("#nick");
  await p.fill("#nick", "gecikmis"); await p.click("#kaydet");
  const k3 = await kelimeTuruOyna(p);
  await fetch(SUNUCU + "/__test/geri?sn=70");            // başlangıç 70 sn önce olmuş gibi
  await p.click("#bitir");
  await p.waitForSelector("#ileri");
  s = await metin(p);
  assert.match(s, /Süre aşıldı/, "süre aşımı bildirilmeli: " + s);
  assert.match(s, /Puan 0/);
  await ctx.close();

  // ---- Anahtar yoksa yerel mod ----
  ctx = await b.newContext(); p = await ctx.newPage();
  await p.addInitScript(() => { window.HEDEF_AYAR = { url: "http://x", anonKey: "" }; });
  await p.goto(SAYFA); await p.click("#gunluk");
  await p.waitForSelector("#go"); await p.click("#go");
  assert.ok((await p.$$("[data-h]")).length === 8, "anahtarsız günlük yerelde 8 harf göstermeli");
  await ctx.close();

  await b.close();
  assert.deepStrictEqual(hatalar, [], "tarayıcı hataları: " + hatalar.join(" | "));
  console.log("E2E GEÇTİ");
})().catch((e) => { console.error("E2E BAŞARISIZ:", e.message); process.exit(1); });

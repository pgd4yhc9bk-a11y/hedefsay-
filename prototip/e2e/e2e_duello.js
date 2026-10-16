// Canlı düello uçtan uca: iki tarayıcı oyuncusu <-> gerçek `duel` fonksiyon kodu (sahte_sunucu.ts, port 8787).
// Çalıştır (sunucuyu yeniden başlattıktan sonra): NODE_PATH=<playwright node_modules> node prototip/e2e/e2e_duello.js
const { chromium } = require("playwright");
const path = require("path");
const assert = require("assert");
const SAYFA = "file://" + path.resolve(__dirname, "../index.html");
const SUNUCU = "http://localhost:8787";

async function yeniSayfa(b, hatalar, ad) {
  const ctx = await b.newContext({ viewport: { width: 420, height: 900 } });
  const p = await ctx.newPage();
  await p.addInitScript((s) => { window.HEDEF_AYAR = { url: s, anonKey: "test" }; }, SUNUCU);
  p.on("pageerror", (e) => hatalar.push(ad + " pageerror: " + e.message));
  p.on("console", (m) => m.type() === "error" && hatalar.push(ad + " console: " + m.text()));
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

async function kayitOl(p, nick, il) {
  await p.click("#canli");
  await p.waitForSelector("#nick");
  await p.fill("#nick", nick);
  if (il) await p.selectOption("#il", il);
  await p.click("#kaydet");
}

// Bir turu oynar: "iyi" ise en iyi cevabı yazar, değilse hemen bitirir. Sonuç ekranında durur.
async function turOyna(p, iyi) {
  await p.waitForSelector("#bitir", { timeout: 20000 });   // geri sayım bitince tur ekranı gelir
  if (await p.$("[data-h]")) {
    if (iyi) {
      const harfler = await p.$$eval("[data-h]", (e) => e.map((x) => x.dataset.h));
      const en = await p.evaluate((h) => window.Hedef.allWords(h)[0], harfler);
      await tusla(p, en.word);
    }
    await p.click("#bitir");
  } else {
    if (iyi) {
      const hedef = +(await p.textContent(".target"));
      const sayilar = await p.$$eval("[data-n]", (e) => e.map((x) => +x.dataset.n));
      const ifade = await p.evaluate(([n, t]) => window.Hedef.solve(n).get(t).e, [sayilar, hedef]);
      await p.fill("#expr", ifade); await p.click("#gonder");   // tam isabet: tur kendiliğinden biter
    } else await p.click("#bitir");
  }
  await p.waitForSelector("#ileri", { timeout: 20000 });
}

(async () => {
  const hatalar = [];
  const b = await chromium.launch();

  // ---------- 1) İki gerçek oyuncu ----------
  const A = await yeniSayfa(b, hatalar, "ayse"), B = await yeniSayfa(b, hatalar, "mehmet");
  await kayitOl(A.p, "ayse", "Ankara");
  await A.p.waitForFunction(() => document.querySelector("#app").textContent.includes("Rakip aranıyor"));
  await kayitOl(B.p, "mehmet", "İzmir");

  const oynaA = (async () => {
    for (let r = 1; r <= 4; r++) {
      await turOyna(A.p, true);
      const s = await metin(A.p);
      assert.match(s, new RegExp("Tur " + r + " sonucu"));
      assert.match(s, /mehmet/, "rakip adı görünmeli");
      if (r === 1) {   // yeniden bağlanma: sayfayı yenile, canlı düelloya dön → aynı maçta 2. tur
        await A.p.reload();
        await A.p.click("#canli");
        await A.p.waitForSelector("#bitir", { timeout: 20000 });
        assert.match(await metin(A.p), /Tur 2\/4/, "yenileyince maçta kalınan turdan devam etmeli: " + await metin(A.p));
        // 2. tur zaten başlatılmış ve oynanıyor; devam
        await A.p.click("#bitir").catch(() => {});
        // işlem turunda bitir = cevapsız; sonucu bekle ve bir sonraki iterasyona geç
        await A.p.waitForSelector("#ileri", { timeout: 20000 });
        const s2 = await metin(A.p);
        assert.match(s2, /Tur 2 sonucu/);
        r = 2;   // 2. tur kullanıldı (cevapsız); döngü 3'ten sürer
      }
      await A.p.click("#ileri");
    }
    await A.p.waitForFunction(() => document.querySelector("#app").textContent.includes("Rövanş"), null, { timeout: 20000 });
  })();
  const oynaB = (async () => {
    for (let r = 1; r <= 4; r++) {
      await turOyna(B.p, false);
      await B.p.click("#ileri");
    }
    await B.p.waitForFunction(() => document.querySelector("#app").textContent.includes("Rövanş"), null, { timeout: 20000 });
  })();
  await Promise.all([oynaA, oynaB]);

  const sA = await metin(A.p), sB = await metin(B.p);
  assert.match(sA, /Kazandın/, "ayse kazanmalı: " + sA);
  assert.match(sB, /ayse kazandı/, "mehmet kaybetmeli: " + sB);
  const db1 = await (await fetch(SUNUCU + "/__test/db")).json();
  const mac = db1.matches.find((m) => !m.is_bot);
  assert.strictEqual(mac.state, "finished");
  assert.strictEqual(db1.match_rounds.filter((r) => r.match_id === mac.id).length, 4);
  const aId = db1.players.find((x) => x.nick === "ayse").id;
  const bosIyi = db1.match_moves.filter((m) => m.match_id === mac.id && m.player_id === aId && m.round !== 2 && m.payload.score === 0);
  assert.deepStrictEqual(bosIyi.map((m) => m.round), [], "ayse'nin 1., 3., 4. tur en iyi cevapları puan almalı (2. tur yenileme sonrası bilerek cevapsız)");
  const aPuan = db1.match_moves.filter((m) => m.match_id === mac.id && m.player_id === aId).reduce((t, m) => t + m.payload.score, 0);
  assert.match(sA, new RegExp(aPuan + " puan"), "ekrandaki puan sunucudaki toplamla aynı olmalı: " + sA);
  if (process.argv[2]) await A.p.screenshot({ path: process.argv[2] + "/duello-son.png" });
  await A.ctx.close(); await B.ctx.close();

  // ---------- 2) Rakip yok → bot ----------
  const C = await yeniSayfa(b, hatalar, "can");
  await kayitOl(C.p, "can", "Ankara");
  await C.p.waitForFunction(() => document.querySelector("#app").textContent.includes("Rakip aranıyor"));
  assert.match(await metin(C.p), /Bot/, "bota düşme uyarısı görünmeli");
  await fetch(SUNUCU + "/__test/maci_geri?sn=20");     // 15 sn beklemeyi atla
  for (let r = 1; r <= 4; r++) {
    await turOyna(C.p, true);
    const s = await metin(C.p);
    assert.match(s, /Bot/, "rakip açıkça 'Bot' olarak görünmeli");
    await C.p.click("#ileri");
  }
  await C.p.waitForFunction(() => document.querySelector("#app").textContent.includes("Rövanş"), null, { timeout: 20000 });
  const sC = await metin(C.p);
  assert.match(sC, /Kazandın|Bot kazandı|Berabere/);
  const dbC = await (await fetch(SUNUCU + "/__test/db")).json();
  const canId = dbC.players.find((x) => x.nick === "can").id;
  assert.deepStrictEqual(dbC.match_moves.filter((m) => m.player_id === canId).filter((m) => m.payload.score === 0), [], "can'ın tüm en iyi cevapları puan almalı");
  assert.ok(dbC.matches.some((m) => m.is_bot && m.state === "finished"), "bot maçı bitmiş olmalı");
  await C.ctx.close();

  await b.close();
  assert.deepStrictEqual(hatalar, [], "tarayıcı hataları: " + hatalar.join(" | "));
  console.log("DÜELLO E2E GEÇTİ");
})().catch((e) => { console.error("DÜELLO E2E BAŞARISIZ:", e.message); process.exit(1); });

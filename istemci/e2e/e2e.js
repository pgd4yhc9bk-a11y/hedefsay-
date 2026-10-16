// Expo web çıktısı uçtan uca (Playwright). Gerçek Edge Function kodunu sahte veritabanıyla sunan test sunucusuna bağlanır.
// Hazırlık (kökten):
//   1) deno run -A --import-map=supabase/tests/import_map.json prototip/e2e/sahte_sunucu.ts &         (port 8787; her koşudan önce yeniden başlat)
//   2) cd istemci && EXPO_PUBLIC_SUPABASE_URL=http://localhost:8787 EXPO_PUBLIC_SUPABASE_ANON_KEY=test npx expo export --platform web --output-dir <dizin-anahtarli>
//      EXPO_PUBLIC_SUPABASE_URL=http://localhost:8787 EXPO_PUBLIC_SUPABASE_ANON_KEY= npx expo export --platform web --output-dir <dizin-anahtarsiz>
//   3) http-server <dizin-anahtarli> -p 8081 -s &   http-server <dizin-anahtarsiz> -p 8082 -s &
//   4) NODE_PATH=<playwright node_modules> node istemci/e2e/e2e.js [ekran-goruntusu-dizini]
const { chromium } = require("playwright");
const assert = require("assert");
const APP = "http://localhost:8081", APP_ANAHTARSIZ = "http://localhost:8082", SUNUCU = "http://localhost:8787";
const OUT = process.argv[2];

async function yeni(b, hatalar, ad, url = APP) {
  const ctx = await b.newContext({ viewport: { width: 420, height: 900 } });
  const p = await ctx.newPage();
  p.on("pageerror", (e) => hatalar.push(ad + " pageerror: " + e.message));
  p.on("console", (m) => m.type() === "error" && !/favicon/.test(m.text()) && hatalar.push(ad + " console: " + m.text()));
  await p.goto(url);
  return { ctx, p };
}
const T = (p, id) => p.getByTestId(id);
const metin = async (p) => (await p.locator("body").innerText()).replace(/\s+/g, " ");
async function tusla(p, kelime) {
  await p.evaluate((k) => {
    for (const ch of k) document.dispatchEvent(new KeyboardEvent("keydown", { key: ch, bubbles: true }));
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter", bubbles: true }));
  }, kelime);
}
// Tur ekranında iyi/kötü oyna; sonuç ekranında (#ileri) durur
async function turOyna(p, iyi) {
  await T(p, "bitir").waitFor({ timeout: 25000 });
  if (await p.locator('[data-testid^="harf-"]').count()) {
    if (iyi) {
      const harfler = await p.$$eval('[data-testid^="harf-"]', (e) => e.map((x) => x.getAttribute("data-testid").slice(5)));
      const en = await p.evaluate((h) => window.__H.allWords(h)[0], harfler).catch(() => null);
      if (!en) throw new Error("window.__H yok");
      await tusla(p, en.word);
    }
    await T(p, "bitir").click();
  } else if (iyi) {
    const hedef = +(await T(p, "hedef").innerText());
    const sayilar = await p.$$eval('[data-testid^="sayi-"]', (e) => e.map((x) => +x.getAttribute("data-testid").slice(5)));
    const ifade = await p.evaluate(([n, t]) => window.__H.solve(n).get(t).e, [sayilar, hedef]);
    await T(p, "ifade").fill(ifade);
    await T(p, "gonder").click();       // tam isabet: tur kendiliğinden biter
  } else await T(p, "bitir").click();
  await T(p, "ileri").waitFor({ timeout: 25000 });
}

(async () => {
  const hatalar = [];
  const b = await chromium.launch();
  // Çekirdeği test sayfasına açmak için: uygulamanın kendi çekirdeğini window.__H olarak ver (yalnızca testte)
  const cekirdekEkle = (p) => p.addInitScript(() => { /* uygulama yüklendikten sonra eklenir */ });

  // ---------- 0) Anahtarsız yapı: sunucu modları gizli, pratik açık ----------
  {
    const { ctx, p } = await yeni(b, hatalar, "anahtarsiz", APP_ANAHTARSIZ);
    await T(p, "menu-pratik").waitFor();
    assert.strictEqual(await T(p, "menu-canli").count(), 0, "anahtarsız yapıda canlı düello görünmemeli");
    assert.strictEqual(await T(p, "menu-gunluk").count(), 0, "anahtarsız yapıda günlük görünmemeli");
    assert.match(await metin(p), /TV programıyla bağlantısı yoktur/);
    await ctx.close();
  }

  // Çekirdeği sayfaya sokmak için uygulama paketinden bağımsız küçük bir kopya yükleyeceğiz
  const fs = require("fs"), path = require("path");
  const cekirdekKod = fs.readFileSync(path.resolve(__dirname, "../../prototip/sozluk.js"), "utf8") + "\n" + fs.readFileSync(path.resolve(__dirname, "../../prototip/oyun.js"), "utf8")
    + "\nwindow.__H = window.Hedef; window.__H.setDictionary(window.HEDEF_SOZLUK);";
  const hazirla = async (p) => { await p.evaluate(cekirdekKod); };

  // ---------- 1) Pratik (bota karşı, yerel) ----------
  {
    const { ctx, p } = await yeni(b, hatalar, "pratik");
    await hazirla(p);
    await T(p, "menu-pratik").click();
    for (const t of ["sesli", "sesli", "sesli", "sessiz", "sessiz", "sessiz", "sessiz", "sessiz"]) await T(p, t).click();
    await T(p, "devam").click();
    await T(p, "go").click();
    {   // harf seçimi gerçekten rastgele olmalı (3 sesli + 5 sessiz: en az 4 farklı harf)
      const h = await p.$$eval('[data-testid^="harf-"]', (e) => e.map((x) => x.getAttribute("data-testid").slice(5)));
      assert.strictEqual(h.length, 8);
      assert.ok(new Set(h).size >= 4, "harfler rastgele olmalı: " + h.join(""));
    }
    for (let tur = 0; tur < 4; tur++) {
      if (tur > 0) await T(p, "go").click();
      await turOyna(p, true);
      assert.match(await metin(p), new RegExp("Tur " + (tur + 1) + " sonucu"));
      assert.match(await T(p, "en-iyi").innerText(), /EN İYİ|BİLGİSAYARIN ÇÖZÜMÜ/);
      if (tur === 0) assert.match(await metin(p), /Bot/);
      await T(p, "ileri").click();
    }
    await T(p, "rovans").waitFor();
    const s = await metin(p);
    assert.match(s, /Kazandın|Bot kazandı|Berabere/);
    assert.match(await T(p, "paylas").innerText(), /Hedef Düello/);
    if (OUT) await p.screenshot({ path: OUT + "/expo-pratik-son.png" });
    await ctx.close();
  }

  // ---------- 2) Günlük (sunucu) ----------
  {
    const { ctx, p } = await yeni(b, hatalar, "gunluk");
    await hazirla(p);
    await T(p, "menu-gunluk").click();
    await T(p, "nick").waitFor();
    await T(p, "nick").fill("x"); await T(p, "kaydet").click();
    assert.match(await T(p, "profil-hata").innerText(), /2–20/);
    await T(p, "nick").fill("ayse"); await T(p, "il-sec").click(); await T(p, "il-Ankara").click(); await T(p, "kaydet").click();
    await T(p, "go").waitFor();
    assert.strictEqual(await p.locator('[data-testid^="harf-"]').count(), 0, "başlamadan harf görünmemeli");
    for (let tur = 0; tur < 4; tur++) {
      if (tur === 2) {   // yenile: kalınan turdan devam
        await p.reload(); await hazirla(p);
        await T(p, "menu-gunluk").click();
        await T(p, "go").waitFor();
        assert.match(await T(p, "ust-tur").innerText(), /Tur 3\/4/, "yenileyince 3. turdan devam etmeli");
      }
      await T(p, "go").click();
      await turOyna(p, true);
      assert.match(await metin(p), new RegExp("Tur " + (tur + 1) + " sonucu"));
      await T(p, "ileri").click();
    }
    await p.getByText("Bugünün sıralaması").waitFor();
    await p.waitForFunction(() => document.body.innerText.includes("1. ayse"), null, { timeout: 15000 });
    const s = await metin(p);
    assert.match(s, /1\. ayse \(Ankara\)/); assert.match(s, /1\. Ankara \(1 oyuncu\)/); assert.match(s, /🎯/);
    if (OUT) await p.screenshot({ path: OUT + "/expo-gunluk-son.png" });
    await ctx.close();
  }

  // ---------- 3) Canlı düello: iki oyuncu ----------
  const A = await yeni(b, hatalar, "ayse-duello"), B = await yeni(b, hatalar, "mehmet-duello");
  await hazirla(A.p); await hazirla(B.p);
  const kayit = async (p, nick, il) => {
    await T(p, "menu-canli").click(); await T(p, "nick").waitFor();
    await T(p, "nick").fill(nick); await T(p, "il-sec").click(); await T(p, "il-" + il).click(); await T(p, "kaydet").click();
  };
  // A zaten günlükte kayıtlı olabilir (farklı bağlam): yeni bağlamlar yeni kullanıcı
  await kayit(A.p, "ali", "Ankara");
  await p_bekle(A.p, "Rakip aranıyor");
  await kayit(B.p, "veli", "İzmir");
  const oyna = async (X, iyi, ad) => {
    for (let r = 1; r <= 4; r++) {
      await turOyna(X.p, iyi);
      const s = await metin(X.p);
      assert.match(s, new RegExp("Tur " + r + " sonucu"));
      assert.match(s, new RegExp(ad), "rakip adı görünmeli");
      if (r === 1 && iyi) {   // yeniden bağlanma: yenile → canlı düello → aynı maçta 2. tur
        await X.p.reload(); await hazirla(X.p);
        await T(X.p, "menu-canli").click();
        await T(X.p, "bitir").waitFor({ timeout: 25000 });
        assert.match(await T(X.p, "ust-tur").innerText(), /Tur 2\/4/, "yenileyince maçta kalınan turdan devam etmeli");
        await T(X.p, "bitir").click(); await T(X.p, "ileri").waitFor({ timeout: 25000 });
        r = 2;   // 2. tur yenileme sonrası (cevapsız) oynandı; döngü 3. turdan sürer
      }
      await T(X.p, "ileri").click();
    }
    await T(X.p, "rovans").waitFor({ timeout: 25000 });
  };
  await Promise.all([oyna(A, true, "veli"), oyna(B, false, "ali")]);
  const sA = await metin(A.p), sB = await metin(B.p);
  assert.match(sA, /Kazandın/, "ali kazanmalı: " + sA);
  assert.match(sB, /ali kazandı/, "veli kaybetmeli: " + sB);
  if (OUT) await A.p.screenshot({ path: OUT + "/expo-duello-son.png" });
  await A.ctx.close(); await B.ctx.close();

  // ---------- 4) Rakip yok → Bot ----------
  {
    const { ctx, p } = await yeni(b, hatalar, "can-duello");
    await hazirla(p);
    await kayit(p, "can", "Ankara");
    await p_bekle(p, "Rakip aranıyor");
    assert.match(await T(p, "bekle-bilgi").innerText(), /Bot/);
    await fetch(SUNUCU + "/__test/maci_geri?sn=20");
    for (let r = 1; r <= 4; r++) {
      await turOyna(p, true);
      assert.match(await metin(p), /Bot/, "rakip açıkça 'Bot' görünmeli");
      await T(p, "ileri").click();
    }
    await T(p, "rovans").waitFor({ timeout: 25000 });
    assert.match(await metin(p), /Kazandın|Bot kazandı|Berabere/);
    await ctx.close();
  }

  await b.close();
  assert.deepStrictEqual(hatalar, [], "tarayıcı hataları: " + hatalar.join(" | "));
  console.log("EXPO E2E GEÇTİ");
})().catch((e) => { console.error("EXPO E2E BAŞARISIZ:", e.message); process.exit(1); });

async function p_bekle(p, metinParcasi) {
  await p.waitForFunction((m) => document.body.innerText.includes(m), metinParcasi, { timeout: 15000 });
}

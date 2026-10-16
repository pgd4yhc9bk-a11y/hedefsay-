// node prototip/test.js
const assert = require("assert");
const H = require("./oyun.js");
require("./sozluk.js");
H.setDictionary(globalThis.HEDEF_SOZLUK);
let n = 0;
const t = (ad, f) => { f(); n++; console.log("ok -", ad); };

t("trLower İ/I", () => {
  assert.strictEqual(H.trLower("İSTANBUL"), "istanbul");
  assert.strictEqual(H.trLower("ISIK"), "ısık");
  assert.strictEqual(H.trLower("rüzgâr"), "rüzgar");
});

t("rng aynı tohumda aynı", () => {
  const a = H.makeRng("x"), b = H.makeRng("x"), c = H.makeRng("y");
  assert.strictEqual(a(), b());
  assert.notStrictEqual(H.makeRng("x")(), c());
});

t("ifade doğrulama", () => {
  const pool = [7, 3, 8, 5, 2, 10];
  assert.deepStrictEqual(H.evaluate("(7+3)*8-5", pool).value, 75);
  assert.ok(!H.evaluate("7+7", pool).ok, "7 iki kez");
  assert.ok(!H.evaluate("3-5", pool).ok, "negatif");
  assert.ok(!H.evaluate("3-3", [3, 3]).ok, "sıfır");
  assert.ok(!H.evaluate("7/2", pool).ok, "tam bölünmeyen");
  assert.ok(!H.evaluate("(7+3", pool).ok, "parantez");
  assert.ok(!H.evaluate("9+1", pool).ok, "elde yok");
  assert.strictEqual(H.evaluate("10÷2×3", [10, 2, 3]).value, 15);
  assert.strictEqual(H.evaluate("8-(5-2)", pool).value, 5);
});

t("puanlar", () => {
  assert.deepStrictEqual([0, 1, 5, 6, 10, 11].map(d => H.numberScore(500, 500 + d)), [10, 7, 7, 5, 5, 0]);
});

t("sayı turu: 30 tur, hedef 101–999 ve çözücü ifadesi geçerli", () => {
  for (let i = 0; i < 30; i++) {
    const r = H.generateNumberRound(H.makeRng("sayi-" + i));
    assert.strictEqual(r.nums.length, 6);
    assert.ok(r.nums.slice(0, 5).every(x => x >= 1 && x <= 9));
    assert.ok(r.nums[5] % 10 === 0 && r.nums[5] >= 10 && r.nums[5] <= 90);
    assert.ok(r.target >= 101 && r.target <= 999);
    const sol = r.found.get(r.target);
    const ev = H.evaluate(sol.e, r.nums);
    assert.ok(ev.ok, sol.e + " -> " + ev.error);
    assert.strictEqual(ev.value, r.target);
  }
});

t("çözücü: bilinen örnek", () => {
  const f = H.solve([25, 50, 75, 100, 3, 6]);
  assert.ok(f.has(952));
  const ev = H.evaluate(f.get(952).e, [25, 50, 75, 100, 3, 6]);
  assert.ok(ev.ok && ev.value === 952);
});

t("kelime: kurulabilirlik, joker, puan", () => {
  const L = "kalemtai".split("");
  assert.ok(H.wordInfo("kalem", L).valid);
  assert.strictEqual(H.wordInfo("kalem", L).score, 5 + 3);
  assert.ok(!H.wordInfo("kalemx", L).valid);
  assert.strictEqual(H.wordInfo("zzzz", L).reason, "Harfler yetmiyor");
  const J = H.wordInfo("kitap", "kalemtai".split("")); // p yok -> joker
  assert.strictEqual(J.valid, true);
  assert.strictEqual(J.joker, true);
  assert.strictEqual(J.score, 5);
  assert.strictEqual(H.wordInfo("KİTAP", "kalemtai".split("")).word, "kitap");
});

t("harf üretici: en az 3 sesli, 6+ harfli çözüm", () => {
  for (let i = 0; i < 30; i++) {
    const L = H.generateRackAuto(H.makeRng("kelime-" + i));
    assert.strictEqual(L.length, 8);
    assert.ok(L.filter(c => H.SESLI.includes(c)).length >= 3, L.join(""));
    assert.ok(H.hasLong(L, 6), L.join(""));
  }
});

t("allWords sıralı, ilk eleman en iyi; bot geçerli kelime verir", () => {
  const L = H.generateRackAuto(H.makeRng("bot-1"));
  const list = H.allWords(L);
  assert.ok(list.length > 0);
  for (let i = 1; i < list.length; i++) assert.ok(list[i - 1].score >= list[i].score);
  const b = H.botWord(L, H.makeRng("b"));
  assert.ok(H.wordInfo(b.word, L).valid);
});

console.log(`\n${n} test geçti`);

// Hedef — oyun çekirdeği (arayüzden bağımsız; tarayıcıda ve Node'da çalışır).
// Sayı turu: üretici + çözücü + ifade doğrulama + puan.
// Kelime turu: harf üretici + sözlük denetimi + puan + en iyi kelime.
// Bot rakip: düello akışını tek başına denemek için.
(function (root) {
  "use strict";

  // ---------- Türkçe yardımcılar ----------
  var SESLI = "aeıioöuü";
  var SESSIZ = "bcçdfgğhjklmnprsştvyz";
  var ALFABE = "abcçdefgğhıijklmnoöprsştuüvyz";
  // Yaklaşık Türkçe harf sıklığı (%)
  var AGIRLIK = {
    a: 11.9, e: 9.0, i: 8.5, n: 7.5, r: 6.9, l: 5.9, ı: 5.1, k: 4.7, d: 4.7, m: 3.7, y: 3.4,
    t: 3.3, u: 3.2, s: 3.0, b: 2.8, o: 2.5, ü: 1.9, ş: 1.7, z: 1.5, ç: 1.2, g: 1.2, h: 1.1,
    ğ: 1.1, v: 1.0, c: 1.0, p: 0.9, ö: 0.8, f: 0.5, j: 0.1
  };
  var TAM_KULLANIM_BONUSU = 10; // belgede "ek bonus" denmiş, değer ayarlanacak
  var JOKERSIZ_BONUSU = 3;
  var MIN_SESLI = 3;
  var HARF_SAYISI = 8;

  function trLower(s) {
    return String(s)
      .replace(/İ/g, "i").replace(/I/g, "ı")
      .toLowerCase()
      .replace(/â/g, "a").replace(/î/g, "i").replace(/û/g, "u");
  }

  // ---------- Tohumlu rastgele sayı ----------
  function xmur3(str) {
    var h = 1779033703 ^ str.length;
    for (var i = 0; i < str.length; i++) {
      h = Math.imul(h ^ str.charCodeAt(i), 3432918353);
      h = (h << 13) | (h >>> 19);
    }
    return function () {
      h = Math.imul(h ^ (h >>> 16), 2246822507);
      h = Math.imul(h ^ (h >>> 13), 3266489909);
      return (h ^= h >>> 16) >>> 0;
    };
  }
  function mulberry32(a) {
    return function () {
      a |= 0; a = (a + 0x6d2b79f5) | 0;
      var t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  function makeRng(seed) { return mulberry32(xmur3(String(seed))()); }
  function randInt(rng, n) { return Math.floor(rng() * n); }

  // ---------- Sözlük ----------
  var sozluk = new Set();
  var sozlukListe = [];
  function setDictionary(words) {
    sozluk = new Set();
    for (var i = 0; i < words.length; i++) {
      var w = trLower(words[i]);
      if (/^[a-zçğıöşü]{2,9}$/.test(w)) sozluk.add(w);
    }
    sozlukListe = Array.from(sozluk);
  }

  // ---------- Kelime turu ----------
  function drawLetter(rng, type) {
    var set = type === "sesli" ? SESLI : SESSIZ;
    var total = 0, i;
    for (i = 0; i < set.length; i++) total += AGIRLIK[set[i]];
    var r = rng() * total;
    for (i = 0; i < set.length; i++) {
      r -= AGIRLIK[set[i]];
      if (r < 0) return set[i];
    }
    return set[set.length - 1];
  }

  // joker hariç, eksik harf sayısı (0 = jokersiz kurulur, 1 = joker gerekir)
  function eksik(word, letters) {
    var have = {}, miss = 0, i;
    for (i = 0; i < letters.length; i++) have[letters[i]] = (have[letters[i]] || 0) + 1;
    for (i = 0; i < word.length; i++) {
      var ch = word[i];
      if (have[ch] > 0) have[ch]--; else miss++;
    }
    return miss;
  }

  function puanla(word, miss) {
    var len = word.length;
    var p = len;
    if (miss === 0) p += JOKERSIZ_BONUSU;
    if (len === HARF_SAYISI + 1 || (len === HARF_SAYISI && miss === 0)) p += TAM_KULLANIM_BONUSU;
    return p;
  }

  // Tek kelimeyi değerlendir (geçersizse neden döner)
  function wordInfo(word, letters) {
    var w = trLower(word);
    if (w.length < 2) return { valid: false, reason: "En az 2 harf gerekli" };
    if (eksik(w, letters) > 1) return { valid: false, reason: "Harfler yetmiyor" };
    if (!sozluk.has(w)) return { valid: false, reason: "Sözlükte yok" };
    var miss = eksik(w, letters);
    return { valid: true, word: w, score: puanla(w, miss), joker: miss === 1 };
  }

  // Bu harflerle kurulabilen tüm sözlük kelimeleri, puana göre azalan
  function allWords(letters) {
    var out = [];
    for (var i = 0; i < sozlukListe.length; i++) {
      var w = sozlukListe[i];
      if (w.length > letters.length + 1) continue;
      var m = eksik(w, letters);
      if (m <= 1) out.push({ word: w, score: puanla(w, m), joker: m === 1 });
    }
    out.sort(function (a, b) { return b.score - a.score || b.word.length - a.word.length || (a.word < b.word ? -1 : 1); });
    return out;
  }

  function hasLong(letters, min) {
    min = min || 6;
    for (var i = 0; i < sozlukListe.length; i++) {
      var w = sozlukListe[i];
      if (w.length >= min && w.length <= letters.length + 1 && eksik(w, letters) <= 1) return true;
    }
    return false;
  }

  // Son harfi çeker; setin 6+ harfli çözümü olması için (mümkünse) yeniden çeker.
  function completeRack(rng, ilk, type) {
    var last = null;
    for (var t = 0; t < 400; t++) {
      last = drawLetter(rng, type);
      if (hasLong(ilk.concat(last), 6)) break;
    }
    return ilk.concat(last);
  }

  // Sesli/sessiz dizisinden 8 harf üretir.
  function generateRack(rng, types) {
    var letters = [];
    for (var i = 0; i < types.length - 1; i++) letters.push(drawLetter(rng, types[i]));
    return completeRack(rng, letters, types[types.length - 1]);
  }

  function randomTypes(rng) {
    var r = rng();
    var v = r < 0.5 ? 3 : r < 0.85 ? 4 : 5;
    var types = [];
    for (var i = 0; i < HARF_SAYISI; i++) types.push(i < v ? "sesli" : "sessiz");
    for (i = types.length - 1; i > 0; i--) {
      var j = randInt(rng, i + 1), tmp = types[i]; types[i] = types[j]; types[j] = tmp;
    }
    return types;
  }

  // Sistem seçimli (günlük / bot seçimli) set: 6+ harfli çözüm garantili
  function generateRackAuto(rng) {
    var best = null;
    for (var k = 0; k < 600; k++) {
      var letters = generateRack(rng, randomTypes(rng));
      best = letters;
      if (hasLong(letters, 6)) return letters;
    }
    return best;
  }

  // ---------- Sayı turu ----------
  var ONCELIK = { "+": 1, "−": 1, "×": 2, "÷": 2 };

  function yaz(it, op, sag) {
    var p = ONCELIK[op];
    if (sag) {
      var strict = op === "−" || op === "÷";
      return (it.p < p || (strict && it.p === p)) ? "(" + it.e + ")" : it.e;
    }
    return it.p < p ? "(" + it.e + ")" : it.e;
  }
  function birlestir(a, b, op, v) {
    return { v: v, e: yaz(a, op, false) + op + yaz(b, op, true), p: ONCELIK[op], n: a.n + b.n };
  }

  // Altı sayıdan ulaşılabilen tüm pozitif tam sayılar: Map(değer -> {e, n})
  function solve(nums) {
    var found = new Map();
    var seen = new Set();
    function kaydet(it) {
      var cur = found.get(it.v);
      if (!cur || it.n < cur.n) found.set(it.v, { e: it.e, n: it.n });
    }
    function rec(items) {
      if (items.length < 2) return;
      var key = items.map(function (x) { return x.v; }).sort(function (a, b) { return a - b; }).join(",");
      if (seen.has(key)) return;
      seen.add(key);
      for (var i = 0; i < items.length; i++) {
        for (var j = i + 1; j < items.length; j++) {
          var a = items[i], b = items[j];
          var rest = [];
          for (var k = 0; k < items.length; k++) if (k !== i && k !== j) rest.push(items[k]);
          var yeni = [];
          yeni.push(birlestir(a, b, "+", a.v + b.v));
          yeni.push(birlestir(a, b, "×", a.v * b.v));
          if (a.v > b.v) yeni.push(birlestir(a, b, "−", a.v - b.v));
          else if (b.v > a.v) yeni.push(birlestir(b, a, "−", b.v - a.v));
          if (a.v % b.v === 0) yeni.push(birlestir(a, b, "÷", a.v / b.v));
          if (a.v !== b.v && b.v % a.v === 0) yeni.push(birlestir(b, a, "÷", b.v / a.v));
          for (var y = 0; y < yeni.length; y++) {
            kaydet(yeni[y]);
            rec(rest.concat(yeni[y]));
          }
        }
      }
    }
    var start = nums.map(function (n) { return { v: n, e: String(n), p: 3, n: 1 }; });
    start.forEach(kaydet);
    rec(start);
    return found;
  }

  // 5 tek basamaklı (1–9) + 1 onluk (10…90); hedef 101–999 ve tam ulaşılabilir
  function generateNumberRound(rng) {
    for (var t = 0; t < 200; t++) {
      var nums = [];
      for (var i = 0; i < 5; i++) nums.push(1 + randInt(rng, 9));
      nums.push((1 + randInt(rng, 9)) * 10);
      var found = solve(nums);
      var adaylar = [], zor = [];
      found.forEach(function (info, v) {
        if (v >= 101 && v <= 999) { adaylar.push(v); if (info.n >= 4) zor.push(v); }
      });
      var havuz = zor.length ? zor : adaylar;
      if (!havuz.length) continue;
      havuz.sort(function (a, b) { return a - b; });
      return { nums: nums, target: havuz[randInt(rng, havuz.length)], found: found };
    }
    throw new Error("Sayı turu üretilemedi");
  }

  // Oyuncunun yazdığı ifadeyi doğrula ve hesapla
  function evaluate(text, pool) {
    var s = String(text).replace(/[*xX·]/g, "×").replace(/\//g, "÷").replace(/[-–—]/g, "−");
    var tokens = s.match(/\d+|[+−×÷()]/g) || [];
    var kalan = s.replace(/\d+|[+−×÷()]|\s+/g, "");
    if (kalan.length) return { ok: false, error: "Geçersiz karakter: " + kalan[0] };
    if (!tokens.length) return { ok: false, error: "İfade boş" };
    var pos = 0, used = [];
    function fail(msg) { var e = new Error(msg); e.hedef = true; throw e; }
    function factor() {
      var t = tokens[pos];
      if (t === undefined) fail("İfade yarım kaldı");
      if (t === "(") {
        pos++;
        var v = expr();
        if (tokens[pos] !== ")") fail("Parantez kapanmadı");
        pos++;
        return v;
      }
      if (/^\d+$/.test(t)) { pos++; var n = parseInt(t, 10); used.push(n); return n; }
      fail("Beklenmeyen işaret: " + t);
    }
    function term() {
      var l = factor();
      while (tokens[pos] === "×" || tokens[pos] === "÷") {
        var op = tokens[pos++], r = factor();
        if (op === "×") l = l * r;
        else {
          if (r === 0 || l % r !== 0) fail("Bölme tam sayı çıkmalı (" + l + "÷" + r + ")");
          l = l / r;
        }
      }
      return l;
    }
    function expr() {
      var l = term();
      while (tokens[pos] === "+" || tokens[pos] === "−") {
        var op = tokens[pos++], r = term();
        if (op === "+") l = l + r;
        else {
          if (l <= r) fail("Çıkarma sonucu pozitif olmalı (" + l + "−" + r + ")");
          l = l - r;
        }
      }
      return l;
    }
    try {
      var value = expr();
      if (pos < tokens.length) fail("Beklenmeyen işaret: " + tokens[pos]);
      var have = {};
      pool.forEach(function (n) { have[n] = (have[n] || 0) + 1; });
      for (var i = 0; i < used.length; i++) {
        if (!(have[used[i]] > 0)) return { ok: false, error: used[i] + " sayısı elinde yok ya da fazla kullanıldı" };
        have[used[i]]--;
      }
      return { ok: true, value: value, used: used };
    } catch (e) {
      if (e.hedef) return { ok: false, error: e.message };
      throw e;
    }
  }

  function numberScore(target, value) {
    var d = Math.abs(target - value);
    if (d === 0) return 10;
    if (d <= 5) return 7;
    if (d <= 10) return 5;
    return 0;
  }

  // ---------- Bot rakip ----------
  function botWord(letters, rng) {
    var list = allWords(letters);
    if (!list.length) return null;
    var idx = Math.floor(Math.pow(rng(), 3) * Math.min(list.length, 12));
    return list[idx];
  }
  function botNumber(round, rng) {
    var target = round.target, found = round.found;
    if (rng() < 0.45) return { value: target, expr: found.get(target).e };
    var d = 1 + randInt(rng, 12), yon = rng() < 0.5 ? 1 : -1;
    for (var k = 0; k < 200; k++) {
      var cands = [target + yon * (d + k), target - yon * (d + k)];
      for (var c = 0; c < 2; c++) if (found.has(cands[c])) return { value: cands[c], expr: found.get(cands[c]).e };
    }
    return { value: target, expr: found.get(target).e };
  }

  var Hedef = {
    SESLI: SESLI, SESSIZ: SESSIZ, ALFABE: ALFABE, MIN_SESLI: MIN_SESLI, HARF_SAYISI: HARF_SAYISI,
    trLower: trLower, makeRng: makeRng, randInt: randInt,
    setDictionary: setDictionary, getDictionarySize: function () { return sozlukListe.length; },
    drawLetter: drawLetter, completeRack: completeRack, generateRack: generateRack, generateRackAuto: generateRackAuto, randomTypes: randomTypes,
    wordInfo: wordInfo, allWords: allWords, hasLong: hasLong,
    solve: solve, generateNumberRound: generateNumberRound, evaluate: evaluate, numberScore: numberScore,
    botWord: botWord, botNumber: botNumber
  };
  if (typeof module !== "undefined" && module.exports) module.exports = Hedef;
  root.Hedef = Hedef;
})(typeof window !== "undefined" ? window : globalThis);

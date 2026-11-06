(() => {
'use strict';
// ================= Sabitler =================
const RW = 420, RH = 820, PY = 0.7, WALLH = 46, LIP = 22, TILE = 40, PR = 12;
const MAXLV = 80, INV = 30;
const C = { bg: '#110e14', wallLine: 'rgba(0,0,0,.25)', lip: '#1a151e', bad: '#ff5d5d', fg: '#efe6dc', gold: '#ffd27a', exp: '#8fb8ff', crit: '#ffe27a',
  rat: '#a8917a', ratTop: '#d8c4ad', guard: '#6f7d92', guardTop: '#a9b6c9', archer: '#8b9a4a', archerTop: '#c8d88a', boss: '#7a2a2a', bossTop: '#ff8a3d', arrow: '#ff6a6a' };
const RCOL = ['#b9ada3', '#5fa8ff', '#c47bff', '#ffb347'];
const RNAME = ['Sıradan', 'Nadir', 'Destansı', 'Efsanevi'];
const RMULT = [1, 1.2, 1.45, 1.8];
const PLUSM = [1, 1.08, 1.16, 1.25, 1.36, 1.48, 1.62, 1.85, 2.1, 2.4];
const CHANCE = [100, 100, 100, 80, 65, 50, 40, 30, 20];
const TAS = [1, 1, 2, 2, 3, 4, 4, 5, 6];
const KOR = [0, 0, 0, 0, 0, 0, 1, 2, 3];

const CLASSES = {
  savasci: { ad: 'Savaşçı', kisa: 'S', ac: 'Yakın dövüş. Yüksek can ve zırh, önündeki her şeyi biçer.', yetenek: 'Yer Sarsıntısı', yac: 'Çevreye büyük hasar, düşmanları geri iter.',
    col: '#d9653b', top: '#ffab7a', hp: [120, 14], dmg: [10, 2.4], arm: [5, 0.7], rate: 1.5, kind: 'melee', cd: 8 },
  okcu: { ad: 'Okçu', kisa: 'O', ac: 'Uzaktan hızlı oklar. Orta can, en hızlı saldırı.', yetenek: 'Ok Yağmuru', yac: 'Her yöne delici ok yağdırır.',
    col: '#e8b64a', top: '#ffe39a', hp: [85, 10], dmg: [8, 2.0], arm: [2, 0.35], rate: 2.4, kind: 'arrow', cd: 7 },
  buyucu: { ad: 'Büyücü', kisa: 'B', ac: 'Patlayan büyüler. Düşük can, toplu düşmana en çok hasar.', yetenek: 'Buz Halkası', yac: 'Geniş alanda hasar verir, düşmanları yavaşlatır.',
    col: '#6f8cff', top: '#b8c6ff', hp: [75, 9], dmg: [12, 2.8], arm: [1, 0.3], rate: 1.25, kind: 'bolt', cd: 9 },
};
const REGIONS = [
  { ad: 'Kül Mahzeni', min: 1, max: 10, a: '#2a2330', b: '#2e2735', wall: '#3a3040', wallTop: '#55475c', spot: '255,138,61' },
  { ad: 'Paslı Atölye', min: 10, max: 20, a: '#2d2620', b: '#332a22', wall: '#4a3a2c', wallTop: '#6b5440', spot: '200,120,60' },
  { ad: 'Kök Labirenti', min: 20, max: 30, a: '#1f2a22', b: '#243026', wall: '#2f4233', wallTop: '#4a6650', spot: '140,220,120' },
];
const SLOTS = ['silah', 'zirh', 'yuzuk', 'kolye'];
const SLOTAD = { silah: 'Silah', zirh: 'Zırh', yuzuk: 'Yüzük', kolye: 'Kolye' };
const NAMES = {
  silah: { savasci: ['Paslı Kılıç', 'Demir Kılıç', 'Kök Kılıcı'], okcu: ['Kısa Yay', 'Avcı Yayı', 'Kök Yayı'], buyucu: ['Çıra Asası', 'Bakır Asa', 'Kök Asası'] },
  zirh: ['Deri Yelek', 'Zincir Zırh', 'Kabuk Zırh'], yuzuk: ['Bakır Yüzük', 'Gümüş Yüzük', 'Kor Yüzüğü'], kolye: ['İp Kolye', 'Taş Kolye', 'Kök Kolye'],
};
const AFF = {
  crit: { ad: 'Kritik şansı', f: v => '+%' + v }, atk: { ad: 'Saldırı hızı', f: v => '+%' + v }, hp: { ad: 'Can', f: v => '+' + v },
  spd: { ad: 'Hareket hızı', f: v => '+%' + v }, leech: { ad: 'Can çalma', f: v => '%' + v }, gold: { ad: 'Altın bulma', f: v => '+%' + v },
  exp: { ad: 'EXP kazanımı', f: v => '+%' + v }, dmgPct: { ad: 'Hasar', f: v => '+%' + v },
};

// ================= Kayıt =================
const KEY = 'kayip-katlar-v1';
let save = null;
try { const raw = localStorage.getItem(KEY); if (raw) save = JSON.parse(raw); } catch (e) {}
const persist = () => { try { localStorage.setItem(KEY, JSON.stringify(save)); } catch (e) {} };
function newSave(cls) {
  return { cls, lvl: 1, exp: 0, gold: 0, tas: 0, kor: 0, inv: [], eq: { silah: starter(cls), zirh: null, yuzuk: null, kolye: null }, nextId: 2, best: [0, 0, 0] };
}
function starter(cls) { return { id: 1, slot: 'silah', r: 0, ilvl: 1, name: NAMES.silah[cls][0], aff: [], plus: 0, pity: 0 }; }

// ================= Ses =================
let AC = null;
function audio() { if (!AC) { try { AC = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) {} } if (AC && AC.state === 'suspended') AC.resume(); }
function blip(f, d = 0.08, type = 'square', v = 0.05, slide = 0) {
  if (!AC) return;
  const t = AC.currentTime, o = AC.createOscillator(), g = AC.createGain();
  o.type = type; o.frequency.setValueAtTime(f, t);
  if (slide) o.frequency.exponentialRampToValueAtTime(Math.max(30, f * slide), t + d);
  g.gain.setValueAtTime(v, t); g.gain.exponentialRampToValueAtTime(0.0001, t + d);
  o.connect(g).connect(AC.destination); o.start(t); o.stop(t + d + 0.02);
}

// ================= Seviye ve istatistik =================
function need(L) { const band = L <= 30 ? 1 : L <= 50 ? 2.5 : L <= 65 ? 5 : 9; return Math.round((60 + 22 * Math.pow(L, 1.5)) * band); }
function itemMain(it) {
  const m = RMULT[it.r] * PLUSM[it.plus], L = it.ilvl;
  switch (it.slot) {
    case 'silah': return { dmg: Math.round((3 + L * 1.6) * m) };
    case 'zirh': return { maxHp: Math.round((12 + L * 6) * m), armor: Math.round((2 + L * 0.5) * m) };
    case 'yuzuk': return { crit: Math.round((2 + L * 0.15) * m), dmg: Math.round((1 + L * 0.4) * m) };
    case 'kolye': return { maxHp: Math.round((8 + L * 4) * m), dmg: Math.round((1 + L * 0.5) * m) };
  }
}
function baseStats() {
  const c = CLASSES[save.cls], L = save.lvl - 1;
  return { maxHp: c.hp[0] + c.hp[1] * L, dmg: c.dmg[0] + c.dmg[1] * L, armor: c.arm[0] + c.arm[1] * L, crit: 5, atk: 1, spd: 1, leech: 0, gold: 1, exp: 1, dmgPct: 0 };
}
function addItem(s, it) {
  const m = itemMain(it); for (const k in m) s[k] += m[k];
  for (const a of it.aff) {
    if (a.k === 'crit') s.crit += a.v; else if (a.k === 'hp') s.maxHp += a.v; else if (a.k === 'leech') s.leech += a.v;
    else if (a.k === 'dmgPct') s.dmgPct += a.v; else s[a.k] += a.v / 100;
  }
}
function calcStats(eq = save.eq) {
  const s = baseStats();
  for (const sl of SLOTS) if (eq[sl]) addItem(s, eq[sl]);
  s.dmg = Math.round(s.dmg * (1 + s.dmgPct / 100)); s.maxHp = Math.round(s.maxHp); s.armor = Math.round(s.armor);
  s.crit = Math.min(60, s.crit);
  return s;
}
function power(s) { return s.dmg * 3 * (1 + s.crit / 100) * s.atk + s.maxHp * 0.4 + s.armor * 2; }
function isBetter(it) {
  const cur = power(calcStats());
  const eq = Object.assign({}, save.eq, { [it.slot]: it });
  return power(calcStats(eq)) > cur + 0.5;
}
function gainExp(n) {
  if (save.lvl >= MAXLV) return;
  save.exp += n;
  let up = false;
  while (save.lvl < MAXLV && save.exp >= need(save.lvl)) { save.exp -= need(save.lvl); save.lvl++; up = true; }
  if (up) {
    persist(); toast('Seviye ' + save.lvl + '!');
    blip(520, 0.1, 'triangle', 0.07, 1.5); setTimeout(() => blip(780, 0.12, 'triangle', 0.06, 1.5), 90); setTimeout(() => blip(1040, 0.2, 'triangle', 0.05), 180);
    if (run) { const s = runStats(); P1.hp = s.maxHp; RN.ev('level', { x: P1.x, y: P1.y }); } else if (town) RN.ev('level', { x: town.p.x, y: town.p.y });
  }
}

// ================= Eşya üretimi =================
const rnd = (a, b) => a + Math.random() * (b - a);
const ri = (a, b) => Math.floor(rnd(a, b + 1));
function rollRarity(boss) {
  const x = Math.random() * 100;
  if (boss) return x < 10 ? 3 : x < 45 ? 2 : 1;
  return x < 1 ? 3 : x < 10 ? 2 : x < 38 ? 1 : 0;
}
function makeItem(ilvl, boss) {
  const slot = SLOTS[ri(0, 3)], r = rollRarity(boss), tier = Math.min(2, Math.floor((ilvl - 1) / 10));
  const list = slot === 'silah' ? NAMES.silah[save.cls] : NAMES[slot];
  const keys = Object.keys(AFF).sort(() => Math.random() - 0.5).slice(0, r);
  const aff = keys.map(k => ({ k, v: k === 'hp' ? Math.round((5 + ilvl * 2) * rnd(0.6, 1.2)) : k === 'leech' ? ri(1, 3) : k === 'crit' ? ri(1, 4) : ri(3, 8) }));
  return { id: save.nextId++, slot, r, ilvl, name: list[tier], aff, plus: 0, pity: 0 };
}
function sellPrice(it) { return Math.round((4 + it.ilvl * 2) * (1 + it.r * 1.5) * (1 + it.plus * 0.6)); }

// ================= Sahne (3D) =================
const cv = document.getElementById('cv');
const RN = window.Sahne;
RN.init(cv, document.getElementById('ov'));
function resize() { RN.resize(); }
let hurtT = 0;
function flashHurt() { const el = document.getElementById('hurtFx'); el.style.opacity = '1'; clearTimeout(hurtT); hurtT = setTimeout(() => { el.style.opacity = '0'; }, 120); }

// ================= Girdi =================
const joy = { on: false, id: -1, bx: 0, by: 0, dx: 0, dy: 0 };
const keys = {};
let dashReq = false, skillReq = false;
let tapStart = null;
cv.addEventListener('pointerdown', e => {
  audio();
  tapStart = { x: e.clientX, y: e.clientY, t: performance.now() };
  if ((G.mode !== 'play' && G.mode !== 'town') || joy.on) return;
  joy.on = true; joy.id = e.pointerId; joy.bx = e.clientX; joy.by = e.clientY; joy.dx = joy.dy = 0;
  try { cv.setPointerCapture(e.pointerId); } catch (_) {}
});
cv.addEventListener('pointermove', e => {
  if (!joy.on || e.pointerId !== joy.id) return;
  let dx = e.clientX - joy.bx, dy = e.clientY - joy.by; const R = 50, l = Math.hypot(dx, dy);
  if (l > R) { joy.bx += dx - dx / l * R; joy.by += dy - dy / l * R; dx = dx / l * R; dy = dy / l * R; }
  joy.dx = dx / R; joy.dy = dy / R;
});
const joyEnd = e => {
  if (e.pointerId === joy.id) { joy.on = false; joy.dx = joy.dy = 0; }
  if (e.type === 'pointerup' && tapStart && G.mode === 'town' && Math.hypot(e.clientX - tapStart.x, e.clientY - tapStart.y) < 10 && performance.now() - tapStart.t < 350) townTap(e.clientX, e.clientY);
  tapStart = null;
};
cv.addEventListener('pointerup', joyEnd); cv.addEventListener('pointercancel', joyEnd);
const $ = id => document.getElementById(id);
$('dash').addEventListener('pointerdown', e => { e.preventDefault(); e.stopPropagation(); audio(); dashReq = true; });
$('skill').addEventListener('pointerdown', e => { e.preventDefault(); e.stopPropagation(); audio(); skillReq = true; });
addEventListener('keydown', e => {
  keys[e.key.toLowerCase()] = true;
  if (G.mode === 'play') {
    if (e.key === ' ') { dashReq = true; e.preventDefault(); }
    if (e.key.toLowerCase() === 'q' || e.key.toLowerCase() === 'e') skillReq = true;
  }
  if (e.key === 'Escape' && (G.mode === 'play' || G.mode === 'pause')) togglePause();
});
addEventListener('keyup', e => { keys[e.key.toLowerCase()] = false; });

const SKILLICON = {
  savasci: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 3v10M8 9l4 4 4-4"/><path d="M3 19c3-2 6-2 9-2s6 0 9 2"/><path d="M5 15l-2-2M19 15l2-2"/></svg>',
  okcu: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 2v6M12 16v6M2 12h6M16 12h6M5 5l4 4M15 15l4 4M19 5l-4 4M9 15l-4 4"/></svg>',
  buyucu: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="8"/><path d="M12 2v4M12 18v4M2 12h4M18 12h4M12 9l2 3-2 3-2-3z"/></svg>',
};
// ================= Oyun durumu =================
const G = { mode: 'menu', t: 0, clearT: -1, slow: 0 };
let run = null, P1, enemies, shots, arrows, pending, texts, waves, warns, bots;
function runStats() {
  const s = calcStats(), b = run.buff;
  return { maxHp: Math.round(s.maxHp * b.hp), dmg: s.dmg * b.dmg, armor: s.armor, crit: Math.min(75, s.crit + b.crit), atk: s.atk * b.atk,
    spd: s.spd * b.spd, leech: s.leech + b.leech, gold: s.gold, exp: s.exp, cd: b.cd, multi: b.multi, reach: b.reach, luck: b.luck };
}
function newRunBase(extra) {
  run = Object.assign({ kills: 0, bag: { gold: 0, tas: 0, kor: 0, items: [] }, safe: { gold: 0, tas: 0, kor: 0, items: 0 }, expRun: 0, perfects: 0, stars: 0, floorsDone: 0,
    buff: { hp: 1, dmg: 1, atk: 1, spd: 1, crit: 0, leech: 0, cd: 1, multi: 0, reach: 1, luck: 1 } }, extra);
  P1 = { x: RW / 2, y: RH * 0.72, hp: 1, inv: 0, dashT: 0, dashCd: 0, fx: 0, fy: -1, fireT: 0, ax: 0, ay: -1, skillCd: 0, swing: 0, swingA: 0,
    lastDash: { t: -9, x: 0, y: 0 }, critN: 0, lastPerfect: -9, atkT: 0 };
  P1.hp = runStats().maxHp;
  $('skillIcon').innerHTML = SKILLICON[save.cls];
  G.mode = 'play'; show(null);
}
function startRun(ri_) { newRunBase({ kind: 'kat', region: ri_, floor: 0 }); nextFloor(); }
function mlv() {
  if (run.kind === 'acik') return OPEN.rooms[run.room].lvl;
  const R = REGIONS[run.region]; return R.min + (run.floor - 1) * (R.max - R.min) / 19;
}
function resetRoom() { enemies = []; shots = []; arrows = []; pending = []; texts = []; warns = []; bots = []; waves = []; G.clearT = -1; }
const BOSSNAME = ['Kül Bekçisi', 'Pas Golemi', 'Kök Devi'];
const EVENTAD = { goblin: 'Hazine Goblini görüldü! Kaçmadan yakala', tuzak: 'Tuzaklı kat: yerdeki kırmızı alanlardan kaç', karanlik: 'Karanlık kat: sadece meşalenin ışığı var' };
const AFFIXAD = { hizli: 'Hızlı', patlayan: 'Patlayan' };
function nextFloor() {
  run.floor++; resetRoom();
  P1.x = RW / 2; P1.y = RH * 0.74; P1.inv = 1.0;
  const n = run.floor, rg = run.region, boss = n === 10 || n === 20;
  if (boss) {
    waves.push([{ type: 'boss' }, ...Array(2 + rg + (n === 20 ? 2 : 0)).fill(0).map(() => ({ type: 'rat' }))]);
  } else {
    const count = 3 + Math.floor(n * 0.45) + rg;
    const make = c => Array.from({ length: c }, () => {
      const r = Math.random();
      if ((rg > 0 || n >= 5) && r < 0.22) return { type: 'archer' };
      if ((rg > 0 || n >= 3) && r < 0.42) return { type: 'guard' };
      return { type: 'rat' };
    });
    waves.push(make(count));
    if (n >= 4) waves.push(make(Math.ceil(count * 0.6)));
    // elitler
    const ne = n >= 8 ? 2 : n >= 3 ? 1 : 0;
    for (let i = 0; i < ne; i++) { const w = waves[waves.length - 1]; const q = w[ri(0, w.length - 1)]; q.elite = Math.random() < 0.5 ? 'hizli' : 'patlayan'; }
  }
  run.event = null;
  if (n >= 2 && n % 5 !== 0 && !boss && Math.random() < 0.35) run.event = ['goblin', 'tuzak', 'karanlik'][ri(0, 2)];
  if (run.event === 'goblin') pending.push({ x: rnd(80, 340), y: rnd(120, 320), type: 'goblin', t: 1.6 });
  run.trapT = 2;
  run.floorT = 0; run.floorHit = false;
  run.par = Math.round(16 + waves.reduce((a, w) => a + w.length, 0) * 2.4 + (boss ? 30 : 0));
  spawnWave(); updHud();
  floorTitle(REGIONS[rg].ad + ' · ' + n + '. kat', boss ? BOSSNAME[rg] + ' uyandı' : run.event ? EVENTAD[run.event] : (n % 5 === 0 ? 'Bu katın sonunda çıkış kapısı var' : ''));
}
let ftT = 0;
function floorTitle(a, b) {
  const el = $('floorCard'); $('fcA').textContent = a; $('fcB').textContent = b; $('fcB').hidden = !b;
  el.classList.remove('on'); void el.offsetWidth; el.classList.add('on');
  const f = $('fade'); f.classList.remove('on'); void f.offsetWidth; f.classList.add('on');
}
function spawnWave() {
  const w = waves.shift(); if (!w) return;
  w.forEach((s, i) => {
    let x, y, k = 0;
    do { x = 40 + Math.random() * (RW - 80); y = 40 + Math.random() * (RH * 0.6); k++; }
    while (Math.hypot(x - P1.x, y - P1.y) < 200 && k < 30);
    if (s.type === 'boss') { x = RW / 2; y = 160; }
    pending.push({ x, y, type: s.type, elite: s.elite, t: 0.9 + i * 0.1 });
  });
}
function makeEnemy(type, x, y, q) {
  const L = mlv(), bossHp = run.kind === 'kat' && run.floor === 20 ? 1.5 : run.kind === 'acik' ? 1.6 : 1;
  const b = {
    rat:    { r: 11, hp: 12 + L * 7,  sp: 92 + L * 1.2, h: 14, dmg: 5 + L * 1.8, c: C.rat, ct: C.ratTop, xp: 1, g: 1 },
    guard:  { r: 18, hp: 45 + L * 22, sp: 52, h: 30, dmg: 10 + L * 3.2, c: C.guard, ct: C.guardTop, xp: 1.8, g: 2 },
    archer: { r: 12, hp: 16 + L * 9,  sp: 72, h: 24, dmg: 6 + L * 2.2, c: C.archer, ct: C.archerTop, xp: 1.3, g: 1.5 },
    boss:   { r: 34, hp: (300 + L * 120) * bossHp, sp: 42, h: 58, dmg: 10 + L * 2.8, c: C.boss, ct: C.bossTop, xp: 15, g: 12 },
    goblin: { r: 10, hp: 30 + L * 14, sp: 128, h: 16, dmg: 0, c: '#d8b84a', ct: '#ffe39a', xp: 4, g: 30 },
  }[type];
  const e = Object.assign({ type, x, y, lvl: L, flash: 0, slow: 0, cd: 1 + Math.random() * 1.5, cd2: 3 + Math.random() * 3, dashT: 0, dvx: 0, dvy: 0, atkLock: 0, pdmg: 0, pat: 0, life: 13 }, b);
  if (q && q.elite) { e.elite = q.elite; e.hp *= 2.6; e.r *= 1.15; e.xp *= 2.2; e.g *= 2.5; if (e.elite === 'hizli') e.sp *= 1.55; }
  e.mhp = e.hp;
  return e;
}

// ================= Yardımcılar =================
const clamp = (v, a, b) => v < a ? a : v > b ? b : v;
function burstParts(x, y, col, n = 10, z = 10, sp = 120) { RN.burst(x, y, z, col, n, sp); }
function floatText(x, y, txt, col, big) { if (texts.length > 60) texts.shift(); texts.push({ x: x + rnd(-6, 6), y, z: 30, txt, col, t: 1, big }); }
let toastT = 0;
function toast(t) { const el = $('toast'); el.textContent = t; el.hidden = false; clearTimeout(toastT); toastT = setTimeout(() => { el.hidden = true; }, 2200); }
function hurtPlayer(d, srcLvl) {
  if (P1.inv > 0 || P1.dashT > 0 || G.mode !== 'play') return;
  const s = runStats(), red = s.armor / (s.armor + 40 + srcLvl * 6);
  const dmg = Math.max(1, Math.round(d * (1 - red)));
  P1.hp -= dmg; P1.inv = 0.4; run.floorHit = true;
  RN.ev('hurt', { x: P1.x, y: P1.y, k: Math.min(0.4, 0.12 + dmg / s.maxHp) }); flashHurt();
  floatText(P1.x, P1.y, '-' + dmg, C.bad);
  blip(110, 0.18, 'sawtooth', 0.06, 0.5);
  updHud();
  if (P1.hp <= 0) die();
}
function expPenalty() {
  const top = run.kind === 'acik' ? OPEN.rooms[run.room].lvl + 4 : REGIONS[run.region].max;
  const diff = save.lvl - top;
  return diff >= 8 ? 0.1 : diff >= 4 ? 0.5 : 1;
}
const lootMul = () => run.kind === 'acik' ? 1.5 : 1;
function killEnemy(e, byBot) {
  e.dead = true;
  if (e.elite === 'patlayan') warn({ kind: 'c', x: e.x, y: e.y, r: 78, t: 0.9, dmg: e.dmg * 1.6, lvl: e.lvl, col: 'fire' });
  if (e.type === 'boss' && run.kind === 'acik') run.lairCd = 45;
  RN.ev('kill', { x: e.x, y: e.y, col: e.type === 'boss' ? '#ffb04a' : e.c, boss: e.type === 'boss' });
  if (byBot && !(e.pdmg > 0)) { blip(300, 0.06, 'triangle', 0.02, 0.6); return; }
  run.kills++;
  const s = runStats(), LM = lootMul();
  const xp = Math.round((5 + e.lvl * 2) * e.xp * s.exp * expPenalty());
  gainExp(xp); run.expRun += xp;
  const gold = Math.round((2 + e.lvl) * e.g * rnd(0.7, 1.3) * s.gold * LM);
  run.bag.gold += gold;
  floatText(e.x, e.y - 4, '+' + gold, C.gold);
  if (Math.random() < (e.type === 'boss' ? 1 : 0.12 * LM)) { const n = e.type === 'boss' ? Math.round(ri(3, 5) * LM) : 1; run.bag.tas += n; floatText(e.x, e.y + 8, '+' + n + ' Basma Taşı', '#d7c7b8'); }
  if (e.type === 'boss') { const n = Math.round((ri(1, 2) + (run.floor === 20 ? 1 : 0)) * LM); run.bag.kor += n; floatText(e.x, e.y + 20, '+' + n + ' Kor Tozu', C.bossTop); }
  else if (e.lvl >= 20 && Math.random() < 0.01 * LM) { run.bag.kor++; floatText(e.x, e.y + 20, '+1 Kor Tozu', C.bossTop); }
  const chance = ({ rat: 0.05, archer: 0.08, guard: 0.12, boss: 1, goblin: 1 })[e.type] * s.luck * LM;
  let drops = e.type === 'boss' ? (run.floor === 20 ? 3 : 2) : e.type === 'goblin' ? 2 : (Math.random() < chance ? 1 : 0);
  if (e.elite) drops++;
  if (e.type === 'goblin') { toast('Hazine Goblini yakalandı!'); blip(1400, 0.3, 'triangle', 0.06, 1.4); }
  for (let i = 0; i < drops; i++) {
    const it = makeItem(Math.max(1, Math.round(e.lvl)), e.type === 'boss' || e.type === 'goblin' || (e.elite && i === drops - 1));
    run.bag.items.push(it);
    floatText(e.x, e.y - 18 - i * 12, RNAME[it.r] + ' ' + it.name, RCOL[it.r], true);
    if (it.r >= 1) RN.ev('loot', { x: e.x + rnd(-15, 15), y: e.y + rnd(-15, 15), col: RCOL[it.r] });
    if (it.r >= 2) blip(1200, 0.25, 'sine', 0.05, 1.3);
  }
  RN.ev('gold', { x: e.x, y: e.y });
  blip(330, 0.08, 'triangle', 0.05, 0.6);
  updHud();
}
function hitEnemy(e, base, silent) {
  if (e.dead) return;
  const s = runStats(), forced = P1.critN > 0, crit = forced || Math.random() * 100 < s.crit, d = Math.round(base * (crit ? (forced ? 2.2 : 1.8) : 1) * rnd(0.9, 1.1));
  if (forced) P1.critN--;
  e.hp -= d; e.pdmg += d; e.flash = 0.08; RN.ev('hit', { x: e.x, y: e.y, crit });
  if (!silent || crit) floatText(e.x, e.y - e.h * 0.3, (crit ? d + '!' : '' + d), crit ? C.crit : '#f3e9df', crit);
  if (s.leech) P1.hp = Math.min(s.maxHp, P1.hp + d * s.leech / 100);
  if (e.hp <= 0) killEnemy(e, false);
}
function botHit(e, d) {
  if (e.dead) return;
  e.hp -= d; e.flash = 0.06; RN.ev('hit', { x: e.x, y: e.y, crit: false });
  if (e.hp <= 0) killEnemy(e, true);
}
function nearest(range = 1e9) {
  let tgt = null, best = range;
  for (const e of enemies) { if (e.dead) continue; const d = Math.hypot(e.x - P1.x, e.y - P1.y) - e.r; if (d < best) { best = d; tgt = e; } }
  return tgt;
}
// ---------- uyarı alanları (atılarak kaçılabilen saldırılar) ----------
function warn(o) { o.t0 = o.t; warns.push(o); return o; }
function inWarn(w, x, y) {
  if (w.kind === 'c') return Math.hypot(x - w.x, y - w.y) < w.r + PR * 0.5;
  const dx = w.x2 - w.x, dy = w.y2 - w.y, L2 = dx * dx + dy * dy || 1;
  const k = clamp(((x - w.x) * dx + (y - w.y) * dy) / L2, 0, 1);
  return Math.hypot(x - (w.x + dx * k), y - (w.y + dy * k)) < w.w / 2 + PR * 0.5;
}
function resolveWarn(w) {
  if (w.fn) w.fn(w);
  if (!w.dmg) return;
  if (w.kind === 'c') RN.ev('impact', { x: w.x, y: w.y, r: w.r, fire: w.col === 'fire' });
  const p = P1, inside = inWarn(w, p.x, p.y), ld = p.lastDash, recent = G.t - ld.t < 0.45;
  if ((inside && p.dashT > 0) || (!inside && recent && inWarn(w, ld.x, ld.y))) perfectDodge();
  else if (inside) hurtPlayer(w.dmg, w.lvl);
}
function perfectDodge() {
  if (G.t - P1.lastPerfect < 0.6) return;
  P1.lastPerfect = G.t; G.slow = 0.9; P1.critN = 3; run.perfects++;
  floatText(P1.x, P1.y - 12, 'Kusursuz kaçış!', '#7ff0ff', true);
  RN.ev('perfect', { x: P1.x, y: P1.y });
  const el = $('slowFx'); el.classList.remove('on'); void el.offsetWidth; el.classList.add('on');
  blip(1500, 0.25, 'sine', 0.06, 0.5); setTimeout(() => blip(2000, 0.2, 'sine', 0.04, 0.7), 80);
}

// ================= Açık bölge =================
const OPEN = { ad: 'Sınır Toprakları', rooms: [
  { ad: 'Kamp', gx: 0, gy: 2, lvl: 1, camp: 1 },
  { ad: 'Küllü Patika', gx: 1, gy: 2, lvl: 3 },
  { ad: 'Yanık Koru', gx: 2, gy: 2, lvl: 6 },
  { ad: 'Taş Ocağı', gx: 2, gy: 1, lvl: 9 },
  { ad: 'Paslı Köprü', gx: 3, gy: 1, lvl: 12 },
  { ad: 'Çökük Kule', gx: 3, gy: 0, lvl: 15 },
  { ad: 'Sis Bataklığı', gx: 4, gy: 1, lvl: 18 },
  { ad: 'Kök Vadisi', gx: 4, gy: 2, lvl: 22 },
  { ad: 'Kemik Tarlası', gx: 5, gy: 2, lvl: 26 },
  { ad: 'Ejder Mağarası', gx: 5, gy: 1, lvl: 30, lair: 1 },
] };
const CAMP_PORTAL = { x: 210, y: 150 };
function roomAt(gx, gy) { return OPEN.rooms.findIndex(r => r.gx === gx && r.gy === gy); }
function doorsOf(i) { const r = OPEN.rooms[i]; return { n: roomAt(r.gx, r.gy - 1), s: roomAt(r.gx, r.gy + 1), w: roomAt(r.gx - 1, r.gy), e: roomAt(r.gx + 1, r.gy) }; }
const roomPal = i => { const l = OPEN.rooms[i].lvl; return l < 10 ? 0 : l < 20 ? 1 : 2; };
const BOTNAMES = ['Kartal', 'Atlas', 'Mira', 'Bozkurt', 'Eflin', 'Kılıçaslan', 'Toprak', 'Ilgaz', 'Defne', 'Barlas', 'Nehir', 'Alp', 'Sarp', 'Lale', 'Börü', 'Ece'];
function startOpen() {
  newRunBase({ kind: 'acik', region: 0, room: 0, visited: { 0: 1 }, respawn: 2, lairCd: 0 });
  enterRoom(0, null);
  toast('Kapılardan geçerek odalar arasında dolaş. Kamptaki geçit seni kasabaya götürür.');
}
function roomTarget(i) { const r = OPEN.rooms[i]; return r.camp ? 0 : 4 + Math.floor(r.lvl / 7); }
function enterRoom(i, from) {
  run.room = i; run.region = roomPal(i); run.visited[i] = 1; resetRoom();
  const r = OPEN.rooms[i];
  if (from === 'w') { P1.x = 34; P1.y = RH / 2; } else if (from === 'e') { P1.x = RW - 34; P1.y = RH / 2; }
  else if (from === 'n') { P1.x = RW / 2; P1.y = 34; } else if (from === 's') { P1.x = RW / 2; P1.y = RH - 34; }
  else { P1.x = RW / 2; P1.y = 260; }
  P1.inv = 0.8;
  for (let k = 0; k < roomTarget(i); k++) spawnOpenEnemy(0.3 + k * 0.15);
  if (r.lair && run.lairCd <= 0) pending.push({ x: RW / 2, y: 200, type: 'boss', t: 1.2 });
  const nb = r.camp ? ri(3, 4) : ri(1, 3), names = BOTNAMES.slice().sort(() => Math.random() - 0.5);
  for (let k = 0; k < nb; k++) {
    const cls = ['savasci', 'okcu', 'buyucu'][ri(0, 2)];
    bots.push({ name: names[k], clan: ['', 'KOR', 'GECE', 'ASİL', ''][ri(0, 4)], cls, lvl: clamp(r.lvl + ri(-2, 5), 1, 80),
      of: OUTFITS[ri(1, OUTFITS.length - 1)], x: rnd(80, 340), y: r.camp ? rnd(320, 520) : rnd(200, 700), fx: 0, fy: 1, fireT: rnd(0, 1), tx: 0, ty: 0, wait: rnd(0, 2), atkT: 0 });
  }
  floorTitle(OPEN.ad + ' · ' + r.ad, r.camp ? 'Güvenli bölge · geçit kasabaya döner' : 'Seviye ' + r.lvl + ' · herkese açık · ganimet 1,5 kat');
  updHud();
}
function spawnOpenEnemy(delay) {
  const r = OPEN.rooms[run.room];
  let x, y, k = 0;
  do { x = 50 + Math.random() * (RW - 100); y = 60 + Math.random() * (RH - 120); k++; } while (Math.hypot(x - P1.x, y - P1.y) < 220 && k < 30);
  const q = Math.random();
  const type = r.lvl >= 8 && q < 0.25 ? 'archer' : r.lvl >= 5 && q < 0.5 ? 'guard' : 'rat';
  pending.push({ x, y, type, t: delay || 0.8, elite: Math.random() < 0.12 ? (Math.random() < 0.5 ? 'hizli' : 'patlayan') : null });
}
function updateOpen(dt) {
  const r = OPEN.rooms[run.room], d = doorsOf(run.room), p = P1;
  // kapılar
  const mid = 50;
  if (p.x <= PR + 1 && d.w >= 0 && Math.abs(p.y - RH / 2) < mid) return enterRoom(d.w, 'e');
  if (p.x >= RW - PR - 1 && d.e >= 0 && Math.abs(p.y - RH / 2) < mid) return enterRoom(d.e, 'w');
  if (p.y <= PR + 1 && d.n >= 0 && Math.abs(p.x - RW / 2) < mid) return enterRoom(d.n, 's');
  if (p.y >= RH - PR - 1 && d.s >= 0 && Math.abs(p.x - RW / 2) < mid) return enterRoom(d.s, 'n');
  // kamp geçidi
  if (r.camp && Math.hypot(p.x - CAMP_PORTAL.x, p.y - CAMP_PORTAL.y) < 34) { const sold = bank(); endRun('camp', sold); return; }
  // yeniden doğma
  run.respawn -= dt; run.lairCd -= dt;
  if (run.respawn <= 0) {
    run.respawn = 3.5;
    if (enemies.filter(e => !e.dead && e.type !== 'boss').length + pending.length < roomTarget(run.room)) spawnOpenEnemy(0.9);
    if (r.lair && run.lairCd <= 0 && !enemies.some(e => e.type === 'boss' && !e.dead) && !pending.some(q => q.type === 'boss')) { pending.push({ x: RW / 2, y: 200, type: 'boss', t: 1.5 }); toast('Ejder Mağarası bekçisi yeniden doğuyor!'); run.lairCd = 999; }
  }
  // diğer oyuncular (örnek)
  for (const b of bots) {
    b.fireT -= dt; b.atkT = Math.max(0, b.atkT - dt);
    let tgt = null, bd = 320;
    for (const e of enemies) { if (e.dead) continue; const dd = Math.hypot(e.x - b.x, e.y - b.y); if (dd < bd) { bd = dd; tgt = e; } }
    const melee = b.cls === 'savasci', range = melee ? 34 : 170;
    if (tgt && !r.camp) {
      const dx = tgt.x - b.x, dy = tgt.y - b.y, dd = Math.hypot(dx, dy) || 1;
      b.fx = dx / dd; b.fy = dy / dd;
      if (dd > range) { b.x += dx / dd * 120 * dt; b.y += dy / dd * 120 * dt; }
      if (b.fireT <= 0 && dd < range + 20) {
        b.fireT = rnd(0.7, 1.1); b.atkT = 0.25;
        const dmg = 6 + b.lvl * 2.2;
        if (melee) { RN.ev('swing', { x: b.x, y: b.y, a: Math.atan2(dy, dx), r: 50, col: '#ffd2a8' }); botHit(tgt, dmg); }
        else shots.push({ x: b.x, y: b.y, vx: dx / dd * 380, vy: dy / dd * 380, t: 1.2, pierce: 0, hit: new Set(), dmg, kind: b.cls === 'okcu' ? 'arrow' : 'bolt', bot: 1 });
      }
    } else {
      b.wait -= dt;
      if (b.wait <= 0) { b.tx = rnd(80, 340); b.ty = r.camp ? rnd(300, 560) : rnd(150, 700); b.wait = rnd(2, 5); }
      const dx = b.tx - b.x, dy = b.ty - b.y, dd = Math.hypot(dx, dy);
      if (dd > 4) { b.x += dx / dd * 60 * dt; b.y += dy / dd * 60 * dt; b.fx = dx / dd; b.fy = dy / dd; }
    }
    b.x = clamp(b.x, PR, RW - PR); b.y = clamp(b.y, PR, RH - PR);
  }
}

// ================= Güncelleme =================
let hudT = 0;
function update(dt) {
  G.t += dt;
  const s = runStats(), p = P1, cls = CLASSES[save.cls];
  let mx = joy.dx, my = joy.dy;
  if (keys.a || keys.arrowleft) mx -= 1; if (keys.d || keys.arrowright) mx += 1;
  if (keys.w || keys.arrowup) my -= 1; if (keys.s || keys.arrowdown) my += 1;
  let ml = Math.hypot(mx, my); if (ml > 1) { mx /= ml; my /= ml; ml = 1; }
  if (ml > 0.15) { p.fx = mx / ml; p.fy = my / ml; }
  p.dashCd -= dt; p.inv -= dt; p.skillCd -= dt; p.swing -= dt; p.atkT = Math.max(0, p.atkT - dt);
  const speed = 150 * s.spd;
  if (dashReq && p.dashCd <= 0) {
    p.dashT = 0.2; p.dashCd = 0.95; p.lastDash = { t: G.t, x: p.x, y: p.y };
    blip(700, 0.08, 'sine', 0.05, 0.4); RN.ev('dash', { x: p.x, y: p.y });
  }
  dashReq = false;
  if (p.dashT > 0) { p.dashT -= dt; p.x += p.fx * speed * 3.3 * dt; p.y += p.fy * speed * 3.3 * dt; }
  else { p.x += mx * speed * dt; p.y += my * speed * dt; }
  p.x = clamp(p.x, PR, RW - PR); p.y = clamp(p.y, PR, RH - PR);
  $('dash').classList.toggle('cool', p.dashCd > 0);
  $('skill').classList.toggle('cool', p.skillCd > 0);
  const cdk = p.skillCd > 0 ? p.skillCd / (cls.cd * s.cd) : 0;
  $('skill').style.setProperty('--cd', (cdk * 360) + 'deg');
  $('skillName').textContent = p.skillCd > 0 ? Math.ceil(p.skillCd) : '';

  if (run.kind === 'acik') { updateOpen(dt); if (G.mode !== 'play') return; }
  if (run.kind === 'kat') {
    if (!G.clearT || G.clearT < 0) run.floorT += dt;
    if (run.event === 'tuzak') {
      run.trapT -= dt;
      if (run.trapT <= 0) {
        run.trapT = 2.3; const L = mlv();
        for (let i = 0; i < 4; i++) {
          const near = i < 2, x = near ? p.x + rnd(-70, 70) : rnd(40, RW - 40), y = near ? p.y + rnd(-70, 70) : rnd(60, RH - 60);
          warn({ kind: 'c', x: clamp(x, 30, RW - 30), y: clamp(y, 30, RH - 30), r: 40, t: 1.1, dmg: 6 + L * 2.2, lvl: L, col: 'trap' });
        }
      }
    }
  }

  for (const q of pending) { q.t -= dt; if (q.t <= 0) { enemies.push(makeEnemy(q.type, q.x, q.y, q)); RN.ev('spawn', { x: q.x, y: q.y }); } }
  pending = pending.filter(q => q.t > 0);

  // yetenek
  if (skillReq && p.skillCd <= 0) {
    p.skillCd = cls.cd * s.cd;
    if (cls.kind === 'melee') {
      RN.ev('shock', { x: p.x, y: p.y, r: 100 }); p.swing = 0.16; p.swingA = 0;
      for (const e of enemies) { const dx = e.x - p.x, dy = e.y - p.y, d = Math.hypot(dx, dy) || 1; if (d < 100 + e.r) { hitEnemy(e, s.dmg * 2.5); if (e.type !== 'boss') { e.x += dx / d * 60; e.y += dy / d * 60; e.atkLock = 0.6; } } }
      blip(90, 0.3, 'sawtooth', 0.08, 0.4);
    } else if (cls.kind === 'arrow') {
      for (let i = 0; i < 16; i++) { const a = i / 16 * 6.283; shots.push({ x: p.x, y: p.y, vx: Math.cos(a) * 420, vy: Math.sin(a) * 420, t: 1.2, pierce: 2, hit: new Set(), dmg: s.dmg * 1.5, kind: 'arrow' }); }
      RN.ev('volley', { x: p.x, y: p.y }); p.atkT = 0.3; blip(900, 0.15, 'square', 0.04, 0.5);
    } else {
      RN.ev('ice', { x: p.x, y: p.y, r: 130 }); p.atkT = 0.4;
      for (const e of enemies) if (Math.hypot(e.x - p.x, e.y - p.y) < 130 + e.r) { hitEnemy(e, s.dmg * 1.8); e.slow = 3; }
      blip(1300, 0.3, 'sine', 0.06, 0.4);
    }
  }
  skillReq = false;

  // otomatik saldırı
  p.fireT -= dt;
  const reach = 62 * s.reach;
  const tgt = cls.kind === 'melee' ? nearest(reach + 8) : nearest(420);
  const any = nearest();
  if (any) { const a = Math.atan2(any.y - p.y, any.x - p.x); p.ax = Math.cos(a); p.ay = Math.sin(a); }
  if (tgt && p.fireT <= 0) {
    p.fireT = 1 / (cls.rate * s.atk);
    const a0 = Math.atan2(tgt.y - p.y, tgt.x - p.x);
    if (cls.kind === 'melee') {
      p.swing = 0.16; p.swingA = a0; RN.ev('swing', { x: p.x, y: p.y, a: a0, r: reach + 10, col: cls.top });
      for (const e of enemies) {
        if (e.dead) continue;
        const dx = e.x - p.x, dy = e.y - p.y, d = Math.hypot(dx, dy);
        let da = Math.abs(Math.atan2(dy, dx) - a0); if (da > Math.PI) da = 6.283 - da;
        if (d < reach + e.r && da < 1.1) hitEnemy(e, s.dmg);
      }
      blip(240, 0.06, 'square', 0.03, 0.5);
    } else {
      const n = 1 + s.multi;
      for (let i = 0; i < n; i++) {
        const a = a0 + (i - (n - 1) / 2) * 0.16, v = cls.kind === 'arrow' ? 440 : 300;
        shots.push({ x: p.x, y: p.y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, t: 1.4, pierce: 0, hit: new Set(), dmg: s.dmg, kind: cls.kind });
      }
      p.atkT = 0.25; if (cls.kind === 'bolt') RN.ev('cast', { x: p.x, y: p.y });
      blip(cls.kind === 'arrow' ? 880 : 520, 0.04, cls.kind === 'arrow' ? 'square' : 'sine', 0.02, 0.7);
    }
  }

  // mermiler
  for (const b of shots) {
    b.x += b.vx * dt; b.y += b.vy * dt; b.t -= dt;
    if (b.x < 0 || b.x > RW || b.y < 0 || b.y > RH) b.t = 0;
    for (const e of enemies) {
      if (e.dead || b.t <= 0 || b.hit.has(e)) continue;
      if (Math.hypot(e.x - b.x, e.y - b.y) < e.r + 5) {
        b.hit.add(e);
        if (b.bot) { botHit(e, b.dmg); b.t = 0; continue; }
        if (b.kind === 'bolt') {
          RN.ev('boom', { x: b.x, y: b.y, r: 42 });
          for (const o of enemies) if (!o.dead && Math.hypot(o.x - b.x, o.y - b.y) < 42 + o.r) hitEnemy(o, o === e ? b.dmg : b.dmg * 0.6, o !== e);
          b.t = 0;
        } else {
          hitEnemy(e, b.dmg);
          if (b.pierce-- <= 0) b.t = 0;
        }
      }
    }
  }
  shots = shots.filter(b => b.t > 0);

  // düşmanlar: her saldırı önce yerde uyarı olarak görünür, atılarak kaçılabilir
  for (const e of enemies) {
    if (e.dead) continue;
    e.flash -= dt; e.slow -= dt; e.cd -= dt; e.cd2 -= dt; e.atkLock = Math.max(0, e.atkLock - dt);
    const slowK = e.slow > 0 ? 0.45 : 1, sp = e.sp * slowK;
    const dx = p.x - e.x, dy = p.y - e.y, d = Math.hypot(dx, dy) || 1, ux = dx / d, uy = dy / d;
    const L = e.lvl;
    if (e.dashT > 0) { e.dashT -= dt; e.x += e.dvx * dt; e.y += e.dvy * dt; }
    else if (e.type === 'rat') {
      if (d < 95 && e.cd <= 0 && !e.atkLock) {
        const len = 95; e.cd = 1.7 / (e.elite === 'hizli' ? 1.4 : 1); e.atkLock = 0.6;
        warn({ kind: 'l', x: e.x, y: e.y, x2: e.x + ux * len, y2: e.y + uy * len, w: 28, t: 0.55 / slowK, dmg: e.dmg, lvl: L, fn: () => { if (!e.dead) { e.dashT = 0.16; e.dvx = ux * len / 0.16; e.dvy = uy * len / 0.16; } } });
      } else if (!e.atkLock && d > 30) { e.x += ux * sp * dt; e.y += uy * sp * dt; }
    } else if (e.type === 'guard') {
      if (d < 100 && e.cd <= 0 && !e.atkLock) {
        e.cd = 2.4; e.atkLock = 1.0;
        warn({ kind: 'c', x: e.x + ux * 42, y: e.y + uy * 42, r: 52, t: 0.85 / slowK, dmg: e.dmg, lvl: L });
      } else if (d > 170 && d < 330 && e.cd2 <= 0 && !e.atkLock) {
        const len = Math.min(d + 50, 280); e.cd2 = 6; e.atkLock = 1.4;
        warn({ kind: 'l', x: e.x, y: e.y, x2: e.x + ux * len, y2: e.y + uy * len, w: 40, t: 0.9 / slowK, dmg: e.dmg * 1.2, lvl: L, fn: () => { if (!e.dead) { e.dashT = 0.32; e.dvx = ux * len / 0.32; e.dvy = uy * len / 0.32; } } });
      } else if (!e.atkLock && d > 48) { e.x += ux * sp * dt; e.y += uy * sp * dt; }
    } else if (e.type === 'archer') {
      const want = d < 170 ? -1 : d > 270 ? 1 : 0;
      if (!e.atkLock) { e.x += ux * sp * want * dt + Math.cos(G.t + e.r) * 20 * dt; e.y += uy * sp * want * dt; }
      if (e.cd <= 0 && d < 420) {
        e.cd = 2.5; e.atkLock = 0.7;
        warn({ kind: 'l', x: e.x, y: e.y, x2: e.x + ux * 460, y2: e.y + uy * 460, w: 8, t: 0.65 / slowK, aim: 1, fn: () => { if (!e.dead) arrows.push({ x: e.x, y: e.y, vx: ux * 400, vy: uy * 400, t: 2, dmg: e.dmg, lvl: L }); blip(300, 0.05, 'triangle', 0.025, 1.5); } });
      }
    } else if (e.type === 'goblin') {
      e.life -= dt;
      if (e.life <= 0) { e.dead = true; floatText(e.x, e.y, 'Goblin kaçtı!', '#ffe39a', true); RN.ev('poof', { x: e.x, y: e.y }); continue; }
      const fl = d < 260 ? -1 : 0.2;
      e.x += (ux * fl + Math.cos(G.t * 1.7 + e.r) * 0.6) * sp * dt; e.y += (uy * fl + Math.sin(G.t * 1.3) * 0.6) * sp * dt;
    } else if (e.type === 'boss') {
      const ph2 = e.hp < e.mhp / 2;
      if (!e.atkLock) { e.x += ux * sp * dt; e.y += uy * sp * dt; }
      if (e.cd <= 0) {
        const pat = e.pat++ % 3; e.cd = (ph2 ? 2.2 : 3.0);
        if (pat === 0) {
          const k = ph2 ? 16 : 12, off = Math.random();
          for (let i = 0; i < k; i++) { const a = (i + off) / k * 6.283; arrows.push({ x: e.x, y: e.y, vx: Math.cos(a) * 150, vy: Math.sin(a) * 150, t: 4, dmg: e.dmg, lvl: L, orb: true }); }
          blip(160, 0.2, 'sawtooth', 0.05, 0.6);
        } else if (pat === 1) {
          e.atkLock = 1.2;
          const n = ph2 ? 5 : 3;
          for (let i = 0; i < n; i++) warn({ kind: 'c', x: clamp(p.x + rnd(-50, 50) * (i > 0 ? 1 : 0), 30, RW - 30), y: clamp(p.y + rnd(-50, 50) * (i > 0 ? 1 : 0), 30, RH - 30), r: 62, t: 0.95 + i * 0.32, dmg: e.dmg * 1.3, lvl: L, col: 'fire' });
        } else {
          const len = 320; e.atkLock = 1.6;
          warn({ kind: 'l', x: e.x, y: e.y, x2: e.x + ux * len, y2: e.y + uy * len, w: 70, t: 1.0, dmg: e.dmg * 1.6, lvl: L, fn: () => { if (!e.dead) { e.dashT = 0.4; e.dvx = ux * len / 0.4; e.dvy = uy * len / 0.4; RN.addShake(0.25); } } });
        }
      }
    }
    e.x = clamp(e.x, e.r, RW - e.r); e.y = clamp(e.y, e.r, RH - e.r);
    // temas hasar vermez, sadece iter
    if (e.type !== 'goblin' && d < e.r + PR) { const push = (e.r + PR - d); p.x = clamp(p.x + ux * push, PR, RW - PR); p.y = clamp(p.y + uy * push, PR, RH - PR); }
  }
  for (let i = 0; i < enemies.length; i++) for (let j = i + 1; j < enemies.length; j++) {
    const a = enemies[i], b = enemies[j]; if (a.dead || b.dead || a.dashT > 0 || b.dashT > 0) continue;
    const dx = b.x - a.x, dy = b.y - a.y, d = Math.hypot(dx, dy) || 0.01, m = a.r + b.r;
    if (d < m) { const k = (m - d) / 2 / d; a.x -= dx * k; a.y -= dy * k; b.x += dx * k; b.y += dy * k; }
  }
  enemies = enemies.filter(e => !e.dead);

  // uyarılar
  for (const w of warns) { w.t -= dt; if (w.t <= 0 && !w.done) { w.done = true; resolveWarn(w); } }
  warns = warns.filter(w => !w.done);

  for (const a of arrows) {
    a.x += a.vx * dt; a.y += a.vy * dt; a.t -= dt;
    if (a.x < 0 || a.x > RW || a.y < 0 || a.y > RH) a.t = 0;
    if (G.mode === 'play' && Math.hypot(p.x - a.x, p.y - a.y) < PR + (a.orb ? 4 : 0)) {
      a.t = 0;
      if (p.dashT > 0) perfectDodge(); else hurtPlayer(a.dmg, a.lvl);
    }
  }
  arrows = arrows.filter(a => a.t > 0);

  for (const q of texts) { q.t -= dt; q.z += 34 * dt; }
  texts = texts.filter(q => q.t > 0);
  updHpOnly();
  hudT -= dt; if (hudT <= 0) { hudT = 0.25; updTimer(); }

  if (run.kind === 'kat' && G.mode === 'play' && !enemies.some(e => e.type !== 'goblin') && !pending.some(q => q.type !== 'goblin')) {
    if (waves.length) spawnWave();
    else if (G.clearT < 0) G.clearT = 0.8;
  }
  if (G.clearT > 0) { G.clearT -= dt; if (G.clearT <= 0) floorCleared(); }
}
function updTimer() {
  const el = $('hTime');
  if (!run || run.kind !== 'kat') { el.hidden = true; return; }
  el.hidden = false;
  const over = run.floorT > run.par;
  el.innerHTML = `<b class="${over ? 'down' : ''}">${Math.floor(run.floorT)}</b>/${run.par} sn · ${run.floorHit ? '<span class="down">hasar aldın</span>' : '<span class="up">hasarsız</span>'}`;
}

// ================= Ekranlar =================
const LAYERS = ['create', 'town', 'inv', 'forge', 'gate', 'end', 'pcard'];
function show(id) {
  LAYERS.forEach(l => { $(l).hidden = l !== id; });
  const inRun = run && (id === null || id === 'gate');
  $('hud').hidden = !inRun; $('dash').hidden = id !== null || !run; $('skill').hidden = id !== null || !run;
  $('thud').hidden = !(G.mode === 'town' && id === null); if (id !== null || G.mode !== 'town') $('ctx').hidden = true;
}
function updHpOnly() {
  const s = runStats(), k = clamp(P1.hp / s.maxHp, 0, 1);
  $('hHp').style.width = (k * 100) + '%'; $('hHpT').textContent = Math.max(0, Math.ceil(P1.hp)) + ' / ' + s.maxHp;
}
function updHud() {
  if (!run) return;
  $('hLv').textContent = save.lvl; $('hExp').style.width = (save.lvl >= MAXLV ? 100 : save.exp / need(save.lvl) * 100) + '%';
  if (run.kind === 'acik') { const r = OPEN.rooms[run.room]; $('hRegion').textContent = OPEN.ad; $('hPlace').innerHTML = '<b>' + r.ad + '</b> · Sv ' + r.lvl; }
  else { $('hRegion').textContent = REGIONS[run.region].ad; $('hPlace').innerHTML = 'Kat <b>' + run.floor + '</b>/20'; }
  $('hGold').textContent = run.bag.gold; $('hItems').textContent = run.bag.items.length;
  updHpOnly();
}
function bank() {
  const b = run.bag;
  save.gold += b.gold; save.tas += b.tas; save.kor += b.kor;
  let sold = 0;
  for (const it of b.items) { if (save.inv.length < INV) save.inv.push(it); else { save.gold += sellPrice(it); sold++; } }
  run.safe.gold += b.gold; run.safe.tas += b.tas; run.safe.kor += b.kor; run.safe.items += b.items.length;
  run.bag = { gold: 0, tas: 0, kor: 0, items: [] };
  persist(); updHud();
  return sold;
}
function floorCleared() {
  const s = runStats();
  P1.hp = Math.min(s.maxHp, P1.hp + s.maxHp * 0.25);
  const bonus = Math.round((10 + mlv() * 4) * s.exp * expPenalty()); gainExp(bonus); run.expRun += bonus;
  floatText(P1.x, P1.y, '+' + bonus + ' EXP', C.exp, true);
  // yıldızlar: geçmek 1, hasarsız +1, hedef sürede +1
  const noHit = !run.floorHit, fast = run.floorT <= run.par, stars = 1 + (noHit ? 1 : 0) + (fast ? 1 : 0);
  run.stars += stars; run.floorsDone++;
  let msg = '★'.repeat(stars) + '☆'.repeat(3 - stars) + ' ' + run.floor + '. kat';
  if (stars >= 2) { const g = Math.round((10 + mlv() * 3) * stars * s.gold); run.bag.gold += g; msg += ' · +' + g + ' altın'; }
  if (stars === 3) {
    const it = makeItem(Math.max(1, Math.round(mlv())), Math.random() < 0.35); run.bag.items.push(it);
    msg += ' · ödül sandığı: ' + RNAME[it.r] + ' ' + it.name; RN.ev('loot', { x: P1.x, y: P1.y, col: RCOL[it.r] });
    blip(880, 0.12, 'triangle', 0.06, 1.5); setTimeout(() => blip(1320, 0.2, 'triangle', 0.05), 120);
  }
  toast(msg + (stars < 3 ? (noHit ? '' : ' · hasarsız bitirirsen +1 yıldız') + (fast ? '' : ' · ' + run.par + ' sn altında +1 yıldız') : ''));
  save.best[run.region] = Math.max(save.best[run.region] || 0, run.floor);
  blip(660, 0.12, 'triangle', 0.06, 1.5); setTimeout(() => blip(990, 0.15, 'triangle', 0.05), 110);
  updHud();
  if (run.floor === 20) { const sold = bank(); endRun('done', sold); return; }
  if (run.floor % 5 === 0) {
    const b = run.bag, sold = bank();
    $('gateTitle').textContent = run.floor + '. kat · Çıkış kapısı';
    $('gateText').textContent = 'Güvene alındı: ' + b.gold + ' altın, ' + b.items.length + ' eşya' + (b.tas ? ', ' + b.tas + ' Basma Taşı' : '') + (b.kor ? ', ' + b.kor + ' Kor Tozu' : '') + '.' + (sold ? ' Çanta dolu olduğu için ' + sold + ' eşya satıldı.' : '');
    G.mode = 'gate'; show('gate'); persist(); return;
  }
  nextFloor();
}
$('gateGo').onclick = () => { G.mode = 'play'; show(null); nextFloor(); };
$('gateOut').onclick = () => endRun('out', 0);
function die() {
  if (G.mode !== 'play') return;
  G.mode = 'dying';
  const b = run.bag, keep = { gold: Math.floor(b.gold / 2), tas: Math.floor(b.tas / 2), kor: Math.floor(b.kor / 2) };
  const items = b.items.slice().sort(() => Math.random() - 0.5);
  const kept = items.slice(0, Math.floor(items.length / 2));
  const lost = { gold: b.gold - keep.gold, items: items.length - kept.length, tas: b.tas - keep.tas, kor: b.kor - keep.kor };
  run.bag = { gold: keep.gold, tas: keep.tas, kor: keep.kor, items: kept };
  const sold = bank();
  blip(220, 0.5, 'sawtooth', 0.07, 0.3);
  setTimeout(() => endRun('dead', sold, lost), 500);
}
function endRun(kind, sold, lost) {
  G.mode = 'end';
  $('endTitle').textContent = kind === 'dead' ? 'Düştün' : kind === 'done' ? 'Bölge tamamlandı' : kind === 'camp' ? 'Kasabaya döndün' : 'Ganimetle çıktın';
  $('endText').textContent = kind === 'dead' ? (run.kind === 'acik' ? 'Kampa dönmeden topladıklarının yarısı kayboldu. EXP\'n duruyor.' : 'Son çıkış kapısından sonra topladıklarının yarısı kayboldu. EXP\'n duruyor.')
    : kind === 'done' ? REGIONS[run.region].ad + ' bölgesinin 20 katını da geçtin.' : 'Ganimetin kasabada, güvende.';
  const r = run.safe, rows = [
    run.kind === 'acik' ? ['Gezilen oda', Object.keys(run.visited).length + '/10'] : ['Ulaşılan kat', run.floor], ['Öldürme', run.kills], ['Kazanılan EXP', run.expRun],
    ['Kusursuz kaçış', run.perfects],
    ['Kasaya giren altın', r.gold], ['Kasaya giren eşya', r.items], ['Basma Taşı / Kor Tozu', r.tas + ' / ' + r.kor],
  ];
  if (run.kind === 'kat' && run.floorsDone) rows.splice(3, 0, ['Toplam yıldız', run.stars + '/' + run.floorsDone * 3]);
  if (lost) rows.push(['Kaybedilen', lost.gold + ' altın, ' + lost.items + ' eşya']);
  if (sold) rows.push(['Çanta dolu, satılan', sold + ' eşya']);
  $('endRows').innerHTML = rows.map(([a, b]) => `<div><span>${a}</span><b${a === 'Kaybedilen' ? ' class="down"' : ''}>${b}</b></div>`).join('');
  persist(); show('end');
}
$('endBtn').onclick = () => { run = null; openSquare(true); };

// ---------- Sınıf seçimi ----------
function openCreate() {
  const box = $('classPicks'); box.innerHTML = '';
  for (const id in CLASSES) {
    const c = CLASSES[id], b = document.createElement('button'); b.className = 'pick'; b.type = 'button';
    b.innerHTML = `<em style="color:${c.col}">${c.yetenek}</em><b>${c.ad}</b><span>${c.ac} ${c.yac}</span>`;
    b.onclick = () => { audio(); save = newSave(id); persist(); town = null; openSquare(); };
    box.appendChild(b);
  }
  if (!town) initTown();
  G.mode = 'menu'; show('create');
}
// ---------- Kasaba ----------
let resetArm = false;
function openTown() {
  G.mode = 'menu'; resetArm = false; $('resetNote').hidden = true;
  const c = CLASSES[save.cls], s = calcStats();
  $('tBadge').textContent = c.kisa; $('tBadge').style.background = c.col;
  $('tName').textContent = c.ad + ' · Seviye ' + save.lvl;
  const nd = need(save.lvl);
  $('tExp').style.width = (save.lvl >= MAXLV ? 100 : save.exp / nd * 100) + '%';
  $('tExpT').textContent = save.lvl >= MAXLV ? 'En yüksek seviye' : save.exp + ' / ' + nd + ' EXP';
  $('tHp').textContent = s.maxHp; $('tDmg').textContent = s.dmg; $('tArm').textContent = s.armor;
  $('tGold').textContent = save.gold; $('tTas').textContent = save.tas; $('tKor').textContent = save.kor;
  const box = $('regionPicks'); box.innerHTML = '';
  { const b = document.createElement('button'); b.className = 'pick'; b.type = 'button';
    b.innerHTML = `<em>Açık bölge · Seviye 1–30 · herkese açık</em><b>${OPEN.ad}</b><span>10 oda, sağ üstte harita. Diğer oyuncularla aynı yerde savaş. Ganimet 1,5 kat, EXP aynı. Kamptaki geçitten dönünce ganimet güvende.</span>`;
    b.onclick = () => { audio(); startOpen(); }; box.appendChild(b); }
  REGIONS.forEach((R, i) => {
    const b = document.createElement('button'); b.className = 'pick'; b.type = 'button';
    const open = save.lvl >= R.min, pen = save.lvl - R.max >= 4;
    b.disabled = !open;
    b.innerHTML = `<em>Seviye ${R.min}–${R.max} · en derin kat ${save.best[i] || 0}/20</em><b>${R.ad}</b><span>${open ? (pen ? 'Seviyen bu bölge için yüksek, EXP azalır.' : '20 kat. 10. ve 20. katta bekçi var.') : 'Seviye ' + R.min + ' olunca açılır.'}</span>`;
    b.onclick = () => { audio(); startRun(i); };
    box.appendChild(b);
  });
  show('town');
}
const QN = { yuksek: 'Yüksek', dengeli: 'Dengeli', dusuk: 'Düşük' };
function gfxLabel() { $('gfxBtn').textContent = 'Grafik kalitesi: ' + QN[RN.quality]; }
$('gfxBtn').onclick = () => { const o = ['yuksek', 'dengeli', 'dusuk']; RN.setQuality(o[(o.indexOf(RN.quality) + 1) % 3], true); gfxLabel(); };
RN.onAuto = q => { gfxLabel(); toast('Akıcılık için grafik kalitesi: ' + QN[q]); };
gfxLabel();
$('resetBtn').onclick = () => {
  if (!resetArm) { resetArm = true; $('resetNote').hidden = false; return; }
  try { localStorage.removeItem(KEY); } catch (e) {}
  save = null; town = null; openCreate();
};
// ---------- Eşya kartı ----------
function itemLines(it) {
  const m = itemMain(it), lines = [];
  if (m.dmg) lines.push(['Hasar', '+' + m.dmg]); if (m.maxHp) lines.push(['Can', '+' + m.maxHp]);
  if (m.armor) lines.push(['Zırh', '+' + m.armor]); if (m.crit) lines.push(['Kritik şansı', '+%' + m.crit]);
  for (const a of it.aff) lines.push([AFF[a.k].ad, AFF[a.k].f(a.v)]);
  return lines;
}
function itemTitle(it) { return `<span class="nm t${it.r}">${it.name}${it.plus ? ' +' + it.plus : ''}</span>`; }
const ICON = {
  kilic: '<path d="M18 3l3 3-11 11-3-3zM6 15l3 3M4 17l3 3M3 21l2-2"/>',
  yay: '<path d="M6 3c8 3 12 9 12 18M6 3l12 18M3 12h9M9 9l3 3-3 3"/>',
  asa: '<path d="M6 21L17 10"/><circle cx="18.5" cy="5.5" r="3"/><path d="M15 3l1 1M22 6l-1 0"/>',
  zirh: '<path d="M7 3l5 2 5-2 3 4-2 3v11H6V10L4 7z"/>',
  yuzuk: '<circle cx="12" cy="14" r="6"/><path d="M9 6l3-3 3 3-3 3z"/>',
  kolye: '<path d="M5 3c0 6 3 9 7 9s7-3 7-9"/><path d="M12 12l-3 4 3 5 3-5z"/>',
};
function iconFor(slot) { const k = slot === 'silah' ? ({ savasci: 'kilic', okcu: 'yay', buyucu: 'asa' })[save.cls] : slot; return `<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round" stroke-linecap="round">${ICON[k]}</svg>`; }
function slotHtml(it, sel, label) {
  if (!it) return `<div class="slot empty">${label || ''}</div>`;
  const better = !Object.values(save.eq).includes(it) && isBetter(it);
  return `<button type="button" class="slot r${it.r}${sel ? ' sel' : ''}" data-id="${it.id}">${better ? '<span class="bt">↑</span>' : ''}${it.plus ? `<span class="pl">+${it.plus}</span>` : ''}<span class="ic t${it.r}">${iconFor(it.slot)}</span><span>Sv ${it.ilvl}</span></button>`;
}
function findItem(id) { for (const sl of SLOTS) if (save.eq[sl] && save.eq[sl].id === id) return { it: save.eq[sl], where: 'eq' }; const it = save.inv.find(x => x.id === id); return it ? { it, where: 'inv' } : null; }
// ---------- Envanter ----------
let selId = null;
function openInv() { G.mode = 'menu'; selId = null; renderInv(); show('inv'); }
function renderInv() {
  $('eqGrid').innerHTML = SLOTS.map(sl => slotHtml(save.eq[sl], save.eq[sl] && save.eq[sl].id === selId, SLOTAD[sl])).join('');
  $('invCount').textContent = 'Çanta ' + save.inv.length + '/' + INV;
  const cells = save.inv.map(it => slotHtml(it, it.id === selId));
  $('invGrid').innerHTML = cells.join('') || '<p class="note" style="grid-column:1/-1">Çantan boş. Seferden eşya getir.</p>';
  document.querySelectorAll('#inv .slot[data-id]').forEach(el => el.onclick = () => { selId = +el.dataset.id; renderInv(); });
  const d = $('detail'), f = selId && findItem(selId);
  if (!f) { d.hidden = true; return; }
  const it = f.it, cur = calcStats(), eq2 = Object.assign({}, save.eq, { [it.slot]: it }), nxt = calcStats(eq2);
  const cmp = f.where === 'inv' ? [['Can', nxt.maxHp - cur.maxHp], ['Hasar', nxt.dmg - cur.dmg], ['Zırh', nxt.armor - cur.armor], ['Kritik', nxt.crit - cur.crit]].filter(x => x[1]) : [];
  const canEq = save.lvl >= it.ilvl;
  d.hidden = false;
  d.innerHTML = `${itemTitle(it)}<p class="note">${RNAME[it.r]} ${SLOTAD[it.slot].toLowerCase()} · seviye ${it.ilvl}${f.where === 'eq' ? ' · kuşanılı' : ''}</p>
    <div class="rows">${itemLines(it).map(([a, b]) => `<div><span>${a}</span><b>${b}</b></div>`).join('')}</div>
    ${cmp.length ? `<div class="rows">${cmp.map(([a, v]) => `<div><span>Kuşanırsan ${a.toLowerCase()}</span><b class="${v > 0 ? 'up' : 'down'}">${v > 0 ? '+' : ''}${v}</b></div>`).join('')}</div>` : ''}
    <div class="btnrow">
      ${f.where === 'inv' ? `<button class="btn small" id="dEq" ${canEq ? '' : 'disabled'}>${canEq ? 'Kuşan' : 'Seviye ' + it.ilvl + ' gerekir'}</button><button class="btn alt small" id="dSell">Sat (${sellPrice(it)} altın)</button>` : ''}
      <button class="btn alt small" id="dForge">Demirciye götür</button>
    </div>`;
  if ($('dEq')) $('dEq').onclick = () => {
    const old = save.eq[it.slot]; save.eq[it.slot] = it; save.inv = save.inv.filter(x => x !== it); if (old) save.inv.push(old);
    persist(); blip(600, 0.08, 'triangle', 0.05, 1.3); renderInv();
  };
  if ($('dSell')) $('dSell').onclick = () => { save.gold += sellPrice(it); save.inv = save.inv.filter(x => x !== it); selId = null; persist(); blip(900, 0.06, 'square', 0.03); renderInv(); };
  $('dForge').onclick = () => openForge(it.id);
}
$('sellCommon').onclick = () => {
  let g = 0, n = 0;
  save.inv = save.inv.filter(it => { if (it.r === 0 && it.plus === 0 && !isBetter(it)) { g += sellPrice(it); n++; return false; } return true; });
  save.gold += g; persist(); toast(n ? n + ' eşya satıldı, +' + g + ' altın' : 'Satılacak sıradan eşya yok'); selId = null; renderInv();
};
$('invBtn').onclick = openInv; $('invBack').onclick = () => openSquare();
// ---------- Demirci ----------
let forgeId = null;
function openForge(id) { G.mode = 'menu'; forgeId = id || (save.eq.silah && save.eq.silah.id); $('fMsg').textContent = ''; $('fMsg').className = 'msg'; renderForge(); show('forge'); }
function forgeCost(it) { return { gold: Math.round((30 + it.ilvl * 6) * (it.plus + 1)), tas: TAS[it.plus], kor: KOR[it.plus] }; }
function renderForge() {
  $('fGold').textContent = save.gold; $('fTas').textContent = save.tas; $('fKor').textContent = save.kor;
  const all = SLOTS.map(sl => save.eq[sl]).filter(Boolean).concat(save.inv.slice().sort((a, b) => b.plus - a.plus || b.r - a.r));
  $('forgeGrid').innerHTML = all.map(it => slotHtml(it, it.id === forgeId)).join('');
  document.querySelectorAll('#forge .slot[data-id]').forEach(el => el.onclick = () => { forgeId = +el.dataset.id; $('fMsg').textContent = ''; renderForge(); });
  const d = $('fDetail'), f = forgeId && findItem(forgeId);
  if (!f) { d.hidden = true; return; }
  const it = f.it; d.hidden = false;
  if (it.plus >= 9) { d.innerHTML = `${itemTitle(it)}<p>Bu eşya +9, en üst seviyede.</p>`; return; }
  const c = forgeCost(it), chance = Math.min(100, CHANCE[it.plus] + it.pity * 15);
  const nx = Object.assign({}, it, { plus: it.plus + 1 }), m0 = itemMain(it), m1 = itemMain(nx);
  const gain = Object.keys(m1).map(k => `${{ dmg: 'Hasar', maxHp: 'Can', armor: 'Zırh', crit: 'Kritik' }[k]} ${m0[k]} → <b class="up">${m1[k]}</b>`).join(' · ');
  const ok = save.gold >= c.gold && save.tas >= c.tas && save.kor >= c.kor;
  d.innerHTML = `${itemTitle(it)}
    <div class="rows">
      <div><span>Hedef</span><b>+${it.plus + 1}</b></div>
      <div><span>Başarı şansı</span><b>%${chance}</b></div>
      <div><span>Bedel</span><b>${c.gold} altın · ${c.tas} taş${c.kor ? ' · ' + c.kor + ' Kor Tozu' : ''}</b></div>
    </div>
    <p class="note">${gain}</p>
    <button class="btn" id="fUp" ${ok ? '' : 'disabled'}>${ok ? 'Bas (+' + (it.plus + 1) + ')' : 'Malzeme yetersiz'}</button>`;
  $('fUp').onclick = () => {
    audio();
    if (!(save.gold >= c.gold && save.tas >= c.tas && save.kor >= c.kor)) return;
    save.gold -= c.gold; save.tas -= c.tas; save.kor -= c.kor;
    const m = $('fMsg');
    if (Math.random() * 100 < chance) {
      it.plus++; it.pity = 0; m.textContent = 'Başardın: ' + it.name + ' +' + it.plus; m.className = 'msg ok';
      blip(520, 0.1, 'triangle', 0.07, 1.5); setTimeout(() => blip(780, 0.12, 'triangle', 0.06, 1.5), 90);
    } else {
      it.pity++; m.textContent = 'Kıvılcım söndü. Seviye korundu, sonraki şans %' + Math.min(100, CHANCE[it.plus] + it.pity * 15) + '.'; m.className = 'msg no';
      blip(140, 0.3, 'sawtooth', 0.06, 0.5);
    }
    persist(); renderForge();
  };
}
$('forgeBtn').onclick = () => openForge(); $('forgeBack').onclick = () => openSquare();
// ---------- Duraklatma ----------
function togglePause() {
  if (G.mode === 'play') { G.mode = 'pause'; $('pauseBtn').textContent = '▶'; }
  else if (G.mode === 'pause') { G.mode = 'play'; $('pauseBtn').textContent = 'II'; last = performance.now(); }
}
$('pauseBtn').onclick = togglePause;
document.addEventListener('visibilitychange', () => { if (document.hidden && G.mode === 'play') togglePause(); });


// ================= Kasaba meydanı =================
// Not: Buradaki diğer oyuncular örnektir. Sunucu bağlanınca gerçek oyuncular görünecek.
const TOWNPAL = { a: '#3a3330', b: '#403834', wall: '#4a3e3a', wallTop: '#6b5a52', spot: '255,210,122' };
const STATUE = { x: 210, y: 380 };
const BUILD = [
  { id: 'dais', sortY: 30, x: 210, y: 62, w: 130, d: 56, h: 10, top: '#5a4c46', front: '#3d332f' },
  { id: 'throne', x: 210, y: 52, w: 44, d: 22, h: 46, label: 'Taht', lh: 85 },
  { id: 'forge', x: 52, y: 300, w: 84, d: 120, h: 62, label: 'Demirci', act: 'Demirciye gir', lh: 100 },
  { id: 'stall1', x: 370, y: 270, w: 80, d: 64, h: 34, label: 'Pazar', act: 'Pazara bak', lh: 60 },
  { id: 'stall2', x: 370, y: 390, w: 80, d: 64, h: 34, top: '#2e5a8a', front: '#4a3a2c', act: 'Pazara bak' },
  { id: 'clan', x: 398, y: 600, w: 14, d: 60, h: 52, label: 'Klan Panosu', act: 'Klan panosu', lh: 60 },
  { id: 'gate', x: 14, y: 640, w: 26, d: 150, h: 72, label: 'Sefer Kapısı', act: 'Sefere çık', lh: 100 },
  { id: 'hearth', x: 106, y: 276, w: 22, d: 28, h: 20 },
  { id: 'anvil', x: 108, y: 322, w: 14, d: 22, h: 14 },
];
const OUTFITS = [
  { ad: 'Kraliyet Kıyafeti', body: '#7a1f2b', top: '#ffd27a', cape: '#b8323f', hat: 'tac', aura: '255,210,122', name: '#ffd27a' },
  { ad: 'Muhafız Zırhı', body: '#4d5a6e', top: '#c8d2e0', cape: '#7a1f2b', hat: 'kask', name: '#e8d6c0' },
  { ad: 'Kızıl Ejder Seti', body: '#b8323f', top: '#ff8a6a', cape: '#3b0f14', hat: 'sivri', aura: '255,90,60' },
  { ad: 'Gece Pelerini', body: '#2b2f4a', top: '#8f9bd8', cape: '#141629' },
  { ad: 'Kül Gezgini', body: '#6e625a', top: '#c9bcb0', cape: '#3a302a' },
  { ad: 'Orman Avcısı', body: '#3e6b45', top: '#9fd8a5', cape: '#24402a', hat: 'sivri' },
  { ad: 'Kristal Cübbe', body: '#3c6f8c', top: '#bfe6ff', aura: '143,184,255' },
  { ad: 'Başlangıç Kıyafeti', body: null, top: null },
];
const NPCDEF = [
  ['Demirkurt', 'ASİL', 'Kral', 'savasci', 47, 0, 'king'],
  ['Tunçkalkan', 'ASİL', 'Kraliyet Muhafızı', 'savasci', 44, 1, 'guard'],
  ['Kızılyay', 'ASİL', 'Kraliyet Muhafızı', 'okcu', 43, 1, 'guard'],
  ['GeceAvcısı', 'GECE', 'Klan Lideri', 'okcu', 45, 3, ''],
  ['KorBüyücü', 'KOR', 'Eski Kral', 'buyucu', 46, 2, ''],
  ['Ayaz', 'KOR', 'Boss Avcısı', 'savasci', 38, 2, ''],
  ['Zeyna', 'GECE', '', 'buyucu', 33, 6, ''],
  ['Baykuş', '', '', 'okcu', 21, 5, 'seller'],
  ['Selin', 'KOR', '', 'buyucu', 29, 6, ''],
  ['Akrep', '', '', 'savasci', 17, 4, 'seller'],
  ['Rüzgar', 'GECE', '', 'okcu', 26, 3, ''],
  ['Yağız', '', '', 'savasci', 12, 7, ''],
  ['Tospik', '', '', 'buyucu', 8, 7, ''],
  ['Esmer', 'KOR', '', 'okcu', 31, 4, 'smith'],
];
let town = null, LBL = [];
function npcGear(cls, lvl, seed) {
  let x = seed * 9301 + 49297; const r = () => (x = (x * 9301 + 49297) % 233280) / 233280;
  return SLOTS.map(sl => {
    const rr = Math.min(3, Math.floor(r() * 3 + lvl / 25)), plus = Math.min(9, Math.floor(r() * (lvl / 6)));
    const tier = Math.min(2, Math.floor(lvl / 15));
    return { slot: sl, r: rr, plus, name: sl === 'silah' ? NAMES.silah[cls][tier] : NAMES[sl][tier] };
  });
}
function freeSpot() {
  for (let k = 0; k < 40; k++) {
    const x = rnd(110, 310), y = rnd(170, 700);
    if (Math.hypot(x - STATUE.x, y - STATUE.y) < 60) continue;
    if (BUILD.some(b => Math.abs(x - b.x) < b.w / 2 + 20 && Math.abs(y - b.y) < b.d / 2 + 20)) continue;
    return [x, y];
  }
  return [210, 600];
}
function initTown() {
  town = { p: { x: 210, y: 700, fx: 0, fy: -1 }, npcs: [], near: null, t: 0, banner: 0 };
  NPCDEF.forEach((d, i) => {
    const [name, clan, title, cls, lvl, o, role] = d;
    let x, y;
    if (role === 'king') { x = 210; y = 104; } else if (role === 'guard') { x = i === 1 ? 128 : 292; y = 112; }
    else if (role === 'seller') { x = 318; y = i === 7 ? 270 : 390; } else if (role === 'smith') { x = 132; y = 298; }
    else [x, y] = freeSpot();
    town.npcs.push({ name, clan, title, cls, lvl, of: OUTFITS[o], role, x, y, hx: x, hy: y, tx: x, ty: y, wait: rnd(0, 3), sp: rnd(38, 60), gear: npcGear(cls, lvl, i + 3) });
  });
}
function openSquare(fromRun) {
  if (!town) initTown();
  if (fromRun) { town.p.x = 62; town.p.y = 640; town.p.fx = 1; town.p.fy = 0; }
  G.mode = 'town'; resetArm = false; town.near = null; show(null);
  const c = CLASSES[save.cls];
  $('sqLv').textContent = save.lvl; $('sqWho').innerHTML = '<b>' + c.ad + '</b> · Seviye ' + save.lvl;
  $('sqGold').textContent = save.gold;
  $('sqChan').textContent = 'Kasaba Meydanı · Kanal 1 · ' + (town.npcs.length + 1) + ' kişi (örnek oyuncular)';
  if (!town.bannerDone) {
    town.bannerDone = true;
    setTimeout(() => { const b = $('banner'); b.textContent = 'Kral Demirkurt [ASİL] meydana geldi'; b.hidden = false; }, 1200);
    setTimeout(() => { const b = $('banner'); b.textContent = 'Kral Bereketi aktif: tüm sunucuya +%20 EXP (örnek)'; }, 5200);
  }
}
function collide(o) {
  for (const b of BUILD) {
    const hw = b.w / 2 + PR, hd = b.d / 2 + PR, dx = o.x - b.x, dy = o.y - b.y;
    if (Math.abs(dx) < hw && Math.abs(dy) < hd) {
      const px = hw - Math.abs(dx), py = hd - Math.abs(dy);
      if (px < py) o.x += Math.sign(dx || 1) * px; else o.y += Math.sign(dy || 1) * py;
    }
  }
  const dx = o.x - STATUE.x, dy = o.y - STATUE.y, d = Math.hypot(dx, dy) || 1, m = 30 + PR;
  if (d < m) { o.x += dx / d * (m - d); o.y += dy / d * (m - d); }
  o.x = clamp(o.x, PR, RW - PR); o.y = clamp(o.y, PR, RH - PR);
}
function updateTown(dt) {
  G.t += dt;
  const p = town.p;
  let mx = joy.dx, my = joy.dy;
  if (keys.a || keys.arrowleft) mx -= 1; if (keys.d || keys.arrowright) mx += 1;
  if (keys.w || keys.arrowup) my -= 1; if (keys.s || keys.arrowdown) my += 1;
  let ml = Math.hypot(mx, my); if (ml > 1) { mx /= ml; my /= ml; ml = 1; }
  if (ml > 0.15) { p.fx = mx / ml; p.fy = my / ml; }
  p.x += mx * 140 * dt; p.y += my * 140 * dt; collide(p);
  moveNpcs(dt);
  townNear(p);
}
function moveNpcs(dt) {
  for (const n of town.npcs) {
    if (n.wait > 0) { n.wait -= dt; continue; }
    const dx = n.tx - n.x, dy = n.ty - n.y, d = Math.hypot(dx, dy);
    if (d < 3) {
      n.wait = rnd(1.5, 5);
      if (n.role) { n.tx = n.hx + rnd(-14, 14); n.ty = n.hy + rnd(-8, 8); } else [n.tx, n.ty] = freeSpot();
    } else { n.x += dx / d * n.sp * dt; n.y += dy / d * n.sp * dt; n.fx = dx / d; n.fy = dy / d; }
  }
}
function townNear(p) {
  let near = null;
  for (const b of BUILD) if (b.act && Math.abs(p.x - b.x) < b.w / 2 + 34 && Math.abs(p.y - b.y) < b.d / 2 + 30) near = b;
  if (!near && Math.hypot(p.x - STATUE.x, p.y - STATUE.y) < 70) near = { id: 'statue', act: 'Heykeli incele' };
  if ((near && near.id) !== (town.near && town.near.id)) {
    town.near = near; const el = $('ctx');
    el.hidden = !near; if (near) el.textContent = near.act;
  }
}
function townAction(id) {
  if (id === 'forge') openForge();
  else if (id === 'gate') openTown();
  else if (id === 'stall1' || id === 'stall2') toast('Pazar çevrim içi sürümde açılacak (Etap 3)');
  else if (id === 'clan') toast('Klan sistemi çevrim içi sürümde açılacak (Etap 4)');
  else if (id === 'statue') openKingCard();
}
$('ctx').addEventListener('pointerdown', e => { e.preventDefault(); e.stopPropagation(); audio(); if (town && town.near) townAction(town.near.id); });
$('sqChar').onclick = () => openTown();
$('sqBag').onclick = () => openInv();
$('charBack').onclick = () => openSquare();
function townTap(cx, cy) {
  let best = null, bd = 34;
  const cand = town.npcs.map(n => ({ o: n, k: 'npc' })).concat([{ o: town.p, k: 'me' }, { o: STATUE, k: 'statue' }]);
  for (const c of cand) {
    const [sx, sy] = RN.project(c.o.x, c.o.y, c.k === 'statue' ? 50 : 22), d = Math.hypot(sx - cx, sy - cy);
    if (d < bd) { bd = d; best = c; }
  }
  if (!best) return;
  joy.on = false; joy.dx = joy.dy = 0;
  if (best.k === 'statue') openKingCard(); else if (best.k === 'me') openMyCard(); else openNpcCard(best.o);
}
function gearRows(list) {
  return list.map(g => `<div><span>${SLOTAD[g.slot]}</span><b class="t${g.r}">${g ? g.name + (g.plus ? ' +' + g.plus : '') : '—'}</b></div>`).join('');
}
function openCard(html) {
  $('pcardBody').innerHTML = html + '<button class="btn alt" id="pcClose">Kapat</button>';
  $('pcClose').onclick = () => openSquare();
  G.mode = 'menu'; show('pcard');
}
function openNpcCard(n) {
  const c = CLASSES[n.cls];
  openCard(`<div class="who"><div class="badge" style="background:${n.of.body || c.col}">${c.kisa}</div><div class="grow">
      <b${n.title === 'Kral' ? ' class="gold"' : ''}>${n.name}</b><p class="note">${n.clan ? '[' + n.clan + '] klanı' : 'Klansız'}${n.title ? ' · ' + n.title : ''}</p></div></div>
    <div class="rows"><div><span>Sınıf</span><b>${c.ad}</b></div><div><span>Seviye</span><b>${n.lvl}</b></div><div><span>Kıyafet</span><b>${n.of.ad}</b></div></div>
    <h3>Kuşandıkları</h3><div class="rows">${gearRows(n.gear)}</div>
    <p class="note">Örnek oyuncu. Sunucu bağlanınca burada gerçek oyuncular görünecek.</p>`);
}
function openMyCard() {
  const c = CLASSES[save.cls];
  const gear = SLOTS.map(sl => save.eq[sl] ? { slot: sl, r: save.eq[sl].r, plus: save.eq[sl].plus, name: save.eq[sl].name } : { slot: sl, r: 0, plus: 0, name: '—' });
  openCard(`<div class="who"><div class="badge" style="background:${c.col}">${c.kisa}</div><div class="grow"><b>Sen</b><p class="note">Klansız · diğer oyuncular seni böyle görür</p></div></div>
    <div class="rows"><div><span>Sınıf</span><b>${c.ad}</b></div><div><span>Seviye</span><b>${save.lvl}</b></div><div><span>Kıyafet</span><b>Başlangıç Kıyafeti</b></div></div>
    <h3>Kuşandıkların</h3><div class="rows">${gearRows(gear)}</div>`);
}
function openKingCard() {
  openCard(`<h2 class="gold">Kasım Kralı</h2>
    <p class="lead">Demirkurt · [ASİL] klanının lideri</p>
    <div class="rows"><div><span>Taht Puanı</span><b>18.420</b></div><div><span>Kral olduğu ay</span><b>2. ay üst üste</b></div><div><span>Pazar vergisi</span><b>%8</b></div><div><span>Kral Bereketi</span><b>Bu hafta 1/2 kullanıldı</b></div></div>
    <p>Heykel her ay yeni kralın kıyafetiyle yenilenir. Taht Puanı en yüksek klanın lideri ay sonunda kral olur.</p>
    <p class="note">Örnek veri.</p>`);
}

// ================= Döngü =================
const VIEW = {
  get mode() { return G.mode; }, get t() { return G.t; }, get run() { return run; }, get P1() { return P1; },
  get enemies() { return enemies; }, get shots() { return shots; }, get arrows() { return arrows; }, get pending() { return pending; },
  get texts() { return texts; }, get warns() { return warns; }, get bots() { return bots; }, OPEN, CAMP_PORTAL,
  get doors() { return run && run.kind === 'acik' ? doorsOf(run.room) : null; }, get town() { return town; }, get save() { return save; }, joy, BUILD, STATUE,
  get showMe() { return !!save && !!town && $('create').hidden; }, get anyEnemy() { return !!(run && enemies && enemies.some(e => !e.dead)); },
};
let last = performance.now();
function frame(now) {
  const dt = Math.min(0.033, (now - last) / 1000); last = now;
  G.slow = Math.max(0, G.slow - dt);
  const gdt = G.slow > 0 ? dt * 0.35 : dt;
  if (G.mode === 'play' || G.mode === 'dying') update(gdt);
  else if (G.mode === 'town') updateTown(dt);
  else { G.t += dt; if (!run && town) moveNpcs(dt); }
  RN.render(G.slow > 0 ? dt * 0.35 : dt, VIEW);
  RN.perfWatch(dt, G.mode === 'play' || G.mode === 'town');
  requestAnimationFrame(frame);
}
addEventListener('resize', resize);
resize();
if (save && save.cls && CLASSES[save.cls]) openSquare(); else openCreate();
requestAnimationFrame(frame);
window.__kk = { get save() { return save; }, get run() { return run; }, get P1() { return P1; }, get town() { return town; }, get pending() { return pending; }, get enemies() { return enemies; }, get warns() { return warns; }, RN, G, startOpen, enterRoom: (i, f) => enterRoom(i, f) };
})();

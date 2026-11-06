// Kayıp Katlar — 3D sahne (Three.js r128)
// Oyun mantığı oyun.js'te; bu dosya sadece çizer. Oyun koordinatları piksel (420×820), burada 1 birim = 20 piksel.
window.Sahne = (() => {
'use strict';
const T = THREE;
const U = 1 / 20, RW = 420, RH = 820, HW = RW * U / 2, HD = RH * U / 2;
const X = x => x * U - HW, Z = y => y * U - HD, Y = z => z * U;
const lerp = (a, b, k) => a + (b - a) * k;
const clamp = (v, a, b) => v < a ? a : v > b ? b : v;

let renderer, scene, camera, composer, bloomPass, ov, octx, W = 1, H = 1, DPR = 1;
let quality = 'yuksek';
try { quality = localStorage.getItem('kk-grafik') || 'yuksek'; } catch (e) {}
let envKey = null, envGroup, entGroup, fxGroup, hemi, sun;
const PL = []; // sabit sayıda nokta ışığı (shader yeniden derlenmesin diye)
let flick = [], envAnims = [], emitters = [];
const camT = new T.Vector3(), camP = new T.Vector3(); let camInit = false, shake = 0, orbit = 0;
const models = new Set(); let frameNo = 0;
const effects = [];

// ---------- malzemeler ----------
const lin = c => new T.Color(c).convertSRGBToLinear();
const MC = {};
function M(color, o) {
  const k = color + (o ? JSON.stringify(o) : '');
  if (!MC[k]) { const m = new T.MeshStandardMaterial(Object.assign({ roughness: 0.82, metalness: 0, flatShading: true }, o || {})); m.color = lin(color); if (o && o.emissive) m.emissive = lin(o.emissive); MC[k] = m; }
  return MC[k];
}
function Gl(color, op) {
  const k = 'g' + color + (op || 1);
  if (!MC[k]) { MC[k] = new T.MeshBasicMaterial({ color: lin(color), transparent: op < 1, opacity: op || 1, toneMapped: false }); }
  return MC[k];
}
const FLASH = new T.MeshBasicMaterial({ color: 0xffffff });
const GEO = {};
const geo = (k, f) => GEO[k] || (GEO[k] = f());
function mesh(g, m, cast = true, recv = true) { const o = new T.Mesh(g, m); o.castShadow = cast; o.receiveShadow = recv; return o; }
const bx = (w, h, d, m) => mesh(geo('b' + w + h + d, () => new T.BoxGeometry(w, h, d)), m);
const cy = (rt, rb, h, seg, m) => mesh(geo('c' + rt + rb + h + seg, () => new T.CylinderGeometry(rt, rb, h, seg)), m);
const sp = (r, m, det = 1) => mesh(geo('s' + r + det, () => new T.IcosahedronGeometry(r, det)), m);
const cn = (r, h, seg, m) => mesh(geo('k' + r + h + seg, () => new T.ConeGeometry(r, h, seg)), m);

// parlama dokusu
function glowTex() {
  const c = document.createElement('canvas'); c.width = c.height = 64; const g = c.getContext('2d');
  const r = g.createRadialGradient(32, 32, 0, 32, 32, 32);
  r.addColorStop(0, 'rgba(255,255,255,1)'); r.addColorStop(0.25, 'rgba(255,255,255,.6)'); r.addColorStop(1, 'rgba(255,255,255,0)');
  g.fillStyle = r; g.fillRect(0, 0, 64, 64); const t = new T.CanvasTexture(c); return t;
}
let GLOW;
function glowSprite(color, size, op = 1) {
  const s = new T.Sprite(new T.SpriteMaterial({ map: GLOW, color: lin(color), transparent: true, opacity: op, blending: T.AdditiveBlending, depthWrite: false, toneMapped: false }));
  s.scale.set(size, size, 1); return s;
}
function canvasTex(w, h, draw) { const c = document.createElement('canvas'); c.width = w; c.height = h; draw(c.getContext('2d'), w, h); const t = new T.CanvasTexture(c); t.encoding = T.sRGBEncoding; t.anisotropy = 4; return t; }

// ---------- parçacıklar ----------
const PMAX = 2400;
let pGeo, pts, pi = 0;
const pa = { x: new Float32Array(PMAX), y: new Float32Array(PMAX), z: new Float32Array(PMAX), vx: new Float32Array(PMAX), vy: new Float32Array(PMAX), vz: new Float32Array(PMAX),
  life: new Float32Array(PMAX), max: new Float32Array(PMAX), size: new Float32Array(PMAX), grav: new Float32Array(PMAX), drag: new Float32Array(PMAX) };
let posA, colA, sizeA, alphaA;
function initParticles() {
  pGeo = new T.BufferGeometry();
  posA = new Float32Array(PMAX * 3); colA = new Float32Array(PMAX * 3); sizeA = new Float32Array(PMAX); alphaA = new Float32Array(PMAX);
  pGeo.setAttribute('position', new T.BufferAttribute(posA, 3));
  pGeo.setAttribute('pcolor', new T.BufferAttribute(colA, 3));
  pGeo.setAttribute('psize', new T.BufferAttribute(sizeA, 1));
  pGeo.setAttribute('palpha', new T.BufferAttribute(alphaA, 1));
  const mat = new T.ShaderMaterial({
    uniforms: { uScale: { value: 400 }, map: { value: GLOW } },
    vertexShader: 'attribute float psize; attribute float palpha; attribute vec3 pcolor; varying vec3 vC; varying float vA; uniform float uScale;' +
      'void main(){ vC=pcolor; vA=palpha; vec4 mv=modelViewMatrix*vec4(position,1.0); gl_PointSize=psize*uScale/max(0.1,-mv.z); gl_Position=projectionMatrix*mv; }',
    fragmentShader: 'uniform sampler2D map; varying vec3 vC; varying float vA; void main(){ vec4 t=texture2D(map,gl_PointCoord); gl_FragColor=vec4(vC*t.rgb*1.6, t.a*vA); }',
    transparent: true, depthWrite: false, blending: T.AdditiveBlending,
  });
  pts = new T.Points(pGeo, mat); pts.frustumCulled = false; pts.renderOrder = 10;
}
const tmpC = new T.Color();
function emit(x, y, z, vx, vy, vz, life, size, color, grav = 0, drag = 0) {
  const i = pi; pi = (pi + 1) % PMAX;
  pa.x[i] = x; pa.y[i] = y; pa.z[i] = z; pa.vx[i] = vx; pa.vy[i] = vy; pa.vz[i] = vz; pa.life[i] = life; pa.max[i] = life; pa.size[i] = size; pa.grav[i] = grav; pa.drag[i] = drag;
  tmpC.set(color); colA[i * 3] = tmpC.r; colA[i * 3 + 1] = tmpC.g; colA[i * 3 + 2] = tmpC.b;
}
function stepParticles(dt) {
  for (let i = 0; i < PMAX; i++) {
    if (pa.life[i] <= 0) { if (alphaA[i] !== 0) { alphaA[i] = 0; sizeA[i] = 0; } continue; }
    pa.life[i] -= dt;
    const d = 1 - pa.drag[i] * dt;
    pa.vx[i] *= d; pa.vz[i] *= d; pa.vy[i] = pa.vy[i] * d - pa.grav[i] * dt;
    pa.x[i] += pa.vx[i] * dt; pa.y[i] += pa.vy[i] * dt; pa.z[i] += pa.vz[i] * dt;
    if (pa.y[i] < 0.02 && pa.grav[i] > 0) { pa.y[i] = 0.02; pa.vy[i] *= -0.35; pa.vx[i] *= 0.6; pa.vz[i] *= 0.6; }
    posA[i * 3] = pa.x[i]; posA[i * 3 + 1] = pa.y[i]; posA[i * 3 + 2] = pa.z[i];
    const k = pa.life[i] / pa.max[i];
    alphaA[i] = Math.min(1, k * 2.2); sizeA[i] = pa.size[i] * (0.4 + 0.6 * k);
  }
  pGeo.attributes.position.needsUpdate = true; pGeo.attributes.pcolor.needsUpdate = true;
  pGeo.attributes.psize.needsUpdate = true; pGeo.attributes.palpha.needsUpdate = true;
}
function burst3(x, y, z, color, n, spd, size = 0.35, grav = 9, life = 0.7) {
  for (let i = 0; i < n; i++) {
    const a = Math.random() * 6.283, u = Math.random() * 0.9 + 0.1, v = spd * (0.35 + Math.random() * 0.8);
    emit(x, y, z, Math.cos(a) * v * u, v * (0.4 + Math.random() * 0.9), Math.sin(a) * v * u, life * (0.6 + Math.random() * 0.6), size * (0.6 + Math.random() * 0.8), color, grav, 1.2);
  }
}

// ---------- kurulum ----------
function init(glcv, ovcv) {
  renderer = new T.WebGLRenderer({ canvas: glcv, antialias: true, powerPreference: 'high-performance' });
  renderer.outputEncoding = T.sRGBEncoding;
  renderer.shadowMap.enabled = true; renderer.shadowMap.type = T.PCFSoftShadowMap;
  scene = new T.Scene();
  scene.background = lin('#0c0910');
  scene.fog = new T.Fog(lin('#0c0910'), 40, 90);
  camera = new T.PerspectiveCamera(34, 1, 0.5, 200);
  GLOW = glowTex();
  hemi = new T.HemisphereLight(lin('#8a7aa8'), lin('#1a1420'), 0.5); scene.add(hemi);
  sun = new T.DirectionalLight(lin('#c8b8ff'), 0.7);
  sun.castShadow = true; sun.shadow.bias = -0.0006; sun.shadow.normalBias = 0.02;
  const sc = sun.shadow.camera; sc.left = -14; sc.right = 14; sc.top = 24; sc.bottom = -24; sc.near = 1; sc.far = 80;
  scene.add(sun); scene.add(sun.target);
  for (let i = 0; i < 5; i++) { const l = new T.PointLight(0xffffff, 0, 10, 2); scene.add(l); PL.push(l); }
  envGroup = new T.Group(); entGroup = new T.Group(); fxGroup = new T.Group();
  scene.add(envGroup, entGroup, fxGroup);
  initParticles(); scene.add(pts);
  ov = ovcv; octx = ov.getContext('2d');
  applyQuality(); resize();
}
function applyQuality() {
  const dpr = window.devicePixelRatio || 1;
  DPR = quality === 'yuksek' ? Math.min(dpr, 2) : quality === 'dengeli' ? Math.min(dpr, 1.5) : 1;
  renderer.setPixelRatio(DPR);
  renderer.shadowMap.enabled = quality !== 'dusuk';
  const ms = quality === 'yuksek' ? 2048 : 1024;
  if (sun.shadow.mapSize.x !== ms) { sun.shadow.mapSize.set(ms, ms); if (sun.shadow.map) { sun.shadow.map.dispose(); sun.shadow.map = null; } }
  scene.traverse(o => { if (o.material) { const ms_ = Array.isArray(o.material) ? o.material : [o.material]; ms_.forEach(m => m.needsUpdate = true); } });
  composer = null;
  if (quality === 'yuksek' && T.EffectComposer && T.UnrealBloomPass) {
    try {
      composer = new T.EffectComposer(renderer);
      composer.addPass(new T.RenderPass(scene, camera));
      bloomPass = new T.UnrealBloomPass(new T.Vector2(256, 256), 0.85, 0.5, 0.82);
      composer.addPass(bloomPass);
      if (T.GammaCorrectionShader) composer.addPass(new T.ShaderPass(T.GammaCorrectionShader));
    } catch (e) { composer = null; }
  }
  resize();
}
function setQuality(q, manual) { quality = q; try { localStorage.setItem('kk-grafik', q); if (manual) localStorage.setItem('kk-grafik-el', '1'); } catch (e) {} applyQuality(); }
let perfAcc = 0, perfN = 0, perfDrops = 0, onAuto = null;
function perfWatch(dt, active) {
  if (!active || perfDrops >= 2) return;
  let manual = false; try { manual = localStorage.getItem('kk-grafik-el') === '1'; } catch (e) {}
  if (manual) return;
  perfAcc += dt; perfN++;
  if (perfAcc > 4) {
    const fps = perfN / perfAcc; perfAcc = 0; perfN = 0;
    if (fps < 34 && quality !== 'dusuk') { perfDrops++; setQuality(quality === 'yuksek' ? 'dengeli' : 'dusuk'); if (onAuto) onAuto(quality); }
  }
}
function resize() {
  if (!renderer) return;
  W = window.innerWidth; H = window.innerHeight;
  renderer.setSize(W, H, false);
  renderer.domElement.style.width = W + 'px'; renderer.domElement.style.height = H + 'px';
  camera.aspect = W / H; camera.updateProjectionMatrix();
  if (composer) { composer.setPixelRatio(DPR); composer.setSize(W, H); }
  const od = Math.min(window.devicePixelRatio || 1, 2);
  ov.width = Math.round(W * od); ov.height = Math.round(H * od); ov.style.width = W + 'px'; ov.style.height = H + 'px'; ov._d = od;
  pts.material.uniforms.uScale.value = H * DPR / (2 * Math.tan(T.MathUtils.degToRad(camera.fov / 2)));
}

// ---------- ortam: ortak parçalar ----------
function clearEnv() {
  scene.remove(envGroup); envGroup = new T.Group(); scene.add(envGroup);
  flick = []; envAnims = []; emitters = [];
  PL.forEach(l => { l.intensity = 0; });
  [...models].forEach(m => { entGroup.remove(m.root); models.delete(m); });
}
function diorama(cols, opts = {}) {
  // taban bloğu: odayı havada duran bir maket gibi gösterir
  const base = bx(RW * U + 0.8, 3, RH * U + 0.8, M(cols.base)); base.position.y = -1.7; base.castShadow = false; envGroup.add(base);
  const lip = bx(RW * U + 1.0, 0.25, RH * U + 1.0, M(cols.lip)); lip.position.y = -0.32; lip.castShadow = false; envGroup.add(lip);
  const nx = 10, nz = 20, tw = RW * U / nx, td = RH * U / nz;
  const g = new T.BoxGeometry(tw - 0.07, 0.36, td - 0.07);
  const mat = new T.MeshStandardMaterial({ roughness: 0.9, flatShading: true, metalness: opts.metal || 0 });
  const im = new T.InstancedMesh(g, mat, nx * nz); im.receiveShadow = true;
  const o = new T.Object3D(), ca = lin(cols.a), cb = lin(cols.b), c = new T.Color();
  let k = 0;
  for (let i = 0; i < nx; i++) for (let j = 0; j < nz; j++) {
    const x = -HW + tw * (i + 0.5), z = -HD + td * (j + 0.5);
    o.position.set(x, -0.18 + Math.random() * 0.05, z); o.rotation.y = (Math.random() - 0.5) * 0.02; o.updateMatrix();
    im.setMatrixAt(k, o.matrix);
    c.copy((i + j) % 2 ? ca : cb).multiplyScalar(0.82 + Math.random() * 0.3);
    if (opts.tint) opts.tint(x, z, c);
    im.setColorAt(k, c); k++;
  }
  envGroup.add(im);
}
function backWall(col, capCol, h = 3.4, gap = {}) {
  const n = 12, w = RW * U / n;
  for (let i = 0; i < n; i++) {
    if (gap.n && (i === 5 || i === 6)) continue;
    const hh = h + (Math.random() - 0.5) * 0.5;
    const b = bx(w - 0.05, hh, 1.3, M(col)); b.position.set(-HW + w * (i + 0.5), hh / 2 - 0.3, -HD - 0.65); envGroup.add(b);
    const cap = bx(w + 0.05, 0.22, 1.45, M(capCol)); cap.position.set(b.position.x, hh - 0.3 + 0.11, -HD - 0.65); envGroup.add(cap);
  }
  for (const s of [-1, 1]) {
    const open = s < 0 ? gap.w : gap.e;
    const segs = open ? [[-HD - 1.3, -2.6], [2.6, HD]] : [[-HD - 1.3, HD]];
    for (const [z0, z1] of segs) {
      const L = z1 - z0, zc = (z0 + z1) / 2;
      const side = bx(0.8, 1.1, L, M(col)); side.position.set(s * (HW + 0.4), 0.25, zc); envGroup.add(side);
      const cap = bx(0.95, 0.18, L + 0.1, M(capCol)); cap.position.set(s * (HW + 0.4), 0.88, zc); envGroup.add(cap);
    }
  }
}
function doorMark(x, z, rot, big) {
  const g = new T.Group(); g.position.set(x, 0, z); g.rotation.y = rot;
  for (const s of [-1, 1]) {
    const p = bx(0.55, big ? 3.6 : 1.6, 0.55, M('#6a5c55')); p.position.set(s * 2.4, (big ? 3.6 : 1.6) / 2 - 0.3, 0); g.add(p);
    const f = cn(0.12, 0.35, 6, Gl('#8fb8ff')); f.position.set(s * 2.4, (big ? 3.6 : 1.6) - 0.1, 0); f.castShadow = false; g.add(f);
  }
  if (big) { const l = bx(5.4, 0.5, 0.7, M('#7a6a62')); l.position.y = 3.4; g.add(l); }
  const fl = mesh(geo('doorfl', () => new T.PlaneGeometry(4.2, 2.6)), new T.MeshBasicMaterial({ map: GLOW, color: lin('#6f8cff'), transparent: true, opacity: 0.55, blending: T.AdditiveBlending, depthWrite: false, toneMapped: false }), false, false);
  fl.rotation.x = -Math.PI / 2; fl.position.set(0, 0.02, 0); g.add(fl);
  envGroup.add(g);
  envAnims.push((dt, tt) => { fl.material.opacity = 0.4 + Math.sin(tt * 3) * 0.15; });
  emitters.push({ rate: 3, acc: 0, fn: () => { const v = new T.Vector3((Math.random() - 0.5) * 4, 0.1, (Math.random() - 0.5) * 1.2).applyAxisAngle(new T.Vector3(0, 1, 0), rot); emit(x + v.x, 0.1, z + v.z, 0, 0.8 + Math.random() * 0.6, 0, 1.2, 0.2, '#8fb8ff', 0, 0); } });
}
function pillar(x, z, col, capCol, h = 4.4) {
  const p = bx(1.3, h, 1.3, M(col)); p.position.set(x, h / 2 - 0.3, z); envGroup.add(p);
  const c1 = bx(1.6, 0.3, 1.6, M(capCol)); c1.position.set(x, h - 0.3, z); envGroup.add(c1);
  const c0 = bx(1.6, 0.3, 1.6, M(capCol)); c0.position.set(x, -0.05, z); envGroup.add(c0);
}
function torch(x, y, z, li, color = '#ff9a4a') {
  const h = bx(0.18, 0.5, 0.18, M('#2b2420', { metalness: 0.4 })); h.position.set(x, y, z); envGroup.add(h);
  const cup = cy(0.2, 0.12, 0.22, 6, M('#3a302a', { metalness: 0.5 })); cup.position.set(x, y + 0.32, z); envGroup.add(cup);
  const f = cn(0.13, 0.42, 6, Gl(color)); f.position.set(x, y + 0.6, z); f.castShadow = false; envGroup.add(f);
  const s = glowSprite(color, 2.4, 0.8); s.position.set(x, y + 0.65, z); envGroup.add(s);
  if (li != null) { const l = PL[li]; l.color = lin(color); l.distance = 13; l.position.set(x, y + 0.9, z + 0.6); flick.push({ l, base: 1.7, f: s, fl: f }); }
  else flick.push({ f: s, fl: f });
  emitters.push({ rate: 4, acc: 0, fn: () => emit(x + (Math.random() - 0.5) * 0.15, y + 0.75, z, (Math.random() - 0.5) * 0.2, 0.9 + Math.random() * 0.6, (Math.random() - 0.5) * 0.2, 0.9, 0.18, color, -0.4, 0.5) });
}

// ---------- zindanlar ----------
const DUNG = [
  { a: '#3b3240', b: '#322a38', base: '#1a1520', lip: '#2a2230', wall: '#3d3346', cap: '#564a60', fog: '#0e0a12', hemiS: '#8a7aa8', hemiG: '#1a1420', sun: '#c8b8ff' },
  { a: '#463a2e', b: '#3c3127', base: '#1d1712', lip: '#2c231b', wall: '#4d3c2c', cap: '#6b5440', fog: '#100c09', hemiS: '#b89a7a', hemiG: '#1d1610', sun: '#ffd2a8' },
  { a: '#2e3d31', b: '#26342a', base: '#121a14', lip: '#1e2a21', wall: '#2f4434', cap: '#47634c', fog: '#08100b', hemiS: '#8ab89a', hemiG: '#0f1a12', sun: '#c8ffd8' },
];
let envLight = { hemi: 0.8, sun: 0.55 };
function buildDungeon(ri, opt = {}) {
  clearEnv();
  const D = DUNG[ri], gap = opt.doors ? { n: opt.doors.n >= 0, s: opt.doors.s >= 0, w: opt.doors.w >= 0, e: opt.doors.e >= 0 } : {};
  scene.background = lin(D.fog); scene.fog.color = lin(D.fog);
  hemi.color = lin(D.hemiS); hemi.groundColor = lin(D.hemiG); hemi.intensity = 0.8;
  sun.color = lin(D.sun); sun.intensity = 0.55; sun.position.set(-8, 26, 12);
  diorama(D, { metal: ri === 1 ? 0.25 : 0 });
  backWall(D.wall, D.cap, 3.4, gap);
  for (const x of [-7, 0, 7]) if (!(gap.n && x === 0)) pillar(x, -HD - 0.4, D.wall, D.cap);
  if (gap.n) doorMark(0, -HD - 0.3, 0, true);
  if (gap.s) doorMark(0, HD - 0.4, 0, false);
  if (gap.w) doorMark(-HW + 0.4, 0, Math.PI / 2, false);
  if (gap.e) doorMark(HW - 0.4, 0, Math.PI / 2, false);
  envLight = { hemi: 0.8, sun: 0.55 };
  if (opt.camp) { camp(); envLight = { hemi: 1.0, sun: 0.75 }; }
  if (opt.lair) { for (let i = 0; i < 8; i++) bones(-HW + 2 + Math.random() * (RW * U - 4), -HD + 3 + Math.random() * 10, Math.random); }
  torch(-7, 2.1, -HD + 0.45, 0); torch(7, 2.1, -HD + 0.45, 1);
  for (const s of [-1, 1]) { const t = torch; t(s * (HW + 0.3), 0.9, 4, null); t(s * (HW + 0.3), 0.9, 14, null); }
  const rng = seeded(11 + ri * 7);
  // moloz taşları ve zemin lekeleri (her bölgede)
  const stoneM = M(D.cap), stoneD = M(D.wall);
  for (let i = 0; i < 34; i++) {
    const s = sp(0.08 + rng() * 0.16, rng() < 0.5 ? stoneM : stoneD, 0); s.scale.y = 0.6;
    const edge = rng() < 0.7;
    s.position.set(edge ? (rng() < 0.5 ? -1 : 1) * (HW - 0.4 - rng() * 1.6) : -HW + 1 + rng() * (RW * U - 2), 0.05, -HD + 1 + rng() * (RH * U - 2));
    s.rotation.set(rng() * 3, rng() * 3, 0); envGroup.add(s);
  }
  const stain = new T.MeshBasicMaterial({ map: GLOW, color: 0x000000, transparent: true, opacity: 0.35, depthWrite: false });
  for (let i = 0; i < 10; i++) { const p = mesh(geo('stain', () => new T.PlaneGeometry(1, 1)), stain, false, false); p.rotation.x = -Math.PI / 2; const sc = 1.5 + rng() * 2.5; p.scale.set(sc, sc * (0.6 + rng() * 0.6), 1); p.position.set(-HW + 1 + rng() * (RW * U - 2), 0.012, -HD + 1 + rng() * (RH * U - 2)); envGroup.add(p); }
  if (ri === 0) {
    // kor çatlakları, kemik yığınları, fıçılar
    for (let i = 0; i < 12; i++) {
      let x = -HW + 1.5 + rng() * (RW * U - 3), z = -HD + 2 + rng() * (RH * U - 4), a = rng() * 6.283;
      for (let k = 0; k < 4; k++) {
        const L = 0.35 + rng() * 0.45;
        const c = bx(0.045, 0.02, L, Gl(k === 0 ? '#ff9a4a' : '#d2581e')); c.castShadow = false; c.receiveShadow = false;
        c.position.set(x + Math.sin(a) * L / 2, 0.015, z + Math.cos(a) * L / 2); c.rotation.y = a; envGroup.add(c);
        x += Math.sin(a) * L; z += Math.cos(a) * L; a += (rng() - 0.5) * 1.6;
      }
      const gs = glowSprite('#ff7a2a', 1.4, 0.25); gs.position.set(x, 0.1, z); envGroup.add(gs);
    }
    for (let i = 0; i < 5; i++) bones(-HW + 1.2 + rng() * 2 + (i % 2) * (RW * U - 4.4), -HD + 3 + rng() * (RH * U - 6), rng);
    for (let i = 0; i < 4; i++) barrel(i % 2 ? HW - 1.1 : -HW + 1.1, -HD + 2 + i * 4.5 + rng(), rng);
    emitters.push({ rate: 9, acc: 0, fn: () => emit(-HW + Math.random() * RW * U, 0.1, -HD + Math.random() * RH * U, (Math.random() - 0.5) * 0.3, 0.5 + Math.random() * 0.8, (Math.random() - 0.5) * 0.3, 3.5, 0.12 + Math.random() * 0.1, Math.random() < 0.7 ? '#ff7a2a' : '#ffcf8a', -0.05, 0.1) });
  } else if (ri === 1) {
    for (const [x, r] of [[-3.5, 1.4], [3.6, 1.1], [-9, 0.9]]) gear(x, 2.0, -HD + 0.1, r, '#7a5a3a');
    for (let k = 0; k < 2; k++) { const p = cy(0.22, 0.22, RW * U, 10, M('#a8683a', { metalness: 0.7, roughness: 0.35 })); p.rotation.z = Math.PI / 2; p.position.set(0, 0.7 + k * 0.6, -HD + 0.15); envGroup.add(p); }
    for (let i = 0; i < 6; i++) crate(i % 2 ? HW - 1 : -HW + 1, -HD + 3 + i * 3.2 + rng(), rng);
    for (const vx of [-5, 5]) {
      const v = cy(0.35, 0.45, 0.3, 8, M('#3a3028', { metalness: 0.6 })); v.position.set(vx, 0.1, -HD + 1.4); envGroup.add(v);
      emitters.push({ rate: 10, acc: 0, fn: () => emit(vx + (Math.random() - 0.5) * 0.3, 0.3, -HD + 1.4, (Math.random() - 0.5) * 0.4, 1.6 + Math.random(), (Math.random() - 0.5) * 0.4, 1.6, 0.55, '#6b6660', -0.2, 0.6) });
    }
    emitters.push({ rate: 1.2, acc: 0, fn: () => { const x = -HW + Math.random() * RW * U; burst3(x, 2.4, -HD + 0.3, '#ffcf6a', 6, 3, 0.12, 9, 0.6); } });
  } else {
    for (let i = 0; i < 9; i++) root(rng);
    for (let i = 0; i < 9; i++) mushrooms(i % 2 ? HW - 1 - rng() * 1.5 : -HW + 1 + rng() * 1.5, -HD + 2 + i * 4 + rng() * 2, rng, i === 4 ? 2 : null);
    emitters.push({ rate: 3, acc: 0, fn: () => emit(-HW + Math.random() * RW * U, 0.5 + Math.random() * 2, -HD + Math.random() * RH * U, (Math.random() - 0.5) * 0.6, (Math.random() - 0.5) * 0.3, (Math.random() - 0.5) * 0.6, 4, 0.22, '#b8ff8a', 0, 0) });
  }
  envKey = opt.key || 'd' + ri;
}
function camp() {
  const cx = X(210), cz = Z(430);
  for (let i = 0; i < 5; i++) { const l = cy(0.12, 0.12, 1.2, 6, M('#4a3020')); l.rotation.z = Math.PI / 2; l.rotation.y = i / 5 * 3.14; l.position.set(cx, 0.15, cz); envGroup.add(l); }
  for (let i = 0; i < 8; i++) { const st = sp(0.18, M('#6a5c55'), 0); const a = i / 8 * 6.283; st.position.set(cx + Math.cos(a) * 0.85, 0.1, cz + Math.sin(a) * 0.85); envGroup.add(st); }
  const f = cn(0.35, 0.9, 7, Gl('#ff8a2a')); f.position.set(cx, 0.55, cz); envGroup.add(f);
  const fs = glowSprite('#ff8a3d', 3.5, 0.9); fs.position.set(cx, 0.7, cz); envGroup.add(fs);
  const l = PL[2]; l.color = lin('#ff9a4a'); l.distance = 12; l.position.set(cx, 1.4, cz); flick.push({ l, base: 2.2, f: fs, fl: f });
  emitters.push({ rate: 10, acc: 0, fn: () => emit(cx + (Math.random() - 0.5) * 0.5, 0.6, cz + (Math.random() - 0.5) * 0.5, (Math.random() - 0.5) * 0.4, 1.5 + Math.random(), (Math.random() - 0.5) * 0.4, 1.1, 0.2, '#ffb04a', -0.3, 0.3) });
  for (const [tx, tz, c] of [[-6, -6, '#8a3b2e'], [6, -3, '#2e6a8a'], [-6.5, 9, '#4e6a3a']]) {
    const tent = mesh(new T.CylinderGeometry(0, 2.0, 2.2, 4, 1), M(c)); tent.rotation.y = Math.PI / 4; tent.position.set(tx, 1.1, tz); envGroup.add(tent);
    const door = bx(0.7, 1.0, 0.05, M('#1a1410')); door.position.set(tx, 0.5, tz + 1.42); envGroup.add(door);
  }
  // kasabaya dönüş geçidi
  const px = X(210), pz = Z(150);
  for (const s of [-1, 1]) { const p = bx(0.8, 3.4, 0.8, M('#6a5c55')); p.position.set(px + s * 1.9, 1.4, pz); envGroup.add(p); }
  const lt = bx(4.6, 0.6, 0.9, M('#7a6a62')); lt.position.set(px, 3.3, pz); envGroup.add(lt);
  const mat = new T.ShaderMaterial({ uniforms: { t: { value: 0 } }, transparent: true, depthWrite: false, blending: T.AdditiveBlending, side: T.DoubleSide,
    vertexShader: 'varying vec2 vUv; void main(){ vUv=uv; gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0); }',
    fragmentShader: 'uniform float t; varying vec2 vUv; void main(){ vec2 p=vUv-0.5; float r=length(p)*2.0; float a=atan(p.y,p.x); float s=sin(a*3.0+r*9.0-t*3.0)*0.5+0.5; vec3 c=mix(vec3(1.0,0.75,0.3),vec3(1.0,0.45,0.2),s); float al=smoothstep(1.0,0.7,r)*(0.45+0.55*s); gl_FragColor=vec4(c*1.3,al); }' });
  const portal = mesh(new T.PlaneGeometry(3.0, 3.0), mat, false, false); portal.position.set(px, 1.5, pz); envGroup.add(portal);
  envAnims.push((dt, tt) => { mat.uniforms.t.value = tt; });
  const L2 = PL[1]; L2.color = lin('#ffb06a'); L2.distance = 9; L2.intensity = 1.6; L2.position.set(px, 1.8, pz + 1.2);
}
function seeded(s) { return () => (s = (s * 16807) % 2147483647) / 2147483647; }
function bones(x, z, r) {
  for (let i = 0; i < 4; i++) { const b = cy(0.05, 0.05, 0.6, 5, M('#d8cfc0')); b.rotation.z = Math.PI / 2; b.rotation.y = r() * 3; b.position.set(x + (r() - 0.5) * 0.6, 0.06, z + (r() - 0.5) * 0.6); envGroup.add(b); }
  const sk = sp(0.17, M('#e0d6c8'), 1); sk.position.set(x, 0.15, z); envGroup.add(sk);
  for (const s of [-1, 1]) { const e = bx(0.05, 0.05, 0.02, M('#1a1410')); e.position.set(x + s * 0.06, 0.18, z + 0.16); envGroup.add(e); }
}
function barrel(x, z, r) { const b = cy(0.42, 0.42, 1.0, 10, M('#5a3d28')); b.position.set(x, 0.5, z); envGroup.add(b); for (const y of [0.2, 0.8]) { const h = cy(0.44, 0.44, 0.07, 10, M('#2a2420', { metalness: 0.6 })); h.position.set(x, y, z); envGroup.add(h); } }
function crate(x, z, r) { const s = 0.8 + r() * 0.4; const c = bx(s, s, s, M('#6b4a2e')); c.position.set(x, s / 2, z); c.rotation.y = r(); envGroup.add(c); const b = bx(s + 0.02, 0.1, s + 0.02, M('#3a2a1c')); b.position.set(x, s * 0.75, z); b.rotation.y = c.rotation.y; envGroup.add(b); }
function gear(x, y, z, r, col) {
  const g = new T.Group(); g.position.set(x, y, z);
  const disk = cy(r, r, 0.25, 16, M(col, { metalness: 0.75, roughness: 0.4 })); disk.rotation.x = Math.PI / 2; g.add(disk);
  const hub = cy(r * 0.3, r * 0.3, 0.35, 8, M('#3a2a1c', { metalness: 0.6 })); hub.rotation.x = Math.PI / 2; g.add(hub);
  const n = Math.round(r * 9);
  for (let i = 0; i < n; i++) { const t = bx(0.25, 0.3, 0.25, M(col, { metalness: 0.75, roughness: 0.4 })); const a = i / n * 6.283; t.position.set(Math.cos(a) * (r + 0.1), Math.sin(a) * (r + 0.1), 0); t.rotation.z = a; g.add(t); }
  envGroup.add(g); const sp_ = (Math.random() < 0.5 ? -1 : 1) * 0.6 / r;
  envAnims.push(dt => { g.rotation.z += sp_ * dt; });
}
function root(r) {
  const side = r() < 0.5 ? -1 : 1, z0 = -HD + r() * RH * U;
  const pts_ = [new T.Vector3(side * (HW + 0.3), 1.2 + r(), z0), new T.Vector3(side * (HW - 0.8 - r()), 0.4, z0 + (r() - 0.5) * 3), new T.Vector3(side * (HW - 1.8 - r() * 2), 0.1, z0 + (r() - 0.5) * 5)];
  const t = mesh(new T.TubeGeometry(new T.CatmullRomCurve3(pts_), 12, 0.18 + r() * 0.12, 6), M('#4a3a26')); envGroup.add(t);
}
function mushrooms(x, z, r, li) {
  for (let i = 0; i < 3; i++) {
    const s = 0.5 + r() * 0.7, ox = x + (r() - 0.5) * 0.9, oz = z + (r() - 0.5) * 0.9;
    const st = cy(0.06 * s, 0.09 * s, 0.5 * s, 6, M('#d8d0b8')); st.position.set(ox, 0.25 * s, oz); envGroup.add(st);
    const cap = mesh(geo('cap', () => new T.SphereGeometry(0.3, 10, 6, 0, 6.283, 0, Math.PI / 2)), Gl('#3affc8')); cap.scale.setScalar(s); cap.position.set(ox, 0.48 * s, oz); envGroup.add(cap);
  }
  const g = glowSprite('#3affc8', 2.2, 0.5); g.position.set(x, 0.5, z); envGroup.add(g);
  if (li != null) { const l = PL[li]; l.color = lin('#3affc8'); l.distance = 9; l.intensity = 1.1; l.position.set(x, 1, z); }
}

// ---------- kasaba ----------
let townBuilt = null;
function buildTown(S) {
  clearEnv();
  scene.background = lin('#120e16'); scene.fog.color = lin('#120e16');
  hemi.color = lin('#ffd9b8'); hemi.groundColor = lin('#2a2018'); hemi.intensity = 0.62;
  sun.color = lin('#ffb27a'); sun.intensity = 0.95; sun.position.set(-16, 20, 8);
  const st = S.STATUE;
  diorama({ a: '#5a504a', b: '#4e4540', base: '#1c1714', lip: '#2e2622' }, {
    tint: (x, z, c) => { const d = Math.hypot(x - X(st.x), z - Z(st.y)); if (d > 2.4 && d < 4.6) c.lerp(lin('#8a6a3a'), 0.45); if (Math.abs(x) < 1.1 && z < Z(st.y) - 1 && z > -HD + 1.5) c.copy(lin('#7a2028')).multiplyScalar(0.9 + Math.random() * 0.15); },
  });
  // halı kenarları
  for (const s of [-1, 1]) { const e = bx(0.08, 0.02, Z(st.y) - 1 - (-HD + 1.5), Gl('#c89a4a')); e.castShadow = false; e.position.set(s * 1.1, 0.01, (Z(st.y) - 1 + (-HD + 1.5)) / 2); envGroup.add(e); }
  // sur duvarı ve mazgallar
  backWall('#5e5048', '#7a6a60', 3.8);
  for (let i = 0; i < 12; i++) { const m = bx(0.9, 0.7, 0.9, M('#6e6058')); m.position.set(-HW + 0.9 + i * 1.75, 3.85, -HD - 0.65); envGroup.add(m); }
  // flamalar
  const banTex = canvasTex(64, 128, (g, w, h) => {
    g.fillStyle = '#8a1f2b'; g.fillRect(0, 0, w, h); g.fillStyle = '#5a121b'; g.fillRect(0, 0, 6, h); g.fillRect(w - 6, 0, 6, h);
    g.fillStyle = '#e8b44a'; g.beginPath(); g.moveTo(14, 60); g.lineTo(14, 36); g.lineTo(23, 48); g.lineTo(32, 30); g.lineTo(41, 48); g.lineTo(50, 36); g.lineTo(50, 60); g.closePath(); g.fill();
    g.fillRect(14, 64, 36, 4); g.beginPath(); g.moveTo(0, h - 16); g.lineTo(w / 2, h); g.lineTo(w, h - 16); g.lineTo(w, h); g.lineTo(0, h); g.fillStyle = '#120e16'; g.fill();
  });
  for (const x of [-4.2, 4.2, -9, 9]) { const b = mesh(new T.PlaneGeometry(1.2, 2.4), new T.MeshStandardMaterial({ map: banTex, side: T.DoubleSide, roughness: 0.9 })); b.position.set(x, 2.2, -HD + 0.02); envGroup.add(b); }
  torch(-6.6, 2.3, -HD + 0.45, null); torch(6.6, 2.3, -HD + 0.45, null);
  for (const b of S.BUILD) buildPiece(b);
  statue(X(st.x), Z(st.y));
  for (const [x, z, li] of [[-6, -1, 2], [6, 6, 3], [-6, 12, null], [6, 15, null]]) lamp(x, z, li);
  const rng = seeded(5);
  [[9.4, 15.6, 0], [9.4, 17.4, 1], [8.1, 17.8, 0], [-9.4, -13, 1], [-9.4, -11.3, 0], [9.4, -12.6, 1]].forEach(([x, z, k]) => (k ? crate : barrel)(x, z, rng));
  for (const [x, z] of [[-3, 17.5], [3.2, 18.6], [8.8, 17]]) plant(x, z);
  emitters.push({ rate: 2, acc: 0, fn: () => emit(-HW + Math.random() * RW * U, 0.4 + Math.random() * 2.5, -HD + Math.random() * RH * U, (Math.random() - 0.5) * 0.5, (Math.random() - 0.5) * 0.2, (Math.random() - 0.5) * 0.5, 5, 0.18, '#ffd27a', 0, 0) });
  envKey = 'town';
}
function buildPiece(b) {
  const x = X(b.x), z = Z(b.y), w = b.w * U, d = b.d * U;
  if (b.id === 'dais') {
    for (let i = 0; i < 3; i++) { const s = bx(w - i * 0.8, 0.22, d - i * 0.5, M(i % 2 ? '#7a6a62' : '#6a5c55')); s.position.set(x, 0.11 + i * 0.22, z - i * 0.15); envGroup.add(s); }
  } else if (b.id === 'throne') {
    const y0 = 0.66;
    const seat = bx(w, 0.5, d, M('#7a1f2b')); seat.position.set(x, y0 + 0.25, z); envGroup.add(seat);
    const back = bx(w, 2.4, 0.3, M('#c8973a', { metalness: 0.7, roughness: 0.35 })); back.position.set(x, y0 + 1.4, z - d / 2); envGroup.add(back);
    const cush = bx(w - 0.3, 1.8, 0.1, M('#8a1f2b')); cush.position.set(x, y0 + 1.25, z - d / 2 + 0.2); envGroup.add(cush);
    for (const s of [-1, 1]) { const a = bx(0.25, 0.7, d, M('#c8973a', { metalness: 0.7, roughness: 0.35 })); a.position.set(x + s * (w / 2), y0 + 0.6, z); envGroup.add(a); }
    for (let i = 0; i < 5; i++) { const sp_ = cn(0.12, 0.45, 4, M('#e8b44a', { metalness: 0.8, roughness: 0.3 })); sp_.position.set(x - w / 2 + 0.12 + i * (w - 0.24) / 4, y0 + 2.8 + (i === 2 ? 0.15 : 0), z - d / 2); envGroup.add(sp_); }
    const gem = sp(0.12, Gl('#ff4a5a')); gem.position.set(x, y0 + 2.2, z - d / 2 + 0.17); envGroup.add(gem);
  } else if (b.id === 'forge') {
    const wall = bx(w, 2.6, d, M('#b8a48a')); wall.position.set(x, 1.3, z); envGroup.add(wall);
    for (const zz of [-d / 2, 0, d / 2]) { const beam = bx(w + 0.06, 2.6, 0.18, M('#4a3020')); beam.position.set(x, 1.3, z + zz); envGroup.add(beam); }
    const hb = bx(w + 0.06, 0.18, d + 0.06, M('#4a3020')); hb.position.set(x, 1.6, z); envGroup.add(hb);
    const roof = mesh(new T.CylinderGeometry(0, w * 0.82, 1.7, 4, 1), M('#7a2a22')); roof.rotation.y = Math.PI / 4; roof.scale.set(1, 1, d / w); roof.position.set(x, 3.45, z); envGroup.add(roof);
    const ch = bx(0.6, 1.6, 0.6, M('#6a5c55')); ch.position.set(x - 0.4, 3.9, z - d / 4); envGroup.add(ch);
    emitters.push({ rate: 6, acc: 0, fn: () => emit(x - 0.4 + (Math.random() - 0.5) * 0.2, 4.8, z - d / 4, 0.25 + Math.random() * 0.2, 0.9 + Math.random() * 0.4, (Math.random() - 0.5) * 0.2, 3, 0.9, '#3a3330', -0.05, 0.2) });
    // ocak ve örs (meydana bakan yüzde)
    const fx_ = x + w / 2 + 0.55;
    const hearth = bx(1.0, 1.0, 1.4, M('#4a403a')); hearth.position.set(fx_, 0.5, z - 1.2); envGroup.add(hearth);
    const coal = bx(0.7, 0.1, 1.0, Gl('#ff6a1a')); coal.position.set(fx_, 1.02, z - 1.2); envGroup.add(coal);
    const fs = glowSprite('#ff8a3d', 2.6, 0.9); fs.position.set(fx_, 1.3, z - 1.2); envGroup.add(fs);
    const l = PL[0]; l.color = lin('#ff8a3d'); l.distance = 9; l.position.set(fx_ + 0.6, 1.6, z - 1.2); flick.push({ l, base: 1.8, f: fs });
    emitters.push({ rate: 5, acc: 0, fn: () => emit(fx_ + (Math.random() - 0.5) * 0.5, 1.1, z - 1.2 + (Math.random() - 0.5) * 0.6, (Math.random() - 0.5) * 0.4, 1.2 + Math.random(), (Math.random() - 0.5) * 0.4, 1, 0.16, '#ffb04a', 1, 0.2) });
    const an = new T.Group(); an.position.set(fx_ + 0.1, 0, z + 1.0);
    const a1 = bx(0.35, 0.55, 0.35, M('#3a302a')); a1.position.y = 0.28; an.add(a1);
    const a2 = bx(0.45, 0.22, 0.95, M('#5a5a62', { metalness: 0.85, roughness: 0.3 })); a2.position.y = 0.66; an.add(a2);
    const a3 = cn(0.11, 0.35, 4, M('#5a5a62', { metalness: 0.85, roughness: 0.3 })); a3.rotation.x = Math.PI / 2; a3.position.set(0, 0.66, 0.62); an.add(a3);
    envGroup.add(an);
  } else if (b.id === 'stall1' || b.id === 'stall2') {
    const col = b.id === 'stall1' ? '#b8323f' : '#2e6aa8';
    const tex = canvasTex(64, 64, (g, w_) => { for (let i = 0; i < 8; i++) { g.fillStyle = i % 2 ? '#efe2c8' : col; g.fillRect(i * 8, 0, 8, 64); } });
    for (const sx of [-1, 1]) for (const sz of [-1, 1]) { const p = cy(0.07, 0.07, 2.2, 6, M('#4a3020')); p.position.set(x + sx * (w / 2 - 0.15), 1.1, z + sz * (d / 2 - 0.15)); envGroup.add(p); }
    const aw = mesh(new T.BoxGeometry(w + 0.3, 0.08, d + 0.3), new T.MeshStandardMaterial({ map: tex, roughness: 0.9 })); aw.position.set(x, 2.25, z); aw.rotation.z = 0.12; envGroup.add(aw);
    const tb = bx(w - 0.3, 0.12, d - 0.6, M('#6b4a2e')); tb.position.set(x, 0.9, z); envGroup.add(tb);
    const tl = bx(w - 0.4, 0.8, d - 0.7, M('#5a3d28')); tl.position.set(x, 0.45, z); envGroup.add(tl);
    const rng = seeded(b.x + b.y);
    for (let i = 0; i < 9; i++) {
      const kind = rng(), px = x - w / 2 + 0.5 + rng() * (w - 1), pz = z - d / 2 + 0.5 + rng() * (d - 1);
      if (kind < 0.4) { const ap = sp(0.12, M(rng() < 0.5 ? '#c8323f' : '#7ab83a'), 0); ap.position.set(px, 1.05, pz); envGroup.add(ap); }
      else if (kind < 0.7) { const pot = cy(0.08, 0.1, 0.3, 6, Gl(['#5fa8ff', '#c47bff', '#ff5d5d'][Math.floor(rng() * 3)])); pot.position.set(px, 1.1, pz); envGroup.add(pot); }
      else { const sw = bx(0.06, 0.05, 0.7, M('#c9d2dc', { metalness: 0.85, roughness: 0.25 })); sw.position.set(px, 0.99, pz); sw.rotation.y = rng(); envGroup.add(sw); }
    }
  } else if (b.id === 'clan') {
    for (const s of [-1, 1]) { const p = cy(0.08, 0.08, 2.2, 6, M('#4a3020')); p.position.set(x, 1.1, z + s * (d / 2 - 0.1)); envGroup.add(p); }
    const board = bx(0.15, 1.3, d, M('#6b4a2e')); board.position.set(x, 1.5, z); envGroup.add(board);
    const rng = seeded(31);
    for (let i = 0; i < 6; i++) { const pp = bx(0.02, 0.35, 0.3, M(['#efe2c8', '#d8c8a8', '#b8323f', '#2e6aa8'][i % 4])); pp.position.set(x - 0.09, 1.2 + rng() * 0.6, z - d / 2 + 0.35 + rng() * (d - 0.7)); pp.rotation.x = (rng() - 0.5) * 0.3; envGroup.add(pp); }
    const roof = bx(0.6, 0.12, d + 0.3, M('#7a2a22')); roof.position.set(x, 2.25, z); envGroup.add(roof);
  } else if (b.id === 'gate') {
    // Sefer kapısı: taş kemer + dönen geçit
    for (const s of [-1, 1]) {
      const p = bx(0.9, 3.6, 0.9, M('#6a5c55')); p.position.set(x, 1.8, z + s * (d / 2 - 0.45)); envGroup.add(p);
      const c = bx(1.1, 0.3, 1.1, M('#7a6a62')); c.position.set(x, 3.65, z + s * (d / 2 - 0.45)); envGroup.add(c);
    }
    const lin_ = bx(0.9, 0.7, d, M('#7a6a62')); lin_.position.set(x, 3.95, z); envGroup.add(lin_);
    const key = bx(1.0, 0.8, 0.6, M('#8a7a70')); key.position.set(x, 4.1, z); envGroup.add(key);
    const mat = new T.ShaderMaterial({
      uniforms: { t: { value: 0 } }, transparent: true, depthWrite: false, blending: T.AdditiveBlending, side: T.DoubleSide,
      vertexShader: 'varying vec2 vUv; void main(){ vUv=uv; gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0); }',
      fragmentShader: 'uniform float t; varying vec2 vUv; void main(){ vec2 p=vUv-0.5; p.y*=0.8; float r=length(p)*2.0; float a=atan(p.y,p.x); float s=sin(a*3.0+r*9.0-t*3.0)*0.5+0.5; vec3 c=mix(vec3(0.25,0.4,1.0),vec3(0.8,0.55,1.0),s); float al=smoothstep(1.0,0.7,r)*(0.45+0.55*s); gl_FragColor=vec4(c*1.4,al); }',
    });
    const portal = mesh(new T.PlaneGeometry(d - 1.8, 3.2), mat, false, false); portal.rotation.y = Math.PI / 2; portal.position.set(x + 0.05, 1.75, z); envGroup.add(portal);
    envAnims.push((dt, t) => { mat.uniforms.t.value = t; });
    const l = PL[1]; l.color = lin('#7a8aff'); l.distance = 10; l.intensity = 1.6; l.position.set(x + 1.2, 1.8, z);
    emitters.push({ rate: 8, acc: 0, fn: () => emit(x + 0.2, 0.3 + Math.random() * 3, z + (Math.random() - 0.5) * (d - 2), 0.4 + Math.random() * 0.4, 0.2, (Math.random() - 0.5) * 0.2, 1.4, 0.2, Math.random() < 0.5 ? '#8fb8ff' : '#c47bff', 0, 0.3) });
  }
}
function statue(x, z) {
  const p1 = cy(1.5, 1.6, 0.5, 8, M('#6a5c55')); p1.position.set(x, 0.25, z); envGroup.add(p1);
  const p2 = cy(1.0, 1.15, 0.9, 8, M('#7a6a62')); p2.position.set(x, 0.95, z); envGroup.add(p2);
  const pl = bx(0.9, 0.35, 0.05, M('#c8973a', { metalness: 0.8, roughness: 0.3 })); pl.position.set(x, 0.95, z + 1.08); envGroup.add(pl);
  const stone = '#9a948e';
  const h = humanoid({ skin: stone, body: stone, body2: '#8a847e', legs: stone, boot: '#8a847e', hair: stone, hat: 'tac', weapon: 'kilic', offhand: 'kalkan', cape: '#8a847e', stone: true });
  h.root.position.set(x, 1.4, z); h.root.scale.setScalar(1.9); h.parts.armR.rotation.x = -2.9; envGroup.add(h.root);
}
function lamp(x, z, li) {
  const p = cy(0.08, 0.1, 2.8, 6, M('#2a2420', { metalness: 0.5 })); p.position.set(x, 1.4, z); envGroup.add(p);
  const b = cy(0.25, 0.3, 0.12, 6, M('#2a2420', { metalness: 0.5 })); b.position.set(x, 0.06, z); envGroup.add(b);
  const lt = bx(0.34, 0.45, 0.34, Gl('#ffd27a')); lt.position.set(x, 2.95, z); envGroup.add(lt);
  const cap = cn(0.32, 0.3, 4, M('#2a2420', { metalness: 0.5 })); cap.position.set(x, 3.32, z); cap.rotation.y = Math.PI / 4; envGroup.add(cap);
  const s = glowSprite('#ffc06a', 2.6, 0.7); s.position.set(x, 2.95, z); envGroup.add(s);
  if (li != null) { const l = PL[li]; l.color = lin('#ffc06a'); l.distance = 10; l.position.set(x, 2.9, z); flick.push({ l, base: 1.2, f: s, soft: 1 }); }
}
function plant(x, z) {
  const pot = cy(0.35, 0.28, 0.5, 8, M('#8a4a2e')); pot.position.set(x, 0.25, z); envGroup.add(pot);
  for (let i = 0; i < 3; i++) { const l = cn(0.4 - i * 0.1, 0.6, 6, M('#3e6b45')); l.position.set(x, 0.75 + i * 0.32, z); envGroup.add(l); }
}

// ---------- karakter modelleri ----------
function humanoid(o) {
  const g = new T.Group(), parts = {};
  const mB = M(o.body), mS = M(o.skin || '#e0b896'), mL = M(o.legs || '#3a2c26');
  for (const s of [-1, 1]) {
    const leg = new T.Group(); leg.position.set(s * 0.14, 0.62, 0);
    const l = bx(0.2, 0.56, 0.22, mL); l.position.y = -0.28; leg.add(l);
    const boot = bx(0.23, 0.16, 0.3, M(o.boot || '#2a2320')); boot.position.set(0, -0.56, 0.03); leg.add(boot);
    g.add(leg); parts[s < 0 ? 'legL' : 'legR'] = leg;
  }
  const torso = cy(0.27, 0.31, 0.64, 8, mB); torso.position.y = 0.93; g.add(torso);
  if (o.robe) { const rb = cy(0.3, 0.44, 0.55, 8, mB); rb.position.y = 0.42; g.add(rb); }
  const chest = bx(0.38, 0.36, 0.08, M(o.body2 || o.body)); chest.position.set(0, 1.0, 0.27); g.add(chest);
  const belt = cy(0.32, 0.32, 0.08, 8, M(o.belt || '#2a1d14')); belt.position.y = 0.66; g.add(belt);
  const head = new T.Group(); head.position.y = 1.47; g.add(head); parts.head = head;
  const hd = sp(0.23, mS, 1); head.add(hd);
  if (!o.stone) for (const s of [-1, 1]) { const e = bx(0.05, 0.06, 0.03, M('#1a1410')); e.position.set(s * 0.08, 0.02, 0.21); head.add(e); }
  if (o.hair) { const hr = mesh(geo('hair', () => new T.SphereGeometry(0.245, 8, 5, 0, 6.283, 0, Math.PI * 0.55)), M(o.hair)); hr.rotation.x = -0.25; head.add(hr); }
  for (const s of [-1, 1]) {
    const arm = new T.Group(); arm.position.set(s * 0.39, 1.2, 0);
    const sh = sp(0.13, M(o.shoulder || o.body), 0); arm.add(sh);
    const a = bx(0.15, 0.5, 0.15, mB); a.position.y = -0.25; arm.add(a);
    const hand = sp(0.08, mS, 0); hand.position.y = -0.53; arm.add(hand);
    const grip = new T.Group(); grip.position.y = -0.55; arm.add(grip);
    g.add(arm); parts[s < 0 ? 'armL' : 'armR'] = arm; parts[s < 0 ? 'gripL' : 'gripR'] = grip;
  }
  if (o.cape) {
    const c = new T.Group(); c.position.set(0, 1.26, -0.24);
    const cm = mesh(geo('cape', () => { const pg = new T.PlaneGeometry(0.62, 1.0, 1, 3); pg.translate(0, -0.5, 0); return pg; }), new T.MeshStandardMaterial({ color: lin(o.cape), side: T.DoubleSide, roughness: 0.9, flatShading: true }));
    c.add(cm); c.rotation.x = 0.12; g.add(c); parts.cape = c;
  }
  hat(head, o.hat, o.stone);
  weapon(parts.gripR, parts.gripL, parts.armL, o.weapon, o.offhand, o.glow, o.stone);
  g.scale.setScalar(o.scale || 1.35);
  return { root: g, parts };
}
function hat(head, kind, stone) {
  if (!kind) return;
  const gold = stone ? M('#a89a7a') : M('#e8b44a', { metalness: 0.85, roughness: 0.3 });
  if (kind === 'tac') {
    const r = mesh(geo('crown', () => new T.CylinderGeometry(0.2, 0.2, 0.12, 8, 1, true)), gold); r.material.side = T.DoubleSide; r.position.y = 0.22; head.add(r);
    for (let i = 0; i < 6; i++) { const a = i / 6 * 6.283, s = cn(0.05, 0.16, 4, gold); s.position.set(Math.cos(a) * 0.19, 0.34, Math.sin(a) * 0.19); head.add(s); }
    if (!stone) { const gm = sp(0.04, Gl('#ff4a5a'), 0); gm.position.set(0, 0.23, 0.2); head.add(gm); }
  } else if (kind === 'sivri') {
    const c = cn(0.2, 0.55, 8, M('#2b2f4a')); c.position.y = 0.42; c.rotation.x = -0.15; head.add(c);
    const b = cy(0.36, 0.36, 0.04, 10, M('#2b2f4a')); b.position.y = 0.17; head.add(b);
  } else if (kind === 'kask') {
    const k = mesh(geo('helm', () => new T.SphereGeometry(0.26, 8, 5, 0, 6.283, 0, Math.PI * 0.6)), M('#9aa6b8', { metalness: 0.85, roughness: 0.35 })); k.position.y = 0.02; head.add(k);
    const pl = bx(0.05, 0.22, 0.32, Gl('#c8323f')); pl.position.set(0, 0.32, -0.02); head.add(pl);
    const vz = bx(0.3, 0.05, 0.05, M('#5a6070', { metalness: 0.8 })); vz.position.set(0, 0.0, 0.24); head.add(vz);
  } else if (kind === 'kukuleta') {
    const h = mesh(geo('hood', () => new T.SphereGeometry(0.29, 8, 6, 0, 6.283, 0, Math.PI * 0.62)), M('#3e4a2e')); h.rotation.x = -0.35; h.position.set(0, 0.02, -0.03); head.add(h);
  }
}
function weapon(gR, gL, armL, w, off, glow, stone) {
  const metal = stone ? M('#a8a29c') : M('#c9d2dc', { metalness: 0.9, roughness: 0.25 });
  const glowM = glow ? Gl(glow) : null;
  if (w === 'kilic') {
    const s = new T.Group();
    const blade = bx(0.07, 0.85, 0.025, glowM || metal); blade.position.y = -0.5; s.add(blade);
    const tip = cn(0.05, 0.14, 4, glowM || metal); tip.position.y = -0.99; tip.rotation.x = Math.PI; s.add(tip);
    const guard = bx(0.28, 0.05, 0.07, stone ? metal : M('#a8783a', { metalness: 0.7 })); guard.position.y = -0.06; s.add(guard);
    const hilt = cy(0.03, 0.03, 0.18, 5, M('#3a2418')); hilt.position.y = 0.05; s.add(hilt);
    s.rotation.x = Math.PI * 0.5; s.position.z = 0.02; gR.add(s);
    if (glow) { const gs = glowSprite(glow, 1.0, 0.6); gs.position.set(0, 0.05, 0.55); s.add(gs); }
  } else if (w === 'asa') {
    const s = new T.Group();
    const shaft = cy(0.035, 0.035, 1.6, 6, M('#5a3a22')); s.add(shaft);
    const orb = sp(0.11, Gl(glow || '#8fb8ff'), 1); orb.position.y = 0.88; s.add(orb);
    for (let i = 0; i < 3; i++) { const p = cn(0.03, 0.2, 4, M('#7a5a3a')); const a = i / 3 * 6.283; p.position.set(Math.cos(a) * 0.08, 0.8, Math.sin(a) * 0.08); p.rotation.z = Math.cos(a) * 0.4; s.add(p); }
    const gs = glowSprite(glow || '#8fb8ff', 0.9, 0.8); gs.position.y = 0.88; s.add(gs);
    s.position.y = 0.1; s.rotation.x = 0.0; gR.add(s);
  } else if (w === 'yay') {
    const s = new T.Group();
    const bow = mesh(geo('bow', () => new T.TorusGeometry(0.5, 0.03, 4, 14, Math.PI * 0.9)), glowM || M('#7a4a2a')); bow.rotation.z = Math.PI / 2 + Math.PI * 0.05; s.add(bow);
    const str = bx(0.01, 0.98, 0.01, M('#e8e0d0')); str.position.x = 0.02; s.add(str);
    s.rotation.y = Math.PI / 2; s.position.set(0, 0, 0.05); gL.add(s);
  }
  if (off === 'kalkan') {
    const sh = new T.Group();
    const d = cy(0.3, 0.3, 0.06, 10, stone ? metal : M('#6a3a2a')); d.rotation.x = Math.PI / 2; sh.add(d);
    const rim = mesh(geo('rim', () => new T.TorusGeometry(0.3, 0.03, 4, 12)), metal); sh.add(rim);
    const boss = sp(0.08, metal, 0); boss.position.z = 0.04; sh.add(boss);
    sh.position.set(-0.08, -0.25, 0.12); sh.rotation.y = -0.25; armL.add(sh);
  } else if (off === 'sadak') {
    // ok sadağı sırtta
  }
}
const CLASSMODEL = {
  savasci: { body: '#8a3a2a', body2: '#9aa6b8', shoulder: '#9aa6b8', legs: '#3a2c26', hair: '#3a2418', weapon: 'kilic', offhand: 'kalkan' },
  okcu: { body: '#4e6a3a', body2: '#6b4a2e', legs: '#4a3a26', hair: '#7a4a22', weapon: 'yay', hat: 'kukuleta', cape: '#2e3d22' },
  buyucu: { body: '#2e4a9a', body2: '#c8973a', legs: '#24366e', hair: '#c8c0b0', weapon: 'asa', hat: 'sivri', robe: 1 },
};
function playerModel(cls, glow) { const m = humanoid(Object.assign({}, CLASSMODEL[cls], { glow })); ring(m.root, CLASSCOL[cls]); return m; }
const CLASSCOL = { savasci: '#ff8a5a', okcu: '#ffd27a', buyucu: '#8fb8ff' };
function ring(parent, col, r = 0.55) {
  const m = mesh(geo('ring' + r, () => new T.RingGeometry(r * 0.78, r, 28)), new T.MeshBasicMaterial({ color: lin(col), transparent: true, opacity: 0.55, depthWrite: false, toneMapped: false }), false, false);
  m.rotation.x = -Math.PI / 2; m.position.y = 0.03; parent.add(m); return m;
}
function npcModel(n, CL) {
  const base = CLASSMODEL[n.cls], of = n.of || {};
  const o = Object.assign({}, base, { body: of.body || base.body, body2: of.top || base.body2, shoulder: of.top || base.shoulder, cape: of.cape || base.cape, hat: of.hat || base.hat });
  const m = humanoid(o);
  if (of.aura) { const a = glowSprite('rgb(' + of.aura + ')', 2.2, 0.35); a.position.y = 0.8; m.root.add(a); m.aura = a; m.auraCol = 'rgb(' + of.aura + ')'; }
  return m;
}
function ratModel() {
  const g = new T.Group(), b = new T.Group(); g.add(b);
  const fur = M('#8a7a6a'), dark = M('#5a4a3e');
  const body = sp(0.32, fur, 1); body.scale.set(1, 0.78, 1.45); body.position.y = 0.32; b.add(body);
  const head = cn(0.2, 0.42, 7, fur); head.rotation.x = Math.PI / 2; head.position.set(0, 0.36, 0.55); b.add(head);
  const nose = sp(0.05, M('#e08a8a'), 0); nose.position.set(0, 0.36, 0.77); b.add(nose);
  for (const s of [-1, 1]) {
    const ear = sp(0.1, M('#c89a8a'), 0); ear.scale.set(1, 1, 0.4); ear.position.set(s * 0.13, 0.55, 0.42); b.add(ear);
    const eye = sp(0.035, Gl('#ff3a2a'), 0); eye.position.set(s * 0.09, 0.44, 0.62); b.add(eye);
    for (const z of [-0.25, 0.25]) { const l = bx(0.08, 0.2, 0.08, dark); l.position.set(s * 0.2, 0.1, z); b.add(l); }
  }
  const tail = mesh(geo('tail', () => new T.TubeGeometry(new T.CatmullRomCurve3([new T.Vector3(0, 0.3, -0.42), new T.Vector3(0, 0.38, -0.8), new T.Vector3(0.15, 0.5, -1.1)]), 8, 0.03, 4)), M('#c89a8a')); b.add(tail);
  g.scale.setScalar(1.35);
  return { root: g, parts: { body: b } };
}
function guardModel() { return humanoid({ body: '#5a6070', body2: '#9aa6b8', shoulder: '#9aa6b8', legs: '#3a3e48', weapon: 'kilic', offhand: 'kalkan', hat: 'kask', skin: '#c8a888', scale: 1.7 }); }
function archerModel() { const m = humanoid({ body: '#5e6a32', body2: '#3e4a22', legs: '#3a3a22', weapon: 'yay', hat: 'kukuleta', cape: '#2e3a18', skin: '#b89a7a' }); return m; }
const BOSSCOL = ['#ff7a2a', '#ffb04a', '#3affc8'];
function bossModel(ri) {
  const g = new T.Group(), parts = {};
  const rock = M(['#4a3a36', '#5a4430', '#34463a'][ri]), dark = M(['#2a2022', '#33281c', '#1e2a22'][ri]), glowc = BOSSCOL[ri];
  for (const s of [-1, 1]) { const leg = new T.Group(); leg.position.set(s * 0.45, 1.1, 0); const l = bx(0.55, 1.1, 0.6, dark); l.position.y = -0.55; leg.add(l); g.add(leg); parts[s < 0 ? 'legL' : 'legR'] = leg; }
  const torso = bx(1.7, 1.4, 1.05, rock); torso.position.y = 1.85; g.add(torso);
  const core = sp(0.3, Gl(glowc), 1); core.position.set(0, 1.95, 0.48); g.add(core); parts.core = core;
  const cs = glowSprite(glowc, 2.2, 0.8); cs.position.set(0, 1.95, 0.6); g.add(cs); parts.coreGlow = cs;
  for (let i = 0; i < 5; i++) { const c = bx(0.06, 0.5 + Math.random() * 0.4, 0.02, Gl(glowc)); c.position.set(-0.6 + i * 0.3, 1.7 + Math.random() * 0.4, 0.53); c.rotation.z = (Math.random() - 0.5) * 0.8; g.add(c); }
  const head = new T.Group(); head.position.y = 2.85; g.add(head); parts.head = head;
  const hd = bx(0.75, 0.6, 0.7, rock); head.add(hd);
  for (const s of [-1, 1]) {
    const e = bx(0.16, 0.08, 0.04, Gl(glowc)); e.position.set(s * 0.17, 0.05, 0.36); head.add(e);
    const horn = cn(0.12, 0.6, 5, M('#d8cfc0')); horn.position.set(s * 0.42, 0.35, 0); horn.rotation.z = -s * 0.6; head.add(horn);
    const arm = new T.Group(); arm.position.set(s * 1.1, 2.3, 0);
    const sh = bx(0.7, 0.6, 0.7, dark); arm.add(sh);
    const a = bx(0.45, 1.0, 0.45, rock); a.position.y = -0.75; arm.add(a);
    const fist = bx(0.6, 0.55, 0.6, dark); fist.position.y = -1.4; arm.add(fist);
    g.add(arm); parts[s < 0 ? 'armL' : 'armR'] = arm;
  }
  g.scale.setScalar(1.45);
  return { root: g, parts, glow: glowc };
}
const WCOL = { trap: '#ff3a8a', fire: '#ff8a2a' };
function warnModel(w) {
  const col = lin(w.aim ? '#ffd27a' : WCOL[w.col] || '#ff3a2a');
  const g = new T.Group();
  const mk = (op) => new T.MeshBasicMaterial({ color: col, transparent: true, opacity: op, depthWrite: false, blending: T.AdditiveBlending, side: T.DoubleSide, toneMapped: false });
  if (w.kind === 'c') {
    const edge = mesh(geo('wring', () => new T.RingGeometry(0.9, 1, 40)), mk(0.75), false, false); edge.rotation.x = -Math.PI / 2; g.add(edge);
    const fill = mesh(geo('wdisc', () => new T.CircleGeometry(1, 40)), mk(0.32), false, false); fill.rotation.x = -Math.PI / 2; fill.position.y = 0.005; g.add(fill);
    return { root: g, parts: { edge, fill } };
  }
  const lg = geo('wline', () => { const p = new T.PlaneGeometry(1, 1); p.rotateX(-Math.PI / 2); p.translate(0, 0, 0.5); return p; });
  const base = mesh(lg, mk(w.aim ? 0.18 : 0.22), false, false); g.add(base);
  const fill = mesh(lg, mk(w.aim ? 0.5 : 0.45), false, false); fill.position.y = 0.005; g.add(fill);
  return { root: g, parts: { base, fill } };
}
function goblinModel() {
  const m = humanoid({ skin: '#7ab84a', body: '#c8973a', body2: '#ffd27a', legs: '#4a3a22', hair: '#3a2a18', scale: 1.05 });
  const sack = sp(0.36, M('#8a6a3a'), 1); sack.position.set(0, 1.05, -0.38); m.root.add(sack);
  const coin = glowSprite('#ffd27a', 1.6, 0.7); coin.position.set(0, 1.4, -0.3); m.root.add(coin);
  for (const s of [-1, 1]) { const ear = cn(0.07, 0.3, 4, M('#7ab84a')); ear.rotation.z = -s * 1.2; ear.position.set(s * 0.27, 0.05, 0); m.parts.head.add(ear); }
  return m;
}
function arrowModel(red) {
  const g = new T.Group();
  if (red) { const s = bx(0.05, 0.05, 0.7, Gl('#ff4a3a')); g.add(s); const gl = glowSprite('#ff4a3a', 0.8, 0.7); g.add(gl); return g; }
  const sh = bx(0.035, 0.035, 0.75, M('#8a6a4a')); g.add(sh);
  const tip = cn(0.06, 0.16, 4, M('#c9d2dc', { metalness: 0.9, roughness: 0.2 })); tip.rotation.x = Math.PI / 2; tip.position.z = 0.44; g.add(tip);
  for (const r of [0, Math.PI / 2]) { const f = bx(0.12, 0.01, 0.16, M('#e8e0d0')); f.rotation.z = r; f.position.z = -0.32; g.add(f); }
  const gl = glowSprite('#ffe39a', 0.6, 0.35); g.add(gl);
  return g;
}
function orbModel(col, r = 0.18) { const g = new T.Group(); g.add(sp(r, Gl(col), 1)); g.add(glowSprite(col, r * 7, 0.85)); return g; }

// ---------- varlık eşitleme ----------
function getModel(obj, kind, make) {
  let m = obj.__m;
  if (!m || m.kind !== kind) {
    m = make(); m.kind = kind; m.obj = obj; m.prevX = obj.x; m.prevY = obj.y; m.walk = 0; m.face = 0;
    obj.__m = m; entGroup.add(m.root); models.add(m);
  }
  m.seen = frameNo; return m;
}
function faceTo(m, dx, dz, dt, sp_ = 12) {
  if (Math.abs(dx) + Math.abs(dz) < 1e-4) return;
  const a = Math.atan2(dx, dz); let d = a - m.face; while (d > Math.PI) d -= 6.283; while (d < -Math.PI) d += 6.283;
  m.face += d * Math.min(1, dt * sp_); m.root.rotation.y = m.face;
}
function animWalk(m, moving, dt, t, speed = 11) {
  m.walk = lerp(m.walk, moving ? 1 : 0, Math.min(1, dt * 10));
  const s = Math.sin(t * speed) * m.walk, p = m.parts;
  if (p.legL) { p.legL.rotation.x = s * 0.7; p.legR.rotation.x = -s * 0.7; }
  if (p.cape) p.cape.rotation.x = 0.12 + m.walk * 0.45 + Math.sin(t * 3) * 0.05;
  return s;
}
function flashModel(m, on) {
  if (!!m.flashing === on) return; m.flashing = on;
  m.root.traverse(o => { if (o.isMesh && !(o.material instanceof T.ShaderMaterial)) { if (on) { o.userData.m0 = o.material; o.material = FLASH; } else if (o.userData.m0) o.material = o.userData.m0; } });
}
function syncRun(S, dt, t) {
  const p = S.P1, cls = S.save.cls;
  const wpn = S.save.eq.silah, glow = wpn && wpn.plus >= 7 ? ['#ffffff', '#5fa8ff', '#c47bff', '#ffb347'][wpn.r] : null;
  const pm = getModel(p, 'p' + cls + (glow || ''), () => playerModel(cls, glow));
  const px = X(p.x), pz = Z(p.y);
  const moved = Math.hypot(p.x - pm.prevX, p.y - pm.prevY) / Math.max(dt, 1e-3);
  pm.root.position.set(px, 0, pz);
  if (p.dashT > 0) { faceTo(pm, p.fx, p.fy, dt, 30); for (let i = 0; i < 2; i++) emit(px + (Math.random() - 0.5) * 0.4, 0.6 + Math.random() * 0.8, pz + (Math.random() - 0.5) * 0.4, 0, 0.2, 0, 0.35, 0.5, CLASSCOL[cls], 0, 0); }
  else faceTo(pm, moved > 20 && !S.anyEnemy ? p.fx : p.ax, moved > 20 && !S.anyEnemy ? p.fy : p.ay, dt);
  const sw = animWalk(pm, moved > 20, dt, t);
  const pp = pm.parts;
  pm.atk = p.atkT || 0;
  if (cls === 'savasci') {
    const k = p.swing > 0 ? 1 - p.swing / 0.16 : 1;
    pp.armR.rotation.x = p.swing > 0 ? -2.5 + k * 3.1 : -sw * 0.6 - 0.2;
    pp.armL.rotation.x = -0.5 + sw * 0.3;
  } else if (cls === 'okcu') {
    const a = pm.atk > 0 ? 1 : S.anyEnemy ? 0.6 : 0;
    pp.armL.rotation.x = lerp(sw * 0.6, -1.5, a); pp.armR.rotation.x = lerp(-sw * 0.6, -1.4, a); pp.armR.rotation.z = a * 0.5;
  } else {
    const a = pm.atk > 0 ? pm.atk / 0.25 : 0;
    pp.armR.rotation.x = -0.4 - a * 1.6 - sw * 0.3; pp.armL.rotation.x = sw * 0.6;
  }
  pm.root.position.y = Math.abs(sw) * 0.05;
  const vis = !(p.inv > 0 && p.inv < 0.3 && Math.floor(t * 20) % 2);
  pm.root.visible = vis;
  pm.prevX = p.x; pm.prevY = p.y;
  // oyuncu ışığı
  const l = PL[4]; l.color = lin('#ffc890'); l.distance = 10; l.intensity = 0.9; l.position.set(px, 2.6, pz + 0.6);
  // düşmanlar
  let bossL = false;
  for (const e of S.enemies) {
    if (e.dead) continue;
    const m = getModel(e, e.type + (e.elite || ''), () => {
      const mm = e.type === 'rat' ? ratModel() : e.type === 'guard' ? guardModel() : e.type === 'archer' ? archerModel() : e.type === 'goblin' ? goblinModel() : bossModel(S.run.region);
      if (e.elite) { const c = e.elite === 'hizli' ? '#ffb347' : '#ff4a3a'; mm.root.scale.multiplyScalar(1.22); ring(mm.root, c, 0.75); const a = glowSprite(c, 2.4, 0.4); a.position.y = 0.6; mm.root.add(a); mm.eliteCol = c; }
      mm.baseScale = mm.root.scale.x; mm.enemy = 1; return mm;
    });
    if (m.eliteCol && Math.random() < dt * 8) emit(X(e.x) + (Math.random() - 0.5) * 0.8, 0.2, Z(e.y) + (Math.random() - 0.5) * 0.8, 0, 1.2, 0, 0.7, 0.25, m.eliteCol, 0, 0);
    if (e.type === 'goblin' && Math.random() < dt * 6) emit(X(e.x), 1.2, Z(e.y), (Math.random() - 0.5) * 2, 2, (Math.random() - 0.5) * 2, 0.6, 0.18, '#ffd27a', 9, 0.3);
    const ex = X(e.x), ez = Z(e.y);
    const mv = Math.hypot(e.x - m.prevX, e.y - m.prevY) / Math.max(dt, 1e-3);
    m.root.position.set(ex, 0, ez);
    faceTo(m, X(p.x) - ex, Z(p.y) - ez, dt, 8);
    if (e.dashT > 0 && Math.random() < 0.6) emit(ex, 0.4, ez, 0, 0.3, 0, 0.3, 0.35, '#ff8a6a', 0, 0);
    if (e.type === 'rat') { m.parts.body.position.y = Math.abs(Math.sin(t * 16 + e.x)) * 0.08 * (mv > 10 ? 1 : 0.2); m.parts.body.rotation.z = Math.sin(t * 16 + e.x) * 0.1; }
    else if (e.type === 'boss') {
      const s = animWalk(m, mv > 5, dt, t, 4);
      m.parts.armL.rotation.x = s * 0.5 + Math.sin(t * 1.5) * 0.1; m.parts.armR.rotation.x = -s * 0.5 - Math.sin(t * 1.5) * 0.1;
      m.root.rotation.x = e.charge > 0 ? 0.25 : 0;
      const k = 1 + Math.sin(t * 6) * 0.12 + (e.hp < e.mhp / 2 ? 0.2 : 0);
      m.parts.core.scale.setScalar(k); m.parts.coreGlow.scale.setScalar(2.2 * k);
      const L = PL[3]; L.color = lin(m.glow); L.distance = 12; L.intensity = 2.2 * k; L.position.set(ex, 2.4, ez + 1.2); bossL = true;
      if (Math.random() < dt * 14) emit(ex + (Math.random() - 0.5) * 1.6, 2.5 + Math.random(), ez + (Math.random() - 0.5), 0, 1, 0, 0.8, 0.25, m.glow, -0.5, 0.2);
    } else {
      const s = animWalk(m, mv > 10, dt, t);
      if (e.type === 'archer') { m.parts.armL.rotation.x = -1.4; m.parts.armR.rotation.x = -1.3 + Math.max(0, 0.6 - e.cd) * 0.5; }
      else if (e.type === 'goblin') { m.parts.armL.rotation.x = s * 0.9; m.parts.armR.rotation.x = -s * 0.9; }
      else { m.parts.armR.rotation.x = e.atkLock > 0 ? -2.6 + (1 - Math.min(1, e.atkLock)) * 3 : -s * 0.6 - 0.3; m.parts.armL.rotation.x = -0.6; }
    }
    flashModel(m, e.flash > 0);
    if (e.slow > 0 && Math.random() < dt * 10) emit(ex + (Math.random() - 0.5), 0.3 + Math.random() * 1.2, ez + (Math.random() - 0.5), 0, 0.3, 0, 0.6, 0.25, '#bfe6ff', 0, 0);
    m.prevX = e.x; m.prevY = e.y;
  }
  if (!bossL) PL[3].intensity = 0;
  // uyarı alanları
  for (const w of S.warns || []) {
    const m = getModel(w, 'w' + w.kind + (w.aim ? 'a' : '') + (w.col || ''), () => warnModel(w));
    const k = clamp(1 - w.t / w.t0, 0, 1);
    if (w.kind === 'c') { m.root.position.set(X(w.x), 0.03, Z(w.y)); m.root.scale.setScalar(w.r * U); m.parts.fill.scale.setScalar(Math.max(0.02, k)); m.parts.edge.material.opacity = 0.5 + 0.4 * Math.sin(t * 20) * k; }
    else {
      const dx = X(w.x2) - X(w.x), dz = Z(w.y2) - Z(w.y), L = Math.hypot(dx, dz);
      m.root.position.set(X(w.x), 0.03, Z(w.y)); m.root.rotation.y = Math.atan2(dx, dz);
      m.parts.base.scale.set(w.w * U, 1, L); m.parts.fill.scale.set(w.w * U, 1, Math.max(0.01, L * k));
    }
  }
  // diğer oyuncular (açık bölge)
  for (const b of S.bots || []) {
    const m = getModel(b, 'bot' + b.cls, () => npcModel(b));
    const mv = Math.hypot(b.x - m.prevX, b.y - m.prevY) / Math.max(dt, 1e-3);
    m.root.position.set(X(b.x), 0, Z(b.y)); faceTo(m, b.fx, b.fy, dt, 10);
    const s = animWalk(m, mv > 5, dt, t + b.lvl);
    m.parts.armL.rotation.x = s * 0.6; m.parts.armR.rotation.x = b.atkT > 0 ? (b.cls === 'savasci' ? -2.4 + (0.25 - b.atkT) * 12 : -1.5) : -s * 0.6;
    if (b.cls === 'okcu' && b.atkT > 0) m.parts.armL.rotation.x = -1.5;
    if (m.aura && Math.random() < dt * 4) emit(X(b.x) + (Math.random() - 0.5) * 0.6, 0.2, Z(b.y) + (Math.random() - 0.5) * 0.6, 0, 0.9, 0, 1.2, 0.2, m.auraCol, 0, 0);
    m.prevX = b.x; m.prevY = b.y;
  }
  // mermiler
  for (const b of S.shots) {
    const m = getModel(b, b.kind, () => b.kind === 'arrow' ? { root: arrowModel(false), parts: {} } : { root: orbModel('#8fb8ff', 0.16), parts: {} });
    m.root.position.set(X(b.x), 0.75, Z(b.y)); m.root.rotation.y = Math.atan2(b.vx, b.vy);
    if (b.kind === 'bolt' && Math.random() < 0.8) emit(X(b.x), 0.75, Z(b.y), (Math.random() - 0.5) * 0.4, (Math.random() - 0.5) * 0.4, (Math.random() - 0.5) * 0.4, 0.35, 0.35, '#8fb8ff', 0, 0);
  }
  for (const a of S.arrows) {
    const m = getModel(a, a.orb ? 'orb' : 'earrow', () => a.orb ? { root: orbModel(BOSSCOL[S.run.region], 0.2), parts: {} } : { root: arrowModel(true), parts: {} });
    m.root.position.set(X(a.x), 0.85, Z(a.y)); m.root.rotation.y = Math.atan2(a.vx, a.vy);
    if (a.orb && Math.random() < 0.5) emit(X(a.x), 0.85, Z(a.y), 0, 0, 0, 0.3, 0.4, BOSSCOL[S.run.region], 0, 0);
  }
  // doğum halkaları
  for (const q of S.pending) {
    const m = getModel(q, 'spawn', () => { const g = new T.Group(); const r = ring(g, '#ff4a3a', 0.9); const r2 = ring(g, '#ff8a6a', 0.5); return { root: g, parts: { r, r2 } }; });
    const k = clamp(1 - q.t / 1.2, 0, 1);
    m.root.position.set(X(q.x), 0.02, Z(q.y)); m.root.scale.setScalar(1.6 - k * 0.6); m.parts.r.material.opacity = 0.3 + 0.6 * k; m.parts.r2.rotation.z = t * 3;
    if (Math.random() < dt * 20) emit(X(q.x) + (Math.random() - 0.5) * 1.2, 0.1, Z(q.y) + (Math.random() - 0.5) * 1.2, 0, 1.5, 0, 0.5, 0.25, '#ff5a3a', 0, 0);
  }
}
function syncTown(S, dt, t) {
  const T_ = S.town;
  for (const n of T_.npcs) {
    const m = getModel(n, 'npc', () => npcModel(n));
    const mv = Math.hypot(n.x - m.prevX, n.y - m.prevY) / Math.max(dt, 1e-3);
    m.root.position.set(X(n.x), 0, Z(n.y));
    faceTo(m, mv > 5 ? (n.fx || 0) : (n.role === 'king' || n.role === 'guard' ? 0 : n.fx || 0), mv > 5 ? (n.fy || 0) : (n.role === 'king' || n.role === 'guard' ? 1 : n.fy || 0), dt, 6);
    const s = animWalk(m, mv > 5, dt, t + n.lvl);
    m.parts.armL.rotation.x = s * 0.6; m.parts.armR.rotation.x = -s * 0.6 - (n.role === 'smith' ? Math.max(0, Math.sin(t * 5)) * 1.8 : 0);
    if (m.aura) { m.aura.material.opacity = 0.3 + Math.sin(t * 3 + n.lvl) * 0.1; if (Math.random() < dt * 4) emit(X(n.x) + (Math.random() - 0.5) * 0.6, 0.2, Z(n.y) + (Math.random() - 0.5) * 0.6, 0, 0.9, 0, 1.2, 0.2, m.auraCol, 0, 0); }
    m.prevX = n.x; m.prevY = n.y;
  }
  if (S.save && S.showMe) {
    const p = T_.p, cls = S.save.cls;
    const wpn = S.save.eq.silah, glow = wpn && wpn.plus >= 7 ? ['#ffffff', '#5fa8ff', '#c47bff', '#ffb347'][wpn.r] : null;
    const pm = getModel(p, 'p' + cls + (glow || ''), () => playerModel(cls, glow));
    const mv = Math.hypot(p.x - pm.prevX, p.y - pm.prevY) / Math.max(dt, 1e-3);
    pm.root.position.set(X(p.x), 0, Z(p.y)); faceTo(pm, p.fx, p.fy, dt);
    const s = animWalk(pm, mv > 5, dt, t);
    pm.parts.armL.rotation.x = s * 0.6 * (S.save.cls === 'okcu' ? 1 : 1); pm.parts.armR.rotation.x = -s * 0.6;
    pm.prevX = p.x; pm.prevY = p.y;
    const l = PL[4]; l.color = lin('#ffc890'); l.distance = 8; l.intensity = 0.5; l.position.set(X(p.x), 2.6, Z(p.y) + 0.6);
  } else PL[4].intensity = 0;
}
function cullModels(dt) {
  for (const m of [...models]) {
    if (m.seen === frameNo) continue;
    if (m.enemy) {
      if (m.dying == null) { m.dying = 0.5; flashModel(m, false); }
      m.dying -= dt; const k = Math.max(0, m.dying / 0.5);
      m.root.scale.setScalar(m.baseScale * (0.3 + 0.7 * k)); m.root.position.y -= dt * 1.2; m.root.rotation.z += dt * 4;
      if (m.dying > 0) continue;
    }
    entGroup.remove(m.root); models.delete(m); if (m.obj && m.obj.__m === m) delete m.obj.__m;
  }
}

// ---------- efektler ----------
function addFx(o) { fxGroup.add(o.mesh); effects.push(o); }
function stepFx(dt) {
  for (let i = effects.length - 1; i >= 0; i--) {
    const f = effects[i]; f.t += dt; const k = f.t / f.dur;
    if (k >= 1) { fxGroup.remove(f.mesh); effects.splice(i, 1); continue; }
    f.upd(k, f.mesh);
  }
}
function fxRing(x, z, r, col, dur = 0.45, y = 0.05) {
  const m = mesh(geo('fxring', () => new T.RingGeometry(0.85, 1, 48)), new T.MeshBasicMaterial({ color: lin(col), transparent: true, depthWrite: false, blending: T.AdditiveBlending, side: T.DoubleSide, toneMapped: false }), false, false);
  m.rotation.x = -Math.PI / 2; m.position.set(x, y, z);
  addFx({ mesh: m, t: 0, dur, upd: (k, o) => { o.scale.setScalar(0.3 * r + k * 0.7 * r); o.material.opacity = (1 - k) * 0.9; } });
}
function fxSlash(x, z, a, r, col) {
  const m = mesh(geo('slash', () => new T.RingGeometry(0.55, 1, 24, 1, -1.15, 2.3)), new T.MeshBasicMaterial({ color: lin(col), transparent: true, depthWrite: false, blending: T.AdditiveBlending, side: T.DoubleSide, toneMapped: false }), false, false);
  m.rotation.x = -Math.PI / 2; m.rotation.z = -a; m.position.set(x, 0.75, z); m.scale.setScalar(r);
  addFx({ mesh: m, t: 0, dur: 0.18, upd: (k, o) => { o.material.opacity = (1 - k) * 0.85; o.scale.setScalar(r * (0.85 + k * 0.2)); } });
}
function fxBeam(x, z, col, dur = 1.4, h = 6, w = 0.5) {
  const m = mesh(geo('beam', () => { const g = new T.CylinderGeometry(1, 1, 1, 16, 1, true); g.translate(0, 0.5, 0); return g; }), new T.MeshBasicMaterial({ color: lin(col), transparent: true, depthWrite: false, blending: T.AdditiveBlending, side: T.DoubleSide, toneMapped: false }), false, false);
  m.position.set(x, 0, z); m.scale.set(w, h, w);
  addFx({ mesh: m, t: 0, dur, upd: (k, o) => { o.material.opacity = Math.sin(k * Math.PI) * 0.45; o.scale.x = o.scale.z = w * (1 - k * 0.5); } });
}
function fxIce(x, z, r) {
  const g = new T.Group(); g.position.set(x, 0, z);
  const n = 18;
  for (let i = 0; i < n; i++) { const a = i / n * 6.283, d = r * (0.55 + Math.random() * 0.45); const c = cn(0.18 + Math.random() * 0.12, 0.9 + Math.random() * 0.8, 5, M('#bfe6ff', { emissive: '#4a8aff', emissiveIntensity: 0.6, metalness: 0.2, roughness: 0.1, transparent: true, opacity: 0.85 })); c.position.set(Math.cos(a) * d, 0, Math.sin(a) * d); c.rotation.set((Math.random() - 0.5) * 0.5, 0, (Math.random() - 0.5) * 0.5); g.add(c); }
  addFx({ mesh: g, t: 0, dur: 0.9, upd: (k, o) => { o.children.forEach((c, i) => { const kk = Math.min(1, k * 5); c.scale.setScalar(k < 0.75 ? kk : (1 - k) * 4); c.position.y = (kk - 1) * 0.6; }); } });
  fxRing(x, z, r, '#bfe6ff', 0.5);
  burst3(x, 0.4, z, '#bfe6ff', 40, 6, 0.3, 6, 0.8);
}
function ev(type, d) {
  const x = d && d.x != null ? X(d.x) : 0, z = d && d.y != null ? Z(d.y) : 0;
  switch (type) {
    case 'swing': fxSlash(x, z, d.a, d.r * U, d.col || '#ffd2a8'); break;
    case 'hit': burst3(x, 0.8, z, d.crit ? '#ffe27a' : '#ffd8b0', d.crit ? 12 : 6, d.crit ? 5 : 3.5, 0.22, 10, 0.4); break;
    case 'kill': burst3(x, 0.7, z, d.col || '#ffb08a', d.boss ? 80 : 18, d.boss ? 8 : 4.5, 0.35, 9, 0.8); if (d.boss) { fxRing(x, z, 6, '#ffb04a', 0.8); shake = Math.max(shake, 0.6); } break;
    case 'shock': fxRing(x, z, d.r * U, '#ffab7a', 0.45); fxRing(x, z, d.r * U * 0.7, '#ffffff', 0.3); burst3(x, 0.2, z, '#c8a888', 40, 6, 0.3, 14, 0.7); shake = Math.max(shake, 0.35); break;
    case 'ice': fxIce(x, z, d.r * U); break;
    case 'boom': fxRing(x, z, d.r * U, '#b8c6ff', 0.3); burst3(x, 0.75, z, '#8fb8ff', 14, 4, 0.3, 4, 0.45); break;
    case 'volley': burst3(x, 1, z, '#ffe39a', 24, 5, 0.25, 4, 0.4); break;
    case 'cast': burst3(x, 1.6, z, d.col || '#8fb8ff', 6, 2, 0.25, 0, 0.3); break;
    case 'hurt': burst3(x, 0.9, z, '#ff4a3a', 10, 3.5, 0.3, 9, 0.5); shake = Math.max(shake, d.k || 0.2); break;
    case 'level': fxBeam(x, z, '#ffd27a', 1.6, 8, 0.9); fxRing(x, z, 3, '#ffd27a', 0.8); for (let i = 0; i < 50; i++) { const a = i / 50 * 6.283 * 3; emit(x + Math.cos(a) * 0.8, i * 0.08, z + Math.sin(a) * 0.8, 0, 2, 0, 1.2, 0.3, '#ffe39a', 0, 0); } break;
    case 'loot': fxBeam(x, z, d.col, 2.2, 5, 0.25); burst3(x, 0.5, z, d.col, 16, 3, 0.3, 5, 0.8); break;
    case 'gold': burst3(x, 0.8, z, '#ffd27a', 5, 3, 0.18, 12, 0.6); break;
    case 'dash': burst3(x, 0.3, z, '#efe6dc', 8, 2.5, 0.3, 2, 0.4); break;
    case 'spawn': burst3(x, 0.2, z, '#ff4a3a', 12, 3, 0.3, 6, 0.6); break;
    case 'clear': break;
    case 'perfect': fxRing(x, z, 3.2, '#7ff0ff', 0.6); fxRing(x, z, 1.6, '#ffffff', 0.35); burst3(x, 1, z, '#7ff0ff', 30, 5, 0.3, 2, 0.7); shake = Math.max(shake, 0.15); break;
    case 'impact': fxRing(x, z, d.r * U, d.fire ? '#ffb04a' : '#ff8a8a', 0.35); burst3(x, 0.2, z, d.fire ? '#ff8a2a' : '#c8b0a0', 16, 4, 0.3, 12, 0.5); shake = Math.max(shake, 0.12); break;
    case 'poof': burst3(x, 0.8, z, '#ffe39a', 30, 4, 0.3, 0, 0.6); fxRing(x, z, 1.5, '#ffe39a', 0.4); break;
  }
}
function burst(x, y, zPx, col, n, spd) { burst3(X(x), Y(zPx || 10), Z(y), col, n, (spd || 120) * U * 1.2); }
function project(x, y, zPx) {
  const v = new T.Vector3(X(x), Y(zPx || 0), Z(y)).project(camera);
  return [(v.x + 1) / 2 * W, (1 - v.y) / 2 * H, v.z];
}

// ---------- kamera ----------
function updateCamera(dt, fx, fz, menuOrbit) {
  const fovH = T.MathUtils.degToRad(camera.fov / 2), asp = W / H;
  let d = asp < 1 ? 7.4 / (Math.tan(fovH) * asp) : 11 / Math.tan(fovH);
  d = Math.min(d, 75);
  const el = T.MathUtils.degToRad(56);
  const tx = clamp(fx, -3.4, 3.4), tz = clamp(fz, -HD + 6.5, HD - 10);
  if (!camInit) { camT.set(tx, 0, tz); camInit = true; }
  camT.x = lerp(camT.x, tx, Math.min(1, dt * 5)); camT.z = lerp(camT.z, tz, Math.min(1, dt * 5));
  if (menuOrbit) {
    orbit += dt * 0.12;
    const r = d * Math.cos(el);
    camera.position.set(camT.x + Math.sin(orbit) * r * 0.5, d * Math.sin(el), camT.z + Math.cos(orbit) * r);
  } else camera.position.set(camT.x, d * Math.sin(el), camT.z + d * Math.cos(el));
  if (shake > 0) { camera.position.x += (Math.random() - 0.5) * shake * 0.8; camera.position.y += (Math.random() - 0.5) * shake * 0.8; shake = Math.max(0, shake - dt * 1.5); }
  camera.lookAt(camT.x, 0, camT.z);
  scene.fog.near = d * 0.9; scene.fog.far = d * 1.9;
  sun.target.position.set(camT.x, 0, camT.z); sun.position.set(camT.x - 8, 26, camT.z + 12);
}

// ---------- 2D katman (isimler, sayılar, can barları) ----------
function txt(s, x, y, col, size, weight = 700) {
  octx.font = `${weight} ${size}px Rubik, system-ui, sans-serif`;
  octx.fillStyle = 'rgba(0,0,0,.7)'; octx.fillText(s, x + 1, y + 1.5); octx.fillStyle = col; octx.fillText(s, x, y);
}
function drawOverlay(S) {
  const d = ov._d; octx.setTransform(d, 0, 0, d, 0, 0); octx.clearRect(0, 0, W, H); octx.textAlign = 'center';
  const k = clamp(W / 400, 0.85, 1.3);
  if (S.mode === 'town' || (!S.run && S.town)) {
    for (const b of S.BUILD) if (b.label) { const [sx, sy] = project(b.x, b.y, b.lh || 90); txt(b.label, sx, sy, '#efe6dc', 11 * k); }
    { const [sx, sy] = project(S.STATUE.x, S.STATUE.y, 95); txt('Kasım Kralı · Demirkurt', sx, sy, '#ffd27a', 10 * k); }
    const lab = [];
    for (const n of S.town.npcs) { const [sx, sy, sz] = project(n.x, n.y, n.of && n.of.hat ? 46 : 40); lab.push({ sx, sy, sz, n }); }
    lab.sort((a, b) => b.sz - a.sz);
    for (const l of lab) {
      const n = l.n, king = n.title === 'Kral';
      txt((n.clan ? '[' + n.clan + '] ' : '') + n.name, l.sx, l.sy, king ? '#ffd27a' : (n.of && n.of.name) || '#efe6dc', 10 * k);
      if (n.title) txt(n.title, l.sx, l.sy - 11 * k, king ? '#ffd27a' : '#c9bcb0', 8.5 * k, 500);
    }
    if (S.save && S.showMe) { const [sx, sy] = project(S.town.p.x, S.town.p.y, 40); txt('Sen · Sv ' + S.save.lvl, sx, sy, '#8fb8ff', 10 * k); }
  }
  if (S.run && S.mode !== 'town') {
    for (const e of S.enemies) {
      if (e.dead || e.hp >= e.mhp) continue;
      const boss = e.type === 'boss', [sx, sy] = project(e.x, e.y, boss ? 85 : e.type === 'guard' ? 46 : e.type === 'rat' ? 22 : 38);
      const w = (boss ? 90 : 34) * k, h = boss ? 6 : 4;
      octx.fillStyle = 'rgba(0,0,0,.65)'; octx.fillRect(sx - w / 2 - 1, sy - 1, w + 2, h + 2);
      octx.fillStyle = boss ? '#ff8a3d' : '#ff5d5d'; octx.fillRect(sx - w / 2, sy, w * clamp(e.hp / e.mhp, 0, 1), h);
    }
    for (const b of S.bots || []) {
      const [sx, sy] = project(b.x, b.y, 46);
      txt((b.clan ? '[' + b.clan + '] ' : '') + b.name, sx, sy, (b.of && b.of.name) || '#d8e8ff', 9.5 * k);
      txt('Sv ' + b.lvl, sx, sy - 10 * k, '#c9bcb0', 8 * k, 500);
    }
    if (S.run.kind === 'acik') {
      const D = S.doors, R_ = S.OPEN.rooms, at = { n: [210, 30], s: [210, 790], w: [30, 410], e: [390, 410] };
      for (const k2 of ['n', 's', 'w', 'e']) if (D[k2] >= 0) { const [sx, sy] = project(at[k2][0], at[k2][1], 70); txt(R_[D[k2]].ad + ' · Sv ' + R_[D[k2]].lvl, sx, sy, '#bcd0ff', 10 * k); }
      if (R_[S.run.room].camp) { const [sx, sy] = project(S.CAMP_PORTAL.x, S.CAMP_PORTAL.y, 85); txt('Kasabaya dönüş', sx, sy, '#ffd27a', 11 * k); }
      miniMap(S, k);
    }
    for (const q of S.texts) {
      const [sx, sy] = project(q.x, q.y, q.z + 20); octx.globalAlpha = clamp(q.t * 1.5, 0, 1);
      txt(q.txt, sx, sy, q.col, (q.big ? 13 : 11) * k * (q.big && q.t > 0.85 ? 1 + (q.t - 0.85) * 2 : 1));
    }
    octx.globalAlpha = 1;
  }
  const j = S.joy;
  if (j && j.on && (S.mode === 'play' || S.mode === 'town')) {
    octx.strokeStyle = 'rgba(239,230,220,.3)'; octx.lineWidth = 2; octx.beginPath(); octx.arc(j.bx, j.by, 50, 0, 6.283); octx.stroke();
    octx.fillStyle = 'rgba(239,230,220,.35)'; octx.beginPath(); octx.arc(j.bx + j.dx * 50, j.by + j.dy * 50, 20, 0, 6.283); octx.fill();
  }
  if (S.mode === 'pause') { octx.fillStyle = 'rgba(10,8,12,.55)'; octx.fillRect(0, 0, W, H); octx.font = '22px Bungee, Impact, sans-serif'; octx.fillStyle = '#efe6dc'; octx.fillText('Duraklatıldı', W / 2, H / 2); }
}

function miniMap(S, k) {
  const R_ = S.OPEN.rooms, cs = 14 * k, gp = 4 * k, cols = 6, rows = 3;
  const w = cols * cs + (cols - 1) * gp + 14, h = rows * cs + (rows - 1) * gp + 26;
  const x0 = W - w - 12, y0 = 132;
  octx.fillStyle = 'rgba(17,14,20,.62)'; octx.strokeStyle = 'rgba(255,255,255,.12)'; octx.lineWidth = 1;
  octx.beginPath(); octx.roundRect ? octx.roundRect(x0, y0, w, h, 10) : octx.rect(x0, y0, w, h); octx.fill(); octx.stroke();
  octx.textAlign = 'left'; octx.font = `700 ${8.5 * k}px Rubik, system-ui, sans-serif`; octx.fillStyle = '#c9bcb0'; octx.fillText(S.OPEN.ad, x0 + 7, y0 + 12);
  const cx = r => x0 + 7 + r.gx * (cs + gp), cy_ = r => y0 + 19 + r.gy * (cs + gp);
  octx.strokeStyle = 'rgba(188,208,255,.45)'; octx.lineWidth = 2;
  R_.forEach((r, i) => { for (const [dx, dy] of [[1, 0], [0, 1]]) { const j = R_.findIndex(o => o.gx === r.gx + dx && o.gy === r.gy + dy); if (j >= 0) { octx.beginPath(); octx.moveTo(cx(r) + cs / 2, cy_(r) + cs / 2); octx.lineTo(cx(R_[j]) + cs / 2, cy_(R_[j]) + cs / 2); octx.stroke(); } } });
  R_.forEach((r, i) => {
    const cur = i === S.run.room, vis = S.run.visited[i];
    octx.fillStyle = cur ? '#ff8a3d' : r.camp ? '#3e6b45' : r.lair ? '#7a1f2b' : vis ? '#4e4258' : '#2a2330';
    octx.fillRect(cx(r), cy_(r), cs, cs);
    octx.strokeStyle = r.lair ? '#ff5d5d' : 'rgba(255,255,255,.25)'; octx.lineWidth = 1; octx.strokeRect(cx(r) + 0.5, cy_(r) + 0.5, cs - 1, cs - 1);
    octx.textAlign = 'center'; octx.font = `700 ${7 * k}px Rubik, system-ui, sans-serif`; octx.fillStyle = cur ? '#1a0d05' : '#efe6dc';
    octx.fillText(r.camp ? 'K' : String(r.lvl), cx(r) + cs / 2, cy_(r) + cs / 2 + 2.5 * k);
  });
  octx.textAlign = 'center';
}
// ---------- ana çizim ----------
let lastT = 0;
function render(dt, S) {
  frameNo++; const t = S.t;
  const want = S.run ? (S.run.kind === 'acik' ? 'o' + S.run.room : 'd' + S.run.region) : 'town';
  if (want !== envKey) {
    if (want === 'town') buildTown(S);
    else if (S.run.kind === 'acik') { const r = S.OPEN.rooms[S.run.room]; buildDungeon(S.run.region, { doors: S.doors, camp: r.camp, lair: r.lair, key: want }); }
    else buildDungeon(S.run.region);
    camInit = false;
  }
  if (S.run) syncRun(S, dt, t); else if (S.town) syncTown(S, dt, t);
  cullModels(dt);
  if (S.run) {
    const dark = S.run.event === 'karanlik';
    hemi.intensity = lerp(hemi.intensity, dark ? 0.06 : envLight.hemi, Math.min(1, dt * 3));
    sun.intensity = lerp(sun.intensity, dark ? 0.04 : envLight.sun, Math.min(1, dt * 3));
    if (dark) { PL[4].intensity = 2.4; PL[4].distance = 13; }
  }
  for (const a of envAnims) a(dt, t);
  for (const f of flick) {
    const n = (f.soft ? 0.06 : 0.18) * (Math.sin(t * 13 + f.base * 7) * 0.5 + Math.sin(t * 23.7) * 0.3 + Math.random() * 0.4);
    if (f.l) f.l.intensity = f.base * (1 + n);
    if (f.f) f.f.material.opacity = 0.7 + n; if (f.fl) f.fl.scale.y = 1 + n * 1.5;
  }
  for (const e of emitters) { e.acc += dt * e.rate; while (e.acc > 1) { e.acc--; e.fn(); } }
  stepParticles(dt); stepFx(dt);
  let fx = 0, fz = 0;
  if (S.run && S.P1) { fx = X(S.P1.x); fz = Z(S.P1.y); }
  else if (S.town) { if (S.showMe) { fx = X(S.town.p.x); fz = Z(S.town.p.y); } else { fx = 0; fz = Z(S.STATUE.y) + 1; } }
  updateCamera(dt, fx, fz, !S.showMe && !S.run);
  if (composer) composer.render(); else renderer.render(scene, camera);
  drawOverlay(S);
}
function addShake(k) { shake = Math.max(shake, k); }
return { init, resize, render, ev, burst, project, setQuality, get quality() { return quality; }, addShake, perfWatch, set onAuto(f) { onAuto = f; } };
})();

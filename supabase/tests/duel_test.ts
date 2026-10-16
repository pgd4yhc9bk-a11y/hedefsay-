// `duel` Edge Function'ının mantığı (sahte supabase-js ile). Çalıştır:
//   deno test -A --import-map=supabase/tests/import_map.json supabase/tests/duel_test.ts
// deno-lint-ignore-file no-explicit-any
import { db, sifirla } from "./sahte_supabase.ts";

Deno.env.set("SUPABASE_URL", "http://x");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "k");
Deno.env.set("DUELLO_GERI_SAYIM_MS", "30");   // testte kısa geri sayım
Deno.env.set("DUELLO_BOT_BEKLEME_MS", "15000");

let isleyici: (r: Request) => Promise<Response>;
(Deno as any).serve = (h: any) => { isleyici = h; return {} as any; };
await import("../functions/duel/index.ts");
const { H } = await import("../functions/_shared/ortak.ts");

function esit(a: unknown, b: unknown, m = "") { if (a !== b) throw new Error(`${m} beklenen ${JSON.stringify(b)}, gelen ${JSON.stringify(a)}`); }
function dogru(c: unknown, m = "") { if (!c) throw new Error("başarısız: " + m); }
const bekle = (ms: number) => new Promise((r) => setTimeout(r, ms));

const tum: string[] = [];   // tüm yanıt gövdeleri (sızıntı denetimi için)
async function cagir(kim: string, body: unknown): Promise<{ s: number; j: any }> {
  const r = await isleyici(new Request("http://x", { method: "POST", headers: { Authorization: "Bearer user:" + kim }, body: JSON.stringify(body) }));
  const t = await r.text(); tum.push(t);
  return { s: r.status, j: JSON.parse(t) };
}
function hazirla(...kimler: string[]) {
  sifirla(); tum.length = 0;
  for (const k of kimler) db.players.push({ id: k, nick: "oyuncu-" + k, city: "Ankara" });
}
/** İki oyuncuyu eşleştirir, maç id'sini döner */
async function esles(a = "A", b = "B") {
  const q1 = await cagir(a, { action: "queue" }); esit(q1.j.state, "waiting");
  const q2 = await cagir(b, { action: "queue" }); esit(q2.j.state, "active", "ikinci oyuncu bekleyene katılmalı");
  esit(q2.j.match_id, q1.j.match_id);
  return q1.j.match_id as string;
}
/** Turu başlatır (geri sayımı bekler), bulmacayı döner */
async function baslat(kim: string, mid: string, round: number) {
  for (let i = 0; i < 50; i++) {
    const r = await cagir(kim, { action: "start", match_id: mid, round });
    if (r.j.durum === "basladi") return r.j;
    esit(r.s, 200, "start " + JSON.stringify(r.j));
    await bekle(Math.min(60, (r.j.bekle_ms ?? 20) + 5));
  }
  throw new Error("tur başlamadı");
}
function enIyiCevap(t: any): string {
  return t.kind === "kelime" ? H.allWords(t.payload.letters)[0].word : H.solve(t.payload.nums).get(t.payload.target).e;
}

Deno.test("giriş ve oyuncu kartı zorunlu; başkasının maçına erişilemez", async () => {
  hazirla("A", "B", "C");
  const r = await isleyici(new Request("http://x", { method: "POST", body: "{}" }));
  esit(r.status, 401);
  esit((await cagir("Z", { action: "queue" })).s, 428);
  const mid = await esles();
  esit((await cagir("C", { action: "status", match_id: mid })).s, 404, "üçüncü kişi maçı göremez");
  esit((await cagir("C", { action: "start", match_id: mid, round: 1 })).s, 404);
  esit((await cagir("A", { action: "bilinmeyen" })).s, 400);
});

Deno.test("çapraz eşleşme: iki oyuncu aynı anda bekleyen maç açarsa eski olana katılınır", async () => {
  hazirla("A", "B");
  const a = (await cagir("A", { action: "queue" })).j;
  // B'nin bekleyen maçını A'dan sonra, "aynı anda" açılmış gibi elle ekle
  const bMac = { id: "bmac", a: "B", b: null, is_bot: false, state: "waiting", seed: "s", created_at: new Date(Date.now() + 5).toISOString() };
  db.matches.push(bMac);
  const bs = (await cagir("B", { action: "status", match_id: "bmac" })).j;
  esit(bs.state, "active"); esit(bs.match_id, a.match_id, "B, A'nın maçına geçmeli");
  esit(db.matches.find((m) => m.id === "bmac")!.state, "abandoned");
  // A'nın maçı artık aktif ve rakibi B
  const as = (await cagir("A", { action: "status", match_id: a.match_id })).j;
  esit(as.state, "active"); esit(as.rakip.nick, "oyuncu-B");
});

Deno.test("aynı anda iki oyuncu bekleyene katılmaya çalışırsa yalnızca biri katılır", async () => {
  hazirla("A", "B", "C");
  const a = (await cagir("A", { action: "queue" })).j;
  const [b, c] = await Promise.all([cagir("B", { action: "queue" }), cagir("C", { action: "queue" })]);
  const katilan = [b.j, c.j].filter((x) => x.match_id === a.match_id);
  esit(katilan.length, 1, "tek oyuncu katılmalı");
  const diger = [b.j, c.j].find((x) => x.match_id !== a.match_id)!;
  esit(diger.state, "waiting", "diğeri kendi maçında beklemeli");
});

Deno.test("tam oyun: 4 tur, sıra zorunlu, aynı bulmaca/başlangıç, puanlar, kazanan; hiçbir yanıt seed sızdırmaz", async () => {
  hazirla("A", "B");
  const mid = await esles();
  const seed = db.matches[0].seed;
  let skorA = 0;
  for (let r = 1; r <= 4; r++) {
    const ta = await baslat("A", mid, r), tb = await baslat("B", mid, r);
    esit(ta.started_at, tb.started_at, "başlangıç anı aynı olmalı");
    esit(JSON.stringify(ta.payload), JSON.stringify(tb.payload), "bulmaca aynı olmalı");
    esit(ta.best_solution, undefined, "başlangıç yanıtı cevabı sızdırmamalı");
    const cevap = enIyiCevap({ kind: ta.kind, payload: ta.payload });

    if (r === 1) {   // A gönderdi, B henüz göndermedi: tur bitmedi, A 2. tura geçemez, B'nin cevabı/puanı bilinmez
      const g = await cagir("A", { action: "submit", match_id: mid, round: 1, answer: cevap });
      esit(g.s, 200); esit(g.j.ben_gonderdim, true); esit(g.j.sonuclar.length, 0, "tur bitmeden sonuç açıklanmamalı");
      esit((await cagir("A", { action: "start", match_id: mid, round: 2 })).s, 409, "önceki tur bitmeden başlatılamaz");
      esit((await cagir("A", { action: "submit", match_id: mid, round: 1, answer: cevap })).s, 409, "ikinci gönderim");
      const bg = await cagir("B", { action: "submit", match_id: mid, round: 1, answer: "" });   // B boş gönderir
      esit(bg.j.sonuclar.length, 1, "iki taraf da gönderince tur biter");
      skorA += bg.j.sonuclar[0].rakip.score;   // B'nin görünümünde rakip = A
      dogru(bg.j.sonuclar[0].rakip.score > 0, "A'nın puanı");
      esit(bg.j.sonuclar[0].ben.score, 0);
      esit(bg.j.sonuclar[0].best_solution.length > 0, true);
    } else {
      await cagir("A", { action: "submit", match_id: mid, round: r, answer: cevap });
      const bg = await cagir("B", { action: "submit", match_id: mid, round: r, answer: "" });
      esit(bg.j.sonuclar.length, r);
      skorA = bg.j.toplam.rakip;
    }
  }
  const son = (await cagir("A", { action: "status", match_id: mid })).j;
  esit(son.bitti, true); esit(son.state, "finished"); esit(son.kazanan, "ben"); esit(son.toplam.ben, skorA);
  esit(db.matches[0].state, "finished");
  const sonB = (await cagir("B", { action: "status", match_id: mid })).j;
  esit(sonB.kazanan, "rakip");
  esit(tum.some((t) => t.includes(seed)), false, "hiçbir yanıt maç tohumunu içermemeli");
  // düelloda süre bonusu yok: işlem turunda tam isabet tam 10 puan
  const islem = db.match_moves.find((m) => m.round === 2 && m.player_id === "A")!;
  esit(islem.payload.score, 10, "düelloda süre bonusu olmamalı");
});

Deno.test("bot: erken çağrı reddedilir; süre dolunca bot başlar; bot hamlesi seed'den deterministik ve açıkça 'Bot'", async () => {
  hazirla("A");
  const q = (await cagir("A", { action: "queue" })).j;
  esit(q.state, "waiting"); dogru(q.bot_icin_kalan_ms > 0);
  esit((await cagir("A", { action: "bot", match_id: q.match_id })).s, 409, "erken bot");
  db.matches[0].created_at = new Date(Date.now() - 20000).toISOString();
  const b = (await cagir("A", { action: "bot", match_id: q.match_id })).j;
  const seed = db.matches[0].seed;
  esit(b.state, "active"); esit(b.rakip.bot, true, "bot rakip her zaman bot=true olmalı");
  esit(b.rakip.nick, H.botPersona(seed).nick, "kişilik seed'den gelmeli"); esit(b.rakip.city, H.botPersona(seed).city);
  for (let r = 1; r <= 4; r++) {
    const t = await baslat("A", q.match_id, r);
    const g = await cagir("A", { action: "submit", match_id: q.match_id, round: r, answer: enIyiCevap({ kind: t.kind, payload: t.payload }) });
    esit(g.j.sonuclar.length, r, "bot maçında tur, oyuncu gönderince biter");
    const beklenen = H.botMove(seed, r - 1, H.roundFromSeed("duello-" + seed, r - 1));
    esit(g.j.sonuclar[r - 1].rakip.score, beklenen.score, "bot puanı seed'den türetilmeli (tur " + r + ")");
  }
  const son = (await cagir("A", { action: "status", match_id: q.match_id })).j;
  esit(son.bitti, true); dogru(["ben", "rakip", "berabere"].includes(son.kazanan));
  esit(tum.some((t) => t.includes(seed)), false, "tohum sızmamalı");
});

Deno.test("zaman aşımı: rakip göndermezse süre dolunca tur 0 puanla kapanır, oyun devam eder", async () => {
  hazirla("A", "B");
  const mid = await esles();
  const t = await baslat("A", mid, 1); await baslat("B", mid, 1);
  await cagir("A", { action: "submit", match_id: mid, round: 1, answer: enIyiCevap({ kind: t.kind, payload: t.payload }) });
  esit((await cagir("A", { action: "start", match_id: mid, round: 2 })).s, 409, "B bitirmedi, süre de dolmadı");
  db.match_rounds[0].started_at = new Date(Date.now() - 70000).toISOString();   // 70 sn önce başlamış
  const s = (await cagir("A", { action: "status", match_id: mid })).j;
  esit(s.sonuclar.length, 1, "süre dolunca tur kapanmalı");
  esit(s.sonuclar[0].rakip.score, 0); esit(s.sonuclar[0].rakip.answer, "");
  dogru(s.sonuclar[0].ben.score > 0);
  const t2 = await baslat("A", mid, 2);   // A 2. turu oynayabilir
  dogru(t2.payload);
  // B geç gönderirse 0 puan alır; daha önce gösterilen sonuç ve toplam değişmez
  const gec = await cagir("B", { action: "submit", match_id: mid, round: 1, answer: enIyiCevap({ kind: t.kind, payload: t.payload }) });
  esit(gec.s, 200);
  esit(db.match_moves.find((m) => m.player_id === "B")!.payload.score, 0, "geç cevap puan almamalı");
  const s2 = (await cagir("A", { action: "status", match_id: mid })).j;
  esit(s2.sonuclar[0].rakip.score, 0); esit(s2.sonuclar[0].ben.score, s.sonuclar[0].ben.score);
});

Deno.test("süre aşımı geç gönderim: tur süresi + tolerans sonrası gelen cevap 0 puan", async () => {
  hazirla("A", "B");
  const mid = await esles();
  const t = await baslat("A", mid, 1); await baslat("B", mid, 1);
  db.match_rounds[0].started_at = new Date(Date.now() - 62000).toISOString();   // 62 sn: tolerans (3 sn) içinde ama limit aşılmış değil sayılmaz
  const g = await cagir("A", { action: "submit", match_id: mid, round: 1, answer: enIyiCevap({ kind: t.kind, payload: t.payload }) });
  esit(g.s, 200);
  const hamle = db.match_moves.find((m) => m.player_id === "A")!;
  esit(hamle.payload.score > 0, true, "62 sn tolerans içinde: kabul");
  db.match_rounds[0].started_at = new Date(Date.now() - 66000).toISOString();
  const gb = await cagir("B", { action: "submit", match_id: mid, round: 1, answer: enIyiCevap({ kind: t.kind, payload: t.payload }) });
  esit(gb.s, 200);
  esit(db.match_moves.find((m) => m.player_id === "B")!.payload.score, 0, "66 sn: süre aşıldı");
});

Deno.test("terk: eski bekleyen maç kapatılır, yeni maç açılır; aktif maç varken tekrar queue aynı maça döner", async () => {
  hazirla("A", "B");
  const eski = (await cagir("A", { action: "queue" })).j;
  db.matches[0].created_at = new Date(Date.now() - 200000).toISOString();
  const yeni = (await cagir("A", { action: "queue" })).j;
  dogru(yeni.match_id !== eski.match_id, "yeni maç");
  esit(db.matches.find((m) => m.id === eski.match_id)!.state, "abandoned");
  const b = (await cagir("B", { action: "queue" })).j;
  esit(b.match_id, yeni.match_id);
  esit((await cagir("A", { action: "queue" })).j.match_id, yeni.match_id, "yeniden bağlanınca aynı maç");
  esit((await cagir("B", { action: "queue" })).j.match_id, yeni.match_id);
});

Deno.test("tur arası bekleme: biri bitirince rakibe en fazla 20 sn kalır; ondan önce tur kapanmaz; kalan süre bildirilir", async () => {
  hazirla("A", "B");
  const mid = await esles();
  const t = await baslat("A", mid, 1); await baslat("B", mid, 1);
  const g = await cagir("A", { action: "submit", match_id: mid, round: 1, answer: enIyiCevap({ kind: t.kind, payload: t.payload }) });
  esit(g.j.sonuclar.length, 0, "rakip bitirmedi: tur açık");
  dogru(g.j.rakip_kalan_ms > 15000 && g.j.rakip_kalan_ms <= 20000, "rakibe kalan süre ~20 sn olmalı: " + g.j.rakip_kalan_ms);
  // A 10 sn önce göndermiş gibi göster: hâlâ açık
  db.match_rounds[0].started_at = new Date(Date.now() - 12000).toISOString();
  db.match_moves[0].payload.elapsed_ms = 2000;   // A, başlangıçtan 2 sn sonra göndermiş -> kapanış başlangıç+22 sn
  esit((await cagir("A", { action: "status", match_id: mid })).j.sonuclar.length, 0, "12. sn: tur açık");
  db.match_rounds[0].started_at = new Date(Date.now() - 23000).toISOString();   // kapanış geçti
  const s = (await cagir("A", { action: "status", match_id: mid })).j;
  esit(s.sonuclar.length, 1, "ilk gönderimden 20 sn sonra tur kapanmalı");
  esit(s.sonuclar[0].rakip.score, 0);
  dogru((await baslat("A", mid, 2)).payload, "2. tur başlayabilmeli");
});

Deno.test("yapay zekâ kişilikleri: 100 farklı ad, deterministik, beceri aralığı, tek maçta tutarlı", () => {
  esit(new Set(H.BOT_ADLARI).size, 100);
  const k1 = H.botPersona("tohum-1"), k2 = H.botPersona("tohum-1");
  esit(JSON.stringify(k1), JSON.stringify(k2));
  dogru(k1.bot === true && k1.skill >= 0.3 && k1.skill <= 0.9, "beceri aralığı");
  const adlar = new Set(Array.from({ length: 200 }, (_, i) => H.botPersona("t" + i).nick));
  dogru(adlar.size > 40, "çeşitli adlar seçilmeli: " + adlar.size);
});

/** A ve B'yi eşleştirip 4 turu oynatır (A en iyi cevapları, B boş) ve biten maçın id'sini döner */
async function macBitir(a = "A", b = "B") {
  const mid = await esles(a, b);
  for (let r = 1; r <= 4; r++) {
    const t = await baslat(a, mid, r); await baslat(b, mid, r);
    await cagir(a, { action: "submit", match_id: mid, round: r, answer: enIyiCevap({ kind: t.kind, payload: t.payload }) });
    await cagir(b, { action: "submit", match_id: mid, round: r, answer: "" });
  }
  esit((await cagir(a, { action: "status", match_id: mid })).j.bitti, true);
  return mid;
}
async function botIste(kim: string) {
  const q = (await cagir(kim, { action: "queue" })).j;
  db.matches.find((m) => m.id === q.match_id)!.created_at = new Date(Date.now() - 20000).toISOString();
  return (await cagir(kim, { action: "bot", match_id: q.match_id })).j;
}

Deno.test("kayıtlı rakip: izin veren oyuncunun eski maçı, adı/fotoğrafıyla, aynı bulmaca ve kayıtlı puanlarla oynatılır", async () => {
  hazirla("A", "B", "C");
  db.players.find((p) => p.id === "A")!.kayit_izni = true;
  db.players.find((p) => p.id === "A")!.avatar_url = "https://x/storage/v1/object/public/avatarlar/A/avatar.jpg";
  db.players.find((p) => p.id === "B")!.kayit_izni = true;
  const eski = await macBitir();
  const eskiMac = db.matches.find((m) => m.id === eski)!;
  const eskiTurlar = db.match_rounds.filter((r) => r.match_id === eski).map((r) => JSON.stringify(r.payload));
  const eskiHamle = (oyuncu: string, tur: number) => db.match_moves.find((m) => m.match_id === eski && m.player_id === oyuncu && m.round === tur)!.payload;

  const g = await botIste("C");
  esit(g.state, "active");
  esit(g.rakip.kayitli, true, "kayıtlı rakip etiketi"); esit(g.rakip.bot, false, "yapay zekâ değil, kayıtlı gerçek oyuncu");
  dogru(["oyuncu-A", "oyuncu-B"].includes(g.rakip.nick), "gerçek oyuncu adı: " + g.rakip.nick);
  const yeniMac = db.matches.find((m) => m.id === g.match_id)!;
  const rakipId = yeniMac.ghost_player as string;
  esit(yeniMac.seed, eskiMac.seed, "aynı bulmacalar için tohum eski maçınki"); esit(yeniMac.ghost_of, eski);
  if (rakipId === "A") esit(g.rakip.avatar_url, "https://x/storage/v1/object/public/avatarlar/A/avatar.jpg", "fotoğraf görünmeli");

  for (let r = 1; r <= 4; r++) {
    const t = await baslat("C", g.match_id, r);
    esit(JSON.stringify(t.payload), eskiTurlar[r - 1], "aynı bulmaca (tur " + r + ")");
    const s = await cagir("C", { action: "submit", match_id: g.match_id, round: r, answer: "" });
    esit(s.j.sonuclar.length, r, "kayıtlı rakipte tur, ben gönderince biter");
    esit(s.j.sonuclar[r - 1].rakip.score, eskiHamle(rakipId, r).score, "kayıtlı puan (tur " + r + ")");
  }
  esit(tum.some((t) => t.includes(eskiMac.seed)), false, "tohum sızmamalı");
});

Deno.test("kayıtlı rakip: izin yoksa yapay zekâ; kendi oynadığım maçtaki oyuncu rakip olarak çıkmaz", async () => {
  hazirla("A", "B", "C");
  await macBitir();                                  // izin verilmemiş (varsayılan kapalı)
  const g1 = await botIste("C");
  esit(g1.rakip.bot, true, "izin yoksa yapay zekâ"); esit(g1.rakip.kayitli, undefined);

  hazirla("A", "B");
  db.players.forEach((p) => { p.kayit_izni = true; });
  await macBitir();
  const g2 = await botIste("A");                     // A o maçın tarafı: aynı bulmacaları görmüş, rakip olamaz
  esit(g2.rakip.bot, true, "kendi maçımdaki oyuncu kayıtlı rakip olmamalı");
});

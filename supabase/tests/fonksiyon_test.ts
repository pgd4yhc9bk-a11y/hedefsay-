// Edge Function'ların mantığı (sahte supabase-js ile). Çalıştır:
//   deno test -A --import-map=supabase/tests/import_map.json supabase/tests/fonksiyon_test.ts
// deno-lint-ignore-file no-explicit-any
import { db, sifirla } from "./sahte_supabase.ts";

Deno.env.set("SUPABASE_URL", "http://x");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "k");
Deno.env.set("CRON_SECRET", "gizli");

// Deno.serve'ü yakala
const isleyiciler: Record<string, (r: Request) => Promise<Response>> = {};
let sonAd = "";
(Deno as any).serve = (h: any) => { isleyiciler[sonAd] = h; return {} as any; };
async function yukle(ad: string) { sonAd = ad; await import(`../functions/${ad}/index.ts`); }
await yukle("daily-round");
await yukle("generate-daily-puzzle");
const { bugun, yarin, H } = await import("../functions/_shared/ortak.ts");

function esit(a: unknown, b: unknown, m = "") { if (a !== b) throw new Error(`${m} beklenen ${b}, gelen ${a}`); }
function istek(ad: string, body: unknown, basliklar: Record<string, string> = {}) {
  return isleyiciler[ad](new Request("http://x", { method: "POST", headers: basliklar, body: JSON.stringify(body) }));
}
const oyun = (jwt: string, body: unknown) => istek("daily-round", body, { Authorization: "Bearer " + jwt });

async function hazirla() {
  sifirla();
  const bugunTarih = bugun();
  db.players.push({ id: "A", nick: "ayse" });
  for (let i = 0; i < 4; i++) {
    const r = H.dailyRound(bugunTarih, i);
    db.daily_puzzles.push({ date: bugunTarih, round: i + 1, kind: r.kind, payload: r.payload });
    db.daily_solutions.push({ date: bugunTarih, round: i + 1, best_score: r.best.score, best_solution: r.best.solution });
  }
  return bugunTarih;
}

Deno.test("üretici: yetkisiz reddedilir, yarının 4 turu yazılır, ikinci çağrı ezmez", async () => {
  sifirla();
  esit((await istek("generate-daily-puzzle", {})).status, 401, "secret yok");
  esit((await istek("generate-daily-puzzle", {}, { "x-cron-secret": "yanlis" })).status, 401, "yanlış secret");
  const r = await istek("generate-daily-puzzle", {}, { "x-cron-secret": "gizli" });
  esit(r.status, 200); esit(db.daily_puzzles.length, 4); esit(db.daily_solutions.length, 4);
  esit(db.daily_puzzles[0].date, yarin());
  const once = JSON.stringify(db.daily_puzzles);
  await istek("generate-daily-puzzle", {}, { "x-cron-secret": "gizli" });
  esit(db.daily_puzzles.length, 4, "ikinci çağrı çoğalttı"); esit(JSON.stringify(db.daily_puzzles), once, "ezdi");
  esit((await istek("generate-daily-puzzle", { date: "yarin" }, { "x-cron-secret": "gizli" })).status, 400);
});

Deno.test("giriş zorunlu, oyuncu kartı zorunlu", async () => {
  await hazirla();
  esit((await oyun("kotu", { action: "start", round: 1 })).status, 401);
  esit((await oyun("user:Z", { action: "start", round: 1 })).status, 428);
  esit((await oyun("user:A", { action: "start", round: 9 })).status, 400);
  esit((await oyun("user:A", { action: "x", round: 1 })).status, 400);
});

Deno.test("tam oyun: 4 tur, cevaplar yalnızca gönderimden sonra açılır, puan sunucuda", async () => {
  const t = await hazirla();
  let toplam = 0;
  for (let i = 1; i <= 4; i++) {
    const s = await oyun("user:A", { action: "start", round: i });
    esit(s.status, 200, "start " + i);
    const govde = await s.json();
    if ("best_solution" in govde || "answer" in govde) throw new Error("başlangıç cevabı sızdırıyor");
    const cevap = db.daily_solutions[i - 1].best_solution;
    const g = await oyun("user:A", { action: "submit", round: i, answer: cevap });
    esit(g.status, 200, "submit " + i);
    const sonuc = await g.json();
    esit(sonuc.valid, true, "geçerli " + i);
    esit(sonuc.best_solution, cevap);
    toplam += sonuc.score;
  }
  esit(db.daily_scores.length, 4); esit(db.daily_scores[0].date, t);
  if (toplam < 4 * 5) throw new Error("toplam çok düşük: " + toplam);
});

Deno.test("hile denemeleri: sıra atlama, başlatmadan gönderme, tekrar gönderme, geç gönderme, yeniden başlatma", async () => {
  await hazirla();
  esit((await oyun("user:A", { action: "start", round: 2 })).status, 409, "tur 1 bitmeden tur 2");
  esit((await oyun("user:A", { action: "submit", round: 1, answer: "x" })).status, 409, "başlatmadan gönderme");

  await oyun("user:A", { action: "start", round: 1 });
  // süreyi geriye al: 70 sn önce başlamış gibi
  db.daily_round_starts[0].started_at = new Date(Date.now() - 70_000).toISOString();
  const gec = await (await oyun("user:A", { action: "submit", round: 1, answer: db.daily_solutions[0].best_solution })).json();
  esit(gec.score, 0, "geç gönderim puan almamalı"); esit(gec.detail, "Süre aşıldı");

  esit((await oyun("user:A", { action: "submit", round: 1, answer: db.daily_solutions[0].best_solution })).status, 409, "ikinci gönderim");
  esit((await oyun("user:A", { action: "start", round: 1 })).status, 409, "bitmiş turu yeniden başlatma");

  // başlatmayı tekrar çağırmak süreyi sıfırlamaz
  await oyun("user:A", { action: "start", round: 2 });
  const ilk = db.daily_round_starts[1].started_at;
  await new Promise((r) => setTimeout(r, 20));
  await oyun("user:A", { action: "start", round: 2 });
  esit(db.daily_round_starts.length, 2); esit(db.daily_round_starts[1].started_at, ilk, "süre sıfırlandı");
});

Deno.test("bulmaca yoksa 404; geçersiz cevap 0 puan ama kaydedilir", async () => {
  sifirla(); db.players.push({ id: "A", nick: "ayse" });
  esit((await oyun("user:A", { action: "start", round: 1 })).status, 404);
  await hazirla();
  await oyun("user:A", { action: "start", round: 1 });
  const s = await (await oyun("user:A", { action: "submit", round: 1, answer: "zzzzqq" })).json();
  esit(s.score, 0); esit(db.daily_scores.length, 1);
});

Deno.test("PUZZLE_SALT: yoksa uyarır, varsa bulmaca tuzla üretilir (tarihten tahmin edilemez)", async () => {
  sifirla();
  const gun = "2031-01-05";
  const r1 = await (await istek("generate-daily-puzzle", { date: gun }, { "x-cron-secret": "gizli" })).json();
  if (!String(r1.uyari).includes("PUZZLE_SALT")) throw new Error("tuz yokken uyarı beklenir: " + JSON.stringify(r1));
  esit(JSON.stringify(db.daily_puzzles[0].payload), JSON.stringify(H.dailyRound(gun, 0).payload), "tuzsuz = herkesin hesaplayabildiği bulmaca");

  sifirla();
  Deno.env.set("PUZZLE_SALT", "cok-gizli-tuz");
  const r2 = await (await istek("generate-daily-puzzle", { date: gun }, { "x-cron-secret": "gizli" })).json();
  esit(r2.uyari, undefined, "tuz varken uyarı olmamalı");
  esit(JSON.stringify(db.daily_puzzles[1].payload), JSON.stringify(H.dailyRound(gun, 1, "cok-gizli-tuz").payload));
  if (JSON.stringify(db.daily_puzzles[1].payload) === JSON.stringify(H.dailyRound(gun, 1).payload)) throw new Error("tuzlu bulmaca tuzsuzla aynı olmamalı");
  Deno.env.delete("PUZZLE_SALT");
});

Deno.test("tuz kaynağı: ortam sırrı yoksa puzzle_tuzu tablosu kullanılır; ikisi de varsa ortam sırrı kazanır", async () => {
  sifirla();
  const gun = "2031-02-07";
  db.puzzle_tuzu.push({ id: true, tuz: "veritabani-tuzu-0123456789abcdef0123456789abcdef" });
  const r1 = await (await istek("generate-daily-puzzle", { date: gun }, { "x-cron-secret": "gizli" })).json();
  esit(r1.uyari, undefined, "tablodaki tuz varken uyarı olmamalı");
  esit(JSON.stringify(db.daily_puzzles[0].payload), JSON.stringify(H.dailyRound(gun, 0, "veritabani-tuzu-0123456789abcdef0123456789abcdef").payload), "tablodaki tuzla üretilmeli");
  if (JSON.stringify(db.daily_puzzles[0].payload) === JSON.stringify(H.dailyRound(gun, 0).payload)) throw new Error("tuzlu bulmaca tuzsuzla aynı olmamalı");

  db.daily_puzzles.length = 0; db.daily_solutions.length = 0;
  Deno.env.set("PUZZLE_SALT", "ortam-tuzu");
  await istek("generate-daily-puzzle", { date: gun }, { "x-cron-secret": "gizli" });
  esit(JSON.stringify(db.daily_puzzles[0].payload), JSON.stringify(H.dailyRound(gun, 0, "ortam-tuzu").payload), "ortam sırrı tabloyu geçmeli");
  Deno.env.delete("PUZZLE_SALT");
});

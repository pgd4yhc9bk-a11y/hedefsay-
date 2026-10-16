// Yerel test sunucusu: GERÇEK Edge Function kodunu (daily-round, generate-daily-puzzle) bellek içi
// sahte veritabanıyla HTTP üzerinden sunar; auth/REST uçları yalnızca istemcinin kullandığı kadar taklit edilir.
// RLS burada test edilmez (o, supabase/tests/calistir.sh'ta).
// Çalıştır:  deno run -A --import-map=supabase/tests/import_map.json prototip/e2e/sahte_sunucu.ts   (PORT=8787)
// deno-lint-ignore-file no-explicit-any
import { db } from "../../supabase/tests/sahte_supabase.ts";

Deno.env.set("SUPABASE_URL", "http://sahte");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "k");
Deno.env.set("CRON_SECRET", "gizli");
if (!Deno.env.get("DUELLO_GERI_SAYIM_MS")) Deno.env.set("DUELLO_GERI_SAYIM_MS", "800");   // testte kısa geri sayım (dışarıdan geçersiz kılınabilir)
Deno.env.set("PUZZLE_SALT", "e2e-tuz");

const gercekServe = Deno.serve.bind(Deno);
const isleyici: Record<string, (r: Request) => Promise<Response>> = {};
let sonAd = "";
(Deno as any).serve = (h: any) => { isleyici[sonAd] = h; return {} as any; };
for (const ad of ["daily-round", "generate-daily-puzzle", "duel"]) { sonAd = ad; await import(`../../supabase/functions/${ad}/index.ts`); }
(Deno as any).serve = gercekServe;
const { bugun } = await import("../../supabase/functions/_shared/ortak.ts");

// Bugünün bulmacasını üret (cron'un yaptığı)
await isleyici["generate-daily-puzzle"](new Request("http://x", {
  method: "POST", headers: { "x-cron-secret": "gizli" }, body: JSON.stringify({ date: bugun() }),
}));

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, prefer, x-client-info, x-upsert",
  "Access-Control-Allow-Methods": "GET, POST, PATCH, OPTIONS",
};
const json = (b: unknown, status = 200) => new Response(JSON.stringify(b), { status, headers: { "content-type": "application/json", ...cors } });
const oturum = (id: string) => ({ access_token: "user:" + id, refresh_token: "r:" + id, expires_in: 3600, user: { id } });
const siniflar = ["Ankara", "İstanbul", "İzmir"];
const dosyalar = new Map<string, { tur: string; veri: Uint8Array }>();   // sahte depo: yüklenen avatarlar

function toplamlar(tarih?: string) {
  const sayim: Record<string, any> = {};
  for (const s of db.daily_scores) {
    if (tarih && s.date !== tarih) continue;
    const k = s.date + "|" + s.player_id;
    sayim[k] ??= { date: s.date, player_id: s.player_id, total: 0, n: 0 };
    sayim[k].total += s.score; sayim[k].n++;
  }
  return Object.values(sayim).filter((x: any) => x.n === 4);
}

gercekServe({ port: Number(Deno.env.get("PORT") ?? 8787), onListen: () => console.log("hazır") }, async (req) => {
  const u = new URL(req.url), p = u.pathname, q = u.searchParams;
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  const jwt = (req.headers.get("authorization") ?? "").replace(/^Bearer /, "");
  const uid = jwt.startsWith("user:") ? jwt.slice(5) : null;
  const eq = (k: string) => (q.get(k) ?? "").replace(/^eq\./, "");

  if (p === "/auth/v1/signup") return json(oturum(crypto.randomUUID()));
  if (p === "/auth/v1/token") { const b = await req.json(); return json(oturum(String(b.refresh_token).slice(2))); }
  if (p === "/functions/v1/daily-round") return await isleyici["daily-round"](req);
  if (p === "/functions/v1/duel") return await isleyici["duel"](req);

  if (p === "/__test/geri") {   // başlangıç damgalarını n sn geriye al (süre aşımı denemesi için)
    for (const r of db.daily_round_starts) r.started_at = new Date(Date.now() - Number(q.get("sn")) * 1000).toISOString();
    return json({ ok: true });
  }
  if (p === "/__test/maci_geri") {   // bekleyen maçların yaşını n sn artır (bota düşmeyi hızlandırır)
    for (const m of db.matches) if (m.state === "waiting") m.created_at = new Date(Date.parse(m.created_at) - Number(q.get("sn")) * 1000).toISOString();
    return json({ ok: true });
  }
  if (p === "/__test/db") return json(db);

  if (p.startsWith("/storage/v1/object/public/")) {   // herkese açık okuma
    const d = dosyalar.get(p.replace("/storage/v1/object/public/", ""));
    return d ? new Response(d.veri, { headers: { "content-type": d.tur, ...cors } }) : json({ message: "yok" }, 404);
  }
  if (p.startsWith("/storage/v1/object/avatarlar/") && req.method === "POST") {   // yalnızca kendi klasörüne
    const yol = p.replace("/storage/v1/object/", "");
    if (!uid || yol.split("/")[1] !== uid) return json({ message: "RLS: kendi klasörüne yazabilirsin" }, 403);
    const veri = new Uint8Array(await req.arrayBuffer());
    if (veri.length > 1048576) return json({ message: "çok büyük" }, 413);
    dosyalar.set("avatarlar/" + yol.split("/").slice(1).join("/"), { tur: req.headers.get("content-type") ?? "image/jpeg", veri });
    return json({ Key: yol });
  }
  if (!uid && p.startsWith("/rest/v1/") && p !== "/rest/v1/cities") return json({ message: "JWT yok" }, 401);
  if (p === "/rest/v1/cities") return json(siniflar.map((name) => ({ name })));
  if (p === "/rest/v1/players" && req.method === "GET") return json(db.players.filter((x) => x.id === eq("id")));
  if (p === "/rest/v1/players" && req.method === "POST") {
    const b = await req.json();
    if (b.id !== uid) return json({ message: "RLS" }, 403);
    if (String(b.nick).length < 2) return json({ message: "nick kısa" }, 400);
    db.players.push({ id: b.id, nick: b.nick, city: b.city, avatar_url: b.avatar_url ?? null, kayit_izni: b.kayit_izni ?? false });
    return new Response(null, { status: 201, headers: cors });
  }
  if (p === "/rest/v1/players" && req.method === "PATCH") {
    const b = await req.json(); const satir = db.players.find((x) => x.id === eq("id"));
    if (!satir || satir.id !== uid) return json({ message: "RLS" }, 403);
    if (b.avatar_url && !String(b.avatar_url).includes("/storage/v1/object/public/avatarlar/" + uid + "/")) return json({ message: "avatar_url kendi klasörün olmalı" }, 400);
    Object.assign(satir, b);
    return new Response(null, { status: 204, headers: cors });
  }
  if (p === "/rest/v1/daily_scores") {
    return json(db.daily_scores.filter((x) => x.player_id === uid && x.date === eq("date"))
      .map((x) => ({ round: x.round, score: x.score })).sort((a, b) => a.round - b.round));
  }
  if (p === "/rest/v1/daily_leaderboard") {
    const satirlar = toplamlar(eq("date")).map((t: any) => {
      const pl = db.players.find((x) => x.id === t.player_id);
      return { nick: pl?.nick, city: pl?.city ?? null, total: t.total, avatar_url: pl?.avatar_url ?? null };
    }).sort((a, b) => b.total - a.total);
    return json(satirlar.map((x, i) => ({ ...x, rank: i + 1 })));
  }
  if (p === "/rest/v1/city_league") {
    const il: Record<string, any> = {};
    for (const t of toplamlar()) {
      const pl = db.players.find((x) => x.id === t.player_id);
      if (!pl?.city) continue;
      il[pl.city] ??= { city: pl.city, total: 0, ids: new Set(), n: 0 };
      il[pl.city].total += t.total; il[pl.city].ids.add(t.player_id); il[pl.city].n++;
    }
    return json(Object.values(il).map((x: any) => ({ city: x.city, total: x.total, players: x.ids.size, average: x.total / x.n })));
  }
  return json({ message: "bilinmeyen uç: " + p }, 404);
});

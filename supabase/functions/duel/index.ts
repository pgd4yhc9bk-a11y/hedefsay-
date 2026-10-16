// Canlı düello: eşleştirme, geri sayım, tur başlatma/gönderme, bot. Puanı ve süreyi sunucu tutar.
// İstemci yalnızca bu fonksiyonla konuşur (matches/match_moves/match_rounds istemciye kapalı) ve durumu
// düzenli aralıkla `status` ile sorgular (polling): bağlantı kopsa da durum sunucuda durur, `queue`/`status` ile devam edilir.
//   POST {"action":"queue"}                                -> eşleşme ara / mevcut maça dön
//   POST {"action":"status","match_id":"..."}              -> maçın görünümü (bekleyen maçta çapraz eşleşmeyi de dener)
//   POST {"action":"bot","match_id":"..."}                 -> bekleme süresi dolduysa botla başlat (rakip adı açıkça "Bot")
//   POST {"action":"start","match_id":"...","round":n}     -> turu başlat: geri sayım bitince bulmaca gelir
//   POST {"action":"submit","match_id":"...","round":n,"answer":"..."} -> cevabı puanla
// Düello kuralları: harfleri sistem seçer; süre bonusu yok; aynı bulmaca ve aynı başlangıç anı iki oyuncuda da.
import { admin, cors, H, json, kullanici } from "../_shared/ortak.ts";

const env = (k: string, d: number) => Number(Deno.env.get(k) ?? d);
const SURE_MS = H.GUNLUK_SURE * 1000;                       // tur süresi
const TOLERANS_MS = 3000;                                   // ağ gecikmesi payı
const GERI_SAYIM_MS = env("DUELLO_GERI_SAYIM_MS", 3000);    // iki taraf da aynı anda başlasın
const BOT_BEKLEME_MS = env("DUELLO_BOT_BEKLEME_MS", 6000);  // gerçek rakip bulunamazsa yapay zekâ rakibe düş (açıkça etiketlenir)
const RAKIP_BEKLEME_MS = env("DUELLO_RAKIP_BEKLEME_MS", 20000); // biri bitirince diğerine kalan en fazla süre
const BEKLEYEN_OMUR_MS = 30000;                             // bundan eski bekleyen maça katılınmaz
const TERK_MS = 120000;                                     // bekleyen maç bu süreden sonra terk sayılır
const AKTIF_OMUR_MS = 30 * 60000;

// deno-lint-ignore no-explicit-any
type Satir = Record<string, any>;
const simdi = () => Date.now();
const ms = (t: string) => Date.parse(t);
const hata = (m: string, s = 400) => json({ error: m }, s);

async function tek(tablo: string, filtre: Record<string, unknown>): Promise<Satir | null> {
  let q = admin.from(tablo).select("*");
  for (const [k, v] of Object.entries(filtre)) q = q.eq(k, v);
  const { data } = await q.maybeSingle();
  return data ?? null;
}
async function liste(tablo: string, filtre: Record<string, unknown>): Promise<Satir[]> {
  let q = admin.from(tablo).select("*");
  for (const [k, v] of Object.entries(filtre)) q = q.eq(k, v);
  const { data } = await q;
  return data ?? [];
}

function rastgeleTohum() {
  const b = crypto.getRandomValues(new Uint8Array(16));
  return Array.from(b, (x) => x.toString(16).padStart(2, "0")).join("");
}

/** Oyuncunun bekleyen/aktif maçı (terk olanlar kapatılır) */
async function mevcutMac(pid: string): Promise<Satir | null> {
  const adaylar = [...await liste("matches", { a: pid }), ...await liste("matches", { b: pid })]
    .filter((m) => m.state === "waiting" || m.state === "active");
  let secilen: Satir | null = null;
  for (const m of adaylar) {
    const yas = simdi() - ms(m.created_at);
    const eski = (m.state === "waiting" && yas > TERK_MS) || (m.state === "active" && yas > AKTIF_OMUR_MS);
    if (eski) { await admin.from("matches").update({ state: "abandoned" }).eq("id", m.id); continue; }
    if (!secilen || ms(m.created_at) > ms(secilen.created_at)) secilen = m;
  }
  return secilen;
}

/** Bekleyen başka bir maça (atomik) katılmayı dener. Koşul: başkasının, taze, benim bekleyen maçımdan eski. */
async function katil(pid: string, benimMacim: Satir | null): Promise<Satir | null> {
  const adaylar = (await liste("matches", { state: "waiting" }))
    .filter((m) => m.a !== pid && !m.b && !m.is_bot && simdi() - ms(m.created_at) < BEKLEYEN_OMUR_MS)
    .filter((m) => !benimMacim || ms(m.created_at) < ms(benimMacim.created_at) || (m.created_at === benimMacim.created_at && m.id < benimMacim.id))
    .sort((x, y) => ms(x.created_at) - ms(y.created_at));
  for (const m of adaylar) {
    // atomik: yalnızca hâlâ "waiting" ise güncellenir
    const { data } = await admin.from("matches").update({ b: pid, state: "active" }).eq("id", m.id).eq("state", "waiting").select();
    if (data && data.length === 1) {
      if (benimMacim) await admin.from("matches").update({ state: "abandoned" }).eq("id", benimMacim.id).eq("state", "waiting");
      return data[0];
    }
  }
  return null;
}

/** İlk gönderimin sunucu zamanı (başlangıç + geçen süre) */
function ilkGonderim(satir: Satir, hamleler: Satir[]): number | null {
  const z = hamleler.filter((h) => h.round === satir.round).map((h) => ms(satir.started_at) + (h.payload?.elapsed_ms ?? 0));
  return z.length ? Math.min(...z) : null;
}
/** Tur kapanma anı: süre sonu; biri bitirdiyse onun ardından RAKIP_BEKLEME_MS (hangisi önceyse) */
function turKapanis(satir: Satir, hamleler: Satir[]): number {
  const sonSaat = ms(satir.started_at) + SURE_MS + TOLERANS_MS;
  const ilk = ilkGonderim(satir, hamleler);
  return ilk === null ? sonSaat : Math.min(sonSaat, ilk + RAKIP_BEKLEME_MS);
}
function turBitmisMi(satir: Satir, hamleler: Satir[], mac: Satir, pid: string, an: number): boolean {
  const ben = hamleler.find((h) => h.round === satir.round && h.player_id === pid);
  const rakip = hamleler.find((h) => h.round === satir.round && h.player_id !== pid);
  if (mac.is_bot) return !!ben || an > ms(satir.started_at) + SURE_MS + TOLERANS_MS;
  return (!!ben && !!rakip) || an > turKapanis(satir, hamleler);
}

/** İstemciye giden görünüm (rakibin açıklanmamış cevabı ve bulmaca sızmaz) */
async function gorunum(mac: Satir, pid: string): Promise<Response> {
  const an = simdi();
  const rakipId = mac.a === pid ? mac.b : mac.a;
  let rakip: Satir = { bot: true, nick: "Yapay zekâ" };
  if (mac.is_bot) {
    const k = H.botPersona(mac.seed);   // her zaman bot=true: arayüz "yapay zekâ" diye etiketler
    rakip = { bot: true, nick: k.nick, city: k.city };
  } else {
    const o = rakipId ? await tek("players", { id: rakipId }) : null;
    rakip = o ? { bot: false, nick: o.nick, city: o.city ?? null } : { bot: false, nick: null };
  }
  const base: Satir = { match_id: mac.id, state: mac.state, rakip, server_now: new Date(an).toISOString() };
  if (mac.state === "waiting") {
    const gecen = an - ms(mac.created_at);
    return json({ ...base, bekleme_ms: gecen, bot_icin_kalan_ms: Math.max(0, BOT_BEKLEME_MS - gecen) });
  }
  if (mac.state === "abandoned") return json({ ...base, bitti: true, terk: true });

  const turlar = await liste("match_rounds", { match_id: mac.id });
  const hamleler = await liste("match_moves", { match_id: mac.id });
  const sonuclar: Satir[] = [];
  const toplam = { ben: 0, rakip: 0 };
  let guncel = 0;   // oynanacak ilk bitmemiş tur (1..4); 0 = hepsi bitti
  for (let r = 1; r <= 4; r++) {
    const t = turlar.find((x) => x.round === r);
    if (t && turBitmisMi(t, hamleler, mac, pid, an)) {
      const b = hamleler.find((h) => h.round === r && h.player_id === pid)?.payload;
      const o = mac.is_bot ? t.bot_move : hamleler.find((h) => h.round === r && h.player_id !== pid)?.payload;
      const bs = b?.score ?? 0, os = o?.score ?? 0;
      toplam.ben += bs; toplam.rakip += os;
      sonuclar.push({
        round: r, kind: t.kind, target: t.payload.target ?? null,
        ben: { score: bs, answer: b?.answer ?? "", detail: b?.detail ?? (b ? "" : "Cevap gelmedi") },
        rakip: { score: os, answer: o?.answer ?? "" },
        best_solution: t.best_solution, best_score: t.best_score,
      });
    } else { guncel = r; break; }
  }
  if (!guncel) {
    if (mac.state === "active") {
      await admin.from("matches").update({ state: "finished", finished_at: new Date(an).toISOString() }).eq("id", mac.id).eq("state", "active");
    }
    const kazanan = toplam.ben > toplam.rakip ? "ben" : toplam.ben < toplam.rakip ? "rakip" : "berabere";
    return json({ ...base, state: "finished", bitti: true, tur: 0, sonuclar, toplam, kazanan });
  }
  const t = turlar.find((x) => x.round === guncel);
  const benGonderdim = !!hamleler.find((h) => h.round === guncel && h.player_id === pid);
  return json({
    ...base, bitti: false, tur: guncel, sonuclar, toplam, ben_gonderdim: benGonderdim,
    tur_basladi_ms: t ? ms(t.started_at) - an : null,   // <0: başladı, >0: geri sayım
    rakip_kalan_ms: t && benGonderdim && !mac.is_bot ? Math.max(0, turKapanis(t, hamleler) - an) : null,   // rakibe kalan süre
    sure_ms: SURE_MS,
  });
}

async function macBul(matchId: unknown, pid: string): Promise<Satir | null> {
  if (typeof matchId !== "string") return null;
  const m = await tek("matches", { id: matchId });
  return m && (m.a === pid || m.b === pid) ? m : null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return hata("POST gerekli", 405);
  const k = await kullanici(req);
  if (!k) return hata("Giriş gerekli", 401);
  const pid = k.id;

  // deno-lint-ignore no-explicit-any
  let body: any;
  try { body = await req.json(); } catch { return hata("Geçersiz JSON"); }
  if (!(await tek("players", { id: pid }))) return hata("Önce oyuncu kartı oluştur", 428);

  switch (body.action) {
    case "queue": {
      const mevcut = await mevcutMac(pid);
      if (mevcut) return gorunum(mevcut, pid);
      const katildi = await katil(pid, null);
      if (katildi) return gorunum(katildi, pid);
      const { data, error } = await admin.from("matches").insert({ a: pid, seed: rastgeleTohum(), state: "waiting", is_bot: false }).select();
      if (error) return hata(error.message, 500);
      return gorunum(data![0], pid);
    }
    case "status": {
      let mac = await macBul(body.match_id, pid);
      if (!mac) return hata("Maç bulunamadı", 404);
      if (mac.state === "waiting" && mac.a === pid) {
        // Aynı anda iki oyuncu da bekleyen maç açmış olabilir: daha eski olana katıl (eskisi hiçbir yere katılmaz)
        const k2 = await katil(pid, mac);
        if (k2) mac = k2;
      }
      return gorunum(mac, pid);
    }
    case "bot": {
      const mac = await macBul(body.match_id, pid);
      if (!mac) return hata("Maç bulunamadı", 404);
      if (mac.state !== "waiting" || mac.a !== pid) return hata("Maç bekleme durumunda değil", 409);
      if (simdi() - ms(mac.created_at) < BOT_BEKLEME_MS - 1000) return hata("Henüz erken: önce gerçek rakip aranır", 409);
      const { data } = await admin.from("matches").update({ is_bot: true, state: "active" }).eq("id", mac.id).eq("state", "waiting").select();
      return gorunum(data?.[0] ?? (await tek("matches", { id: mac.id }))!, pid);
    }
    case "start":
    case "submit": {
      const mac = await macBul(body.match_id, pid);
      if (!mac) return hata("Maç bulunamadı", 404);
      if (mac.state !== "active") return hata("Maç aktif değil", 409);
      const round = Number(body.round);
      if (!Number.isInteger(round) || round < 1 || round > 4) return hata("Geçersiz tur");

      const an = simdi();
      const turlar = await liste("match_rounds", { match_id: mac.id });
      const hamleler = await liste("match_moves", { match_id: mac.id });
      // sıra: önceki turlar bitmiş olmalı
      for (let r = 1; r < round; r++) {
        const t = turlar.find((x) => x.round === r);
        if (!t || !turBitmisMi(t, hamleler, mac, pid, an)) return hata("Önce önceki tur bitmeli", 409);
      }
      if (hamleler.some((h) => h.round === round && h.player_id === pid)) return hata("Bu tur zaten oynandı", 409);
      let satir = turlar.find((x) => x.round === round);

      if (body.action === "start") {
        if (satir && turBitmisMi(satir, hamleler, mac, pid, an)) return hata("Tur bitti", 409);
        if (!satir) {
          const rr = H.roundFromSeed("duello-" + mac.seed, round - 1);
          const yeni = {
            match_id: mac.id, round, kind: rr.kind, payload: rr.payload,
            best_score: rr.best.score, best_solution: rr.best.solution,
            bot_move: mac.is_bot ? H.botMove(mac.seed, round - 1, rr) : null,
            started_at: new Date(an + GERI_SAYIM_MS).toISOString(),
          };
          // iki oyuncu aynı anda çağırırsa ilk yazılan kazanır (aynı başlangıç anı)
          await admin.from("match_rounds").upsert(yeni, { onConflict: "match_id,round", ignoreDuplicates: true });
          satir = await tek("match_rounds", { match_id: mac.id, round }) ?? undefined;
          if (!satir) return hata("Tur oluşturulamadı", 500);
        }
        const bekle = ms(satir.started_at) - an;
        if (bekle > 0) return json({ durum: "sayim", bekle_ms: bekle, server_now: new Date(an).toISOString() });
        return json({
          durum: "basladi", round, kind: satir.kind, payload: satir.payload,
          started_at: satir.started_at, server_now: new Date(an).toISOString(), limit_sec: H.GUNLUK_SURE,
        });
      }

      // submit
      if (!satir) return hata("Önce tur başlatılmalı", 409);
      if (an < ms(satir.started_at)) return hata("Tur henüz başlamadı", 409);
      const cevap = typeof body.answer === "string" ? body.answer.slice(0, 200) : "";
      const gecen = an - ms(satir.started_at);
      const sonuc = H.scoreRound(satir.kind, satir.payload, cevap, gecen, H.GUNLUK_SURE, { bonus: false });
      const ins = await admin.from("match_moves").insert({
        match_id: mac.id, round, player_id: pid,
        payload: { answer: cevap, score: sonuc.score, valid: sonuc.valid, detail: sonuc.detail, elapsed_ms: Math.round(gecen) },
      });
      if (ins.error) return hata(ins.error.code === "23505" ? "Bu tur zaten oynandı" : ins.error.message, ins.error.code === "23505" ? 409 : 500);
      return gorunum(mac, pid);
    }
    default:
      return hata("Geçersiz işlem");
  }
});

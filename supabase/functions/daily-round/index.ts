// Günlük turu başlatma ve gönderme. Puanı sunucu hesaplar, süreyi sunucu damgası tutar.
//   POST {"action":"start","round":1..4}                 -> bulmaca + sunucu başlangıç zamanı
//   POST {"action":"submit","round":1..4,"answer":"..."} -> puan + açıklanan en iyi cevap
// Kimlik: Authorization: Bearer <kullanıcı JWT'si>. Yalnızca bugünün (İstanbul) bulmacası oynanır.
import { admin, bugun, cors, H, json } from "../_shared/ortak.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "POST gerekli" }, 405);

  const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer /, "");
  const { data: { user }, error: authErr } = await admin.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Giriş gerekli" }, 401);

  let body: { action?: string; round?: unknown; answer?: unknown };
  try { body = await req.json(); } catch { return json({ error: "Geçersiz JSON" }, 400); }

  const round = Number(body.round);
  if (!Number.isInteger(round) || round < 1 || round > 4) return json({ error: "Geçersiz tur" }, 400);
  if (body.action !== "start" && body.action !== "submit") return json({ error: "Geçersiz işlem" }, 400);

  const date = bugun();
  const pid = user.id;

  const { data: player } = await admin.from("players").select("id").eq("id", pid).maybeSingle();
  if (!player) return json({ error: "Önce oyuncu kartı oluştur" }, 428);

  const { data: puzzle } = await admin.from("daily_puzzles").select("kind,payload").eq("date", date).eq("round", round).maybeSingle();
  if (!puzzle) return json({ error: "Bugünün bulmacası hazır değil" }, 404);

  const { data: done } = await admin.from("daily_scores").select("round").eq("date", date).eq("player_id", pid);
  const bitenler = new Set((done ?? []).map((r: { round: number }) => r.round));
  if (bitenler.has(round)) return json({ error: "Bu tur zaten oynandı" }, 409);

  if (body.action === "start") {
    if (round > 1 && !bitenler.has(round - 1)) return json({ error: "Önce önceki turu bitir" }, 409);
    // İlk başlatma kalıcı: yeniden başlatarak süre sıfırlanamaz.
    const ins = await admin.from("daily_round_starts")
      .upsert({ date, player_id: pid, round }, { onConflict: "date,player_id,round", ignoreDuplicates: true });
    if (ins.error) return json({ error: ins.error.message }, 500);
    const { data: st } = await admin.from("daily_round_starts").select("started_at")
      .eq("date", date).eq("player_id", pid).eq("round", round).single();
    return json({
      round, kind: puzzle.kind, payload: puzzle.payload,
      started_at: st!.started_at, server_now: new Date().toISOString(), limit_sec: H.GUNLUK_SURE,
    });
  }

  // submit
  const answer = typeof body.answer === "string" ? body.answer.slice(0, 200) : "";
  const { data: st } = await admin.from("daily_round_starts").select("started_at")
    .eq("date", date).eq("player_id", pid).eq("round", round).maybeSingle();
  if (!st) return json({ error: "Önce tur başlatılmalı" }, 409);

  const elapsedMs = Date.now() - new Date(st.started_at).getTime();
  const sonuc = H.scoreRound(puzzle.kind, puzzle.payload, answer, elapsedMs, H.GUNLUK_SURE);

  const ins = await admin.from("daily_scores").insert({
    date, player_id: pid, round, score: sonuc.score, answer, duration_ms: Math.max(0, Math.round(elapsedMs)),
  });
  if (ins.error) return json({ error: ins.error.code === "23505" ? "Bu tur zaten oynandı" : ins.error.message }, ins.error.code === "23505" ? 409 : 500);

  const { data: sol } = await admin.from("daily_solutions").select("best_score,best_solution").eq("date", date).eq("round", round).maybeSingle();
  return json({
    round, score: sonuc.score, valid: sonuc.valid, detail: sonuc.detail,
    best_score: sol?.best_score ?? null, best_solution: sol?.best_solution ?? null,
  });
});

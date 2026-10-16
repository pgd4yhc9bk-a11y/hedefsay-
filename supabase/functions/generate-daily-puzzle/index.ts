// Günlük bulmacayı üretir (cron ile her gün çağrılır). Varsayılan: yarının bulmacası.
// Çağrı: POST, başlık  x-cron-secret: $CRON_SECRET   gövde (isteğe bağlı): {"date":"YYYY-MM-DD"}
// Yayınlanmış bulmaca asla ezilmez (ignoreDuplicates). Sır: CRON_SECRET (çağrı), PUZZLE_SALT (tohum tuzu).
import { admin, cors, H, json, yarin } from "../_shared/ortak.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "POST gerekli" }, 405);

  const secret = Deno.env.get("CRON_SECRET");
  if (!secret || req.headers.get("x-cron-secret") !== secret) return json({ error: "Yetkisiz" }, 401);

  let date = yarin();
  try {
    const b = await req.json();
    if (b?.date) date = String(b.date);
  } catch { /* gövde yok: varsayılan tarih */ }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return json({ error: "Geçersiz tarih" }, 400);

  // Tohum tarihten türetilir ve kod istemcide herkese açıktır; gizli tuz olmadan bulmaca önceden hesaplanabilir.
  // PUZZLE_SALT yoksa yine de üretir (hizmet kesilmesin) ama uyarır.
  const salt = Deno.env.get("PUZZLE_SALT") || "";
  const uyari = salt ? undefined : "PUZZLE_SALT ayarlı değil: bulmaca tarihten tahmin edilebilir. `supabase secrets set PUZZLE_SALT=<uzun rastgele>`";

  const puzzles = [], solutions = [];
  for (let i = 0; i < 4; i++) {
    const r = H.dailyRound(date, i, salt);
    puzzles.push({ date, round: i + 1, kind: r.kind, payload: r.payload });
    solutions.push({ date, round: i + 1, best_score: r.best.score, best_solution: r.best.solution });
  }

  // daily_solutions, daily_puzzles'a bağlı: önce bulmacalar
  const p = await admin.from("daily_puzzles").upsert(puzzles, { onConflict: "date,round", ignoreDuplicates: true });
  if (p.error) return json({ error: p.error.message }, 500);
  const s = await admin.from("daily_solutions").upsert(solutions, { onConflict: "date,round", ignoreDuplicates: true });
  if (s.error) return json({ error: s.error.message }, 500);

  return json({ date, rounds: 4, ...(uyari ? { uyari } : {}) });
});

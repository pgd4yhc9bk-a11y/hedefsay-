// Edge Function'ların ortak yardımcıları. Oyun mantığı _shared/oyun.js'te (prototip ile aynı kod).
import "./sozluk.js";
import "./oyun.js";
import { createClient } from "jsr:@supabase/supabase-js@2";

// deno-lint-ignore no-explicit-any
export const H = (globalThis as any).Hedef;
// deno-lint-ignore no-explicit-any
H.setDictionary((globalThis as any).HEDEF_SOZLUK);

export const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

export const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-cron-secret",
};

export function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...cors },
  });
}

/** İstanbul takvim günü (YYYY-MM-DD). Günlük bulmaca bu güne göre döner. */
export function bugun(): string {
  return new Date().toLocaleDateString("sv-SE", { timeZone: "Europe/Istanbul" });
}

export function yarin(): string {
  const d = new Date(bugun() + "T00:00:00Z");
  d.setUTCDate(d.getUTCDate() + 1);
  return d.toISOString().slice(0, 10);
}

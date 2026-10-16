// Hedef — Supabase istemcisi (kütüphanesiz; yalnızca fetch). Anonim oturum, oyuncu kartı, daily-round, duel, sıralamalar.
// Puan ve süre sunucuda hesaplanır; istemci yalnızca cevabı gönderir.
import AsyncStorage from "@react-native-async-storage/async-storage";
import { AYAR } from "./ayar";

/* eslint-disable @typescript-eslint/no-explicit-any */
const OTURUM = "hedef-oturum";

interface Oturum { access_token: string; refresh_token: string; expires_at: number; user_id: string }
export class SunucuHatasi extends Error {
  constructor(mesaj: string, public status: number) { super(mesaj); }
}

let bellek: Oturum | null = null;

export const hazir = () => !!(AYAR.url && AYAR.anonKey);

async function istek(yol: string, ayar: { method?: string; body?: unknown; jwt?: string; headers?: Record<string, string> } = {}) {
  const h: Record<string, string> = {
    apikey: AYAR.anonKey, "content-type": "application/json", Authorization: "Bearer " + (ayar.jwt ?? AYAR.anonKey), ...(ayar.headers ?? {}),
  };
  const r = await fetch(AYAR.url + yol, { method: ayar.method ?? "GET", headers: h, body: ayar.body === undefined ? undefined : JSON.stringify(ayar.body) });
  const t = await r.text();
  let j: any = null;
  try { j = t ? JSON.parse(t) : null; } catch { /* gövde JSON değil */ }
  if (!r.ok) throw new SunucuHatasi((j && (j.error || j.message || j.msg)) || "HTTP " + r.status, r.status);
  return j;
}

async function oku(): Promise<Oturum | null> {
  try { return JSON.parse((await AsyncStorage.getItem(OTURUM)) || "null"); } catch { return null; }
}
async function kaydet(n: any): Promise<Oturum> {
  const o: Oturum = {
    access_token: n.access_token, refresh_token: n.refresh_token,
    expires_at: n.expires_at || Math.floor(Date.now() / 1000) + (n.expires_in || 3600), user_id: n.user?.id,
  };
  bellek = o;
  try { await AsyncStorage.setItem(OTURUM, JSON.stringify(o)); } catch { /* depo yoksa bellekte kalır */ }
  return o;
}

/** Geçerli oturum; yoksa yeniler, o da olmazsa anonim yeni oturum açar. */
async function oturum(): Promise<Oturum> {
  const o = bellek ?? (await oku());
  if (o && o.expires_at * 1000 > Date.now() + 30000) { bellek = o; return o; }
  const yeni = async () => kaydet(await istek("/auth/v1/signup", { method: "POST", body: {} }));
  if (o?.refresh_token) {
    try { return await kaydet(await istek("/auth/v1/token?grant_type=refresh_token", { method: "POST", body: { refresh_token: o.refresh_token } })); }
    catch { return yeni(); }
  }
  return yeni();
}

export interface Oyuncu { id: string; nick: string; city: string | null }

export const iller = async (): Promise<string[]> =>
  (await istek("/rest/v1/cities?select=name") as { name: string }[]).map((x) => x.name).sort((a, b) => a.localeCompare(b, "tr"));

export async function oyuncu(): Promise<Oyuncu | null> {
  const o = await oturum();
  const r = await istek("/rest/v1/players?select=id,nick,city&id=eq." + o.user_id, { jwt: o.access_token });
  return r?.[0] ?? null;
}
export async function oyuncuKaydet(nick: string, city: string): Promise<void> {
  const o = await oturum();
  await istek("/rest/v1/players", { method: "POST", jwt: o.access_token, headers: { Prefer: "return=minimal" }, body: { id: o.user_id, nick, city: city || null } });
}
export async function skorlar(tarih: string): Promise<{ round: number; score: number }[]> {
  const o = await oturum();
  return istek("/rest/v1/daily_scores?select=round,score&order=round.asc&date=eq." + tarih, { jwt: o.access_token });
}
export async function gunlukTur(action: "start" | "submit", round: number, answer?: string): Promise<any> {
  const o = await oturum();
  return istek("/functions/v1/daily-round", { method: "POST", jwt: o.access_token, body: { action, round, answer } });
}
export async function duello(action: "queue" | "status" | "bot" | "start" | "submit", ek: Record<string, unknown> = {}): Promise<any> {
  const o = await oturum();
  return istek("/functions/v1/duel", { method: "POST", jwt: o.access_token, body: { action, ...ek } });
}
export async function siralama(tarih: string): Promise<{ nick: string; city: string | null; total: number; rank: number }[]> {
  const o = await oturum();
  return istek("/rest/v1/daily_leaderboard?select=nick,city,total,rank&order=rank.asc&limit=10&date=eq." + tarih, { jwt: o.access_token });
}
export async function ilLigi(hafta: string): Promise<{ city: string; total: number; players: number; average: number }[]> {
  const o = await oturum();
  return istek("/rest/v1/city_league?select=city,total,players,average&order=total.desc&limit=10&week=eq." + hafta, { jwt: o.access_token });
}

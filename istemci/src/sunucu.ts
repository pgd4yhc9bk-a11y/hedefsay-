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
  // Yeni tür herkese açık anahtarlar (sb_publishable_…) JWT değildir: yalnızca `apikey` başlığında gider.
  // Authorization yalnızca kullanıcı oturumu (JWT) varken eklenir.
  const h: Record<string, string> = { apikey: AYAR.anonKey, "content-type": "application/json", ...(ayar.headers ?? {}) };
  if (ayar.jwt) h.Authorization = "Bearer " + ayar.jwt;
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

export interface Oyuncu { id: string; nick: string; city: string | null; avatar_url?: string | null; kayit_izni?: boolean }

export const iller = async (): Promise<string[]> =>
  (await istek("/rest/v1/cities?select=name") as { name: string }[]).map((x) => x.name).sort((a, b) => a.localeCompare(b, "tr"));

export async function oyuncu(): Promise<Oyuncu | null> {
  const o = await oturum();
  const r = await istek("/rest/v1/players?select=id,nick,city,avatar_url,kayit_izni&id=eq." + o.user_id, { jwt: o.access_token });
  return r?.[0] ?? null;
}
export async function oyuncuKaydet(nick: string, city: string, kayitIzni = false, avatarUrl: string | null = null): Promise<void> {
  const o = await oturum();
  await istek("/rest/v1/players", { method: "POST", jwt: o.access_token, headers: { Prefer: "return=minimal" },
    body: { id: o.user_id, nick, city: city || null, kayit_izni: kayitIzni, avatar_url: avatarUrl } });
}
/** Oyuncu kartında değişiklik (izin, fotoğraf …) */
export async function oyuncuGuncelle(yama: { kayit_izni?: boolean; avatar_url?: string | null; city?: string | null; nick?: string }): Promise<void> {
  const o = await oturum();
  await istek("/rest/v1/players?id=eq." + o.user_id, { method: "PATCH", jwt: o.access_token, headers: { Prefer: "return=minimal" }, body: yama });
}
/** Fotoğrafı kendi klasörüne yükler (avatarlar/<kullanıcı>/avatar.jpg) ve herkese açık adresini döner. Boyut ve tür sunucuda sınırlıdır (1 MB, jpeg/png/webp). */
export async function avatarYukle(uri: string, mime = "image/jpeg"): Promise<string> {
  const o = await oturum();
  const blob = await (await fetch(uri)).blob();
  if (blob.size > 1048576) throw new SunucuHatasi("Fotoğraf 1 MB'tan küçük olmalı", 413);
  const yol = `${o.user_id}/avatar.${mime === "image/png" ? "png" : mime === "image/webp" ? "webp" : "jpg"}`;
  const r = await fetch(`${AYAR.url}/storage/v1/object/avatarlar/${yol}`, {
    method: "POST", headers: { apikey: AYAR.anonKey, Authorization: "Bearer " + o.access_token, "content-type": mime, "x-upsert": "true" }, body: blob,
  });
  if (!r.ok) { let m = "Yüklenemedi"; try { m = (await r.json()).message ?? m; } catch { /* gövde yok */ } throw new SunucuHatasi(m, r.status); }
  return `${AYAR.url}/storage/v1/object/public/avatarlar/${yol}?v=${Date.now()}`;
}
export interface Arkadas { id: string; kullanici: string; nick: string; city: string | null; avatar_url: string | null; durum: "arkadas" | "gelen" | "giden" }
/** Kendi arkadaş kodum + arkadaşlar, gelen ve giden istekler */
export async function arkadaslar(): Promise<{ kod: string; liste: Arkadas[] }> {
  const o = await oturum();
  return istek("/rest/v1/rpc/arkadas_listesi", { method: "POST", jwt: o.access_token, body: {} });
}
/** Kodla istek gönder; karşı taraf zaten istek göndermişse doğrudan arkadaş olunur */
export async function arkadasEkle(kod: string): Promise<{ durum: "arkadas" | "giden" }> {
  const o = await oturum();
  return istek("/rest/v1/rpc/arkadas_ekle", { method: "POST", jwt: o.access_token, body: { p_kod: kod } });
}
export async function arkadasYanit(id: string, kabul: boolean): Promise<void> {
  const o = await oturum();
  await istek("/rest/v1/rpc/arkadas_yanit", { method: "POST", jwt: o.access_token, body: { p_id: id, p_kabul: kabul } });
}
/** Arkadaşı sil veya gönderdiğin isteği geri çek */
export async function arkadasSil(id: string): Promise<void> {
  const o = await oturum();
  await istek("/rest/v1/rpc/arkadas_sil", { method: "POST", jwt: o.access_token, body: { p_id: id } });
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
export async function siralama(tarih: string): Promise<{ nick: string; city: string | null; total: number; rank: number; avatar_url?: string | null }[]> {
  const o = await oturum();
  return istek("/rest/v1/daily_leaderboard?select=nick,city,total,rank,avatar_url&order=rank.asc&limit=10&date=eq." + tarih, { jwt: o.access_token });
}
export async function ilLigi(hafta: string): Promise<{ city: string; total: number; players: number; average: number }[]> {
  const o = await oturum();
  return istek("/rest/v1/city_league?select=city,total,players,average&order=total.desc&limit=10&week=eq." + hafta, { jwt: o.access_token });
}

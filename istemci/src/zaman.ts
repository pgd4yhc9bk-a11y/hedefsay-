/** İstanbul takvim günü (YYYY-MM-DD) */
export function bugun(): string {
  try { return new Date().toLocaleDateString("sv-SE", { timeZone: "Europe/Istanbul" }); }
  catch { return new Date().toISOString().slice(0, 10); }
}
/** Bu haftanın pazartesisi (il ligi haftası) */
export function haftaBasi(): string {
  const d = new Date(bugun() + "T00:00:00Z");
  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
  return d.toISOString().slice(0, 10);
}

// Edge Function testleri için bellek içi sahte supabase-js (yalnızca fonksiyonların kullandığı zincirler).
// deno test --import-map=supabase/tests/import_map.json ...
// deno-lint-ignore-file no-explicit-any
type Row = Record<string, any>;
const PK: Record<string, string[]> = {
  players: ["id"], daily_puzzles: ["date", "round"], daily_solutions: ["date", "round"],
  daily_round_starts: ["date", "player_id", "round"], daily_scores: ["date", "player_id", "round"],
};
export const db: Record<string, Row[]> = {};
export function sifirla() { for (const k of Object.keys(PK)) db[k] = []; }
sifirla();

class Q {
  f: [string, any][] = []; op = "select"; rows: Row[] = []; opts: any = {};
  constructor(public t: string) {}
  select(_c?: string) { return this; }
  eq(c: string, v: any) { this.f.push([c, v]); return this; }
  upsert(rows: Row | Row[], opts: any = {}) { this.op = "upsert"; this.rows = [].concat(rows as any); this.opts = opts; return this; }
  insert(rows: Row | Row[]) { this.op = "insert"; this.rows = [].concat(rows as any); return this; }
  key(r: Row) { return PK[this.t].map((c) => String(r[c])).join("|"); }
  run(): { data: any; error: any } {
    const tablo = db[this.t];
    if (this.op === "select") {
      return { data: tablo.filter((r) => this.f.every(([c, v]) => String(r[c]) === String(v))), error: null };
    }
    for (const r of this.rows) {
      const var_ = tablo.some((x) => this.key(x) === this.key(r));
      if (var_) {
        if (this.op === "insert") return { data: null, error: { code: "23505", message: "duplicate key" } };
        if (this.opts.ignoreDuplicates) continue;
      }
      const yeni = { ...r };
      if (this.t === "daily_round_starts" && !yeni.started_at) yeni.started_at = new Date().toISOString();
      tablo.push(yeni);
    }
    return { data: null, error: null };
  }
  maybeSingle() { const r = this.run(); return Promise.resolve({ data: r.data?.[0] ?? null, error: r.error }); }
  single() {
    const r = this.run(); const x = r.data?.[0];
    return Promise.resolve(x ? { data: x, error: null } : { data: null, error: { message: "satır yok" } });
  }
  then(res: any, rej?: any) { return Promise.resolve(this.run()).then(res, rej); }
}

export function createClient(_u: string, _k: string) {
  return {
    from: (t: string) => new Q(t),
    auth: {
      getUser: (jwt: string) =>
        Promise.resolve(jwt.startsWith("user:")
          ? { data: { user: { id: jwt.slice(5) } }, error: null }
          : { data: { user: null }, error: { message: "geçersiz" } }),
    },
  };
}

-- Canlı düello (Faz 4).
-- Güvenlik: düelloda hem rakibin henüz açıklanmamış cevabı (match_moves) hem de maç tohumu (matches.seed;
-- tohumdan tüm turların bulmacası önceden hesaplanabilir) istemciye sızmamalı. Bu yüzden istemcinin
-- matches / match_moves tablolarına doğrudan erişimi kapatılır; her şey `duel` Edge Function'ından geçer.

drop policy matches_participant_read on public.matches;
drop policy moves_participant_read on public.match_moves;
revoke all on public.matches, public.match_moves from anon, authenticated;

-- Her turun bulmacası (tohumdan üretilir, burada saklanır). Başlangıç = geri sayımın bittiği an (sunucu saati).
create table public.match_rounds (
  match_id      uuid     not null references public.matches (id) on delete cascade,
  round         smallint not null check (round between 1 and 4),
  kind          text     not null check (kind in ('kelime', 'islem')),
  payload       jsonb    not null,
  best_score    smallint not null,
  best_solution text     not null,
  bot_move      jsonb,   -- bot maçlarında botun bu turdaki hamlesi {answer, score}
  started_at    timestamptz not null,
  primary key (match_id, round)
);
alter table public.match_rounds enable row level security;
revoke all on public.match_rounds from anon, authenticated;   -- politika yok = istemciye kapalı

alter table public.matches add column finished_at timestamptz;
create index matches_state_idx on public.matches (state) where state in ('waiting', 'active');

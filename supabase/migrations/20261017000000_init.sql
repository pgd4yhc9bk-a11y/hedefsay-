-- Hedef — ilk şema (docs/TASARIM.md §8 veri modeli taslağından).
--
-- Tasarım notları (taslaktan sapmalar):
--  * Günlük oyun 4 tur olduğu için `daily_puzzles` tur başına bir satır (date, round) + jsonb payload.
--  * Cevaplar (en iyi kelime / en iyi işlem) `daily_solutions` tablosunda, istemciye KAPALI.
--    Tur gönderildikten sonra Edge Function açıklar.
--  * Süre sunucu damgasıyla tutulur: `daily_round_starts.started_at`.
--  * Tüm yazmalar (skor, hamle, eşleşme) Edge Function / service_role ile yapılır; istemcinin
--    yazma politikası yalnızca kendi oyuncu kartında vardır.

-- ---------- iller ----------
create table public.cities (name text primary key);
insert into public.cities (name) values
  ('Adana'),('Adıyaman'),('Afyonkarahisar'),('Ağrı'),('Aksaray'),('Amasya'),('Ankara'),('Antalya'),
  ('Ardahan'),('Artvin'),('Aydın'),('Balıkesir'),('Bartın'),('Batman'),('Bayburt'),('Bilecik'),
  ('Bingöl'),('Bitlis'),('Bolu'),('Burdur'),('Bursa'),('Çanakkale'),('Çankırı'),('Çorum'),
  ('Denizli'),('Diyarbakır'),('Düzce'),('Edirne'),('Elazığ'),('Erzincan'),('Erzurum'),('Eskişehir'),
  ('Gaziantep'),('Giresun'),('Gümüşhane'),('Hakkari'),('Hatay'),('Iğdır'),('Isparta'),('İstanbul'),
  ('İzmir'),('Kahramanmaraş'),('Karabük'),('Karaman'),('Kars'),('Kastamonu'),('Kayseri'),('Kırıkkale'),
  ('Kırklareli'),('Kırşehir'),('Kilis'),('Kocaeli'),('Konya'),('Kütahya'),('Malatya'),('Manisa'),
  ('Mardin'),('Mersin'),('Muğla'),('Muş'),('Nevşehir'),('Niğde'),('Ordu'),('Osmaniye'),
  ('Rize'),('Sakarya'),('Samsun'),('Siirt'),('Sinop'),('Sivas'),('Şanlıurfa'),('Şırnak'),
  ('Tekirdağ'),('Tokat'),('Trabzon'),('Tunceli'),('Uşak'),('Van'),('Yalova'),('Yozgat'),('Zonguldak');

-- ---------- oyuncular (KVKK: yalnızca takma ad + il) ----------
create table public.players (
  id         uuid primary key references auth.users (id) on delete cascade,  -- hesap silinince her şey silinir
  nick       text not null check (char_length(nick) between 2 and 20),
  city       text references public.cities (name) on update cascade,
  created_at timestamptz not null default now()
);

-- ---------- günlük bulmaca ----------
create table public.daily_puzzles (
  date    date     not null,
  round   smallint not null check (round between 1 and 4),
  kind    text     not null check (kind in ('kelime', 'islem')),
  payload jsonb    not null,   -- kelime: {"letters":[8 harf]}  işlem: {"nums":[6 sayı],"target":n}
  primary key (date, round)
);

create table public.daily_solutions (
  date          date     not null,
  round         smallint not null,
  best_score    smallint not null,
  best_solution text     not null,
  primary key (date, round),
  foreign key (date, round) references public.daily_puzzles (date, round) on delete cascade
);

create table public.daily_round_starts (
  date       date     not null,
  player_id  uuid     not null references public.players (id) on delete cascade,
  round      smallint not null check (round between 1 and 4),
  started_at timestamptz not null default now(),
  primary key (date, player_id, round)
);

create table public.daily_scores (
  date        date     not null,
  player_id   uuid     not null references public.players (id) on delete cascade,
  round       smallint not null check (round between 1 and 4),
  score       smallint not null check (score >= 0),
  answer      text,
  duration_ms integer  check (duration_ms >= 0),
  created_at  timestamptz not null default now(),
  primary key (date, player_id, round)   -- günde bir kez
);

-- ---------- düello ----------
create table public.matches (
  id         uuid primary key default gen_random_uuid(),
  a          uuid not null references public.players (id) on delete cascade,
  b          uuid references public.players (id) on delete set null,   -- bot rakipte null
  is_bot     boolean not null default false,
  state      text not null default 'waiting' check (state in ('waiting', 'active', 'finished', 'abandoned')),
  seed       text not null,
  created_at timestamptz not null default now(),
  check (b is null or a <> b),
  check (not (is_bot and b is not null))
);
create index matches_a_idx on public.matches (a);
create index matches_b_idx on public.matches (b);

create table public.match_moves (
  match_id  uuid     not null references public.matches (id) on delete cascade,
  round     smallint not null check (round between 1 and 4),
  player_id uuid     not null references public.players (id) on delete cascade,
  payload   jsonb    not null,
  ts        timestamptz not null default now(),
  primary key (match_id, round, player_id)
);

-- ---------- sıralama görünümleri ----------
-- Görünümler sahibinin yetkisiyle çalışır (RLS'yi atlar) ve yalnızca toplamları açar;
-- kimsenin kelime/işlem cevabı sızmaz. Yalnızca 4 turu tamamlayanlar sayılır.
create view public.daily_totals as
  select date, player_id, sum(score)::int as total, max(created_at) as finished_at
  from public.daily_scores
  group by date, player_id
  having count(*) = 4;

create view public.daily_leaderboard as
  select t.date, p.nick, p.city, t.total,
         rank() over (partition by t.date order by t.total desc, t.finished_at) as rank
  from public.daily_totals t
  join public.players p on p.id = t.player_id;

create view public.city_league as
  select date_trunc('week', t.date)::date as week,
         p.city,
         sum(t.total)::int                as total,
         count(distinct t.player_id)::int as players,
         round(avg(t.total), 1)           as average
  from public.daily_totals t
  join public.players p on p.id = t.player_id
  where p.city is not null
  group by 1, 2;

-- ---------- erişim ----------
alter table public.cities            enable row level security;
alter table public.players           enable row level security;
alter table public.daily_puzzles     enable row level security;
alter table public.daily_solutions   enable row level security;
alter table public.daily_round_starts enable row level security;
alter table public.daily_scores      enable row level security;
alter table public.matches           enable row level security;
alter table public.match_moves       enable row level security;

create policy cities_read on public.cities for select to anon, authenticated using (true);

create policy players_read   on public.players for select to authenticated using (true);
create policy players_insert on public.players for insert to authenticated with check (id = auth.uid());
create policy players_update on public.players for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy players_delete on public.players for delete to authenticated using (id = auth.uid());

-- Bulmaca yalnızca günü gelince görünür (İstanbul saati); cevapları ayrı tabloda.
create policy puzzles_read on public.daily_puzzles for select to authenticated
  using (date <= (now() at time zone 'Europe/Istanbul')::date);

-- daily_solutions ve daily_round_starts: politika yok = istemciye tamamen kapalı (yalnızca service_role).
-- daily_scores: oyuncu yalnızca kendi satırlarını okur; yazma yalnızca service_role.
create policy scores_own_read on public.daily_scores for select to authenticated using (player_id = auth.uid());

create policy matches_participant_read on public.matches for select to authenticated
  using (auth.uid() in (a, b));
create policy moves_participant_read on public.match_moves for select to authenticated
  using (exists (select 1 from public.matches m where m.id = match_id and auth.uid() in (m.a, m.b)));

-- Tablo yetkilerini de daralt (RLS'ye ek, derinlemesine savunma).
revoke all on public.daily_solutions, public.daily_round_starts from anon, authenticated;
revoke insert, update, delete on public.daily_puzzles, public.daily_scores, public.matches, public.match_moves,
                                public.cities from anon, authenticated;
revoke all on public.players, public.daily_puzzles, public.daily_scores, public.matches, public.match_moves from anon;
grant select on public.daily_leaderboard, public.city_league to authenticated;
revoke all on public.daily_totals from anon, authenticated;
revoke all on public.daily_leaderboard, public.city_league from anon;

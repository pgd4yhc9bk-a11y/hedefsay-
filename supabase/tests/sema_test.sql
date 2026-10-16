\set ON_ERROR_STOP on
\set A '''00000000-0000-0000-0000-00000000000a'''
\set B '''00000000-0000-0000-0000-00000000000b'''
\set C '''00000000-0000-0000-0000-00000000000c'''

create function pg_temp.expect_error(q text) returns void language plpgsql as $$
begin
  begin execute q; exception when others then return; end;
  raise exception 'HATA BEKLENİYORDU ama geçti: %', q;
end $$;
create function pg_temp.expect_count(q text, n int) returns void language plpgsql as $$
declare got int;
begin
  execute 'select count(*) from (' || q || ') x' into got;
  if got <> n then raise exception 'beklenen % satır, gelen %: %', n, got, q; end if;
end $$;
grant execute on function pg_temp.expect_error(text), pg_temp.expect_count(text, int) to public;

select (now() at time zone 'Europe/Istanbul')::date as bugun \gset
-- ---- hazırlık ----
-- Gerçekte kullanıcıları Supabase Auth oluşturur; testte süper kullanıcıyla ekliyoruz.
insert into auth.users (id) values (:A), (:B), (:C);
set role service_role;
select pg_temp.expect_count('select 1 from public.cities', 81);
insert into public.players (id, nick, city) values (:A, 'ayse', 'Ankara'), (:B, 'mehmet', 'Ankara'), (:C, 'zeynep', 'İzmir');
insert into public.daily_puzzles (date, round, kind, payload) values
  (:'bugun', 1, 'kelime', '{"letters":["a","b"]}'),
  (:'bugun'::date + 1, 1, 'kelime', '{"letters":["c","d"]}'),
  (:'bugun'::date - 1, 1, 'kelime', '{"letters":["e","f"]}');
insert into public.daily_solutions values (:'bugun', 1, 9, 'gizli');
-- A ve C 4 tur bitirdi; B yalnızca 3
insert into public.daily_scores (date, player_id, round, score, answer)
  select current_date, p, r, 10, 'cevapA' from (values (:A::uuid), (:C::uuid)) a(p), generate_series(1, 4) r;
insert into public.daily_scores (date, player_id, round, score) select current_date, :B, r, 5 from generate_series(1, 3) r;
select pg_temp.expect_error('insert into public.daily_scores (date, player_id, round, score) values (current_date, ' || quote_literal(:A) || ', 1, 3)');  -- günde bir kez
select pg_temp.expect_error('insert into public.players (id, nick, city) values (gen_random_uuid(), ''x'', ''Ankara'')');   -- auth.users yok / nick kısa
select pg_temp.expect_error('insert into public.players (id, nick, city) values (' || quote_literal(:A) || ', ''abc'', ''Atlantis'')');
insert into public.matches (a, b, seed) values (:A, :B, 's1'), (:B, :C, 's2');
insert into public.match_moves (match_id, round, player_id, payload) select id, 1, a, '{}' from public.matches where seed = 's1';

-- ---- A olarak ----
reset role; set role authenticated; set request.jwt.claim.sub = :A;
select pg_temp.expect_count('select 1 from public.players', 3);                                  -- oyuncular herkese açık
select pg_temp.expect_count('select 1 from public.daily_puzzles', 1);                             -- bugün ve yarın görünmez, yalnızca dün (arşiv)
select pg_temp.expect_error('select * from public.daily_solutions');                              -- cevaplar kapalı
select pg_temp.expect_error('select * from public.daily_round_starts');
select pg_temp.expect_error('insert into public.daily_scores (date, player_id, round, score) values (current_date, ' || quote_literal(:A) || ', 1, 99)');
select pg_temp.expect_error('update public.daily_scores set score = 99');
select pg_temp.expect_count('select 1 from public.daily_scores', 4);                              -- yalnızca kendi satırları
select pg_temp.expect_error('select * from public.matches');                                      -- düello yalnızca fonksiyondan: seed ve rakip cevabı sızmaz
select pg_temp.expect_error('select * from public.match_moves');
select pg_temp.expect_error('select * from public.match_rounds');
select pg_temp.expect_error('insert into public.matches (a, seed) values (' || quote_literal(:A) || ', ''hile'')');
select pg_temp.expect_error('select * from public.daily_totals');
select pg_temp.expect_error('insert into public.players (id, nick) values (' || quote_literal(:B) || ', ''baska'')');
update public.players set nick = 'ayse2' where id = :A;
select pg_temp.expect_count('select 1 from public.players where nick = ''ayse2''', 1);
update public.players set nick = 'ele geçirdim' where id = :B;                                    -- RLS: 0 satır etkilenir
select pg_temp.expect_count('select 1 from public.players where nick = ''ele geçirdim''', 0);
select pg_temp.expect_error('update public.players set city = ''Atlantis'' where id = ' || quote_literal(:A));
-- sıralama: yalnızca 4 turu bitirenler (A, C); B yok; cevap sütunu yok
select pg_temp.expect_count('select 1 from public.daily_leaderboard', 2);
select pg_temp.expect_error('select answer from public.daily_leaderboard');
select pg_temp.expect_count('select 1 from public.city_league where city = ''Ankara'' and players = 1 and total = 40', 1);
select pg_temp.expect_count('select 1 from public.city_league where city = ''İzmir'' and players = 1 and total = 40', 1);

-- ---- B olarak: yalnızca kendi maçları ----
reset role; set role authenticated; set request.jwt.claim.sub = :B;
select pg_temp.expect_error('select * from public.matches');
select pg_temp.expect_count('select 1 from public.daily_scores', 3);
delete from public.players where id = :B;                                                         -- hesap silme
reset role; set role service_role;
select pg_temp.expect_count('select 1 from public.daily_scores where player_id = ' || quote_literal(:B), 0);   -- cascade
select pg_temp.expect_count('select 1 from public.matches where b is null and seed = ''s1''', 1);                 -- rakip hesabı silinince b null kalır, maç durur
select pg_temp.expect_count('select 1 from public.matches where seed = ''s2''', 0);                               -- a silinirse maç da gider

-- ---- anon ----
reset role; set role anon;
select pg_temp.expect_count('select 1 from public.cities', 81);
select pg_temp.expect_error('select * from public.players');
select pg_temp.expect_error('select * from public.daily_leaderboard');
select pg_temp.expect_error('select * from public.daily_puzzles');

\echo SEMA TESTLERİ GEÇTİ

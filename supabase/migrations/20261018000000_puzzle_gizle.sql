-- Bugünün bulmacası yalnızca daily-round "start" ile (sunucu süre damgasıyla birlikte) verilir.
-- Önceki politika (date <= bugün) bugünün harflerini tur başlamadan REST ile okunabilir bırakıyordu:
-- oyuncu süre işlemeden istediği kadar düşünebilirdi. Artık yalnızca geçmiş günler okunur (arşiv, 1.1).
drop policy puzzles_read on public.daily_puzzles;
create policy puzzles_past_read on public.daily_puzzles for select to authenticated
  using (date < (now() at time zone 'Europe/Istanbul')::date);

-- Günlük bulmaca tuzu: tarihten türetilen bulmacanın önceden hesaplanamaması için gizli bir değer.
-- Değer BU DOSYADA YOK: migration uygulanırken veritabanında rastgele üretilir ve yalnızca service_role okuyabilir
-- (istemciye tamamen kapalı; politika yok). generate-daily-puzzle önce PUZZLE_SALT ortam sırrına, yoksa bu tabloya bakar.
-- Tuzu değiştirmek yalnızca bundan sonra üretilecek bulmacaları etkiler.
create table public.puzzle_tuzu (
  id  boolean primary key default true check (id),   -- tek satır
  tuz text    not null check (char_length(tuz) >= 32)
);
insert into public.puzzle_tuzu (tuz)
  values (replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''))
  on conflict (id) do nothing;
alter table public.puzzle_tuzu enable row level security;
revoke all on public.puzzle_tuzu from anon, authenticated;

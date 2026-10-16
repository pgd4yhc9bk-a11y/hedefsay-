-- Kayıtlı rakip ("başka bir oyuncunun daha önce oynadığı maç") + oyuncu fotoğrafı.
--  * players.kayit_izni: oyuncunun oyunlarının, adı ve fotoğrafıyla başkalarına KAYITLI rakip olarak gösterilmesine izni (KVKK: açık seçenek).
--  * players.avatar_url: yalnızca kendi klasöründeki avatarlar deposu adresi olabilir (harici adres / izleme pikseli olamaz).
--  * matches.ghost_player / ghost_of: kayıtlı rakip maçı (rakip hamleleri o eski maçtan okunur; arayüz "kayıtlı oyun" der).
--  * Depo: `avatarlar` (herkese açık okuma; yazma yalnızca kendi klasörüne, en çok 1 MB, jpeg/png/webp).

alter table public.players
  add column avatar_url text,
  add column kayit_izni boolean not null default false;   -- KVKK: varsayılan KAPALI, oyuncu açıkça açar
alter table public.players add constraint players_avatar_kendi_klasoru
  check (avatar_url is null or avatar_url like '%/storage/v1/object/public/avatarlar/' || id::text || '/%');

alter table public.matches
  add column ghost_player uuid references public.players (id) on delete set null,
  add column ghost_of uuid references public.matches (id) on delete set null;

-- Sıralama görünümü fotoğrafı da gösterir (sütun sonda: create or replace uyumlu)
create or replace view public.daily_leaderboard as
  select t.date, p.nick, p.city, t.total,
         rank() over (partition by t.date order by t.total desc, t.finished_at) as rank,
         p.avatar_url
  from public.daily_totals t
  join public.players p on p.id = t.player_id;

-- ---- depo ----
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatarlar', 'avatarlar', true, 1048576, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy avatar_oku on storage.objects for select to anon, authenticated using (bucket_id = 'avatarlar');
create policy avatar_yaz on storage.objects for insert to authenticated
  with check (bucket_id = 'avatarlar' and (storage.foldername(name))[1] = auth.uid()::text);
create policy avatar_guncelle on storage.objects for update to authenticated
  using (bucket_id = 'avatarlar' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatarlar' and (storage.foldername(name))[1] = auth.uid()::text);
create policy avatar_sil on storage.objects for delete to authenticated
  using (bucket_id = 'avatarlar' and (storage.foldername(name))[1] = auth.uid()::text);

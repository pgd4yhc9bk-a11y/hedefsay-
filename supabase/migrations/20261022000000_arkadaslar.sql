-- Arkadaşlar: arkadaş koduyla istek gönder / kabul et / sil.
--  * players.arkadas_kodu: 6 karakterli kısa kod (karışan harfler yok). İstemci SADECE kendi kodunu `arkadas_listesi()` ile görür;
--    sütun okuma yetkisi kapatıldığı için başkalarının kodu listelenemez (kod kimseyle paylaşılmadıkça bulunamaz).
--  * arkadaslik: istemciye KAPALI (RLS açık, politika yok); tüm işlemler aşağıdaki SECURITY DEFINER işlevlerle yapılır.
--  * Hesap silinince arkadaşlık satırları da silinir (cascade).

create function public.yeni_arkadas_kodu() returns text language plpgsql volatile security definer set search_path = '' as $$
declare
  harf constant text := 'ABCDEFGHJKLMNPRSTUVYZ23456789';   -- 0/O, 1/I/L karışmasın
  kod text;
begin
  loop
    kod := '';
    for i in 1..6 loop
      kod := kod || substr(harf, 1 + floor(random() * length(harf))::int, 1);
    end loop;
    exit when not exists (select 1 from public.players where arkadas_kodu = kod);
  end loop;
  return kod;
end $$;

alter table public.players add column arkadas_kodu text unique;
update public.players set arkadas_kodu = public.yeni_arkadas_kodu() where arkadas_kodu is null;
alter table public.players alter column arkadas_kodu set default public.yeni_arkadas_kodu();
alter table public.players alter column arkadas_kodu set not null;

-- Kodlar başkalarına okunamasın: tablo düzeyindeki SELECT'i kaldırıp sütun sütun ver (arkadas_kodu hariç).
revoke select on public.players from anon, authenticated;
grant select (id, nick, city, created_at, avatar_url, kayit_izni) on public.players to authenticated;
-- Kod sistem tarafından atanır; istemci yazamaz (özel kod seçemez, başkasının kodunu deneyemez).
revoke insert, update on public.players from anon, authenticated;
grant insert (id, nick, city, avatar_url, kayit_izni), update (nick, city, avatar_url, kayit_izni) on public.players to authenticated;

create table public.arkadaslik (
  id         uuid primary key default gen_random_uuid(),
  gonderen   uuid not null references public.players (id) on delete cascade,
  alan       uuid not null references public.players (id) on delete cascade,
  durum      text not null default 'bekliyor' check (durum in ('bekliyor', 'kabul')),
  created_at timestamptz not null default now(),
  check (gonderen <> alan)
);
create unique index arkadaslik_cift on public.arkadaslik (least(gonderen, alan), greatest(gonderen, alan));
create index arkadaslik_alan on public.arkadaslik (alan);
alter table public.arkadaslik enable row level security;   -- politika yok: yalnızca işlevler

-- Kendi kodum + arkadaşlık listesi (arkadas | gelen | giden)
create function public.arkadas_listesi() returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'kod', (select arkadas_kodu from public.players where id = auth.uid()),
    'liste', coalesce((
      select jsonb_agg(jsonb_build_object(
          'id', a.id, 'kullanici', p.id, 'nick', p.nick, 'city', p.city, 'avatar_url', p.avatar_url,
          'durum', case when a.durum = 'kabul' then 'arkadas' when a.alan = auth.uid() then 'gelen' else 'giden' end)
        order by (a.durum = 'kabul') desc, p.nick)
      from public.arkadaslik a
      join public.players p on p.id = case when a.gonderen = auth.uid() then a.alan else a.gonderen end
      where auth.uid() in (a.gonderen, a.alan)), '[]'::jsonb));
$$;

-- Kodla istek gönder. Karşı taraf zaten bana istek göndermişse doğrudan arkadaş olunur.
create function public.arkadas_ekle(p_kod text) returns jsonb language plpgsql volatile security definer set search_path = '' as $$
declare
  ben uuid := auth.uid();
  hedef uuid;
  var public.arkadaslik;
begin
  if ben is null or not exists (select 1 from public.players where id = ben) then
    raise exception 'Önce oyuncu kartını oluştur';
  end if;
  select id into hedef from public.players where arkadas_kodu = upper(btrim(coalesce(p_kod, '')));
  if hedef is null then raise exception 'Bu kodla oyuncu bulunamadı'; end if;
  if hedef = ben then raise exception 'Bu senin kendi kodun'; end if;
  select * into var from public.arkadaslik where least(gonderen, alan) = least(ben, hedef) and greatest(gonderen, alan) = greatest(ben, hedef);
  if found then
    if var.durum = 'kabul' then raise exception 'Zaten arkadaşsınız'; end if;
    if var.alan = ben then
      update public.arkadaslik set durum = 'kabul' where id = var.id;
      return jsonb_build_object('durum', 'arkadas');
    end if;
    raise exception 'İstek zaten gönderildi';
  end if;
  if (select count(*) from public.arkadaslik where gonderen = ben and durum = 'bekliyor') >= 50 then
    raise exception 'Çok fazla bekleyen isteğin var';
  end if;
  insert into public.arkadaslik (gonderen, alan) values (ben, hedef);
  return jsonb_build_object('durum', 'giden');
end $$;

-- Gelen isteği kabul et / reddet
create function public.arkadas_yanit(p_id uuid, p_kabul boolean) returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  if p_kabul then
    update public.arkadaslik set durum = 'kabul' where id = p_id and alan = auth.uid() and durum = 'bekliyor';
  else
    delete from public.arkadaslik where id = p_id and alan = auth.uid() and durum = 'bekliyor';
  end if;
  if not found then raise exception 'İstek bulunamadı'; end if;
end $$;

-- Arkadaşı sil / gönderdiğin isteği geri çek
create function public.arkadas_sil(p_id uuid) returns void language plpgsql volatile security definer set search_path = '' as $$
begin
  delete from public.arkadaslik where id = p_id and auth.uid() in (gonderen, alan);
  if not found then raise exception 'Kayıt bulunamadı'; end if;
end $$;

revoke all on function public.yeni_arkadas_kodu(), public.arkadas_listesi(), public.arkadas_ekle(text), public.arkadas_yanit(uuid, boolean), public.arkadas_sil(uuid) from public, anon, authenticated;
grant execute on function public.arkadas_listesi(), public.arkadas_ekle(text), public.arkadas_yanit(uuid, boolean), public.arkadas_sil(uuid) to authenticated;
-- Sütun varsayılanı olarak çağrılabilmesi için EXECUTE gerekir; işlev yalnızca kullanılmamış rastgele bir kod döner (SECURITY DEFINER: kod sütununu okuyabilir).
grant execute on function public.yeni_arkadas_kodu() to authenticated, service_role;

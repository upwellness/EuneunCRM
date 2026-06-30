-- EuneunCRM — Supabase backend (passcode-gated, RPC-only)
-- anon อ่าน table ตรงไม่ได้ · เข้าถึงข้อมูลผ่าน RPC ที่เช็ค PIN เท่านั้น
-- ⚠ แก้ 'CHANGE_ME' เป็น PIN ของคุณก่อนรัน (อย่า commit PIN จริงลง repo)

create table if not exists public.crm_customers (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);
create table if not exists public.crm_app (
  k text primary key,
  v jsonb not null,
  updated_at timestamptz not null default now()
);
create table if not exists public.crm_secret (
  id int primary key default 1,
  pin text not null
);
insert into public.crm_secret(id, pin) values (1, 'CHANGE_ME')
  on conflict (id) do nothing;

alter table public.crm_customers enable row level security;
alter table public.crm_app enable row level security;
alter table public.crm_secret enable row level security;
revoke all on public.crm_customers from anon, authenticated;
revoke all on public.crm_app from anon, authenticated;
revoke all on public.crm_secret from anon, authenticated;

-- pin check ภายใน (ไม่ grant ให้ anon · เรียกโดย definer functions)
create or replace function public.crm_ok(p text) returns boolean
  language sql security definer set search_path = public stable as $$
  select exists (select 1 from public.crm_secret where pin = p);
$$;

create or replace function public.crm_list(p text)
  returns setof public.crm_customers
  language plpgsql security definer set search_path = public stable as $$
begin
  if not public.crm_ok(p) then raise exception 'unauthorized'; end if;
  return query select * from public.crm_customers order by updated_at desc;
end; $$;

create or replace function public.crm_upsert(p text, cid text, d jsonb)
  returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.crm_ok(p) then raise exception 'unauthorized'; end if;
  insert into public.crm_customers(id, data, updated_at) values (cid, d, now())
  on conflict (id) do update set data = excluded.data, updated_at = now();
end; $$;

create or replace function public.crm_delete(p text, cid text)
  returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.crm_ok(p) then raise exception 'unauthorized'; end if;
  delete from public.crm_customers where id = cid;
end; $$;

create or replace function public.crm_replace_all(p text, rows jsonb)
  returns int language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not public.crm_ok(p) then raise exception 'unauthorized'; end if;
  delete from public.crm_customers;
  insert into public.crm_customers(id, data)
    select x->>'id', x from jsonb_array_elements(rows) as x;
  get diagnostics n = row_count;
  return n;
end; $$;

create or replace function public.crm_seed_if_empty(p text, rows jsonb)
  returns int language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not public.crm_ok(p) then raise exception 'unauthorized'; end if;
  if (select count(*) from public.crm_customers) = 0 then
    insert into public.crm_customers(id, data)
      select x->>'id', x from jsonb_array_elements(rows) as x;
  end if;
  select count(*) into n from public.crm_customers;
  return n;
end; $$;

create or replace function public.crm_get_app(p text, key text)
  returns jsonb language plpgsql security definer set search_path = public stable as $$
begin
  if not public.crm_ok(p) then raise exception 'unauthorized'; end if;
  return (select v from public.crm_app where k = key);
end; $$;

create or replace function public.crm_set_app(p text, key text, val jsonb)
  returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.crm_ok(p) then raise exception 'unauthorized'; end if;
  insert into public.crm_app(k, v, updated_at) values (key, val, now())
  on conflict (k) do update set v = excluded.v, updated_at = now();
end; $$;

grant execute on function
  public.crm_list(text),
  public.crm_upsert(text, text, jsonb),
  public.crm_delete(text, text),
  public.crm_replace_all(text, jsonb),
  public.crm_seed_if_empty(text, jsonb),
  public.crm_get_app(text, text),
  public.crm_set_app(text, text, jsonb)
to anon, authenticated;

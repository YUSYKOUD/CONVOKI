-- CONVOKI · Backend mínimo para invitaciones y RSVP
-- Ejecuta este archivo en Supabase > SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.convoki_invites (
  token uuid primary key,
  owner_key uuid not null,
  guest_name text not null,
  phone text,
  status text not null default 'Pendiente'
    check (status in ('Pendiente','Acepta','Rechaza')),
  event_title text not null default '',
  event_date date,
  event_time time,
  event_address text not null default '',
  event_note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.convoki_invites enable row level security;
revoke all on public.convoki_invites from anon, authenticated;

create or replace function public.convoki_create_invite(
  p_token uuid,
  p_owner_key uuid,
  p_guest_name text,
  p_phone text,
  p_event_title text,
  p_event_date date,
  p_event_time time,
  p_event_address text,
  p_event_note text
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.convoki_invites(
    token, owner_key, guest_name, phone, event_title, event_date,
    event_time, event_address, event_note, updated_at
  )
  values(
    p_token, p_owner_key, p_guest_name, p_phone, coalesce(p_event_title,''),
    p_event_date, p_event_time, coalesce(p_event_address,''),
    coalesce(p_event_note,''), now()
  )
  on conflict (token) do update
  set guest_name=excluded.guest_name,
      phone=excluded.phone,
      event_title=excluded.event_title,
      event_date=excluded.event_date,
      event_time=excluded.event_time,
      event_address=excluded.event_address,
      event_note=excluded.event_note,
      updated_at=now()
  where public.convoki_invites.owner_key = p_owner_key;
end;
$$;

create or replace function public.convoki_get_invite(p_token uuid)
returns table(
  token uuid,
  guest_name text,
  status text,
  event_title text,
  event_date date,
  event_time time,
  event_address text,
  event_note text
)
language sql
security definer
set search_path = public
as $$
  select i.token, i.guest_name, i.status, i.event_title, i.event_date,
         i.event_time, i.event_address, i.event_note
  from public.convoki_invites i
  where i.token = p_token
  limit 1;
$$;

create or replace function public.convoki_respond(
  p_token uuid,
  p_status text
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_status not in ('Acepta','Rechaza') then
    return false;
  end if;

  update public.convoki_invites
  set status=p_status, updated_at=now()
  where token=p_token;

  return found;
end;
$$;

create or replace function public.convoki_owner_statuses(p_owner_key uuid)
returns table(token uuid, status text)
language sql
security definer
set search_path = public
as $$
  select i.token, i.status
  from public.convoki_invites i
  where i.owner_key=p_owner_key;
$$;

create or replace function public.convoki_owner_update_status(
  p_owner_key uuid,
  p_token uuid,
  p_status text
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_status not in ('Pendiente','Acepta','Rechaza') then
    return false;
  end if;

  update public.convoki_invites
  set status=p_status, updated_at=now()
  where owner_key=p_owner_key and token=p_token;

  return found;
end;
$$;

create or replace function public.convoki_delete_invite(
  p_owner_key uuid,
  p_token uuid
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.convoki_invites
  where owner_key=p_owner_key and token=p_token;
  return found;
end;
$$;

revoke all on function public.convoki_create_invite(uuid,uuid,text,text,text,date,time,text,text) from public;
revoke all on function public.convoki_get_invite(uuid) from public;
revoke all on function public.convoki_respond(uuid,text) from public;
revoke all on function public.convoki_owner_statuses(uuid) from public;
revoke all on function public.convoki_owner_update_status(uuid,uuid,text) from public;
revoke all on function public.convoki_delete_invite(uuid,uuid) from public;

grant execute on function public.convoki_create_invite(uuid,uuid,text,text,text,date,time,text,text) to anon, authenticated;
grant execute on function public.convoki_get_invite(uuid) to anon, authenticated;
grant execute on function public.convoki_respond(uuid,text) to anon, authenticated;
grant execute on function public.convoki_owner_statuses(uuid) to anon, authenticated;
grant execute on function public.convoki_owner_update_status(uuid,uuid,text) to anon, authenticated;
grant execute on function public.convoki_delete_invite(uuid,uuid) to anon, authenticated;

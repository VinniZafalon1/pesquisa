create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  birth_date date,
  nickname text,
  avatar_url text
);

alter table public.profiles enable row level security;

drop policy if exists "Perfil proprio" on public.profiles;
create policy "Perfil proprio" on public.profiles
  for all to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', false)
on conflict (id) do nothing;

drop policy if exists "Fotos proprias" on storage.objects;
create policy "Fotos proprias" on storage.objects
  for all to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

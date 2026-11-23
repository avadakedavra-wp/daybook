create table public.custom_activities (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null check (id ~ '^custom-[0-9a-f]{32}$'),
  title text not null check (char_length(btrim(title)) between 1 and 80),
  category text not null check (char_length(category) <= 40),
  minutes integer not null check (minutes between 1 and 1440),
  description text not null check (char_length(description) <= 500),
  primary key (user_id, id)
);

alter table public.custom_activities enable row level security;
revoke all on public.custom_activities from anon, authenticated;
grant select, insert, update, delete on public.custom_activities to authenticated;

create policy "Manage own custom activities"
  on public.custom_activities for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

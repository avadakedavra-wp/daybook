create table public.activity_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  activity_date date not null,
  activity_id text not null check (char_length(activity_id) between 1 and 64),
  completed boolean not null,
  primary key (user_id, activity_date, activity_id)
);

alter table public.activity_progress enable row level security;

revoke all on public.activity_progress from anon, authenticated;
grant select, insert, update on public.activity_progress to authenticated;

create policy "Read own progress"
  on public.activity_progress for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Insert own progress"
  on public.activity_progress for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Update own progress"
  on public.activity_progress for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

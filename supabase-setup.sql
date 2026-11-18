-- Σημειώσεις: πίνακες για συγχρονισμό μεταξύ συσκευών.
-- Τρέξε το ολόκληρο μία φορά στο Supabase → SQL Editor → New query → Run.

create table if not exists public.notes (
  user_id    uuid    not null default auth.uid() references auth.users (id) on delete cascade,
  id         text    not null,
  data       jsonb   not null default '{}'::jsonb,
  updated_at bigint  not null,
  deleted    boolean not null default false,
  primary key (user_id, id)
);

create table if not exists public.boards (
  user_id    uuid    not null default auth.uid() references auth.users (id) on delete cascade,
  id         text    not null,
  data       jsonb   not null default '{}'::jsonb,
  updated_at bigint  not null,
  deleted    boolean not null default false,
  primary key (user_id, id)
);

-- Κάθε χρήστης βλέπει και αλλάζει ΜΟΝΟ τις δικές του γραμμές.
alter table public.notes  enable row level security;
alter table public.boards enable row level security;

drop policy if exists "own notes"  on public.notes;
drop policy if exists "own boards" on public.boards;

create policy "own notes" on public.notes
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "own boards" on public.boards
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Ζωντανές ενημερώσεις: όταν αλλάζεις κάτι σε μία συσκευή, οι άλλες το βλέπουν αμέσως.
do $$ begin
  alter publication supabase_realtime add table public.notes;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.boards;
exception when duplicate_object then null; end $$;

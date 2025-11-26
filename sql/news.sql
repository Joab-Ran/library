create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(title) between 3 and 160),
  content text not null,
  author_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end; $$;

drop trigger if exists trg_touch_updated_at on public.books;
create trigger trg_touch_updated_at
before update on public.books
for each row execute procedure public.touch_updated_at();

alter table public.books enable row level security;

create policy "read all books (auth users)" on public.books
for select using (auth.role() = 'authenticated');

create policy "insert own books" on public.books
for insert with check (auth.uid() = author_id);

create policy "update own books" on public.books
for update using (auth.uid() = author_id);

create policy "delete own books" on public.books
for delete using (auth.uid() = author_id);

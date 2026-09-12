# Supabase Setup — Salesman Dashboard

Do these three things in your Supabase project, then send me back your **Project URL** and **anon (public) API key** (Project Settings → API) so I can wire them into `salesman_dashboard.html`. Never share the `service_role` key — only the `anon`/`public` one is meant to be embedded in a browser app.

## 1. Create the table + unique key (for upsert/dedupe)

Run this in Supabase → SQL Editor:

```sql
create table if not exists public.sales_transactions (
  id bigint generated always as identity primary key,
  date date not null,
  week text,
  month text,
  year int,
  salesman text not null,
  distributor text not null,
  sub_area text,
  sub_brand text not null,
  abs text,
  customer_no text not null default '',
  quantity numeric not null default 0,
  sales_amount numeric not null default 0,
  uploaded_at timestamptz not null default now(),
  constraint sales_transactions_natural_key
    unique (date, salesman, distributor, sub_brand, customer_no)
);
```

The `unique (...)` constraint is what makes re-uploads update existing rows instead of duplicating them — matches the columns the dashboard upserts on.

## 2. Lock the table down with Row Level Security

Still in the SQL Editor:

```sql
alter table public.sales_transactions enable row level security;

create policy "authenticated can read"
  on public.sales_transactions for select
  to authenticated using (true);

create policy "authenticated can insert"
  on public.sales_transactions for insert
  to authenticated with check (true);

create policy "authenticated can update"
  on public.sales_transactions for update
  to authenticated using (true) with check (true);
```

With RLS on and no policy for the `anon` role, nobody can read or write this table without being logged in — even though the anon key is public in the page.

## 3. Create the one shared login

Supabase → Authentication → Users → **Add user** → enter an email (e.g. `sales-team@yourcompany.com`) and a password. This is the single shared login everyone on the team will use to open the dashboard.

Then go to Authentication → Settings and turn **off** "Allow new users to sign up" — so this is the only account that can ever exist.

## 4. Send me

- Project URL (Settings → API → Project URL, looks like `https://xxxxx.supabase.co`)
- anon/public API key (Settings → API → Project API keys → `anon` `public`)

I'll drop those into the `SUPABASE_URL` / `SUPABASE_ANON_KEY` constants near the top of the `<script>` in `salesman_dashboard.html` and the dashboard will start requiring sign-in, storing every upload, and offering a "Refresh" button to pull in data uploaded from other laptops.

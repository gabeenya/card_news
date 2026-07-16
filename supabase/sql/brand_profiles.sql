-- ════════════════════════════════════════════════════════════════
-- 브랜드 프로필 (캐릭터 고정 + 금칙어) — 팀 전체가 공유하는 리소스
-- Supabase 대시보드 → SQL Editor 에 통째로 붙여넣고 Run
-- ════════════════════════════════════════════════════════════════

create table if not exists public.brand_profiles (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  brand            text,
  character_design text,
  banned_words     text,
  created_by       uuid references auth.users(id),
  created_at       timestamptz default now(),
  updated_at       timestamptz default now()
);

alter table public.brand_profiles enable row level security;

-- 승인된 사용자는 모두 조회 가능
drop policy if exists "approved read" on public.brand_profiles;
create policy "approved read" on public.brand_profiles
  for select using (
    exists(select 1 from public.profiles where id = auth.uid() and approved = true)
  );

-- 승인된 사용자는 모두 생성/수정/삭제 가능 (팀 공용 리소스)
drop policy if exists "approved insert" on public.brand_profiles;
create policy "approved insert" on public.brand_profiles
  for insert with check (
    exists(select 1 from public.profiles where id = auth.uid() and approved = true)
  );

drop policy if exists "approved update" on public.brand_profiles;
create policy "approved update" on public.brand_profiles
  for update using (
    exists(select 1 from public.profiles where id = auth.uid() and approved = true)
  );

drop policy if exists "approved delete" on public.brand_profiles;
create policy "approved delete" on public.brand_profiles
  for delete using (
    exists(select 1 from public.profiles where id = auth.uid() and approved = true)
  );

-- ════════════════════════════════════════════════════════════════
-- 관리자가 앱 안에서 사용자 목록 조회 + 승인/취소 할 수 있게 하는 권한
-- Supabase 대시보드 → SQL Editor 에 통째로 붙여넣고 Run
-- ════════════════════════════════════════════════════════════════

-- 요청자가 관리자인지 확인 (SECURITY DEFINER → RLS 무한재귀 방지)
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- 관리자는 모든 프로필 조회 가능
drop policy if exists "admin read all" on public.profiles;
create policy "admin read all" on public.profiles
  for select using (public.is_admin());

-- 관리자는 승인 여부/역할 수정 가능
drop policy if exists "admin update" on public.profiles;
create policy "admin update" on public.profiles
  for update using (public.is_admin()) with check (public.is_admin());

-- ════════════════════════════════════════════════════════════════
-- 승인제 가입 + 관리자 설정
-- Supabase 대시보드 → SQL Editor 에 통째로 붙여넣고 Run
-- ↓ 관리자 이메일: gabeenya@gmail.com (바꾸려면 아래 세 군데 함께 수정)
-- ════════════════════════════════════════════════════════════════

-- 1) 사용자 프로필 테이블 (역할 + 승인 여부)
create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  email      text,
  role       text    not null default 'member',   -- 'admin' | 'member'
  approved   boolean not null default false,        -- 관리자가 승인하면 true
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

-- 본인 프로필은 본인이 읽을 수 있음 (앱에서 승인 여부 확인용)
drop policy if exists "read own profile" on public.profiles;
create policy "read own profile" on public.profiles
  for select using (auth.uid() = id);

-- 2) 회원가입 시 프로필 자동 생성 (관리자는 자동 승인)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, role, approved)
  values (
    new.id,
    new.email,
    case when lower(new.email) = 'gabeenya@gmail.com' then 'admin'  else 'member' end,
    case when lower(new.email) = 'gabeenya@gmail.com' then true     else false    end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3) 가입 도메인 제한 (회사 이메일 + 관리자 gmail 예외)
create or replace function public.enforce_email_domain()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if lower(new.email) <> 'gabeenya@gmail.com'
     and new.email !~* '@(eland\.co\.kr)$' then
    raise exception 'allowed_domain_only';
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_email_domain_trigger on auth.users;
create trigger enforce_email_domain_trigger
  before insert on auth.users
  for each row execute function public.enforce_email_domain();

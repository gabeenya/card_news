-- 회사 이메일 도메인만 회원가입 허용
-- Supabase 대시보드 → SQL Editor 에 붙여넣고 실행하세요.
-- ↓↓↓ 'yourcompany.com' 을 실제 회사 도메인으로 바꾸세요 (예: 'elandeats.com') ↓↓↓
-- 여러 도메인을 허용하려면: @(elandeats\.com|eland\.co\.kr)$

create or replace function public.enforce_email_domain()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.email !~* '@(eland\.co\.kr)$' then
    raise exception 'allowed_domain_only';
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_email_domain_trigger on auth.users;

create trigger enforce_email_domain_trigger
  before insert on auth.users
  for each row execute function public.enforce_email_domain();

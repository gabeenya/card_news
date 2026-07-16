# 배포 가이드 — AI 카드뉴스 생성기

구조: **GitHub Pages(프론트)** + **Supabase(인증 + Edge Function + 시크릿 키)**

```
[GitHub Pages: index.html]
   │  로그인/회원가입 (supabase-js)
   ▼
[Supabase Auth]  ←─ 회사 이메일 도메인만 가입 허용 (DB 트리거)
   │  로그인 토큰을 실어서 호출
   ▼
[Edge Function: claude / image]  ←─ 여기에만 API 키 존재 (시크릿)
   ▼
Anthropic / OpenAI
```

---

## 1. Supabase 프로젝트 만들기
1. https://supabase.com 가입 → **New project** 생성 (region: Northeast Asia(Seoul) 권장)
2. 프로젝트 생성되면 **Settings → API** 에서 두 값 복사:
   - `Project URL`  → index.html CONFIG의 `supabaseUrl`
   - `anon public` 키 → index.html CONFIG의 `supabaseAnonKey`
   - (이 두 값은 공개돼도 안전한 값입니다)

## 2. 회사 이메일 도메인 제한
1. 대시보드 **SQL Editor** → `supabase/sql/restrict_domain.sql` 내용 붙여넣기
2. `yourcompany.com` 을 **실제 회사 도메인**으로 바꾼 뒤 **Run**

## 3. API 키를 서버 시크릿으로 등록 (브라우저엔 절대 안 들어감)
CLI 설치: `npm i -g supabase`  → `supabase login`  → `supabase link --project-ref <프로젝트ref>`

```bash
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
supabase secrets set OPENAI_API_KEY=sk-proj-...
```
(SUPABASE_URL / SUPABASE_ANON_KEY 는 Supabase가 자동 주입하므로 등록 불필요)

## 4. Edge Function 배포
```bash
supabase functions deploy claude
supabase functions deploy image
```

## 5. Auth 설정 (이메일 확인 링크가 제대로 작동하게)
대시보드 **Authentication → URL Configuration**
- **Site URL**: `https://<깃허브아이디>.github.io/<레포명>/`  (GitHub Pages 주소)
- **Redirect URLs**: 위와 동일 주소 추가
- (Authentication → Providers → Email 이 켜져 있는지 확인)

## 6. 프론트엔드 — CONFIG 채우기
`index.html` 상단 CONFIG:
```js
supabaseUrl:     'https://xxxx.supabase.co',
supabaseAnonKey: 'eyJhbGciOi...',
```

## 7. GitHub Pages 배포
1. GitHub에서 새 레포 생성 → `index.html` 을 레포 루트에 올림
   (supabase/ 폴더도 함께 올려도 됨 — 정적 호스팅엔 영향 없음)
2. 레포 **Settings → Pages** → Source: `Deploy from a branch` → Branch: `main` / `/(root)` → Save
3. 1~2분 뒤 `https://<아이디>.github.io/<레포명>/` 에서 접속
4. 5번의 Site URL 을 이 주소로 맞췄는지 다시 확인

## 8. 동작 확인
- 사이트 접속 → 회원가입(회사 이메일) → 확인 메일 링크 클릭 → 로그인 → 카드뉴스 생성

## 9. 브랜드 프로필 (캐릭터 고정 + 금칙어) 테이블 생성
1. 대시보드 **SQL Editor** → `supabase/sql/brand_profiles.sql` 내용 붙여넣고 **Run**
2. 승인된 사용자는 누구나 프로필을 만들고 공유해서 쓸 수 있어요 (팀 공용 리소스)

---

### 보안 메모
- API 키는 **Edge Function 시크릿**에만 있고 브라우저로 내려가지 않음.
- Edge Function은 내부에서 `getUser()` 로 **로그인 여부를 검증**하므로, anon key만 가진 외부 요청은 거부됨.
- 도메인 제한 트리거로 외부인 가입 차단.

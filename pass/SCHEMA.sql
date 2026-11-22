-- LEANON 정액권(선불 충전권) 스키마
-- Supabase SQL Editor 에서 1회 실행

create table if not exists pass_members (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  phone      text,
  memo       text,
  balance    integer not null default 0,   -- 캐시된 현재 잔액(원장 합계로 재검증)
  created_at timestamptz not null default now()
);

create table if not exists pass_transactions (
  id            uuid primary key default gen_random_uuid(),
  member_id     uuid not null references pass_members(id) on delete cascade,
  type          text not null check (type in ('charge','use')),
  amount        integer not null default 0,  -- charge: 결제금액 / use: 차감금액
  bonus         integer not null default 0,  -- charge: 적립 보너스
  delta         integer not null,            -- 잔액 변동 (charge:+(amount+bonus) / use:-amount)
  balance_after integer not null,            -- 거래 직후 잔액 스냅샷
  memo          text,
  designer      text,
  signature     text,                        -- 전자서명 PNG (data URL)
  created_by    text,
  created_at    timestamptz not null default now()
);
create index if not exists idx_pass_tx_member on pass_transactions(member_id, created_at desc);
create index if not exists idx_pass_tx_created on pass_transactions(created_at desc);

alter table pass_members      enable row level security;
alter table pass_transactions enable row level security;

-- 직원(로그인) 전용: 익명 접근 불가
create policy "auth all pass_members"      on pass_members      for all to authenticated using (true) with check (true);
create policy "auth all pass_transactions" on pass_transactions for all to authenticated using (true) with check (true);

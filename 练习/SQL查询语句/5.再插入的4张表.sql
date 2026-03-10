-- ============================================================
-- 新增4张表（建议在已有7张表基础上执行）
-- 1) transfer_order            转账业务主单
-- 2) account_balance_snapshot  账户余额快照
-- 3) account_freeze_hold       当前冻结明细（生效态）
-- 4) ledger_entry              账务分录表
-- ============================================================

-- 1) 转账业务主单（业务请求层）
create table if not exists yewu.transfer_order (
  transfer_order_id   bigint generated always as identity primary key,
  order_no            varchar(40) not null unique,              -- 业务单号（对外/内部单号）
  request_id          varchar(64) not null unique,              -- 幂等键（业务层）
  from_account_id     bigint not null references yewu.account(account_id),
  to_account_id       bigint not null references yewu.account(account_id),
  amount              numeric(18,2) not null,
  currency            char(3) not null,
  status              smallint not null default 1,              -- 1=init,2=processing,3=success,9=failed
  channel_code        varchar(20),                              -- APP/柜面/API/ATM...
  biz_ref             varchar(64),                              -- 外部参考号（可选）
  memo                varchar(300),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  constraint ck_transfer_order_amount check (amount > 0),
  constraint ck_transfer_order_currency check (currency ~ '^[A-Z]{3}$'),
  constraint ck_transfer_order_status check (status in (1,2,3,9)),
  constraint ck_transfer_order_accounts check (from_account_id <> to_account_id)
);

create index if not exists ix_transfer_order_from_account_time
  on yewu.transfer_order(from_account_id, created_at desc);

create index if not exists ix_transfer_order_to_account_time
  on yewu.transfer_order(to_account_id, created_at desc);

create index if not exists ix_transfer_order_status
  on yewu.transfer_order(status);

create index if not exists ix_transfer_order_biz_ref
  on yewu.transfer_order(biz_ref);


-- 2) 账户余额快照表（当前状态层）
-- 说明：把 account.balance（演示字段）与更真实的余额状态拆开；学习时可并存
create table if not exists yewu.account_balance_snapshot (
  account_id          bigint primary key references yewu.account(account_id),
  ledger_balance      numeric(18,2) not null default 0,         -- 账面余额
  available_balance   numeric(18,2) not null default 0,         -- 可用余额（扣除冻结等）
  frozen_amount       numeric(18,2) not null default 0,         -- 冻结金额汇总
  last_txn_id         bigint references yewu.txn(txn_id),       -- 最近关联流水（可空）
  last_posted_at      timestamptz,                               -- 最近成功入账时间（可空）
  updated_at          timestamptz not null default now(),
  constraint ck_abs_ledger_balance check (ledger_balance >= 0),
  constraint ck_abs_available_balance check (available_balance >= 0),
  constraint ck_abs_frozen_amount check (frozen_amount >= 0),
  constraint ck_abs_available_le_ledger check (available_balance <= ledger_balance)
);

create index if not exists ix_abs_last_posted_at
  on yewu.account_balance_snapshot(last_posted_at desc);


-- 3) 当前冻结明细表（控制层，记录“现在仍有效”的冻结）
-- 与 account_freeze_log 的区别：
-- - hold 表：当前有效状态
-- - log 表：历史动作日志
create table if not exists yewu.account_freeze_hold (
  hold_id             bigint generated always as identity primary key,
  account_id          bigint not null references yewu.account(account_id),
  hold_type           varchar(20) not null,                     -- FULL / PARTIAL
  hold_amount         numeric(18,2),                            -- PARTIAL时必填；FULL时可空
  reason_code         varchar(30) not null,                     -- KYC_RISK / COURT_HOLD ...
  reason_text         varchar(200),
  source_system       varchar(30) not null default 'MANUAL',    -- MANUAL/RISK/AML/COURT...
  branch_id           bigint references yewu.branch(branch_id),
  operator_name       varchar(50) not null,
  start_at            timestamptz not null default now(),
  end_at              timestamptz,                              -- 解除时写入（也可通过状态表示）
  status              smallint not null default 1,              -- 1=active,2=released,3=expired
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  constraint ck_afh_hold_type check (hold_type in ('FULL','PARTIAL')),
  constraint ck_afh_status check (status in (1,2,3)),
  constraint ck_afh_hold_amount_nonneg check (hold_amount is null or hold_amount > 0),
  constraint ck_afh_partial_amount_required check (
    (hold_type = 'FULL' and hold_amount is null)
    or
    (hold_type = 'PARTIAL' and hold_amount is not null)
  ),
  constraint ck_afh_end_after_start check (end_at is null or end_at >= start_at)
);

create index if not exists ix_afh_account_status
  on yewu.account_freeze_hold(account_id, status);

create index if not exists ix_afh_branch_status
  on yewu.account_freeze_hold(branch_id, status);

create index if not exists ix_afh_reason_code
  on yewu.account_freeze_hold(reason_code);

create index if not exists ix_afh_start_at
  on yewu.account_freeze_hold(start_at desc);


-- 4) 账务分录表（账务事实层）
-- 一笔业务通常会生成多条分录（借/贷）
create table if not exists yewu.ledger_entry (
  entry_id            bigint generated always as identity primary key,
  entry_no            varchar(50) not null unique,              -- 分录号（便于审计/追踪）
  transfer_order_id   bigint references yewu.transfer_order(transfer_order_id), -- 可空：非转账类业务可不填
  txn_id              bigint references yewu.txn(txn_id),       -- 可空：与展示流水关联
  account_id          bigint not null references yewu.account(account_id),
  currency            char(3) not null,
  dr_cr               char(1) not null,                         -- D=借, C=贷（学习用）
  amount              numeric(18,2) not null,
  entry_type          varchar(30) not null,                     -- TRANSFER/FEE/DEPOSIT/WITHDRAW...
  status              smallint not null default 1,              -- 1=posted,2=pending,9=reversed
  posted_at           timestamptz not null default now(),
  memo                varchar(300),
  created_at          timestamptz not null default now(),
  constraint ck_ledger_dr_cr check (dr_cr in ('D','C')),
  constraint ck_ledger_amount check (amount > 0),
  constraint ck_ledger_currency check (currency ~ '^[A-Z]{3}$'),
  constraint ck_ledger_status check (status in (1,2,9))
);

create index if not exists ix_ledger_account_posted_time
  on yewu.ledger_entry(account_id, posted_at desc);

create index if not exists ix_ledger_transfer_order
  on yewu.ledger_entry(transfer_order_id);

create index if not exists ix_ledger_txn
  on yewu.ledger_entry(txn_id);

create index if not exists ix_ledger_entry_type
  on yewu.ledger_entry(entry_type);
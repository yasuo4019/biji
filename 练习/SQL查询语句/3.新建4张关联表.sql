--branch 机构/网点表（先建）
create table if not exists yewu.branch (
  branch_id          bigint generated always as identity primary key,
  branch_code        varchar(20) not null unique,         -- 机构编码，如 HQ001/XA001
  branch_name        varchar(100) not null,               -- 机构名称
  parent_branch_id   bigint references yewu.branch(branch_id), -- 自关联（总行/分行/支行）
  branch_level       smallint not null,                   -- 1=总行,2=分行,3=支行
  city               varchar(50),
  status             smallint not null default 1,         -- 1=启用,0=停用
  created_at         timestamptz not null default now(),
  constraint ck_branch_level check (branch_level in (1,2,3)),
  constraint ck_branch_status check (status in (0,1))
);

create index if not exists ix_branch_parent on yewu.branch(parent_branch_id);

--account_type_dict 账户类型字典表
create table if not exists yewu.account_type_dict (
  account_type_code   varchar(20) primary key,            -- 与 account.account_type 对应
  account_type_name_cn varchar(50) not null,              -- 中文名称
  allow_overdraft     boolean not null default false,     -- 是否允许透支
  status              smallint not null default 1,        -- 1=启用,0=停用
  sort_no             integer not null default 100,
  created_at          timestamptz not null default now(),
  constraint ck_account_type_dict_status check (status in (0,1))
);

create index if not exists ix_account_type_dict_sort on yewu.account_type_dict(sort_no);

--txn_type_dict 交易类型字典表
create table if not exists yewu.txn_type_dict (
  txn_type_code       varchar(30) primary key,            -- 与 txn.txn_type 对应
  txn_type_name_cn    varchar(50) not null,
  default_direction   smallint,                           -- 1/-1/null（可双向时为null）
  need_review         boolean not null default false,     -- 是否需要审核
  status              smallint not null default 1,        -- 1=启用,0=停用
  sort_no             integer not null default 100,
  created_at          timestamptz not null default now(),
  constraint ck_txn_type_dict_direction check (
    default_direction is null or default_direction in (1,-1)
  ),
  constraint ck_txn_type_dict_status check (status in (0,1))
);

create index if not exists ix_txn_type_dict_sort on yewu.txn_type_dict(sort_no);

--account_freeze_log 冻结/解冻日志表（最后建）
create table if not exists yewu.account_freeze_log (
  freeze_log_id       bigint generated always as identity primary key,
  account_id          bigint not null references yewu.account(account_id),
  action_type         varchar(20) not null,               -- FREEZE / UNFREEZE
  reason_code         varchar(30) not null,               -- KYC_RISK / COURT_HOLD / MANUAL ...
  reason_text         varchar(200),
  operator_name       varchar(50) not null,               -- 操作员/柜员/系统
  branch_id           bigint references yewu.branch(branch_id), -- 操作机构（可空）
  created_at          timestamptz not null default now(),
  constraint ck_freeze_action_type check (action_type in ('FREEZE','UNFREEZE'))
);

create index if not exists ix_freeze_log_account_time
  on yewu.account_freeze_log(account_id, created_at desc);

create index if not exists ix_freeze_log_branch
  on yewu.account_freeze_log(branch_id);

create index if not exists ix_freeze_log_reason
  on yewu.account_freeze_log(reason_code);
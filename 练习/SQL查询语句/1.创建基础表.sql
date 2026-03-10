create schema if not exists yewu;
create table if not exists yewu.customer (
  customer_id      bigint generated always as identity primary key,
  customer_no      varchar(32) not null unique,         -- 外部客户号/业务号
  full_name        varchar(200) not null,
  id_type          varchar(20)  not null,               -- 如: ID_CARD, PASSPORT
  id_no            varchar(64)  not null,
  phone            varchar(32),
  email            varchar(128),
  status           smallint not null default 1,          -- 1=active, 0=inactive, 9=blocked
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint ck_customer_status check (status in (0,1,9)),
  constraint uq_customer_iddoc unique (id_type, id_no)  -- 同证件不重复（示例）
);

create table if not exists yewu.account (
  account_id       bigint generated always as identity primary key,
  account_no       varchar(40) not null unique,          -- 账号/卡号/虚拟账号
  customer_id      bigint not null references yewu.customer(customer_id),
  currency         char(3) not null,                     -- ISO 4217: CNY/USD...
  account_type     varchar(20) not null,                 -- SAVINGS/CHECKING/CREDIT...
  status           smallint not null default 1,           -- 1=normal, 2=frozen, 9=closed
  balance          numeric(18,2) not null default 0,      -- 演示用途；严谨账务一般不直接改 balance
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint ck_account_status check (status in (1,2,9)),
  constraint ck_currency_format check (currency ~ '^[A-Z]{3}$')
);

create index if not exists ix_account_customer on yewu.account(customer_id);

create table if not exists yewu.txn (
  txn_id           bigint generated always as identity primary key,
  request_id       varchar(64) not null,                 -- 幂等键：同一次请求唯一
  account_id       bigint not null references yewu.account(account_id),
  direction        smallint not null,                     -- 1=credit(入账), -1=debit(出账)
  amount           numeric(18,2) not null,
  currency         char(3) not null,
  txn_type         varchar(30) not null,                 -- TRANSFER/DEPOSIT/WITHDRAW/FEE...
  status           smallint not null default 1,           -- 1=posted, 2=pending, 9=failed
  biz_ref          varchar(64),                           -- 外部业务参考号（可选）
  memo             varchar(500),
  created_at       timestamptz not null default now(),
  constraint ck_txn_dir check (direction in (1,-1)),
  constraint ck_txn_amt check (amount > 0),
  constraint ck_txn_status check (status in (1,2,9)),
  constraint ck_txn_currency check (currency ~ '^[A-Z]{3}$'),
  constraint uq_txn_request unique (request_id)
);

create index if not exists ix_txn_account_time on yewu.txn(account_id, created_at desc);
create index if not exists ix_txn_bizref on yewu.txn(biz_ref);

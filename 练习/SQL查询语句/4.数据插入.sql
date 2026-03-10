--1) 插入 branch（注意顺序：先总行，再分行，再支行）
-- 1. 总行
insert into yewu.branch (branch_code, branch_name, parent_branch_id, branch_level, city, status)
values ('HQ001', '总行', null, 1, '北京', 1)
on conflict (branch_code) do nothing;

-- 2. 分行（引用总行）
insert into yewu.branch (branch_code, branch_name, parent_branch_id, branch_level, city, status)
select 'BJ001', '北京分行', b.branch_id, 2, '北京', 1
from yewu.branch b
where b.branch_code = 'HQ001'
on conflict (branch_code) do nothing;

insert into yewu.branch (branch_code, branch_name, parent_branch_id, branch_level, city, status)
select 'XA001', '西安分行', b.branch_id, 2, '西安', 1
from yewu.branch b
where b.branch_code = 'HQ001'
on conflict (branch_code) do nothing;

insert into yewu.branch (branch_code, branch_name, parent_branch_id, branch_level, city, status)
select 'SH001', '上海分行', b.branch_id, 2, '上海', 1
from yewu.branch b
where b.branch_code = 'HQ001'
on conflict (branch_code) do nothing;

-- 3. 支行（引用分行）
insert into yewu.branch (branch_code, branch_name, parent_branch_id, branch_level, city, status)
select 'XA101', '西安高新支行', b.branch_id, 3, '西安', 1
from yewu.branch b
where b.branch_code = 'XA001'
on conflict (branch_code) do nothing;

insert into yewu.branch (branch_code, branch_name, parent_branch_id, branch_level, city, status)
select 'XA102', '西安雁塔支行', b.branch_id, 3, '西安', 1
from yewu.branch b
where b.branch_code = 'XA001'
on conflict (branch_code) do nothing;

insert into yewu.branch (branch_code, branch_name, parent_branch_id, branch_level, city, status)
select 'BJ101', '北京朝阳支行', b.branch_id, 3, '北京', 1
from yewu.branch b
where b.branch_code = 'BJ001'
on conflict (branch_code) do nothing;

--2) 插入 account_type_dict
insert into yewu.account_type_dict
(account_type_code, account_type_name_cn, allow_overdraft, status, sort_no)
values
('SAVINGS',  '储蓄账户', false, 1, 10),
('CHECKING', '结算账户', true,  1, 20),
('CREDIT',   '信用账户', true,  1, 30)
on conflict (account_type_code) do nothing;

--3) 插入 txn_type_dict
insert into yewu.txn_type_dict
(txn_type_code, txn_type_name_cn, default_direction, need_review, status, sort_no)
values
('DEPOSIT',  '存入/入账',    1,  false, 1, 10),
('WITHDRAW', '取现/支出',   -1,  false, 1, 20),
('TRANSFER', '转账',        null,false, 1, 30), -- 可能转入也可能转出
('FEE',      '手续费',      -1,  false, 1, 40),
('REFUND',   '退款',         1,  false, 1, 50)
on conflict (txn_type_code) do nothing;

--4) 插入 account_freeze_log（日志）
-- 为冻结账户写一条冻结日志（示例：账户风险复核）
insert into yewu.account_freeze_log
(account_id, action_type, reason_code, reason_text, operator_name, branch_id)
select
  a.account_id,
  'FREEZE',
  'KYC_RISK',
  '客户身份信息待复核，临时冻结',
  '柜员-张敏',
  b.branch_id
from yewu.account a
cross join yewu.branch b
where a.account_no = '622202600000000004'
  and b.branch_code = 'XA101'
  and not exists (
    select 1
    from yewu.account_freeze_log f
    where f.account_id = a.account_id
      and f.action_type = 'FREEZE'
      and f.reason_code = 'KYC_RISK'
  );

-- 再给另一个账户插入一条冻结后解冻日志（演示历史）
insert into yewu.account_freeze_log
(account_id, action_type, reason_code, reason_text, operator_name, branch_id)
select
  a.account_id,
  'FREEZE',
  'MANUAL_CHECK',
  '大额交易人工复核，短时冻结',
  '风控系统',
  b.branch_id
from yewu.account a
cross join yewu.branch b
where a.account_no = '622202600000000002'
  and b.branch_code = 'BJ101'
  and not exists (
    select 1
    from yewu.account_freeze_log f
    where f.account_id = a.account_id
      and f.action_type = 'FREEZE'
      and f.reason_code = 'MANUAL_CHECK'
  );

insert into yewu.account_freeze_log
(account_id, action_type, reason_code, reason_text, operator_name, branch_id)
select
  a.account_id,
  'UNFREEZE',
  'MANUAL_CHECK_PASS',
  '人工复核通过，解除冻结',
  '审核员-李强',
  b.branch_id
from yewu.account a
cross join yewu.branch b
where a.account_no = '622202600000000002'
  and b.branch_code = 'BJ101'
  and not exists (
    select 1
    from yewu.account_freeze_log f
    where f.account_id = a.account_id
      and f.action_type = 'UNFREEZE'
      and f.reason_code = 'MANUAL_CHECK_PASS'
  );
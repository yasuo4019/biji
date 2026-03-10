-- ============================================================
-- 新增4张表 - 测试数据插入（与现有7张表衔接）
-- ============================================================

-- 1) 初始化账户余额快照（按当前 account.balance 生成）
insert into yewu.account_balance_snapshot
(account_id, ledger_balance, available_balance, frozen_amount, last_txn_id, last_posted_at)
select
  a.account_id,
  a.balance as ledger_balance,
  case when a.status = 2 then greatest(a.balance - 1000, 0) else a.balance end as available_balance, -- 演示：冻结账户扣一部分可用
  case when a.status = 2 then least(1000, a.balance) else 0 end as frozen_amount,
  (
    select t.txn_id
    from yewu.txn t
    where t.account_id = a.account_id
    order by t.created_at desc, t.txn_id desc
    limit 1
  ) as last_txn_id,
  (
    select t.created_at
    from yewu.txn t
    where t.account_id = a.account_id
      and t.status = 1
    order by t.created_at desc, t.txn_id desc
    limit 1
  ) as last_posted_at
from yewu.account a
where not exists (
  select 1
  from yewu.account_balance_snapshot s
  where s.account_id = a.account_id
);


-- 2) 插入 transfer_order（演示几笔转账业务主单）
-- 2.1 王伟 -> 李娜（成功）
insert into yewu.transfer_order
(order_no, request_id, from_account_id, to_account_id, amount, currency, status, channel_code, biz_ref, memo)
select
  'TO20260305-0001',
  'TO-REQ-20260305-0001',
  a_from.account_id,
  a_to.account_id,
  1200.00,
  'CNY',
  3,                  -- success
  'APP',
  'APP-TRX-0001',
  '王伟向李娜转账（演示成功）'
from yewu.account a_from
cross join yewu.account a_to
where a_from.account_no = '622202600000000001'
  and a_to.account_no   = '622202600000000002'
  and not exists (
    select 1 from yewu.transfer_order o where o.order_no = 'TO20260305-0001'
  );

-- 2.2 李娜 -> 陈静（处理中）
insert into yewu.transfer_order
(order_no, request_id, from_account_id, to_account_id, amount, currency, status, channel_code, biz_ref, memo)
select
  'TO20260305-0002',
  'TO-REQ-20260305-0002',
  a_from.account_id,
  a_to.account_id,
  666.66,
  'CNY',
  2,                  -- processing
  'API',
  'OPENAPI-20260305-02',
  '李娜向陈静转账（演示处理中）'
from yewu.account a_from
cross join yewu.account a_to
where a_from.account_no = '622202600000000002'
  and a_to.account_no   = '622202600000000005'
  and not exists (
    select 1 from yewu.transfer_order o where o.order_no = 'TO20260305-0002'
  );

-- 2.3 冻结账户 刘洋 -> 王伟（失败）
insert into yewu.transfer_order
(order_no, request_id, from_account_id, to_account_id, amount, currency, status, channel_code, biz_ref, memo)
select
  'TO20260305-0003',
  'TO-REQ-20260305-0003',
  a_from.account_id,
  a_to.account_id,
  300.00,
  'CNY',
  9,                  -- failed
  'COUNTER',
  'COUNTER-FAIL-0003',
  '冻结账户发起转账失败（演示）'
from yewu.account a_from
cross join yewu.account a_to
where a_from.account_no = '622202600000000004'
  and a_to.account_no   = '622202600000000001'
  and not exists (
    select 1 from yewu.transfer_order o where o.order_no = 'TO20260305-0003'
  );


-- 3) 插入 account_freeze_hold（当前冻结状态明细）
-- 3.1 给刘洋的冻结账户建立一个“当前生效中的全额冻结”
insert into yewu.account_freeze_hold
(account_id, hold_type, hold_amount, reason_code, reason_text, source_system, branch_id, operator_name, start_at, status)
select
  a.account_id,
  'FULL',
  null,
  'KYC_RISK',
  '客户身份信息待复核，当前冻结中',
  'MANUAL',
  b.branch_id,
  '柜员-张敏',
  now() - interval '1 day',
  1
from yewu.account a
cross join yewu.branch b
where a.account_no = '622202600000000004'
  and b.branch_code = 'XA101'
  and not exists (
    select 1
    from yewu.account_freeze_hold h
    where h.account_id = a.account_id
      and h.reason_code = 'KYC_RISK'
      and h.status = 1
  );

-- 3.2 给王伟账户加一个“部分冻结”（演示：司法冻结部分金额）
insert into yewu.account_freeze_hold
(account_id, hold_type, hold_amount, reason_code, reason_text, source_system, branch_id, operator_name, start_at, status)
select
  a.account_id,
  'PARTIAL',
  5000.00,
  'COURT_HOLD',
  '司法协查，部分金额冻结（演示）',
  'COURT',
  b.branch_id,
  '系统-司法接口',
  now() - interval '2 hour',
  1
from yewu.account a
cross join yewu.branch b
where a.account_no = '622202600000000001'
  and b.branch_code = 'BJ101'
  and not exists (
    select 1
    from yewu.account_freeze_hold h
    where h.account_id = a.account_id
      and h.reason_code = 'COURT_HOLD'
      and h.status = 1
  );


-- 4) 插入 ledger_entry（账务分录）
-- 说明：这里用 transfer_order（业务单）+ account（账户）构造双边分录示例
-- 4.1 对 TO20260305-0001（成功转账）生成两条posted分录：付款方借(D)，收款方贷(C)
insert into yewu.ledger_entry
(entry_no, transfer_order_id, txn_id, account_id, currency, dr_cr, amount, entry_type, status, posted_at, memo)
select
  'LE-TO20260305-0001-D',
  o.transfer_order_id,
  null,
  o.from_account_id,
  o.currency,
  'D',
  o.amount,
  'TRANSFER',
  1,
  now() - interval '30 minute',
  '转账成功-付款方借记分录'
from yewu.transfer_order o
where o.order_no = 'TO20260305-0001'
  and not exists (
    select 1 from yewu.ledger_entry e where e.entry_no = 'LE-TO20260305-0001-D'
  );

insert into yewu.ledger_entry
(entry_no, transfer_order_id, txn_id, account_id, currency, dr_cr, amount, entry_type, status, posted_at, memo)
select
  'LE-TO20260305-0001-C',
  o.transfer_order_id,
  null,
  o.to_account_id,
  o.currency,
  'C',
  o.amount,
  'TRANSFER',
  1,
  now() - interval '30 minute',
  '转账成功-收款方贷记分录'
from yewu.transfer_order o
where o.order_no = 'TO20260305-0001'
  and not exists (
    select 1 from yewu.ledger_entry e where e.entry_no = 'LE-TO20260305-0001-C'
  );

-- 4.2 对 TO20260305-0002（处理中）生成两条pending分录（演示状态流转）
insert into yewu.ledger_entry
(entry_no, transfer_order_id, txn_id, account_id, currency, dr_cr, amount, entry_type, status, posted_at, memo)
select
  'LE-TO20260305-0002-D',
  o.transfer_order_id,
  null,
  o.from_account_id,
  o.currency,
  'D',
  o.amount,
  'TRANSFER',
  2,  -- pending
  now() - interval '10 minute',
  '转账处理中-付款方待入账分录'
from yewu.transfer_order o
where o.order_no = 'TO20260305-0002'
  and not exists (
    select 1 from yewu.ledger_entry e where e.entry_no = 'LE-TO20260305-0002-D'
  );

insert into yewu.ledger_entry
(entry_no, transfer_order_id, txn_id, account_id, currency, dr_cr, amount, entry_type, status, posted_at, memo)
select
  'LE-TO20260305-0002-C',
  o.transfer_order_id,
  null,
  o.to_account_id,
  o.currency,
  'C',
  o.amount,
  'TRANSFER',
  2,  -- pending
  now() - interval '10 minute',
  '转账处理中-收款方待入账分录'
from yewu.transfer_order o
where o.order_no = 'TO20260305-0002'
  and not exists (
    select 1 from yewu.ledger_entry e where e.entry_no = 'LE-TO20260305-0002-C'
  );

-- 4.3 对 TO20260305-0003（失败）插入一条reversed示例分录（演示失败/冲正语义）
insert into yewu.ledger_entry
(entry_no, transfer_order_id, txn_id, account_id, currency, dr_cr, amount, entry_type, status, posted_at, memo)
select
  'LE-TO20260305-0003-D-REV',
  o.transfer_order_id,
  null,
  o.from_account_id,
  o.currency,
  'D',
  o.amount,
  'TRANSFER',
  9,  -- reversed/failed示例
  now() - interval '5 minute',
  '冻结账户转账失败，分录标记为冲正/失败（演示）'
from yewu.transfer_order o
where o.order_no = 'TO20260305-0003'
  and not exists (
    select 1 from yewu.ledger_entry e where e.entry_no = 'LE-TO20260305-0003-D-REV'
  );
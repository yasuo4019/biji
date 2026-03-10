insert into yewu.customer
(customer_no, full_name, id_type, id_no, phone, email, status)
values
('C20260001', '王伟',   'ID_CARD', '110101199003077314', '13800138001', 'wangwei@example.com',   1),
('C20260002', '李娜',   'ID_CARD', '310101199512120028', '13900139002', 'lina@example.com',     1),
('C20260003', '张强',   'ID_CARD', '44030519881123451X', '13700137003', 'zhangqiang@example.com',1),
('C20260004', '刘洋',   'ID_CARD', '320102199707150011', '13600136004', 'liuyang@example.com',  1),
('C20260005', '陈静',   'ID_CARD', '510105199202280026', '13500135005', 'chenjing@example.com', 1);

insert into yewu.account
(account_no, customer_id, currency, account_type, status, balance)
select '622202600000000001', c.customer_id, 'CNY', 'SAVINGS', 1, 125000.00
from yewu.customer c where c.customer_no = 'C20260001';

insert into yewu.account
(account_no, customer_id, currency, account_type, status, balance)
select '622202600000000002', c.customer_id, 'CNY', 'SAVINGS', 1,  8600.50
from yewu.customer c where c.customer_no = 'C20260002';

insert into yewu.account
(account_no, customer_id, currency, account_type, status, balance)
select '622202600000000003', c.customer_id, 'CNY', 'SAVINGS', 1,  320.00
from yewu.customer c where c.customer_no = 'C20260003';

insert into yewu.account
(account_no, customer_id, currency, account_type, status, balance)
select '622202600000000004', c.customer_id, 'CNY', 'SAVINGS', 2,  5000.00  -- frozen
from yewu.customer c where c.customer_no = 'C20260004';

insert into yewu.account
(account_no, customer_id, currency, account_type, status, balance)
select '622202600000000005', c.customer_id, 'CNY', 'SAVINGS', 1,  98000.00
from yewu.customer c where c.customer_no = 'C20260005';

-- 王伟：工资入账、房租支出、购物支出
insert into yewu.txn
(request_id, account_id, direction, amount, currency, txn_type, status, biz_ref, memo)
select
  'REQ20260303-0001',
  a.account_id,
  1, 30000.00, 'CNY', 'DEPOSIT', 1,
  'PAYROLL-202602', '2026年2月工资'
from yewu.account a where a.account_no = '622202600000000001';

insert into yewu.txn
(request_id, account_id, direction, amount, currency, txn_type, status, biz_ref, memo)
select
  'REQ20260303-0002',
  a.account_id,
  -1, 5500.00, 'CNY', 'TRANSFER', 1,
  'RENT-202603', '3月房租'
from yewu.account a where a.account_no = '622202600000000001';

insert into yewu.txn
(request_id, account_id, direction, amount, currency, txn_type, status, biz_ref, memo)
select
  'REQ20260303-0003',
  a.account_id,
  -1, 328.80, 'CNY', 'WITHDRAW', 1,
  'POS-STARBUCKS', '门店消费'
from yewu.account a where a.account_no = '622202600000000001';


-- 李娜：转入、转出、手续费
insert into yewu.txn
(request_id, account_id, direction, amount, currency, txn_type, status, biz_ref, memo)
select
  'REQ20260303-0101',
  a.account_id,
  1, 2000.00, 'CNY', 'TRANSFER', 1,
  'WX-TRANSFER-IN', '微信转入'
from yewu.account a where a.account_no = '622202600000000002';

insert into yewu.txn
(request_id, account_id, direction, amount, currency, txn_type, status, biz_ref, memo)
select
  'REQ20260303-0102',
  a.account_id,
  -1, 168.00, 'CNY', 'TRANSFER', 1,
  'MEITUAN', '外卖/团购'
from yewu.account a where a.account_no = '622202600000000002';

insert into yewu.txn
(request_id, account_id, direction, amount, currency, txn_type, status, biz_ref, memo)
select
  'REQ20260303-0103',
  a.account_id,
  -1, 2.00, 'CNY', 'FEE', 1,
  'FEE-SMS', '短信通知费'
from yewu.account a where a.account_no = '622202600000000002';


-- 张强：小额入账、ATM取现
insert into yewu.txn
(request_id, account_id, direction, amount, currency, txn_type, status, biz_ref, memo)
select
  'REQ20260303-0201',
  a.account_id,
  1, 500.00, 'CNY', 'DEPOSIT', 1,
  'CASH-DEPOSIT', '现金存入'
from yewu.account a where a.account_no = '622202600000000003';

insert into yewu.txn
(request_id, account_id, direction, amount, currency, txn_type, status, biz_ref, memo)
select
  'REQ20260303-0202',
  a.account_id,
  -1, 200.00, 'CNY', 'WITHDRAW', 1,
  'ATM-ICBC-001', 'ATM取现'
from yewu.account a where a.account_no = '622202600000000003';


-- 刘洋：账户冻结状态下做一笔失败流水（演示 failed）
insert into yewu.txn
(request_id, account_id, direction, amount, currency, txn_type, status, biz_ref, memo)
select
  'REQ20260303-0301',
  a.account_id,
  -1, 1000.00, 'CNY', 'TRANSFER', 9,
  'TRANSFER-OUT', '账户冻结，交易失败（演示数据）'
from yewu.account a where a.account_no = '622202600000000004';


-- 陈静：理财赎回入账、转账支出
insert into yewu.txn
(request_id, account_id, direction, amount, currency, txn_type, status, biz_ref, memo)
select
  'REQ20260303-0401',
  a.account_id,
  1, 15000.00, 'CNY', 'DEPOSIT', 1,
  'WEALTH-REDEEM', '理财赎回到账'
from yewu.account a where a.account_no = '622202600000000005';

insert into yewu.txn
(request_id, account_id, direction, amount, currency, txn_type, status, biz_ref, memo)
select
  'REQ20260303-0402',
  a.account_id,
  -1, 1200.00, 'CNY', 'TRANSFER', 1,
  'ALIPAY', '支付宝转出'
from yewu.account a where a.account_no = '622202600000000005';
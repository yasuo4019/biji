select 
  c.customer_no,
  c.full_name,
  a.account_no,
  a.status as account_status_code,
  s.ledger_balance,
  s.available_balance,
  s.frozen_amount,
  s.updated_at
from yewu.account a
join yewu.customer c
  on c.customer_id = a.customer_id
left join yewu.account_balance_snapshot s
  on s.account_id = a.account_id
where a.status = 2
order by a.account_no;
-- This file should undo anything in `up.sql`

alter table transaction
drop column order_date;

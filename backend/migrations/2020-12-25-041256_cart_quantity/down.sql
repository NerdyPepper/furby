-- This file should undo anything in `up.sql`

alter table cart_items
drop column quantity;

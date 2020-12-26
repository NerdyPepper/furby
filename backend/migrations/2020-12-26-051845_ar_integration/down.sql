-- This file should undo anything in `up.sql`
alter table product
drop column src;

alter table product
drop column ios_src;

-- Your SQL goes here

alter table transaction
add order_date date not null default curdate();

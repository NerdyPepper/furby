-- Your SQL goes here

create table customer (
    id integer primary key auto_increment,
    username varchar(255) not null unique,
    password varchar(255) not null,
    phone_number varchar(10) not null,
    email_id varchar(255) not null,
    address text(500)
);

create table product (
    id integer primary key auto_increment,
    name varchar(255) not null,
    kind varchar(255),
    price float not null,
    description varchar(255)
);

create table cart_items (
    cart_id integer,
    product_id integer,
    constraint cart_items_pk primary key (cart_id, product_id),
    foreign key (cart_id) references customer(id),
    foreign key (product_id) references product(id)
);

create table rating (
    id integer primary key auto_increment,
    comment_text text(500),
    comment_date date default curdate(),
    product_id integer,
    customer_id integer,

    stars integer check (stars >= 0 AND stars <= 5),
    foreign key (customer_id) references customer(id),
    foreign key (product_id) references product(id)
);

create table transaction (
    id integer primary key auto_increment,
    payment_type varchar(255) not null,
    amount float not null,
    customer_id integer,

    foreign key (customer_id) references customer(id)
);

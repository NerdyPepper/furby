table! {
    cart_items (cart_id, product_id) {
        cart_id -> Integer,
        product_id -> Integer,
        quantity -> Nullable<Integer>,
    }
}

table! {
    customer (id) {
        id -> Integer,
        username -> Varchar,
        password -> Varchar,
        phone_number -> Varchar,
        email_id -> Varchar,
        address -> Nullable<Text>,
    }
}

table! {
    product (id) {
        id -> Integer,
        name -> Varchar,
        kind -> Nullable<Varchar>,
        price -> Float,
        description -> Nullable<Varchar>,
    }
}

table! {
    rating (id) {
        id -> Integer,
        comment_text -> Nullable<Text>,
        comment_date -> Nullable<Date>,
        product_id -> Nullable<Integer>,
        customer_id -> Nullable<Integer>,
        stars -> Nullable<Integer>,
    }
}

table! {
    transaction (id) {
        id -> Integer,
        payment_type -> Varchar,
        amount -> Float,
        customer_id -> Nullable<Integer>,
        order_date -> Date,
    }
}

joinable!(cart_items -> customer (cart_id));
joinable!(cart_items -> product (product_id));
joinable!(rating -> customer (customer_id));
joinable!(rating -> product (product_id));
joinable!(transaction -> customer (customer_id));

allow_tables_to_appear_in_same_query!(
    cart_items,
    customer,
    product,
    rating,
    transaction,
);

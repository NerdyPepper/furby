table! {
    members (id) {
        id -> Integer,
        username -> Varchar,
        password -> Varchar,
        phone_number -> Varchar,
        email_id -> Varchar,
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

allow_tables_to_appear_in_same_query!(
    members,
    product,
);

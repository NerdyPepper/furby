use super::schema::{cart_items, customer, product, rating, transaction};

use chrono::naive::{NaiveDate, NaiveDateTime};
use diesel::{Insertable, Queryable};
use serde::{Deserialize, Serialize};

/* Member */
#[derive(Queryable, Serialize)]
pub struct Customer {
    pub id: i32,
    pub username: String,
    pub password: String,
    pub phone_number: String,
    pub email_id: String,
    pub address: Option<String>,
}

#[derive(Insertable, Deserialize)]
#[table_name = "customer"]
pub struct NewCustomer {
    pub username: String,
    pub password: String,
    pub phone_number: String,
    pub email_id: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub address: Option<String>,
}

/* Product */
#[derive(Queryable, Serialize)]
pub struct Product {
    pub id: i32,
    pub name: String,
    pub kind: Option<String>,
    pub price: f32,
    pub description: Option<String>,
}

#[derive(Insertable, Deserialize)]
#[table_name = "product"]
pub struct NewProduct {
    pub name: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub kind: Option<String>,
    pub price: f32,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
}

#[derive(Deserialize)]
pub struct UpdateProduct {
    pub name: String,
    pub kind: Option<String>,
    pub price: f32,
    pub description: Option<String>,
}

/* Cart Items */
#[derive(Queryable, Serialize)]
pub struct CartItem {
    pub cart_id: i32,
    pub product_id: i32,
}

#[derive(Insertable, Deserialize)]
#[table_name = "cart_items"]
pub struct AddCartItem {
    pub cart_id: i32,
    pub product_id: i32,
}

/* Rating */
#[derive(Queryable, Serialize)]
pub struct Rating {
    pub id: i32,
    pub comment_text: Option<String>,
    pub comment_date: Option<NaiveDate>,
    pub product_id: Option<i32>,
    pub customer_id: Option<i32>,
    pub stars: Option<i32>,
}

#[derive(Insertable, Deserialize)]
#[table_name = "rating"]
pub struct AddRating {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub comment_text: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub stars: Option<i32>,

    pub product_id: i32,
    pub customer_id: i32,
}

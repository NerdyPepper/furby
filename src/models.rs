use super::schema::{members, product};

use diesel::{Insertable, Queryable};
use serde::{Deserialize, Serialize};

#[derive(Queryable, Serialize)]
pub struct Member {
    pub id: i32,
    pub username: String,
    pub password: String,
    pub phone_number: String,
    pub email_id: String,
}

#[derive(Insertable, Deserialize)]
#[table_name = "members"]
pub struct NewMember {
    pub username: String,
    pub password: String,
    pub phone_number: String,
    pub email_id: String,
}

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

use super::schema::members;
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

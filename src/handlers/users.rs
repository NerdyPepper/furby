use crate::models::{Member, NewMember};
use crate::schema::members::dsl::*;
use crate::TPool;

use actix_identity::Identity;
use actix_web::{web, HttpResponse, Responder};
use bcrypt::{hash, verify, DEFAULT_COST};
use diesel::prelude::*;
use log::{error, info};
use serde::Deserialize;

pub async fn new_user(
    pool: web::Data<TPool>,
    item: web::Json<NewMember>,
) -> impl Responder {
    let conn = pool.get().unwrap();
    let hashed_item = NewMember {
        password: hash(&item.password, DEFAULT_COST).unwrap(),
        ..(item.into_inner())
    };
    diesel::insert_into(members)
        .values(hashed_item)
        .execute(&conn)
        .expect("Coundn't connect to DB");
    HttpResponse::Ok().body("Inserted successfully!")
}

pub async fn name_exists(
    pool: web::Data<TPool>,
    item: String,
) -> impl Responder {
    let conn = pool.get().unwrap();
    info!("target: {:?}", item);
    if (members
        .filter(username.eq(&item))
        .limit(1)
        .load::<Member>(&conn)
        .expect("Coundn't connect to DB"))
    .len()
        > 0
    {
        HttpResponse::Ok().body("true")
    } else {
        HttpResponse::Ok().body("false")
    }
}

#[derive(Deserialize)]
pub struct Login {
    username: String,
    password: String,
}

pub async fn login(
    pool: web::Data<TPool>,
    cookie: Identity,
    login_details: web::Json<Login>,
) -> impl Responder {
    info!("Login hit");
    let conn = pool.get().unwrap();
    let entered_pass = &login_details.password;
    let selected_user = members
        .filter(username.eq(&login_details.username))
        .limit(1)
        .first::<Member>(&conn)
        .expect("Couldn't connect to DB");
    let hashed_pass = selected_user.password;
    if verify(entered_pass, &hashed_pass).unwrap() {
        cookie.remember(login_details.username.clone());
        info!(
            "Successful login: {} {}",
            selected_user.username, selected_user.email_id
        );
        HttpResponse::Ok().finish()
    } else {
        HttpResponse::Unauthorized().finish()
    }
}

pub async fn logout(cookie: Identity) -> impl Responder {
    cookie.forget();
    HttpResponse::Found().header("location", "/").finish()
}

pub async fn user_details(
    uname: web::Path<String>,
    pool: web::Data<TPool>,
) -> impl Responder {
    let conn = pool.get().unwrap();
    let uname = uname.into_inner();
    info!("Fetching info for: \"{}\"", uname);
    let selected_user = members
        .filter(username.eq(&uname))
        .limit(1)
        .first::<Member>(&conn);
    match selected_user {
        Ok(m) => {
            info!("Found user: {}", uname);
            HttpResponse::Ok().json(m)
        }
        Err(_) => {
            error!("User not found: {}", uname);
            HttpResponse::NotFound().finish()
        }
    }
}

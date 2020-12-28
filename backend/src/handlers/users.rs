use crate::models::{Customer, NewCustomer, Rating, Transaction};
use crate::schema::customer::dsl::*;
use crate::schema::rating::dsl as rs;
use crate::schema::transaction::dsl as ts;
use crate::TPool;

use actix_identity::Identity;
use actix_web::{web, HttpResponse, Responder};
use bcrypt::{hash, verify, DEFAULT_COST};
use diesel::prelude::*;
use log::{error, info};
use redis::Commands;
use serde::{Deserialize, Serialize};

pub async fn new_user(
    pool: web::Data<TPool>,
    item: web::Json<NewCustomer>,
) -> impl Responder {
    info!("Creating ... {:?}", item.username);
    let conn = pool.get().unwrap();
    let hashed_item = NewCustomer {
        password: hash(&item.password, DEFAULT_COST).unwrap(),
        ..(item.into_inner())
    };
    diesel::insert_into(customer)
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
    if (customer
        .filter(username.eq(&item))
        .limit(1)
        .load::<Customer>(&conn)
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
    if cookie.identity().is_some() {
        info!("Found existing cookie: {:?}", cookie.identity());
        return HttpResponse::Ok().finish();
    }
    let conn = pool.get().unwrap();
    let entered_pass = &login_details.password;
    let selected_user = customer
        .filter(username.eq(&login_details.username))
        .limit(1)
        .first::<Customer>(&conn)
        .expect("Couldn't connect to DB");
    let hashed_pass = selected_user.password;
    if verify(entered_pass, &hashed_pass).unwrap() {
        cookie.remember(login_details.username.clone());
        let redis_client = redis::Client::open("redis://127.0.0.1/").unwrap();
        let mut redis_conn = redis_client.get_connection().unwrap();
        redis_conn
            .set::<String, String, String>(
                login_details.username.clone(),
                cookie.identity().unwrap(),
            )
            .unwrap();
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
    let redis_client = redis::Client::open("redis://127.0.0.1/").unwrap();
    let mut redis_conn = redis_client.get_connection().unwrap();
    redis_conn.del::<String, String>(cookie.identity().unwrap());
    cookie.forget();
    HttpResponse::Ok().body("Successful logout.")
}

pub async fn user_details(
    uname: web::Path<String>,
    pool: web::Data<TPool>,
) -> impl Responder {
    let conn = pool.get().unwrap();
    let uname = uname.into_inner();
    info!("Fetching info for: \"{}\"", uname);
    let selected_user = customer
        .filter(username.eq(&uname))
        .limit(1)
        .first::<Customer>(&conn);
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

#[derive(Deserialize, Debug)]
pub struct ChangePassword {
    old_password: String,
    new_password: String,
}

pub async fn change_password(
    cookie: Identity,
    password_details: web::Json<ChangePassword>,
    pool: web::Data<TPool>,
) -> impl Responder {
    info!("Change password request: {:?}", password_details);
    let conn = pool.get().unwrap();
    if let Some(uname) = cookie.identity() {
        let entered_pass = &password_details.old_password;
        let new_password = &password_details.new_password;
        let selected_user = customer
            .filter(username.eq(&uname))
            .limit(1)
            .first::<Customer>(&conn)
            .expect("Couldn't connect to DB");
        let hashed_pass = selected_user.password;
        if verify(entered_pass, &hashed_pass).unwrap() {
            let hashed_new_password =
                hash(&new_password, DEFAULT_COST).unwrap();
            diesel::update(customer.filter(id.eq(selected_user.id)))
                .set(password.eq(hashed_new_password))
                .execute(&conn)
                .unwrap();
            return HttpResponse::Ok().body("Changed password successfully");
        } else {
            return HttpResponse::Ok().body("Invalid password");
        }
    }
    return HttpResponse::Unauthorized().body("Login first");
}

#[derive(Serialize)]
struct UserProfile {
    pub username: String,
    pub email_id: String,
    pub address: Option<String>,
    pub transactions: Vec<Transaction>,
    pub ratings_given: i32,
    pub phone_number: String,
}

pub async fn user_profile(
    cookie: Identity,
    pool: web::Data<TPool>,
) -> impl Responder {
    info!("Fetching user profile for {:?}", cookie.identity());
    let conn = pool.get().unwrap();

    if let Some(uname) = cookie.identity() {
        let selected_user = customer
            .filter(username.eq(&uname))
            .limit(1)
            .first::<Customer>(&conn)
            .expect("Couldn't connect to DB");
        let user_transactions = ts::transaction
            .filter(ts::customer_id.eq(selected_user.id))
            .load(&conn)
            .expect("Couldn't connect to DB");
        let user_ratings = rs::rating
            .filter(rs::customer_id.eq(selected_user.id))
            .load::<Rating>(&conn)
            .expect("Couldn't connect to DB")
            .len() as i32;
        let profile = UserProfile {
            username: selected_user.username,
            email_id: selected_user.email_id,
            address: selected_user.address,
            transactions: user_transactions,
            ratings_given: user_ratings,
            phone_number: selected_user.phone_number,
        };
        return HttpResponse::Ok().json(&profile);
    } else {
        return HttpResponse::Unauthorized()
            .body("Need to be logged in to view profile!");
    }
}

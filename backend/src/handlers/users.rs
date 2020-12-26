use crate::models::{Customer, NewCustomer};
use crate::schema::customer::dsl::*;
use crate::TPool;

use actix_identity::Identity;
use actix_web::{web, HttpResponse, Responder};
use bcrypt::{hash, verify, DEFAULT_COST};
use diesel::prelude::*;
use log::{error, info};
use serde::Deserialize;

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

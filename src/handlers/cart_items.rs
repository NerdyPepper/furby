use crate::models::{AddCartItem, CartItem, Customer, Product};
use crate::schema::product::dsl as prod;
use crate::schema::{cart_items::dsl::*, customer::dsl::*};
use crate::TPool;

use actix_identity::Identity;
use actix_web::{web, HttpResponse, Responder};
use diesel::prelude::*;
use log::{error, info};
use serde::Deserialize;

#[derive(Deserialize, Debug)]
pub struct AddToCart {
    product_id: i32,
}

pub async fn add_to_cart(
    cookie: Identity,
    item_details: web::Json<AddToCart>,
    pool: web::Data<TPool>,
) -> impl Responder {
    info!("Add to cart hit: {:?}", item_details.product_id);
    let conn = pool.get().unwrap();
    if let Some(uname) = cookie.identity() {
        let selected_user = customer
            .filter(username.eq(&uname))
            .limit(1)
            .first::<Customer>(&conn)
            .expect("Couldn't connect to DB");
        let new_cart_item = AddCartItem {
            cart_id: selected_user.id,
            product_id: item_details.product_id,
        };
        diesel::insert_into(cart_items)
            .values(new_cart_item)
            .execute(&conn)
            .expect("Coundn't connect to DB");
        HttpResponse::Ok().body("Inserted successfully!")
    } else {
        error!("Unauthorized add to cart action!");
        return HttpResponse::Unauthorized()
            .body("Need to be logged in to add to cart!");
    }
}

#[derive(Deserialize, Debug)]
pub struct RemoveFromCart {
    product_id: i32,
}

pub async fn remove_from_cart(
    cookie: Identity,
    item_details: web::Json<RemoveFromCart>,
    pool: web::Data<TPool>,
) -> impl Responder {
    info!("Remove from cart hit: {:?}", item_details.product_id);
    let conn = pool.get().unwrap();
    if let Some(uname) = cookie.identity() {
        let selected_user = customer
            .filter(username.eq(&uname))
            .limit(1)
            .first::<Customer>(&conn)
            .expect("Couldn't connect to DB");

        diesel::delete(
            cart_items
                .filter(cart_id.eq(selected_user.id))
                .filter(product_id.eq(item_details.product_id)),
        )
        .execute(&conn)
        .expect("Coundn't connect to DB");
        HttpResponse::Ok().body("Removed successfully!")
    } else {
        error!("Unauthorized add to cart action!");
        return HttpResponse::Unauthorized()
            .body("Need to be logged in to add to cart!");
    }
}

pub async fn get_user_cart_items(
    cookie: Identity,
    pool: web::Data<TPool>,
) -> impl Responder {
    let conn = pool.get().unwrap();
    if let Some(uname) = cookie.identity() {
        let selected_user = customer
            .filter(username.eq(&uname))
            .limit(1)
            .first::<Customer>(&conn)
            .expect("Couldn't connect to DB");
        let user_cart_items = cart_items
            .filter(cart_id.eq(selected_user.id))
            .load::<CartItem>(&conn)
            .expect("Couldn't connect to DB");
        let cart_products = user_cart_items
            .into_iter()
            .map(|item| {
                prod::product
                    .filter(prod::id.eq(item.product_id))
                    .limit(1)
                    .first::<Product>(&conn)
                    .expect("Couldn't connect to db")
            })
            .collect::<Vec<_>>();
        return HttpResponse::Ok().json(&cart_products);
    } else {
        return HttpResponse::Unauthorized()
            .body("Need to be logged in to add to cart!");
    }
}

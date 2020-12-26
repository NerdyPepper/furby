use crate::models::{AddCartItem, CartItem, Customer, Product};
use crate::schema::product::dsl as prod;
use crate::schema::{cart_items::dsl::*, customer::dsl::*};
use crate::TPool;

use actix_identity::Identity;
use actix_web::{web, HttpResponse, Responder};
use diesel::prelude::*;
use log::{error, info};
use serde::Serialize;

pub async fn add_to_cart(
    cookie: Identity,
    item_id: String,
    pool: web::Data<TPool>,
) -> impl Responder {
    let item_details = item_id.parse::<i32>().unwrap_or(-1);
    info!("Add to cart hit: {:?}", item_details);
    info!("[cart] Current user: {:?}", cookie.identity());
    let conn = pool.get().unwrap();
    if let Some(uname) = cookie.identity() {
        let selected_user = customer
            .filter(username.eq(&uname))
            .limit(1)
            .first::<Customer>(&conn)
            .expect("Couldn't connect to DB");
        let new_cart_item = AddCartItem {
            cart_id: selected_user.id,
            product_id: item_details,
            quantity: Some(1),
        };
        info!(
            "cart id: {:?}, product id {:?}",
            selected_user.id, item_details
        );
        let current_entry = cart_items
            .filter(cart_id.eq(selected_user.id))
            .filter(product_id.eq(item_details))
            .limit(1)
            .first::<CartItem>(&conn);
        match current_entry {
            Ok(v) => {
                info!("Item already present in cart, increasing quantity.");
                let old_quantity = v.quantity.unwrap_or(1);
                diesel::update(
                    cart_items
                        .filter(cart_id.eq(selected_user.id))
                        .filter(product_id.eq(item_details)),
                )
                .set(quantity.eq(old_quantity + 1))
                .execute(&conn)
                .unwrap();
                return HttpResponse::Ok()
                    .body("Updated quantity successfully!");
            }
            Err(_) => {
                info!("Item not present, adding to cart.");
                diesel::insert_into(cart_items)
                    .values(new_cart_item)
                    .execute(&conn)
                    .expect("Couldn't connect to DB");
                HttpResponse::Ok().body("Inserted successfully!")
            }
        }
    } else {
        error!("Unauthorized add to cart action!");
        return HttpResponse::Unauthorized()
            .body("Need to be logged in to add to cart!");
    }
}

pub async fn remove_from_cart(
    cookie: Identity,
    item_id: String,
    pool: web::Data<TPool>,
) -> impl Responder {
    info!("Remove from cart hit: {:?}", item_id);
    let item_details = item_id.parse::<i32>().unwrap_or(-1);
    let conn = pool.get().unwrap();
    if let Some(uname) = cookie.identity() {
        let selected_user = customer
            .filter(username.eq(&uname))
            .limit(1)
            .first::<Customer>(&conn)
            .expect("Couldn't connect to DB");
        let current_entry = cart_items
            .filter(cart_id.eq(selected_user.id))
            .filter(product_id.eq(item_details))
            .limit(1)
            .first::<CartItem>(&conn);
        match current_entry {
            Ok(v) => {
                info!("Item already present in cart, increasing quantity.");
                let old_quantity = v.quantity.unwrap_or(1);
                if old_quantity == 1 {
                    diesel::delete(
                        cart_items
                            .filter(cart_id.eq(selected_user.id))
                            .filter(product_id.eq(item_details)),
                    )
                    .execute(&conn)
                    .expect("Coundn't connect to DB");
                } else {
                    diesel::update(
                        cart_items
                            .filter(cart_id.eq(selected_user.id))
                            .filter(product_id.eq(item_details)),
                    )
                    .set(quantity.eq(old_quantity - 1))
                    .execute(&conn)
                    .unwrap();
                    return HttpResponse::Ok()
                        .body("Updated quantity successfully!");
                }
                return HttpResponse::Ok()
                    .body("Updated quantity successfully!");
            }
            Err(_) => {
                info!("Item not present.");
                return HttpResponse::InternalServerError()
                    .body("Item not found!");
            }
        }
    } else {
        error!("Unauthorized add to cart action!");
        return HttpResponse::Unauthorized()
            .body("Need to be logged in to add to cart!");
    }
}

#[derive(Serialize)]
struct UserCartItem {
    product_item: Product,
    quantity: i32,
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
                let p = prod::product
                    .filter(prod::id.eq(item.product_id))
                    .limit(1)
                    .first::<Product>(&conn)
                    .expect("Couldn't connect to db");
                UserCartItem {
                    product_item: p,
                    quantity: item.quantity.unwrap_or(1),
                }
            })
            .collect::<Vec<_>>();
        return HttpResponse::Ok().json(&cart_products);
    } else {
        return HttpResponse::Unauthorized()
            .body("Need to be logged in to add to cart!");
    }
}

pub async fn get_user_cart_total(
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
        let cart_total: f32 = user_cart_items
            .into_iter()
            .map(|item| {
                let p = prod::product
                    .filter(prod::id.eq(item.product_id))
                    .limit(1)
                    .first::<Product>(&conn)
                    .expect("Couldn't connect to db");
                return p.price * item.quantity.unwrap_or(1) as f32;
            })
            .sum();
        return HttpResponse::Ok().json(&cart_total);
    } else {
        return HttpResponse::Unauthorized()
            .body("Need to be logged in to add to cart!");
    }
}

use crate::models::{AddTransaction, CartItem, Customer, Product, Transaction};
use crate::schema::cart_items::dsl::*;
use crate::schema::customer::dsl::*;
use crate::schema::product::dsl as prod;
use crate::schema::transaction::dsl::*;
use crate::TPool;

use actix_identity::Identity;
use actix_web::{web, HttpResponse, Responder};
use diesel::prelude::*;
use log::{error, info};

pub async fn checkout_cart(
    pool: web::Data<TPool>,
    pmt_kind: String,
    cookie: Identity,
) -> impl Responder {
    let conn = pool.get().unwrap();
    info!("Checkout cart for user: {:?}", cookie.identity());
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
        let cart_total = user_cart_items.into_iter().fold(0., |acc, item| {
            let item_price = prod::product
                .filter(prod::id.eq(item.product_id))
                .limit(1)
                .first::<Product>(&conn)
                .unwrap()
                .price;
            acc + item.quantity.unwrap_or(1) as f32 * item_price
        });
        let transaction_entry = AddTransaction {
            customer_id: Some(selected_user.id),
            amount: cart_total,
            payment_type: pmt_kind,
        };
        diesel::insert_into(transaction)
            .values(transaction_entry)
            .execute(&conn)
            .expect("Coundn't connect to DB");
        diesel::delete(cart_items.filter(cart_id.eq(selected_user.id)))
            .execute(&conn)
            .expect("Coundn't connect to DB");
        return HttpResponse::Ok().body("Transaction performed successfully");
    } else {
        return HttpResponse::Unauthorized().body("Login first");
    }
}

pub async fn list_transactions(
    pool: web::Data<TPool>,
    cookie: Identity,
) -> impl Responder {
    let conn = pool.get().unwrap();
    if let Some(uname) = cookie.identity() {
        let selected_user = customer
            .filter(username.eq(&uname))
            .limit(1)
            .first::<Customer>(&conn)
            .expect("Couldn't connect to DB");
        let user_transactions = transaction
            .filter(customer_id.eq(selected_user.id))
            .load::<Transaction>(&conn)
            .expect("Couldn't connect to DB");
        return HttpResponse::Ok().json(&user_transactions);
    } else {
        return HttpResponse::Unauthorized()
            .body("Need to be logged in to add to cart!");
    }
}

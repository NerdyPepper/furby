use crate::models::{NewProduct, Product};
use crate::schema::product::dsl::*;
use crate::TPool;

use actix_identity::Identity;
use actix_web::{web, HttpResponse, Responder};
use bcrypt::{hash, verify, DEFAULT_COST};
use diesel::prelude::*;
use log::{error, info};
use serde::Deserialize;

pub async fn new_product(
    pool: web::Data<TPool>,
    item: web::Json<NewProduct>,
) -> impl Responder {
    let conn = pool.get().unwrap();
    diesel::insert_into(product)
        .values(item.into_inner())
        .execute(&conn)
        .expect("Coundn't connect to DB");
    HttpResponse::Ok().body("Inserted successfully!")
}

pub async fn product_details(
    pool: web::Data<TPool>,
    product_id: web::Path<i32>,
) -> impl Responder {
    let conn = pool.get().unwrap();
    let product_id = product_id.into_inner();
    info!("Fetching product details for {}", product_id);
    let selected_product = product
        .filter(id.eq(&product_id))
        .limit(1)
        .first::<Product>(&conn);
    match selected_product {
        Ok(m) => {
            info!("Found product: {}", product_id);
            HttpResponse::Ok().json(m)
        }
        Err(_) => {
            error!("Product not found: {}", product_id);
            HttpResponse::NotFound().finish()
        }
    }
}

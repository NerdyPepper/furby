use crate::models::{NewProduct, Product, UpdateProduct};
use crate::schema::product::dsl::*;
use crate::TPool;

use actix_web::{web, HttpResponse, Responder};
use diesel::prelude::*;
use log::{error, info};
use serde::Deserialize;

pub async fn new_product(
    pool: web::Data<TPool>,
    item: web::Json<NewProduct>,
) -> impl Responder {
    info!("New product hit: {:?}", item.name);
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

pub async fn update_product(
    pool: web::Data<TPool>,
    product_id: web::Path<i32>,
    product_details: web::Json<UpdateProduct>,
) -> impl Responder {
    let conn = pool.get().unwrap();
    let product_id = product_id.into_inner();
    let product_details = product_details.into_inner();
    info!("Updating product: {:?}", product_id);
    match diesel::update(product.filter(id.eq(product_id)))
        .set((
            name.eq(product_details.name),
            kind.eq(product_details.kind),
            price.eq(product_details.price),
            description.eq(product_details.description),
        ))
        .execute(&conn)
    {
        Ok(_) => {
            return HttpResponse::Ok().body("Changed product successfully")
        }
        _ => {
            return HttpResponse::InternalServerError()
                .body("Unable to update record")
        }
    }
}

pub async fn get_all_products(pool: web::Data<TPool>) -> impl Responder {
    let conn = pool.get().unwrap();
    info!("Generating and returning catalog ...");
    match product.load::<Product>(&conn) {
        Ok(products) => {
            return HttpResponse::Ok()
                .body(serde_json::to_string(&products).unwrap())
        }
        Err(_) => {
            return HttpResponse::InternalServerError()
                .body("Unable to fetch product catalog")
        }
    }
}

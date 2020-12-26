use crate::models::{Customer, NewProduct, Product, Rating, UpdateProduct};
use crate::schema::customer::dsl as cust;
use crate::schema::product::dsl::*;
use crate::schema::rating::dsl as rating;
use crate::TPool;

use actix_web::{web, HttpResponse, Responder};
use chrono::naive::NaiveDate;
use diesel::prelude::*;
use log::{error, info};
use serde::{Deserialize, Serialize};

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

#[derive(Serialize, Debug)]
struct CatalogProduct {
    pub id: i32,
    pub name: String,
    pub kind: Option<String>,
    pub price: f32,
    pub description: Option<String>,
    pub src: Option<String>,
    pub ios_src: Option<String>,
    pub average_rating: Option<f64>,
}

pub async fn get_all_products(pool: web::Data<TPool>) -> impl Responder {
    let conn = pool.get().unwrap();
    info!("Generating and returning catalog ...");
    let product_entries = product
        .load::<Product>(&conn)
        .expect("Couldn't connect to DB");
    let with_rating_avg = product_entries
        .into_iter()
        .map(move |p| {
            let rating_list = rating::rating
                .filter(rating::product_id.eq(p.id))
                .load::<Rating>(&conn)
                .expect("Coundn't connect to DB")
                .into_iter()
                .map(|r| r.stars)
                .collect::<Vec<_>>();
            let (rating_sum, total) =
                rating_list.into_iter().fold((0, 0), |(s, t), x| match x {
                    Some(v) => (s + v, t + 1),
                    None => (s, t),
                });
            let average_rating = if total != 0 {
                Some(rating_sum as f64 / total as f64)
            } else {
                None
            };
            CatalogProduct {
                average_rating,
                name: p.name,
                kind: p.kind,
                price: p.price,
                description: p.description,
                src: p.src,
                ios_src: p.ios_src,
                id: p.id,
            }
        })
        .collect::<Vec<_>>();
    return HttpResponse::Ok().json(&with_rating_avg);
}

#[derive(Serialize, Deserialize, Debug)]
struct ProductRating {
    pub comment_text: Option<String>,
    pub comment_date: NaiveDate,
    pub product_name: String,
    pub customer_name: String,
    pub stars: Option<i32>,
}

pub async fn get_product_reviews(
    pool: web::Data<TPool>,
    product_id: web::Path<i32>,
) -> impl Responder {
    let conn = pool.get().unwrap();
    info!("Fetching product reviews for {}", product_id);
    let pid = product_id.into_inner();
    let rating_entries = rating::rating
        .filter(rating::product_id.eq(pid))
        .load::<Rating>(&conn)
        .expect("Couldn't connect to DB");
    let json_ratings = rating_entries
        .into_iter()
        .map(move |p| {
            let selected_product = product
                .filter(id.eq(&p.product_id.unwrap()))
                .limit(1)
                .first::<Product>(&conn)
                .unwrap()
                .name
                .clone();

            let selected_customer = cust::customer
                .filter(cust::id.eq(&p.customer_id.unwrap()))
                .limit(1)
                .first::<Customer>(&conn)
                .unwrap()
                .username
                .clone();

            ProductRating {
                comment_text: p.comment_text,
                comment_date: p.comment_date.unwrap(),
                product_name: selected_product,
                customer_name: selected_customer,
                stars: p.stars,
            }
        })
        .collect::<Vec<_>>();
    return HttpResponse::Ok().json(&json_ratings);
}

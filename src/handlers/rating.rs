use crate::models::{AddRating, Customer, Rating};
use crate::schema::rating::dsl as rating;
use crate::schema::{customer::dsl::*, product::dsl::*};
use crate::TPool;

use actix_identity::Identity;
use actix_web::{web, HttpResponse, Responder};
use diesel::prelude::*;
use log::{error, info};
use serde::Deserialize;

#[derive(Deserialize, Debug)]
pub struct AddRatingJson {
    pub comment_text: Option<String>,
    pub stars: Option<i32>,
    pub product_id: i32,
}

pub async fn add_rating(
    cookie: Identity,
    rating_details: web::Json<AddRatingJson>,
    pool: web::Data<TPool>,
) -> impl Responder {
    info!("Add rating hit: {:?}", rating_details.product_id);
    let conn = pool.get().unwrap();
    if let Some(uname) = cookie.identity() {
        let selected_user = customer
            .filter(username.eq(&uname))
            .limit(1)
            .first::<Customer>(&conn)
            .expect("Couldn't connect to DB");
        let rating_details = rating_details.into_inner();
        let new_rating = AddRating {
            comment_text: rating_details.comment_text,
            stars: rating_details.stars,
            product_id: rating_details.product_id,
            customer_id: selected_user.id,
        };
        diesel::insert_into(rating::rating)
            .values(new_rating)
            .execute(&conn)
            .expect("Coundn't connect to DB");
        HttpResponse::Ok().body("Inserted rating successfully!")
    } else {
        error!("Unauthorized add rating action!");
        return HttpResponse::Unauthorized()
            .body("Need to be logged in to add rating!");
    }
}

#[derive(Deserialize, Debug)]
pub struct RemoveRating {
    rating_id: i32,
}

pub async fn remove_rating(
    cookie: Identity,
    rating_details: web::Json<RemoveRating>,
    pool: web::Data<TPool>,
) -> impl Responder {
    info!("Remove rating hit: {:?}", rating_details.rating_id);
    let conn = pool.get().unwrap();
    if let Some(uname) = cookie.identity() {
        let selected_user = customer
            .filter(username.eq(&uname))
            .limit(1)
            .first::<Customer>(&conn)
            .expect("Couldn't connect to DB");

        diesel::delete(
            rating::rating
                .filter(rating::customer_id.eq(selected_user.id))
                .filter(rating::id.eq(rating_details.rating_id)),
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

// pub async fn get_product_reviews(
//     product: web::Json<GetProductReviews>,
//     pool: web::Data<TPool>,
// ) -> impl Responder {
//     unimplemented!()
// }

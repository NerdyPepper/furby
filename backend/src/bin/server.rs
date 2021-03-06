use actix_cors::Cors;
use actix_identity::{CookieIdentityPolicy, IdentityService};
use actix_web::middleware;
use actix_web::{web, App, HttpServer};
use diesel::r2d2::{ConnectionManager, Pool};
use diesel::MysqlConnection;
use furby::handlers::smoke::manual_hello;
use furby::handlers::{cart_items, product, rating, transaction, users};
use rand::Rng;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    pretty_env_logger::init();

    let db_url = env!("DATABASE_URL");
    let manager = ConnectionManager::<MysqlConnection>::new(db_url);
    let pool = Pool::builder()
        .build(manager)
        .expect("Failed to create pool.");

    let private_key = rand::thread_rng().gen::<[u8; 32]>();
    HttpServer::new(move || {
        App::new()
            .wrap(IdentityService::new(
                CookieIdentityPolicy::new(&private_key)
                    .name("user-login")
                    .domain("127.0.0.1")
                    .path("/")
                    .same_site(actix_web::cookie::SameSite::None)
                    .http_only(true)
                    .secure(false),
            ))
            .wrap(
                Cors::default()
                    .allowed_origin("http://127.0.0.1:8000")
                    .allowed_origin("http://localhost:8000")
                    .allowed_origin("https://poly.googleusercontent.com")
                    .allow_any_method()
                    .allow_any_header(),
            )
            .wrap(
                middleware::DefaultHeaders::new()
                    .header("Access-Control-Allow-Credentials", "true")
                    .header("Access-Control-Expose-Headers", "set-cookie"),
            )
            .wrap(middleware::Logger::default())
            .data(pool.clone())
            .service(
                web::scope("/user")
                    .route("/profile", web::get().to(users::user_profile))
                    .route("/existing", web::post().to(users::name_exists))
                    .route("/login", web::post().to(users::login))
                    .route("/logout", web::post().to(users::logout))
                    .route("/{uname}", web::get().to(users::user_details))
                    .route("/new", web::post().to(users::new_user))
                    .route(
                        "/change_password",
                        web::post().to(users::change_password),
                    ),
            )
            .service(
                web::scope("/product")
                    .route("/catalog", web::get().to(product::get_all_products))
                    .route("/new", web::post().to(product::new_product))
                    .route("/{id}", web::get().to(product::product_details))
                    .route(
                        "/reviews/{id}",
                        web::get().to(product::get_product_reviews),
                    )
                    .route(
                        "/update_product/{id}",
                        web::post().to(product::update_product),
                    ),
            )
            .service(
                web::scope("/cart")
                    .route(
                        "/items",
                        web::get().to(cart_items::get_user_cart_items),
                    )
                    .route(
                        "/total",
                        web::get().to(cart_items::get_user_cart_total),
                    )
                    .route("/add", web::post().to(cart_items::add_to_cart))
                    .route(
                        "/remove",
                        web::post().to(cart_items::remove_from_cart),
                    ),
            )
            .service(
                web::scope("/rating")
                    .route("/add", web::post().to(rating::add_rating))
                    .route("/remove", web::post().to(rating::remove_rating)),
            )
            .service(
                web::scope("/transaction")
                    .route(
                        "/checkout",
                        web::post().to(transaction::checkout_cart),
                    )
                    .route(
                        "/list",
                        web::get().to(transaction::list_transactions),
                    ),
            )
            .route("/hey", web::get().to(manual_hello))
    })
    .bind("127.0.0.1:7878")?
    .run()
    .await
}

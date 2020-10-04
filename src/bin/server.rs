use actix_cors::Cors;
use actix_identity::{CookieIdentityPolicy, IdentityService};
use actix_web::middleware;
use actix_web::{web, App, HttpServer};
use diesel::r2d2::{ConnectionManager, Pool};
use diesel::MysqlConnection;
use furby::handlers::smoke::manual_hello;
use furby::handlers::users;
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
                    .secure(false),
            ))
            .wrap(Cors::new().supports_credentials().finish())
            .wrap(middleware::Logger::default())
            .data(pool.clone())
            .service(
                web::scope("/user")
                    .route("/existing", web::post().to(users::name_exists))
                    .route("/login", web::post().to(users::login))
                    .route("/{uname}", web::get().to(users::user_details))
                    .route("/new", web::post().to(users::new_user)),
            )
            .route("/hey", web::get().to(manual_hello))
    })
    .bind("127.0.0.1:7878")?
    .run()
    .await
}

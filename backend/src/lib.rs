#[macro_use]
extern crate diesel;

pub mod handlers;
pub mod models;
pub mod schema;

use diesel::r2d2::{self, ConnectionManager};
use diesel::MysqlConnection;
pub type TPool = r2d2::Pool<ConnectionManager<MysqlConnection>>;

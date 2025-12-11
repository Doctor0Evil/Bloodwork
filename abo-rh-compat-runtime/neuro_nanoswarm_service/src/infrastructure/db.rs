use sqlx::{postgres::PgPoolOptions, Pool, Postgres};
use std::time::Duration;

pub struct DbConfig {
    pub url: String,
    pub max_connections: u32,
    pub connect_timeout: Duration,
}

pub async fn init_pool(cfg: &DbConfig) -> Result<Pool<Postgres>, sqlx::Error> {
    PgPoolOptions::new()
        .max_connections(cfg.max_connections)
        .acquire_timeout(cfg.connect_timeout)
        .connect(&cfg.url)
        .await
}

pub async fn init_db(pool: &Pool<Postgres>) -> Result<(), sqlx::Error> {
    // Compile-time checked migrations (sqlx::migrate!).
    sqlx::migrate!("./migrations").run(pool).await?;
    Ok(())
}

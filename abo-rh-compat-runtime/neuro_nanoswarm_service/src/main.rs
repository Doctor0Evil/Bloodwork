use neuro_nanoswarm_service as svc;
use neuro_nanoswarm_service::infrastructure::db::{init_db, init_pool, DbConfig};
use sqlx::PgPool;
use std::env;
use std::sync::Arc;
use std::net::SocketAddr;

#[tokio::main]
async fn main() {
    // if DATABASE_URL is set, wire database into app
    let pool: Option<PgPool> = match env::var("DATABASE_URL") {
        Ok(url) => {
            let cfg = DbConfig {
                url,
                max_connections: 5,
                connect_timeout: std::time::Duration::from_secs(5),
            };
            let p = init_pool(&cfg).await.expect("init pool");
            init_db(&p).await.expect("run migrations");
            Some(p)
        }
        Err(_) => None,
    };

    let app = svc::app_with_db(pool);
    let addr: SocketAddr = "0.0.0.0:8080".parse().unwrap();
    println!("Listening on {}", addr);
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .expect("server error");
}

#[tokio::main]
async fn main() {
    let app = app();
    let addr: SocketAddr = "0.0.0.0:8080".parse().unwrap();
    println!("Listening on {}", addr);
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .expect("server error");
}

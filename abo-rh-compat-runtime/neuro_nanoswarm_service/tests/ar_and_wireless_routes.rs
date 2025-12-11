use axum::http::StatusCode;
use neuro_nanoswarm_service::{app_with_db, infrastructure::db::{init_db, init_pool, DbConfig}};
use sqlx::PgPool;
use std::net::SocketAddr;
use tokio::task::JoinHandle;
use std::time::Duration;
use uuid::Uuid;

async fn spawn_app_with_db() -> (String, JoinHandle<()>) {
    let url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set for integration test");
    let cfg = DbConfig { url: url.clone(), max_connections: 5, connect_timeout: Duration::from_secs(5) };
    let pool = init_pool(&cfg).await.expect("init pool");
    init_db(&pool).await.expect("migrations");

    let app = app_with_db(Some(pool));

    let listener = tokio::net::TcpListener::bind("127.0.0.1:0")
        .await
        .expect("bind");
    let addr: SocketAddr = listener.local_addr().expect("addr");
    let base_url = format!("http://{}", addr);

    let server = axum::Server::from_tcp(listener.into_std().unwrap())
        .unwrap()
        .serve(app.into_make_service());

    let handle = tokio::spawn(async move {
        server.await.expect("server error");
    });

    (base_url, handle)
}

#[tokio::test]
async fn ar_devices_endpoint_works() {
    let (base_url, _handle) = spawn_app_with_db().await;
    let client = reqwest::Client::new();

    let res = client
        .get(format!("{}/ar/devices", base_url))
        .send()
        .await
        .unwrap();

    assert_eq!(res.status(), StatusCode::OK);
}

#[tokio::test]
async fn wireless_descriptor_endpoint_works() {
    let (base_url, _handle) = spawn_app_with_db().await;
    let client = reqwest::Client::new();

    let res = client
        .get(format!("{}/wireless/lockdown/descriptor", base_url))
        .send()
        .await
        .unwrap();

    assert_eq!(res.status(), StatusCode::OK);
}

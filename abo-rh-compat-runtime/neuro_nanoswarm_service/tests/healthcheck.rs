use axum::{http::StatusCode, Router};
use std::net::SocketAddr;
use tokio::task::JoinHandle;

async fn app() -> Router {
    neuro_nanoswarm_service::app()
}

async fn spawn_app() -> (String, JoinHandle<()>) {
    let app = app().await;

    let listener = tokio::net::TcpListener::bind("127.0.0.1:0")
        .await
        .expect("failed to bind ephemeral port");

    let addr: SocketAddr = listener.local_addr().expect("failed to read local_addr");
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
async fn healthcheck_works() {
    let (base_url, _handle) = spawn_app().await;

    let client = reqwest::Client::builder()
        .pool_idle_timeout(std::time::Duration::from_secs(5))
        .build()
        .unwrap();

    let res = client
        .get(format!("{}/health", base_url))
        .send()
        .await
        .unwrap();

    assert_eq!(res.status(), StatusCode::OK);
}

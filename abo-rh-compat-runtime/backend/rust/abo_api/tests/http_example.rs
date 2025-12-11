use std::time::Duration;
use tokio::time::sleep;

#[tokio::test]
async fn example_endpoint_returns_safe_compat() {
    tokio::spawn(async {
        let _ = abo_api::run("127.0.0.1:8080").await;
    });
    sleep(Duration::from_millis(500)).await;
    let body = reqwest::get("http://127.0.0.1:8080/compatibility/example")
        .await
        .expect("request")
        .text()
        .await
        .expect("body");
    assert!(body.contains("\"class_\":\"SAFE\""));
}

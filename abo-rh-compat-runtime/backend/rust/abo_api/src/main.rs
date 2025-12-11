use abo_api::{run};

#[tokio::main]
async fn main() {
    run("0.0.0.0:8080").await.unwrap();
}

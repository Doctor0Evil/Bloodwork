use axum::{routing::get, Json, Router};
use abo_core::{ABO, Rh, BloodType, evaluate};

pub fn app() -> Router {
    Router::new().route(
        "/compatibility/example",
        get(|| async {
            let donor = BloodType { abo: ABO::O, rh: Rh::NEG };
            let recipient = BloodType { abo: ABO::AB, rh: Rh::POS };
            let res = evaluate(donor, recipient);
            Json(res)
        }),
    )
}

pub async fn run(addr_str: &str) -> Result<(), hyper::Error> {
    let addr = addr_str.parse().unwrap();
    let app = app();
    println!("ABO/Rh API listening on {}", addr_str);
    axum::Server::bind(&addr).serve(app.into_make_service()).await
}

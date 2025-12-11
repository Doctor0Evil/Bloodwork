pub mod domain;
pub mod infrastructure;
pub mod http;

pub use axum;

use axum::{routing::get, Extension, Json, Router};
use serde::Serialize;
use sqlx::PgPool;
use std::sync::Arc;

#[derive(Serialize)]
struct HealthResponse {
	status: &'static str,
	device_profile: String,
	db_latency_budget_ms: u64,
}

async fn health_handler() -> Json<HealthResponse> {
	let device_profile =
		std::env::var("DEVICE_PROFILE").unwrap_or_else(|_| "neuro_nanoswarm_v1".to_string());
	let db_latency_budget_ms = std::env::var("DB_LATENCY_BUDGET_MS")
		.ok()
		.and_then(|v| v.parse().ok())
		.unwrap_or(12);

	Json(HealthResponse {
		status: "ok",
		device_profile,
		db_latency_budget_ms,
	})
}

pub fn app_with_db(pool: Option<PgPool>) -> Router {
	let base = Router::new().route("/health", get(health_handler));
	let router = http::router();
	if let Some(p) = pool {
		let state = http::AppState { pool: Arc::new(p) };
		base.merge(router).layer(Extension(state))
	} else {
		base.merge(router)
	}
}

pub fn app() -> Router {
	app_with_db(None)
}

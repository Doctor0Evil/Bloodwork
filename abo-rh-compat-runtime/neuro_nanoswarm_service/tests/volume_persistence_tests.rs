use neuro_nanoswarm_service::infrastructure::{
    db::{init_db, init_pool, DbConfig},
    service::{plan_and_persist_volume_matrix, get_volume_matrix_for_patient},
};
use std::time::Duration;
use uuid::Uuid;

#[tokio::test]
async fn plan_and_persist_volume_matrix_succeeds() {
    let url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set for integration persistence test");

    let pool = init_pool(&DbConfig {
        url,
        max_connections: 5,
        connect_timeout: Duration::from_secs(5),
    })
    .await
    .expect("init pool");

    init_db(&pool).await.expect("run migrations");

    let patient_id = Uuid::new_v4();
    plan_and_persist_volume_matrix(&pool, patient_id, 250.0)
        .await
        .expect("plan and persist");

    get_volume_matrix_for_patient(&pool, patient_id)
        .await
        .expect("fetch persisted rows");
}

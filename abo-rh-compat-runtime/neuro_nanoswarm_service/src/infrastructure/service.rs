use crate::domain::volume::{DefaultVolumePolicy, generate_matrix_rows_with_policy, MatrixError};
use crate::infrastructure::repository::{insert_volume_rows_tx, list_volume_rows_for_patient};
use sqlx::{PgPool, Postgres, Transaction};
use uuid::Uuid;

#[derive(Debug, thiserror::Error)]
pub enum ServiceError {
    #[error("volume policy error: {0}")]
    VolumePolicy(#[from] MatrixError),
    #[error("database error: {0}")]
    Db(#[from] sqlx::Error),
}

pub async fn plan_and_persist_volume_matrix(
    pool: &PgPool,
    patient_id: Uuid,
    requested_ml: f64,
) -> Result<(), ServiceError> {
    let policy = DefaultVolumePolicy {
        max_allowed_ml: 1000.0,
        qpu_cycle_budget_ns: 250,
        compliance_tag: "GMP-CLASS-A",
    };

    let rows = generate_matrix_rows_with_policy(&policy, patient_id, requested_ml)?;

    let mut tx: Transaction<'_, Postgres> = pool.begin().await?;
    insert_volume_rows_tx(&mut tx, &rows).await?;
    tx.commit().await?;

    Ok(())
}

pub async fn get_volume_matrix_for_patient(
    pool: &PgPool,
    patient_id: Uuid,
) -> Result<(), ServiceError> {
    let rows = list_volume_rows_for_patient(pool, patient_id).await?;
    if rows.is_empty() {
        tracing::warn!(?patient_id, "no volume matrix rows found for patient");
    } else {
        tracing::info!(?patient_id, count = rows.len(), "fetched volume matrix rows");
    }
    Ok(())
}

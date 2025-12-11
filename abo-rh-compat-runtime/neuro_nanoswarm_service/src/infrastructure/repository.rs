use crate::domain::volume::VolumeMatrixRow;
use sqlx::{PgPool, Postgres, Transaction};
use uuid::Uuid;

#[derive(Debug, sqlx::FromRow)]
pub struct PatientVolumeMatrixRow {
    pub id: Uuid,
    pub patient_id: Uuid,
    pub max_volume_ml: f64,
    pub compliance_tag: String,
    pub qpu_cycle_budget_ns: i64,
}

pub async fn insert_volume_rows_tx(
    tx: &mut Transaction<'_, Postgres>,
    rows: &[VolumeMatrixRow],
) -> Result<(), sqlx::Error> {
    for row in rows {
        sqlx::query!(
            r#"
            INSERT INTO patient_volume_matrix (
                id,
                patient_id,
                max_volume_ml,
                compliance_tag,
                qpu_cycle_budget_ns
            )
            VALUES ($1, $2, $3, $4, $5)
            "#,
            row.id,
            row.patient_id,
            row.max_volume_ml,
            row.compliance_tag,
            row.qpu_cycle_budget_ns as i64
        )
        .execute(&mut *tx)
        .await?;
    }
    Ok(())
}

pub async fn list_volume_rows_for_patient(
    pool: &PgPool,
    patient_id: Uuid,
) -> Result<Vec<PatientVolumeMatrixRow>, sqlx::Error> {
    let rows = sqlx::query_as!(
        PatientVolumeMatrixRow,
        r#"
        SELECT
            id,
            patient_id,
            max_volume_ml::float8 AS max_volume_ml,
            compliance_tag,
            qpu_cycle_budget_ns
        FROM patient_volume_matrix
        WHERE patient_id = $1
        ORDER BY max_volume_ml
        "#,
        patient_id
    )
    .fetch_all(pool)
    .await?;

    Ok(rows)
}

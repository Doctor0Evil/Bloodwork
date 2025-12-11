use serde::{Serialize, Deserialize};
use uuid::Uuid;
use thiserror::Error;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VolumeMatrixRow {
    pub id: Uuid,
    pub patient_id: Uuid,
    pub max_volume_ml: f64,
    pub compliance_tag: &'static str,
    pub qpu_cycle_budget_ns: u64,
}

#[derive(Debug, Error)]
pub enum MatrixError {
    #[error("max_volume_ml must be non-negative, got {0}")]
    NegativeMaxVolume(f64),
    #[error("max_volume_ml exceeds configured ceiling")]
    AboveDeviceCeiling,
    #[error("invalid parameter: {0}")]
    InvalidParameter(&'static str),
}

pub trait VolumePolicy: Send + Sync {
    fn quantisation_factors(&self, max_volume_ml: f64) -> Result<Vec<f64>, MatrixError>;
    fn qpu_cycle_budget_ns(&self) -> u64;
    fn compliance_tag(&self) -> &'static str;
}

#[derive(Debug, Clone)]
pub struct DefaultVolumePolicy {
    pub max_allowed_ml: f64,
    pub qpu_cycle_budget_ns: u64,
    pub compliance_tag: &'static str,
}

impl VolumePolicy for DefaultVolumePolicy {
    fn quantisation_factors(&self, max_volume_ml: f64) -> Result<Vec<f64>, MatrixError> {
        if max_volume_ml.is_sign_negative() {
            return Err(MatrixError::NegativeMaxVolume(max_volume_ml));
        }
        if max_volume_ml > self.max_allowed_ml {
            return Err(MatrixError::AboveDeviceCeiling);
        }
        if max_volume_ml == 0.0 {
            return Ok(Vec::new());
        }

        Ok(vec![0.2, 0.4, 0.6, 0.8, 1.0])
    }

    fn qpu_cycle_budget_ns(&self) -> u64 {
        self.qpu_cycle_budget_ns
    }

    fn compliance_tag(&self) -> &'static str {
        self.compliance_tag
    }
}

pub fn generate_matrix_rows_with_policy<P: VolumePolicy>(
    policy: &P,
    patient_id: Uuid,
    max_volume_ml: f64,
) -> Result<Vec<VolumeMatrixRow>, MatrixError> {
    let factors = policy.quantisation_factors(max_volume_ml)?;
    let mut rows = Vec::with_capacity(factors.len());

    for frac in factors {
        let v = (max_volume_ml * frac * 1000.0).round() / 1000.0;
        rows.push(VolumeMatrixRow {
            id: Uuid::new_v4(),
            patient_id,
            max_volume_ml: v,
            compliance_tag: policy.compliance_tag(),
            qpu_cycle_budget_ns: policy.qpu_cycle_budget_ns(),
        });
    }

    Ok(rows)
}

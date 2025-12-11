use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviceFamilyProfile {
    pub id: Uuid,
    pub family_code: String,
    pub class: String,
    pub modality_tags: Vec<String>,
    pub description: String,
    pub requires_3d_reference: bool,
    pub requires_physical_phantom: bool,
    pub iso13485_relevant: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BodyTrackingCalibrationProfile {
    pub id: Uuid,
    pub family_code: String,
    pub description: String,
    pub min_markers_or_sensors: i64,
    pub max_markers_or_sensors: i64,
    pub requires_full_body_sweep: bool,
    pub requires_quiet_stance: bool,
    pub target_rms_error_mm: f64,
    pub max_allowed_rms_error_mm: f64,
    pub min_calibration_duration_s: f64,
    pub max_calibration_duration_s: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BiosenseCalibrationProfile {
    pub id: Uuid,
    pub family_code: String,
    pub description: String,
    pub min_analytes: i64,
    pub max_analytes: i64,
    pub requires_reference_controls: bool,
    pub requires_temp_compensation: bool,
    pub target_bias_pct: f64,
    pub max_allowed_bias_pct: f64,
    pub target_cv_pct: f64,
    pub max_allowed_cv_pct: f64,
    pub max_interval_days: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CalibrationLogisticsProfile {
    pub id: Uuid,
    pub facility_type: String,
    pub description: String,
    pub min_staff_trained: i64,
    pub requires_dedicated_room: bool,
    pub requires_force_plate_or_phantom: bool,
    pub requires_traceable_id: bool,
    pub requires_audit_log: bool,
}

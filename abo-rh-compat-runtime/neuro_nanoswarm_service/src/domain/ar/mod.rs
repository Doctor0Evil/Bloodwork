use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ArDeviceProfile {
    pub id: Uuid,
    pub device_code: String,
    pub class: String,
    pub usage_context: String,
    pub description: String,
    pub xr_mode: String,
    pub min_refresh_hz: f64,
    pub max_refresh_hz: f64,
    pub max_rt_latency_ms: f64,
    pub pixel_density_ppd: f64,
    pub stereo_fov_horizontal_deg: f64,
    pub stereo_fov_vertical_deg: f64,
    pub max_brightness_nits: f64,
    pub min_uplink_mbps: f64,
    pub min_downlink_mbps: f64,
    pub max_packet_loss_pct: f64,
    pub is_sterilizable: bool,
    pub sterilization_method: Option<String>,
    pub sterilization_notes: Option<String>,
    pub hexa_fingerprint_256: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ArClinicalStandard {
    pub id: Uuid,
    pub standard_code: String,
    pub use_case: String,
    pub description: String,
    pub max_spatial_error_mm: f64,
    pub max_overlay_lag_ms: f64,
    pub max_stream_latency_ms: f64,
    pub max_jitter_ms: f64,
    pub max_session_minutes: i32,
    pub requires_supervision: bool,
    pub privacy_mask_required: bool,
    pub reference_guideline: Option<String>,
}

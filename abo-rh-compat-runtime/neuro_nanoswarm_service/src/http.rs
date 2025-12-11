use axum::{routing::get, Extension, Json, Router};
use serde::Serialize;
use sqlx::PgPool;
use std::sync::Arc;

use crate::domain::ar::{ArClinicalStandard, ArDeviceProfile};
use crate::domain::cal::{
    BiosenseCalibrationProfile, BodyTrackingCalibrationProfile, CalibrationLogisticsProfile,
    DeviceFamilyProfile,
};
use crate::infrastructure::ar::repository::{
    get_ar_clinical_standard_by_code, list_ar_device_profiles,
};

#[derive(Clone)]
pub struct AppState {
    pub pool: Arc<PgPool>,
}

#[derive(Serialize)]
pub struct WirelessDescriptorResponse {
    pub registry_label: &'static str,
    pub registry_version: &'static str,
    pub compliance_tag: &'static str,
}

pub fn router() -> Router {
    Router::new()
        .route("/ar/devices", get(get_ar_devices))
        .route("/ar/standards/:code", get(get_ar_standard))
        .route(
            "/wireless/lockdown/descriptor",
            get(get_wireless_descriptor),
        )
        .route("/calibration/descriptor", get(get_calibration_descriptor))
        .route("/calibration/device-families", get(list_cal_device_families))
        .route("/calibration/bodytrack-profiles", get(list_bodytrack_profiles))
        .route("/calibration/biosense-profiles", get(list_biosense_profiles))
        .route("/calibration/logistics-profiles", get(list_logistics_profiles))
}

async fn get_ar_devices(
    Extension(state): Extension<AppState>,
) -> Result<Json<Vec<ArDeviceProfile>>, axum::http::StatusCode> {
    let devices = list_ar_device_profiles(&state.pool)
        .await
        .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(Json(devices))
}

async fn get_ar_standard(
    Extension(state): Extension<AppState>,
    axum::extract::Path(code): axum::extract::Path<String>,
) -> Result<Json<ArClinicalStandard>, axum::http::StatusCode> {
    let std = get_ar_clinical_standard_by_code(&state.pool, &code)
        .await
        .map_err(|_| axum::http::StatusCode::INTERNAL_SERVER_ERROR)?;
    match std {
        Some(s) => Ok(Json(s)),
        None => Err(axum::http::StatusCode::NOT_FOUND),
    }
}

async fn get_wireless_descriptor() -> Json<WirelessDescriptorResponse> {
    Json(WirelessDescriptorResponse {
        registry_label: "Minimal-Wireless-Safety-Lockdown-Grid",
        registry_version: "1.0.0",
        compliance_tag: "MED-IOT-BASELINE",
    })
}

use axum::Json as AxJson;

#[derive(Serialize)]
pub struct CalibrationDescriptorSummary {
    pub registry_label: &'static str,
    pub registry_version: &'static str,
    pub compliance_tag: &'static str,
}

async fn get_calibration_descriptor() -> AxJson<CalibrationDescriptorSummary> {
    AxJson(CalibrationDescriptorSummary {
        registry_label: "Minimal-BodyTrack-Biosense-Calibration-Grid",
        registry_version: "1.0.0",
        compliance_tag: "ISO13485-CAL-READY",
    })
}
// NOTE: These values align with the ALN descriptor at aln/minimal_bodytrack_biosense_calibration_v1_0_0.aln

async fn list_cal_device_families() -> AxJson<Vec<DeviceFamilyProfile>> {
    AxJson(vec![
        DeviceFamilyProfile {
            id: "11111111-1111-4111-8111-111111111111".parse().unwrap(),
            family_code: "MOCAP_OPTICAL".into(),
            class: "BODY_TRACKING".into(),
            modality_tags: vec!["optical".into(), "marker_based".into()],
            description: "Optical motion capture camera arrays for gait and biomechanics labs.".into(),
            requires_3d_reference: true,
            requires_physical_phantom: true,
            iso13485_relevant: true,
        },
        DeviceFamilyProfile {
            id: "22222222-2222-4222-8222-222222222222".parse().unwrap(),
            family_code: "IMU_BODY".into(),
            class: "BODY_TRACKING".into(),
            modality_tags: vec!["imu".into(), "wearable".into()],
            description: "Body-worn IMUs for sensor-to-segment tracking and anatomical calibration.".into(),
            requires_3d_reference: false,
            requires_physical_phantom: false,
            iso13485_relevant: true,
        },
        DeviceFamilyProfile {
            id: "33333333-3333-4333-8333-333333333333".parse().unwrap(),
            family_code: "MULTIPLEX_BIOSENSE".into(),
            class: "BIOSENSING".into(),
            modality_tags: vec!["electrochemical".into(), "optical".into(), "multi_analyte".into()],
            description: "Multiplexed biosensing platforms for multi-analyte point-of-care testing.".into(),
            requires_3d_reference: false,
            requires_physical_phantom: false,
            iso13485_relevant: true,
        },
    ])
}

async fn list_bodytrack_profiles() -> AxJson<Vec<BodyTrackingCalibrationProfile>> {
    AxJson(vec![
        BodyTrackingCalibrationProfile {
            id: "44444444-4444-4444-8444-444444444444".parse().unwrap(),
            family_code: "MOCAP_OPTICAL".into(),
            description: "Optical motion-capture volume calibration with wand grid and static reference.".into(),
            min_markers_or_sensors: 8,
            max_markers_or_sensors: 64,
            requires_full_body_sweep: true,
            requires_quiet_stance: true,
            target_rms_error_mm: 0.5,
            max_allowed_rms_error_mm: 2.0,
            min_calibration_duration_s: 30.0,
            max_calibration_duration_s: 600.0,
        },
        BodyTrackingCalibrationProfile {
            id: "55555555-5555-4555-8555-555555555555".parse().unwrap(),
            family_code: "IMU_BODY".into(),
            description: "Anatomical calibration using quiet stance and standard movement tests.".into(),
            min_markers_or_sensors: 4,
            max_markers_or_sensors: 32,
            requires_full_body_sweep: false,
            requires_quiet_stance: true,
            target_rms_error_mm: 5.0,
            max_allowed_rms_error_mm: 10.0,
            min_calibration_duration_s: 60.0,
            max_calibration_duration_s: 900.0,
        },
    ])
}

async fn list_biosense_profiles() -> AxJson<Vec<BiosenseCalibrationProfile>> {
    AxJson(vec![BiosenseCalibrationProfile {
        id: "66666666-6666-4666-8666-666666666666".parse().unwrap(),
        family_code: "MULTIPLEX_BIOSENSE".into(),
        description: "Multi-analyte biosensing calibration using traceable controls and temperature-compensated curves.".into(),
        min_analytes: 2,
        max_analytes: 16,
        requires_reference_controls: true,
        requires_temp_compensation: true,
        target_bias_pct: 3.0,
        max_allowed_bias_pct: 5.0,
        target_cv_pct: 5.0,
        max_allowed_cv_pct: 10.0,
        max_interval_days: 365,
    }])
}

async fn list_logistics_profiles() -> AxJson<Vec<CalibrationLogisticsProfile>> {
    AxJson(vec![
        CalibrationLogisticsProfile {
            id: "77777777-7777-4777-8777-777777777777".parse().unwrap(),
            facility_type: "HOSPITAL".into(),
            description: "Hospital gait lab and scanner calibration logistics.".into(),
            min_staff_trained: 2,
            requires_dedicated_room: true,
            requires_force_plate_or_phantom: true,
            requires_traceable_id: true,
            requires_audit_log: true,
        },
        CalibrationLogisticsProfile {
            id: "88888888-8888-4888-8888-888888888888".parse().unwrap(),
            facility_type: "LAB".into(),
            description: "Research lab body-tracking and biosensor calibration logistics.".into(),
            min_staff_trained: 1,
            requires_dedicated_room: false,
            requires_force_plate_or_phantom: false,
            requires_traceable_id: true,
            requires_audit_log: true,
        },
    ])
}

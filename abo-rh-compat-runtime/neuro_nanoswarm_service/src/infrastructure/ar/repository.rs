use crate::domain::ar::{ArClinicalStandard, ArDeviceProfile};
use sqlx::PgPool;

pub async fn list_ar_device_profiles(pool: &PgPool) -> Result<Vec<ArDeviceProfile>, sqlx::Error> {
    let rows = sqlx::query!(
        r#"
        SELECT
            id,
            device_code,
            class,
            usage_context,
            description,
            xr_mode,
            min_refresh_hz::float8 as min_refresh_hz,
            max_refresh_hz::float8 as max_refresh_hz,
            max_rt_latency_ms::float8 as max_rt_latency_ms,
            pixel_density_ppd::float8 as pixel_density_ppd,
            stereo_fov_horizontal_deg::float8 as stereo_fov_horizontal_deg,
            stereo_fov_vertical_deg::float8 as stereo_fov_vertical_deg,
            max_brightness_nits::float8 as max_brightness_nits,
            min_uplink_mbps::float8 as min_uplink_mbps,
            min_downlink_mbps::float8 as min_downlink_mbps,
            max_packet_loss_pct::float8 as max_packet_loss_pct,
            is_sterilizable,
            sterilization_method,
            sterilization_notes,
            hexa_fingerprint_256
        FROM ar_device_profile
        ORDER BY device_code
        "#
    )
    .fetch_all(pool)
    .await?;

    Ok(rows
        .into_iter()
        .map(|r| ArDeviceProfile {
            id: r.id,
            device_code: r.device_code,
            class: r.class,
            usage_context: r.usage_context,
            description: r.description,
            xr_mode: r.xr_mode,
            min_refresh_hz: r.min_refresh_hz,
            max_refresh_hz: r.max_refresh_hz,
            max_rt_latency_ms: r.max_rt_latency_ms,
            pixel_density_ppd: r.pixel_density_ppd,
            stereo_fov_horizontal_deg: r.stereo_fov_horizontal_deg,
            stereo_fov_vertical_deg: r.stereo_fov_vertical_deg,
            max_brightness_nits: r.max_brightness_nits,
            min_uplink_mbps: r.min_uplink_mbps,
            min_downlink_mbps: r.min_downlink_mbps,
            max_packet_loss_pct: r.max_packet_loss_pct,
            is_sterilizable: r.is_sterilizable,
            sterilization_method: r.sterilization_method,
            sterilization_notes: r.sterilization_notes,
            hexa_fingerprint_256: r.hexa_fingerprint_256,
        })
        .collect())
}

pub async fn get_ar_clinical_standard_by_code(
    pool: &PgPool,
    standard_code: &str,
) -> Result<Option<ArClinicalStandard>, sqlx::Error> {
    let row = sqlx::query!(
        r#"
        SELECT
            id,
            standard_code,
            use_case,
            description,
            max_spatial_error_mm::float8 as max_spatial_error_mm,
            max_overlay_lag_ms::float8 as max_overlay_lag_ms,
            max_stream_latency_ms::float8 as max_stream_latency_ms,
            max_jitter_ms::float8 as max_jitter_ms,
            max_session_minutes,
            requires_supervision,
            privacy_mask_required,
            reference_guideline
        FROM ar_clinical_standard
        WHERE standard_code = $1
        "#,
        standard_code
    )
    .fetch_optional(pool)
    .await?;

    Ok(row.map(|r| ArClinicalStandard {
        id: r.id,
        standard_code: r.standard_code,
        use_case: r.use_case,
        description: r.description,
        max_spatial_error_mm: r.max_spatial_error_mm,
        max_overlay_lag_ms: r.max_overlay_lag_ms,
        max_stream_latency_ms: r.max_stream_latency_ms,
        max_jitter_ms: r.max_jitter_ms,
        max_session_minutes: r.max_session_minutes,
        requires_supervision: r.requires_supervision,
        privacy_mask_required: r.privacy_mask_required,
        reference_guideline: r.reference_guideline,
    }))
}

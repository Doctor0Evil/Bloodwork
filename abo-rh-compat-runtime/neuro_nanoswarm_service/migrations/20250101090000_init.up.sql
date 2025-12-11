CREATE TABLE patient_volume_matrix (
    id                      UUID            PRIMARY KEY,
    patient_id              UUID            NOT NULL,
    max_volume_ml           NUMERIC(10,3)   NOT NULL CHECK (max_volume_ml >= 0),
    compliance_tag          VARCHAR(64)     NOT NULL DEFAULT 'GMP-CLASS-A',
    qpu_cycle_budget_ns     BIGINT          NOT NULL DEFAULT 250,
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_patient_volume_matrix_patient_id
    ON patient_volume_matrix (patient_id);

CREATE TABLE device_telemetry_profile (
    id                      UUID            PRIMARY KEY,
    device_profile          VARCHAR(64)     NOT NULL,
    max_ops_tops            NUMERIC(10,3)   NOT NULL CHECK (max_ops_tops >= 0),
    thermal_envelope_w      NUMERIC(10,3)   NOT NULL CHECK (thermal_envelope_w >= 0),
    hexa_fingerprint        CHAR(64)        NOT NULL,
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_device_telemetry_profile_device_profile
    ON device_telemetry_profile (device_profile);

-- =====================================================================
-- Clinical AR Grid Module for OR / Imaging
-- =====================================================================

CREATE TABLE ar_device_profile (
    id                          UUID            PRIMARY KEY,
    device_code                 VARCHAR(64)     NOT NULL UNIQUE,
    class                       VARCHAR(32)     NOT NULL CHECK (class IN (
                                        'HEADSET',
                                        'WALL_DISPLAY',
                                        'TABLET')),
    usage_context               VARCHAR(32)     NOT NULL CHECK (usage_context IN (
                                        'OR',
                                        'ICU',
                                        'WARD',
                                        'EDU')),
    description                 VARCHAR(512)    NOT NULL,
    xr_mode                     VARCHAR(8)      NOT NULL CHECK (xr_mode IN ('AR','VR','MR')),
    min_refresh_hz              NUMERIC(6,2)    NOT NULL CHECK (min_refresh_hz > 0),
    max_refresh_hz              NUMERIC(6,2)    NOT NULL CHECK (max_refresh_hz >= min_refresh_hz),
    max_rt_latency_ms           NUMERIC(7,3)    NOT NULL CHECK (max_rt_latency_ms > 0),
    pixel_density_ppd           NUMERIC(6,2)    NOT NULL CHECK (pixel_density_ppd > 0),
    stereo_fov_horizontal_deg   NUMERIC(6,2)    NOT NULL,
    stereo_fov_vertical_deg     NUMERIC(6,2)    NOT NULL,
    max_brightness_nits         NUMERIC(8,2)    NOT NULL CHECK (max_brightness_nits > 0),
    min_uplink_mbps             NUMERIC(8,2)    NOT NULL CHECK (min_uplink_mbps >= 0),
    min_downlink_mbps           NUMERIC(8,2)    NOT NULL CHECK (min_downlink_mbps >= 0),
    max_packet_loss_pct         NUMERIC(4,2)    NOT NULL CHECK (max_packet_loss_pct BETWEEN 0 AND 100),
    is_sterilizable             BOOLEAN         NOT NULL DEFAULT FALSE,
    sterilization_method        VARCHAR(64),
    sterilization_notes         VARCHAR(512),
    hexa_fingerprint_256        CHAR(64)        NOT NULL,
    created_at_utc              TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

INSERT INTO ar_device_profile (
    id, device_code, class, usage_context, description,
    xr_mode, min_refresh_hz, max_refresh_hz, max_rt_latency_ms,
    pixel_density_ppd, stereo_fov_horizontal_deg, stereo_fov_vertical_deg,
    max_brightness_nits, min_uplink_mbps, min_downlink_mbps,
    max_packet_loss_pct, is_sterilizable, sterilization_method,
    sterilization_notes, hexa_fingerprint_256
) VALUES
    ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa001',
     'ar_or_overlay_hud_v1',
     'HEADSET',
     'OR',
     'Optical see-through AR headset for intra-operative overlays.',
     'AR',
     72.00, 120.00, 50.000,
     22.00, 90.00, 60.00,
     1000.00, 50.00, 100.00,
     0.50, TRUE, 'wipe',
     'Non-porous housing; alcohol-based OR wipe protocol.',
     'AB12CD34EF56AB78CD90EF12AB34CD56EF7890AB12CD34EF56AB78CD90EF12AB'),
    ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa002',
     'vr_preop_planning_rig_v1',
     'HEADSET',
     'EDU',
     'Room-scale VR rig for pre-operative planning and rehearsal.',
     'VR',
     90.00, 144.00, 100.000,
     20.00, 110.00, 90.00,
     200.00, 20.00, 50.00,
     1.00, FALSE, NULL,
     'Not for sterile field; external planning room use only.',
     'CD34EF56AB78CD90EF12AB34CD56EF7890AB12CD34EF56AB78CD90EF12AB34CD');

CREATE TABLE ar_clinical_standard (
    id                          UUID            PRIMARY KEY,
    standard_code               VARCHAR(64)     NOT NULL UNIQUE,
    use_case                    VARCHAR(64)     NOT NULL CHECK (use_case IN (
                                        'SURGICAL_GUIDANCE',
                                        'PREOP_PLANNING',
                                        'EDUCATION',
                                        'WARD_SUPPORT')),
    description                 VARCHAR(512)    NOT NULL,
    max_spatial_error_mm        NUMERIC(7,3)    NOT NULL CHECK (max_spatial_error_mm > 0),
    max_overlay_lag_ms          NUMERIC(7,3)    NOT NULL CHECK (max_overlay_lag_ms > 0),
    max_stream_latency_ms       NUMERIC(7,3)    NOT NULL CHECK (max_stream_latency_ms > 0),
    max_jitter_ms               NUMERIC(7,3)    NOT NULL CHECK (max_jitter_ms >= 0),
    max_session_minutes         INT             NOT NULL CHECK (max_session_minutes > 0),
    requires_supervision        BOOLEAN         NOT NULL,
    privacy_mask_required       BOOLEAN         NOT NULL,
    reference_guideline         VARCHAR(256),
    created_at_utc              TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

INSERT INTO ar_clinical_standard (
    id, standard_code, use_case, description,
    max_spatial_error_mm, max_overlay_lag_ms,
    max_stream_latency_ms, max_jitter_ms,
    max_session_minutes, requires_supervision,
    privacy_mask_required, reference_guideline
) VALUES
    ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb001',
     'std_or_surgical_guidance_v1',
     'SURGICAL_GUIDANCE',
     'AR overlays for intra-operative guidance with sub-centimeter spatial accuracy and low latency.',
     2.000, 20.000,
     100.000, 10.000,
     240, TRUE,
     TRUE, 'Regulatory and internal OR XR guidance'),
    ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb002',
     'std_preop_planning_v1',
     'PREOP_PLANNING',
     'VR/AR-based pre-operative planning and rehearsal using fused imaging data.',
     2.000, 40.000,
     150.000, 15.000,
     90, FALSE,
     TRUE, 'Clinical XR deployment recommendations for planning suites');

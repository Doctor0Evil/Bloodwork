-- ============================================================================
-- BCI / EEG / MCI / Neuromorphic Signal Governance & Safety Monitoring
-- No nanoswarm references; public-safe, clinically grounded
-- ============================================================================

-- Device operating modes (e.g., clinical EEG, VR-BCI, rehab training)
CREATE TABLE IF NOT EXISTS bci_operating_mode (
    mode_code           VARCHAR(16) PRIMARY KEY,
    description         VARCHAR(128) NOT NULL,
    clinical_context    VARCHAR(64)  NOT NULL,    -- e.g. 'ICU EEG','home-BCI','VR-lab'
    iec60601_profile    VARCHAR(64)  NOT NULL,    -- text tag for applicable 60601/80601 profile
    max_session_minutes INTEGER      NOT NULL CHECK (max_session_minutes BETWEEN 1 AND 480)
);

INSERT INTO bci_operating_mode (mode_code, description, clinical_context, iec60601_profile, max_session_minutes)
VALUES
('EEG_CLIN', 'Clinical diagnostic EEG (awake/sleep)', 'hospital-neurophysiology', 'IEC 60601-2-26 / IEC 80601-2-26', 120),
('EEG_VR',   'Immersive VR-BCI interaction',          'research-lab',             'IEC 60601-1 + EMC 1-2',          90),
('MOTOR_REH','Motor-imagery rehab BCI',               'rehabilitation-centre',    'IEC 60601-1-11 home-care',      60),
('HCI_HMD',  'Mixed-reality HMD biosensing',          'home/office',              'IEC 60601-1-11 + 1-2',          180)
ON CONFLICT (mode_code) DO NOTHING;

-- Reference of devices to modes with guardrails
CREATE TABLE IF NOT EXISTS bci_device_mode_profile (
    profile_id          UUID PRIMARY KEY,
    device_id           UUID NOT NULL,
    mode_code           VARCHAR(16) REFERENCES bci_operating_mode(mode_code),
    max_sampling_hz     INTEGER NOT NULL CHECK (max_sampling_hz BETWEEN 100 AND 10000),
    max_output_current_ma NUMERIC(5,2) NOT NULL CHECK (max_output_current_ma <= 5.00),
    max_output_voltage_v NUMERIC(5,2) NOT NULL CHECK (max_output_voltage_v <= 50.00),
    duty_cycle_percent  NUMERIC(5,2) NOT NULL CHECK (duty_cycle_percent BETWEEN 0 AND 100),
    UNIQUE (device_id, mode_code)
);

-- Signal-quality metrics per recording segment (aggregated, non-identifying)
CREATE TABLE IF NOT EXISTS bci_segment_quality (
    quality_id          UUID PRIMARY KEY,
    device_id           UUID NOT NULL,
    mode_code           VARCHAR(16) REFERENCES bci_operating_mode(mode_code),
    sampling_hz         INTEGER NOT NULL,
    channel_count       SMALLINT NOT NULL,
    duration_seconds    INTEGER NOT NULL CHECK (duration_seconds > 0),
    band_snr_db         DOUBLE PRECISION[5] NOT NULL,  -- [delta,theta,alpha,beta,gamma]
    artifact_ratio_4    DOUBLE PRECISION[4] NOT NULL,  -- [blink,emg,drift,line] 0-1
    peak_to_peak_uv     DOUBLE PRECISION NOT NULL,
    noise_floor_uv_rms  DOUBLE PRECISION NOT NULL,
    clipping_fraction   DOUBLE PRECISION NOT NULL CHECK (clipping_fraction BETWEEN 0 AND 1),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Filled example quality vector reflecting realistic BCI ranges
INSERT INTO bci_segment_quality (
    quality_id, device_id, mode_code, sampling_hz, channel_count,
    duration_seconds, band_snr_db, artifact_ratio_4, peak_to_peak_uv,
    noise_floor_uv_rms, clipping_fraction
) VALUES (
    '11111111-aaaa-4aaa-8aaa-bbbbbbbbbbbb',
    'dddddddd-dddd-4ddd-8ddd-ddddddddddd4',
    'EEG_VR',
    1000,
    32,
    300,
    ARRAY[18.5, 20.2, 22.7, 19.4, 15.8]::DOUBLE PRECISION[],   -- SNR dB per band[web:17][web:20]
    ARRAY[0.05, 0.08, 0.03, 0.02]::DOUBLE PRECISION[],         -- 5–8 % blink/EMG artifacts, etc.
    120.0,
    0.650,
    0.004
)
ON CONFLICT (quality_id) DO NOTHING;

-- Neuromorphic co-processor thermal and power telemetry envelope
CREATE TABLE IF NOT EXISTS neuromorphic_telemetry_profile (
    telemetry_id        UUID PRIMARY KEY,
    device_id           UUID NOT NULL,
    max_junction_temp_c NUMERIC(5,1) NOT NULL CHECK (max_junction_temp_c <= 85.0),
    typical_junction_temp_c NUMERIC(5,1) NOT NULL,
    power_max_w         NUMERIC(6,2) NOT NULL,
    power_typ_w         NUMERIC(6,2) NOT NULL,
    hotspot_density_w_mm2 NUMERIC(6,3) NOT NULL,  -- peak local power density[web:18][web:21]
    thermal_stability_vector_6 DOUBLE PRECISION[6] NOT NULL, -- [idle,low,med,high,burst,safety]
    cooling_strategy    VARCHAR(64) NOT NULL      -- e.g. 'passive-fin + TIM'
);

INSERT INTO neuromorphic_telemetry_profile (
    telemetry_id, device_id, max_junction_temp_c, typical_junction_temp_c,
    power_max_w, power_typ_w, hotspot_density_w_mm2,
    thermal_stability_vector_6, cooling_strategy
) VALUES (
    '22222222-bbbb-4bbb-8bbb-cccccccccccc',
    'dddddddd-dddd-4ddd-8ddd-ddddddddddd4',
    75.0,
    52.5,
    6.50,
    3.20,
    0.480,
    ARRAY[0.99,0.98,0.97,0.96,0.95,0.97]::DOUBLE PRECISION[],
    'passive-fin + high-conductivity TIM'
)
ON CONFLICT (telemetry_id) DO NOTHING;

-- Governance: safe operating thresholds per mode and hardware telemetry
CREATE TABLE IF NOT EXISTS bci_governance_thresholds (
    threshold_id        UUID PRIMARY KEY,
    mode_code           VARCHAR(16) REFERENCES bci_operating_mode(mode_code),
    min_band_snr_db     DOUBLE PRECISION[5] NOT NULL,  -- minimum acceptable per band
    max_artifact_ratio  DOUBLE PRECISION NOT NULL,     -- max of any artifact component
    max_noise_floor_uv_rms DOUBLE PRECISION NOT NULL,
    max_clipping_fraction DOUBLE PRECISION NOT NULL,
    max_junction_temp_c NUMERIC(5,1) NOT NULL,
    max_hotspot_density_w_mm2 NUMERIC(6,3) NOT NULL
);

INSERT INTO bci_governance_thresholds (
    threshold_id, mode_code, min_band_snr_db, max_artifact_ratio,
    max_noise_floor_uv_rms, max_clipping_fraction,
    max_junction_temp_c, max_hotspot_density_w_mm2
) VALUES
(
    '33333333-cccc-4ccc-8ccc-dddddddddddd',
    'EEG_VR',
    ARRAY[10.0, 12.0, 15.0, 10.0, 8.0]::DOUBLE PRECISION[],
    0.20,
    1.000,
    0.010,
    80.0,
    0.800
),
(
    '44444444-dddd-4ddd-8ddd-eeeeeeeeeeee',
    'EEG_CLIN',
    ARRAY[8.0, 10.0, 12.0, 10.0, 6.0]::DOUBLE PRECISION[],
    0.30,
    1.000,
    0.020,
    80.0,
    1.000
)
ON CONFLICT (threshold_id) DO NOTHING;

-- Hex-encoded integrity tokens for public, non-secret configuration sets
CREATE TABLE IF NOT EXISTS bci_config_token (
    token_id            UUID PRIMARY KEY,
    device_id           UUID NOT NULL,
    mode_code           VARCHAR(16) REFERENCES bci_operating_mode(mode_code),
    config_sha256_hex   CHAR(64) NOT NULL,
    qc_crc32_hex        CHAR(8)  NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO bci_config_token (
    token_id, device_id, mode_code, config_sha256_hex, qc_crc32_hex
) VALUES (
    '55555555-eeee-4eee-8eee-ffffffffffff',
    'dddddddd-dddd-4ddd-8ddd-ddddddddddd4',
    'EEG_VR',
    '9F2C47A1D5E8B3C0A4F7D9E2B6C1A8E3D4F0C9B7A2E5D1C3F8B0A6D2E4C7F9',
    '7A3F9C1B'
)
ON CONFLICT (token_id) DO NOTHING;

-- ============================================================================
-- Validation function: joint signal-quality + telemetry governance
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_bci_session (
    p_quality_id        UUID,
    p_telemetry_id      UUID
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    q       bci_segment_quality;
    t       neuromorphic_telemetry_profile;
    g       bci_governance_thresholds;
    snr_ok  BOOLEAN;
    art_ok  BOOLEAN;
    noise_ok BOOLEAN;
    clip_ok BOOLEAN;
    therm_ok BOOLEAN;
    hot_ok BOOLEAN;
    snr_min DOUBLE PRECISION;
    art_max DOUBLE PRECISION;
BEGIN
    SELECT * INTO q FROM bci_segment_quality WHERE quality_id = p_quality_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('validation_status', FALSE,
                                  'system_metrics', jsonb_build_object('error', 'quality_not_found'));
    END IF;

    SELECT * INTO t FROM neuromorphic_telemetry_profile WHERE telemetry_id = p_telemetry_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('validation_status', FALSE,
                                  'system_metrics', jsonb_build_object('error', 'telemetry_not_found'));
    END IF;

    SELECT * INTO g FROM bci_governance_thresholds WHERE mode_code = q.mode_code;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('validation_status', FALSE,
                                  'system_metrics', jsonb_build_object('error', 'thresholds_not_found'));
    END IF;

    -- minimum SNR across 5 bands vs thresholds
    SELECT MIN(q_band - g_band)
    INTO snr_min
    FROM unnest(q.band_snr_db) WITH ORDINALITY AS qv(q_band, idx)
    JOIN unnest(g.min_band_snr_db) WITH ORDINALITY AS gv(g_band, gidx)
      ON qv.idx = gv.gidx;

    snr_ok := (snr_min >= 0);

    -- max artifact component
    SELECT MAX(val) INTO art_max
    FROM unnest(q.artifact_ratio_4) AS val;
    art_ok := (art_max <= g.max_artifact_ratio);

    noise_ok := (q.noise_floor_uv_rms <= g.max_noise_floor_uv_rms);
    clip_ok  := (q.clipping_fraction <= g.max_clipping_fraction);
    therm_ok := (t.max_junction_temp_c <= g.max_junction_temp_c);

    -- max hotspot density from telemetry vector vs threshold
    PERFORM 1; -- placeholder
    hot_ok := (t.hotspot_density_w_mm2 <= g.max_hotspot_density_w_mm2);

    RETURN jsonb_build_object(
        'validation_status', (snr_ok AND art_ok AND noise_ok AND clip_ok AND therm_ok AND hot_ok),
        'system_metrics', jsonb_build_object(
            'mode_code', q.mode_code,
            'snr_margin_db_min', snr_min,
            'artifact_ratio_max', art_max,
            'noise_floor_uv_rms', q.noise_floor_uv_rms,
            'clipping_fraction', q.clipping_fraction,
            'max_junction_temp_c', t.max_junction_temp_c,
            'hotspot_density_w_mm2', t.hotspot_density_w_mm2
        )
    );
END;
$$;

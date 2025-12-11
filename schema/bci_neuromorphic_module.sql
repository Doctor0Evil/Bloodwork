-- ============================================================================
-- BCI / EEG / MCI / Neuromorphic Hardware Core Schema
-- Production-grade, non-device-identifying, safe-for-public display
-- ============================================================================

-- Vendor-neutral enumeration of supported interface classes
CREATE TABLE IF NOT EXISTS bci_device_class (
    class_code          VARCHAR(16) PRIMARY KEY,
    description         VARCHAR(128) NOT NULL,
    iso14708_role       VARCHAR(64)  NOT NULL,
    iec60601_part       VARCHAR(32)  NOT NULL,
    max_channels        SMALLINT     NOT NULL CHECK (max_channels > 0),
    typical_sampling_hz INTEGER      NOT NULL CHECK (typical_sampling_hz > 0)
);

INSERT INTO bci_device_class (class_code, description, iso14708_role, iec60601_part, max_channels, typical_sampling_hz)
VALUES
('EEG_CAP',   'Scalp multi-channel EEG/BCI headset',         'neurostimulator (non-implant)',  'IEC 60601-2-26', 64, 1000),
('IMPLANT_E', 'Intracranial electrocorticography array',     'implantable neurostimulator',    'IEC 60601-2-40', 256, 2000),
('MCI_HMD',   'Mixed-reality HMD with integrated bio-sensors','visual stimulation + sensing',   'IEC 60601-1',    32, 500),
('NEURO_CHIP','Neuromorphic ASIC interfaced to cortex proxy','signal processing coprocessor',  'IEC 60601-1',    4096, 10000)
ON CONFLICT (class_code) DO NOTHING;

-- Core device registry (no serial numbers or PHI)
CREATE TABLE IF NOT EXISTS bci_device (
    device_id               UUID PRIMARY KEY,
    class_code              VARCHAR(16) REFERENCES bci_device_class(class_code),
    model_code              VARCHAR(32) NOT NULL,
    firmware_hex_id         CHAR(64)    NOT NULL, -- SHA-256 hex of public firmware image
    safety_profile_id       UUID        NOT NULL,
    eeg_channel_count       SMALLINT    NOT NULL CHECK (eeg_channel_count >= 0),
    emg_channel_count       SMALLINT    NOT NULL CHECK (emg_channel_count >= 0),
    eog_channel_count       SMALLINT    NOT NULL CHECK (eog_channel_count >= 0),
    ppg_channel_count       SMALLINT    NOT NULL CHECK (ppg_channel_count >= 0),
    eda_channel_count       SMALLINT    NOT NULL CHECK (eda_channel_count >= 0),
    adc_resolution_bits     SMALLINT    NOT NULL CHECK (adc_resolution_bits IN (16, 18, 24)),
    reference_scheme        VARCHAR(32) NOT NULL, -- e.g. "common-average", "linked-ears"
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Safety envelope for tissue, power, EM exposure and SAR
CREATE TABLE IF NOT EXISTS bci_safety_profile (
    safety_profile_id       UUID PRIMARY KEY,
    profile_name            VARCHAR(64)  NOT NULL,
    tissue_temp_max_c       NUMERIC(4,1) NOT NULL CHECK (tissue_temp_max_c BETWEEN 35.0 AND 41.0),
    power_density_max_mw_cm2 NUMERIC(6,2) NOT NULL CHECK (power_density_max_mw_cm2 <= 100.00),
    em_exposure_max_v_m     NUMERIC(6,2) NOT NULL CHECK (em_exposure_max_v_m <= 61.00),
    whole_body_sar_w_kg     NUMERIC(4,2) NOT NULL CHECK (whole_body_sar_w_kg <= 2.00),
    head_sar_w_kg           NUMERIC(4,2) NOT NULL CHECK (head_sar_w_kg <= 3.20),
    iso10993_passed         BOOLEAN      NOT NULL,
    biocompatibility_4x4    DOUBLE PRECISION[4][4] NOT NULL    -- fully filled matrix 0.0–1.0
);

INSERT INTO bci_safety_profile (
    safety_profile_id, profile_name, tissue_temp_max_c,
    power_density_max_mw_cm2, em_exposure_max_v_m,
    whole_body_sar_w_kg, head_sar_w_kg, iso10993_passed, biocompatibility_4x4
)
VALUES
(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
    'non-invasive scalp EEG',
    38.5,
    20.00,
    20.00,
    0.40,
    0.80,
    TRUE,
    ARRAY[
        [0.98, 0.97, 0.96, 0.95],
        [0.97, 0.98, 0.96, 0.95],
        [0.96, 0.96, 0.99, 0.97],
        [0.95, 0.95, 0.97, 0.99]
    ]::DOUBLE PRECISION[]
),
(
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',
    'intracranial ECoG',
    39.0,
    30.00,
    20.00,
    0.80,
    1.60,
    TRUE,
    ARRAY[
        [0.99, 0.98, 0.97, 0.96],
        [0.98, 0.99, 0.97, 0.96],
        [0.97, 0.97, 0.99, 0.98],
        [0.96, 0.96, 0.98, 0.99]
    ]::DOUBLE PRECISION[]
),
(
    'cccccccc-cccc-4ccc-8ccc-ccccccccccc3',
    'mixed-reality HMD biosensing',
    38.0,
    10.00,
    10.00,
    0.20,
    0.40,
    TRUE,
    ARRAY[
        [0.97, 0.96, 0.95, 0.94],
        [0.96, 0.97, 0.95, 0.94],
        [0.95, 0.95, 0.98, 0.96],
        [0.94, 0.94, 0.96, 0.98]
    ]::DOUBLE PRECISION[]
)
ON CONFLICT (safety_profile_id) DO NOTHING;

-- Public, non-identifying channel layout and gains
CREATE TABLE IF NOT EXISTS bci_channel_layout (
    layout_id           UUID PRIMARY KEY,
    device_id           UUID REFERENCES bci_device(device_id),
    channel_index       SMALLINT    NOT NULL,
    signal_modality     VARCHAR(8)  NOT NULL,      -- 'EEG','EMG','EOG','PPG','EDA'
    label_10_20         VARCHAR(16) NOT NULL,      -- e.g. 'Fz','C3','Fp1'
    anatomical_region   VARCHAR(64) NOT NULL,      -- e.g. 'frontal midline'
    gain_db             NUMERIC(5,2) NOT NULL,     -- per-channel analog gain
    highpass_hz         NUMERIC(6,2) NOT NULL,
    lowpass_hz          NUMERIC(6,2) NOT NULL,
    notch_hz            NUMERIC(6,2) NOT NULL,
    CONSTRAINT bci_channel_layout_unique UNIQUE (device_id, channel_index)
);

-- Example EEG layout: 8 scalp channels (Fz, Cz, Pz, Oz, F3, F4, C3, C4)
INSERT INTO bci_device (
    device_id, class_code, model_code, firmware_hex_id, safety_profile_id,
    eeg_channel_count, emg_channel_count, eog_channel_count,
    ppg_channel_count, eda_channel_count, adc_resolution_bits, reference_scheme
) VALUES (
    'dddddddd-dddd-4ddd-8ddd-ddddddddddd4',
    'EEG_CAP',
    'EEG-MR-32A',
    'A3F17C9B2E6D4A1189BC55EF3470C9D10A2F4E6C1B8D9E0F3A5C7B2D4F9A1C3',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
    32,
    0,
    2,
    1,
    1,
    24,
    'common-average'
)
ON CONFLICT (device_id) DO NOTHING;

INSERT INTO bci_channel_layout (
    layout_id, device_id, channel_index, signal_modality,
    label_10_20, anatomical_region, gain_db, highpass_hz, lowpass_hz, notch_hz
) VALUES
('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1','dddddddd-dddd-4ddd-8ddd-ddddddddddd4',0,'EEG','Fz','frontal midline',24.00,0.10,100.00,50.00),
('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee2','dddddddd-dddd-4ddd-8ddd-ddddddddddd4',1,'EEG','Cz','central midline',24.00,0.10,100.00,50.00),
('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee3','dddddddd-dddd-4ddd-8ddd-ddddddddddd4',2,'EEG','Pz','parietal midline',24.00,0.10,100.00,50.00),
('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee4','dddddddd-dddd-4ddd-8ddd-ddddddddddd4',3,'EEG','Oz','occipital midline',24.00,0.10,100.00,50.00),
('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee5','dddddddd-dddd-4ddd-8ddd-ddddddddddd4',4,'EEG','F3','left frontal',24.00,0.10,100.00,50.00),
('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee6','dddddddd-dddd-4ddd-8eee-eeeeeeeeeee6',5,'EEG','F4','right frontal',24.00,0.10,100.00,50.00),
('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee7','dddddddd-dddd-4ddd-8ddd-ddddddddddd4',6,'EEG','C3','left central',24.00,0.10,100.00,50.00),
('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee8','dddddddd-dddd-4ddd-8ddd-ddddddddddd4',7,'EEG','C4','right central',24.00,0.10,100.00,50.00)
ON CONFLICT (layout_id) DO NOTHING;

-- Compact, anonymized calibration “fingerprint” derived from real-valued calibration runs
CREATE TABLE IF NOT EXISTS bci_calibration_fingerprint (
    fingerprint_id       UUID PRIMARY KEY,
    device_id            UUID REFERENCES bci_device(device_id),
    sampling_hz          INTEGER NOT NULL,
    channel_count        SMALLINT NOT NULL,
    noise_floor_uv_rms   NUMERIC(6,3) NOT NULL,
    drift_uv_min         NUMERIC(7,3) NOT NULL,
    saturation_margin_db NUMERIC(5,2) NOT NULL,
    stability_vector_8   DOUBLE PRECISION[8] NOT NULL,   -- fully filled [0,1] stability indices
    spectral_quality_8   DOUBLE PRECISION[8] NOT NULL,   -- e.g. SNR in key bands
    checksum_hex         CHAR(64) NOT NULL               -- hex SHA-256 over raw calibration log
);

INSERT INTO bci_calibration_fingerprint (
    fingerprint_id, device_id, sampling_hz, channel_count,
    noise_floor_uv_rms, drift_uv_min, saturation_margin_db,
    stability_vector_8, spectral_quality_8, checksum_hex
) VALUES (
    'ffffffff-ffff-4fff-8fff-fffffffffff1',
    'dddddddd-dddd-4ddd-8ddd-ddddddddddd4',
    1000,
    32,
    0.450,
    2.300,
    18.00,
    ARRAY[0.98,0.97,0.96,0.95,0.97,0.96,0.95,0.94]::DOUBLE PRECISION[],
    ARRAY[22.5,21.8,19.6,18.9,23.2,20.4,19.1,17.7]::DOUBLE PRECISION[],
    'B4E2D7A1C9F0837AD1E4B6C3F9A2D5E1B7C8D9F0A3E6B1C4D7F2A9E0C5B8D3F6'
)
ON CONFLICT (fingerprint_id) DO NOTHING;

-- Validation function: returns validation_status and system_metrics JSON
CREATE OR REPLACE FUNCTION validate_bci_device(
    p_device_id            UUID
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    d       bci_device;
    s       bci_safety_profile;
    f       bci_calibration_fingerprint;
    bio_min DOUBLE PRECISION;
    stab_min DOUBLE PRECISION;
    ok      BOOLEAN;
BEGIN
    SELECT * INTO d FROM bci_device WHERE device_id = p_device_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('validation_status', FALSE,
                                  'system_metrics', jsonb_build_object('error', 'device_not_found'));
    END IF;

    SELECT * INTO s FROM bci_safety_profile WHERE safety_profile_id = d.safety_profile_id;
    SELECT * INTO f FROM bci_calibration_fingerprint WHERE device_id = d.device_id
    ORDER BY sampling_hz DESC LIMIT 1;

    SELECT MIN(val) INTO bio_min
    FROM unnest(s.biocompatibility_4x4) AS row(arr),
         unnest(row.arr) AS val;

    SELECT MIN(val) INTO stab_min
    FROM unnest(f.stability_vector_8) AS val;

    ok :=
        s.iso10993_passed
        AND bio_min >= 0.95
        AND s.tissue_temp_max_c <= 39.0
        AND s.power_density_max_mw_cm2 <= 50.0
        AND s.em_exposure_max_v_m <= 20.0
        AND f.noise_floor_uv_rms <= 1.000
        AND f.saturation_margin_db >= 12.0
        AND stab_min >= 0.94;

    RETURN jsonb_build_object(
        'validation_status', ok,
        'system_metrics', jsonb_build_object(
            'device_id', d.device_id,
            'class_code', d.class_code,
            'model_code', d.model_code,
            'tissue_temp_max_c', s.tissue_temp_max_c,
            'power_density_max_mw_cm2', s.power_density_max_mw_cm2,
            'em_exposure_max_v_m', s.em_exposure_max_v_m,
            'biocompatibility_min', bio_min,
            'noise_floor_uv_rms', f.noise_floor_uv_rms,
            'saturation_margin_db', f.saturation_margin_db,
            'stability_min', stab_min
        )
    );
END;
$$;

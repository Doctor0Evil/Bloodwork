BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE blood_type (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    abo_group               VARCHAR(2) NOT NULL CHECK (abo_group IN ('O','A','B','AB')),
    rh_factor               VARCHAR(3) NOT NULL CHECK (rh_factor IN ('NEG','POS')),
    is_universal_donor      BOOLEAN NOT NULL,
    is_universal_recipient  BOOLEAN NOT NULL,
    loinc_code              VARCHAR(32) NOT NULL,
    snomed_ct_code          VARCHAR(32) NOT NULL,
    UNIQUE (abo_group, rh_factor)
);

CREATE TABLE compatibility_matrix (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    donor_blood_type_id         UUID NOT NULL REFERENCES blood_type(id),
    recipient_blood_type_id     UUID NOT NULL REFERENCES blood_type(id),
    compatibility_class         VARCHAR(16) NOT NULL CHECK (compatibility_class IN ('SAFE','CONDITIONAL','UNSAFE')),
    rationale_code              VARCHAR(32) NOT NULL CHECK (
                                      rationale_code IN (
                                          'ABO_MATCH',
                                          'ABO_COMPATIBLE',
                                          'ABO_MISMATCH',
                                          'RH_MATCH',
                                          'RH_MISMATCH',
                                          'POLICY_EXCEPTION',
                                          'OTHER'
                                      )
                                ),
    max_transfusion_volume_ml   INTEGER NOT NULL CHECK (max_transfusion_volume_ml >= 0),
    policy_version              VARCHAR(32) NOT NULL,
    regulatory_basis            VARCHAR(128) NOT NULL,
    checksum_hex                CHAR(64) NOT NULL,
    supersedes                  UUID REFERENCES compatibility_matrix(id),
    superseded_by               UUID REFERENCES compatibility_matrix(id),
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by_system_id        VARCHAR(64) NOT NULL,
    locked_at                   TIMESTAMPTZ,
    locked_by                   VARCHAR(64),
    UNIQUE (donor_blood_type_id, recipient_blood_type_id, policy_version)
);

CREATE TABLE patient (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mrn                     VARCHAR(64) NOT NULL UNIQUE,
    date_of_birth           DATE NOT NULL,
    legal_sex               VARCHAR(16),
    primary_identifier_hash CHAR(64) NOT NULL
);

CREATE TABLE lab_sample (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id              UUID NOT NULL REFERENCES patient(id),
    blood_type_id           UUID REFERENCES blood_type(id),
    collection_timestamp    TIMESTAMPTZ NOT NULL,
    specimen_id             VARCHAR(64) NOT NULL UNIQUE,
    crossmatch_status       VARCHAR(16) NOT NULL CHECK (crossmatch_status IN ('PENDING','COMPATIBLE','INCOMPATIBLE')),
    region_code             VARCHAR(16) NOT NULL DEFAULT 'GLOBAL',
    created_by_device_id    VARCHAR(64) NOT NULL
);

CREATE TABLE device_capability_profile (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id                   VARCHAR(64) NOT NULL UNIQUE,
    supported_modalities        VARCHAR(128) NOT NULL,
    max_throughput_ops_per_min  INTEGER NOT NULL CHECK (max_throughput_ops_per_min > 0),
    firmware_version            VARCHAR(64) NOT NULL,
    last_calibrated_at          TIMESTAMPTZ,
    public_key_pem              TEXT NOT NULL,
    attestation_status          VARCHAR(16) NOT NULL DEFAULT 'UNKNOWN'
        CHECK (attestation_status IN ('UNKNOWN','TRUSTED','REVOKED'))
);

CREATE TABLE biometric_binding (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id                  UUID NOT NULL REFERENCES patient(id),
    biometric_template_hash     CHAR(64) NOT NULL,
    binding_confidence          NUMERIC(4,3) NOT NULL CHECK (binding_confidence >= 0.000 AND binding_confidence <= 1.000),
    last_verified_at            TIMESTAMPTZ NOT NULL,
    UNIQUE (patient_id, biometric_template_hash)
);

CREATE TABLE transfusion_session (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id                  UUID NOT NULL REFERENCES patient(id),
    donor_lab_sample_id         UUID NOT NULL REFERENCES lab_sample(id),
    recipient_lab_sample_id     UUID NOT NULL REFERENCES lab_sample(id),
    device_profile_id           UUID NOT NULL REFERENCES device_capability_profile(id),
    compatibility_matrix_id     UUID NOT NULL REFERENCES compatibility_matrix(id),
    biometric_binding_id        UUID NOT NULL REFERENCES biometric_binding(id),
    binding_threshold           NUMERIC(4,3) NOT NULL,
    started_at                  TIMESTAMPTZ,
    completed_at                TIMESTAMPTZ,
    status                      VARCHAR(16) NOT NULL CHECK (status IN ('PLANNED','RUNNING','COMPLETED','ABORTED')),
    abort_reason                VARCHAR(256)
);

CREATE TABLE environmental_threshold (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parameter               VARCHAR(32) NOT NULL CHECK (parameter IN ('TEMP_C','HUMIDITY_PCT','VIBRATION_MG','EM_NOISE_DB')),
    min_value               NUMERIC(8,3) NOT NULL,
    max_value               NUMERIC(8,3) NOT NULL,
    alert_level             VARCHAR(16) NOT NULL CHECK (alert_level IN ('INFO','WARN','CRITICAL')),
    applies_to_device_id    UUID REFERENCES device_capability_profile(id),
    CHECK (min_value <= max_value)
);

CREATE TABLE memory_pool_policy (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pool_name               VARCHAR(64) NOT NULL UNIQUE,
    max_ram_mb              INTEGER NOT NULL CHECK (max_ram_mb > 0),
    max_disk_mb             INTEGER NOT NULL CHECK (max_disk_mb >= 0),
    priority                INTEGER NOT NULL,
    eviction_strategy       VARCHAR(32) NOT NULL CHECK (eviction_strategy IN ('STRICT_LRU','PINNED','TIME_WINDOWED'))
);

CREATE TABLE engine_binding (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    engine_name             VARCHAR(64) NOT NULL,
    pool_id                 UUID NOT NULL REFERENCES memory_pool_policy(id),
    requires_pinned         BOOLEAN NOT NULL,
    requires_full_audit     BOOLEAN NOT NULL
);

CREATE INDEX idx_blood_type_abogroup_rh ON blood_type (abo_group, rh_factor);
CREATE INDEX idx_compat_matrix_donor_recipient ON compatibility_matrix (donor_blood_type_id, recipient_blood_type_id, compatibility_class);
CREATE INDEX idx_lab_sample_patient_time ON lab_sample (patient_id, collection_timestamp DESC);
CREATE INDEX idx_lab_sample_region_time ON lab_sample (region_code, collection_timestamp DESC);
CREATE INDEX idx_biometric_template_hash ON biometric_binding (biometric_template_hash);

COMMIT;

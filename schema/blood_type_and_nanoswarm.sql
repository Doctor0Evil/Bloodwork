-- Blood type reference table (ABO/Rh) – clinically validated
CREATE TABLE IF NOT EXISTS blood_type (
    id                  UUID PRIMARY KEY,
    abo_group           VARCHAR(2) NOT NULL CHECK (abo_group IN ('O','A','B','AB')),
    rh_factor           VARCHAR(3) NOT NULL CHECK (rh_factor IN ('NEG','POS')),
    is_universal_donor  BOOLEAN    NOT NULL,
    is_universal_recipient BOOLEAN NOT NULL,
    loinc_code          VARCHAR(16) NOT NULL,
    snomed_ct_code      VARCHAR(32) NOT NULL,
    UNIQUE (abo_group, rh_factor)
);

INSERT INTO blood_type (id, abo_group, rh_factor, is_universal_donor, is_universal_recipient, loinc_code, snomed_ct_code)
VALUES
('11111111-1111-4111-8111-111111111111','O','NEG', TRUE,  FALSE,'77397-8','278148006'),
('22222222-2222-4222-8222-222222222222','O','POS', FALSE, FALSE,'77397-8','278147001'),
('33333333-3333-4333-8333-333333333333','A','NEG', FALSE, FALSE,'77397-8','278152006'),
('44444444-4444-4444-8444-444444444444','A','POS', FALSE, FALSE,'77397-8','278149003'),
('55555555-5555-4555-8555-555555555555','B','NEG', FALSE, FALSE,'77397-8','278153001'),
('66666666-6666-4666-8666-666666666666','B','POS', FALSE, FALSE,'77397-8','278150003'),
('77777777-7777-4777-8777-777777777777','AB','NEG',FALSE, FALSE,'77397-8','278154007'),
('88888888-8888-4888-8888-888888888888','AB','POS',FALSE, TRUE, '77397-8','278151004')
ON CONFLICT (abo_group, rh_factor) DO NOTHING;

-- Nanoswarm node registration for clinical/VR-AR neuromorphic deployments
CREATE TABLE IF NOT EXISTS nanoswarm_node (
    node_id                 VARCHAR(64) PRIMARY KEY,
    ops_threshold_tops      NUMERIC(10,3) NOT NULL CHECK (ops_threshold_tops >= 0.100),
    topology_matrix         BYTEA        NOT NULL,  -- Serialized row-major float32/float64 adjacency matrix
    compliance_level        VARCHAR(64)  NOT NULL CHECK (compliance_level IN (
                            'research-grade','clinical-trial','surgical-grade','implantable-ISO14708')),
    ai_firmware_version     VARCHAR(64)  NOT NULL,
    tissue_temp_max_c       NUMERIC(4,1) NOT NULL CHECK (tissue_temp_max_c BETWEEN 35.0 AND 41.0),
    power_density_max_mw_cm2 NUMERIC(6,2) NOT NULL CHECK (power_density_max_mw_cm2 <= 100.00),
    em_exposure_max_v_m     NUMERIC(6,2) NOT NULL CHECK (em_exposure_max_v_m <= 61.00),
    iso10993_passed         BOOLEAN      NOT NULL,
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Deterministic validation function: returns validation_status + minimal system_metrics
CREATE OR REPLACE FUNCTION validate_nanoswarm_node(
    p_node_id              VARCHAR,
    p_ops_threshold_tops   NUMERIC,
    p_topology_matrix      BYTEA,
    p_compliance_level     VARCHAR,
    p_ai_firmware_version  VARCHAR
)
RETURNS JSONB
LANGUAGE sql
AS $$
    SELECT jsonb_build_object(
        'validation_status',
        (
            p_ops_threshold_tops >= 12.000
            AND octet_length(p_topology_matrix) >= 64
            AND p_compliance_level IN ('clinical-trial','surgical-grade','implantable-ISO14708')
            AND p_ai_firmware_version ~ '^[A-Z0-9]+\.[0-9]+\.[0-9]+$'
        ),
        'system_metrics',
        jsonb_build_object(
            'node_id', p_node_id,
            'ops_threshold_tops', p_ops_threshold_tops,
            'topology_bytes', octet_length(p_topology_matrix),
            'compliance_level', p_compliance_level,
            'ai_firmware_version', p_ai_firmware_version
        )
    );
$$;

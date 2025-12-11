use neuro_nanoswarm_service::domain::volume::{
    DefaultVolumePolicy, MatrixError, VolumeMatrixRow, generate_matrix_rows_with_policy,
};
use uuid::Uuid;

#[test]
fn generate_matrix_rows_rejects_negative_volume() {
    let policy = DefaultVolumePolicy {
        max_allowed_ml: 500.0,
        qpu_cycle_budget_ns: 250,
        compliance_tag: "GMP-CLASS-A",
    };
    let patient_id = Uuid::new_v4();

    let err = generate_matrix_rows_with_policy(&policy, patient_id, -1.0)
        .expect_err("negative volumes must be rejected");

    match err {
        MatrixError::NegativeMaxVolume(v) => assert!(v < 0.0),
        _ => panic!("expected NegativeMaxVolume error"),
    }
}

#[test]
fn generate_matrix_rows_rejects_above_ceiling() {
    let policy = DefaultVolumePolicy {
        max_allowed_ml: 500.0,
        qpu_cycle_budget_ns: 250,
        compliance_tag: "GMP-CLASS-A",
    };
    let patient_id = Uuid::new_v4();

    let err = generate_matrix_rows_with_policy(&policy, patient_id, 1000.0)
        .expect_err("volumes above policy ceiling must be rejected");

    matches!(err, MatrixError::AboveDeviceCeiling);
}

#[test]
fn generate_matrix_rows_respects_quantisation_bands() {
    let policy = DefaultVolumePolicy {
        max_allowed_ml: 100.0,
        qpu_cycle_budget_ns: 250,
        compliance_tag: "GMP-CLASS-A",
    };
    let patient_id = Uuid::new_v4();

    let rows = generate_matrix_rows_with_policy(&policy, patient_id, 100.0)
        .expect("valid volume must succeed");

    assert_eq!(rows.len(), 5);
    let ml: Vec<f64> = rows.iter().map(|r| r.max_volume_ml).collect();
    assert!(ml.contains(&20.0));
    assert!(ml.contains(&40.0));
    assert!(ml.contains(&60.0));
    assert!(ml.contains(&80.0));
    assert!(ml.contains(&100.0));
}

#[test]
fn generate_matrix_rows_zero_volume_returns_empty() {
    let policy = DefaultVolumePolicy {
        max_allowed_ml: 100.0,
        qpu_cycle_budget_ns: 250,
        compliance_tag: "GMP-CLASS-A",
    };
    let patient_id = Uuid::new_v4();

    let rows = generate_matrix_rows_with_policy(&policy, patient_id, 0.0)
        .expect("zero volume is allowed");
    assert!(rows.is_empty());
}

#[test]
fn volume_matrix_row_roundtrips_via_serde() {
    let row = VolumeMatrixRow {
        id: Uuid::new_v4(),
        patient_id: Uuid::new_v4(),
        max_volume_ml: 42.123,
        compliance_tag: "GMP-CLASS-A",
        qpu_cycle_budget_ns: 250,
    };

    let json = serde_json::to_string(&row).expect("serialize");
    let de: VolumeMatrixRow = serde_json::from_str(&json).expect("deserialize");

    assert_eq!(row.patient_id, de.patient_id);
    assert_eq!(row.max_volume_ml, de.max_volume_ml);
    assert_eq!(row.compliance_tag, de.compliance_tag);
    assert_eq!(row.qpu_cycle_budget_ns, de.qpu_cycle_budget_ns);
}

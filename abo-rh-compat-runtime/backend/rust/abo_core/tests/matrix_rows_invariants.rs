use abo_core::{ABO, Rh, BloodType, CompatibilityClass, MatrixRow, generate_matrix_rows};
use uuid::Uuid;

fn ids() -> Vec<(BloodType, Uuid)> {
    vec![
        (BloodType { abo: ABO::O,  rh: Rh::NEG }, Uuid::parse_str("11111111-1111-4111-8111-111111111111").unwrap()),
        (BloodType { abo: ABO::O,  rh: Rh::POS }, Uuid::parse_str("22222222-2222-4222-8222-222222222222").unwrap()),
        (BloodType { abo: ABO::A,  rh: Rh::NEG }, Uuid::parse_str("33333333-3333-4333-8333-333333333333").unwrap()),
        (BloodType { abo: ABO::A,  rh: Rh::POS }, Uuid::parse_str("44444444-4444-4444-8444-444444444444").unwrap()),
        (BloodType { abo: ABO::B,  rh: Rh::NEG }, Uuid::parse_str("55555555-5555-4555-8555-555555555555").unwrap()),
        (BloodType { abo: ABO::B,  rh: Rh::POS }, Uuid::parse_str("66666666-6666-4666-8666-666666666666").unwrap()),
        (BloodType { abo: ABO::AB, rh: Rh::NEG }, Uuid::parse_str("77777777-7777-4777-8777-777777777777").unwrap()),
        (BloodType { abo: ABO::AB, rh: Rh::POS }, Uuid::parse_str("88888888-8888-4888-8888-888888888888").unwrap()),
    ]
}

#[test]
fn rows_have_correct_max_volume() {
    let map = ids();
    let rows = generate_matrix_rows(&map, "POLICY_V1", 0, "TEST_BASIS");
    assert!(rows.iter().all(|r| r.max_volume_ml == 0));

    let rows_1 = generate_matrix_rows(&map, "POLICY_V1", 150, "TEST_BASIS");
    assert!(rows_1.iter().all(|r| r.max_volume_ml == 150));

    let rows_2 = generate_matrix_rows(&map, "POLICY_V1", -1, "TEST_BASIS");
    assert!(rows_2.iter().all(|r| r.max_volume_ml == -1));
}

#[test]
fn policy_version_changes_affect_rows() {
    let map = ids();
    let a = generate_matrix_rows(&map, "POLICY_A", 500, "TEST_BASIS");
    let b = generate_matrix_rows(&map, "POLICY_A", 500, "TEST_BASIS");
    assert_eq!(a.len(), b.len());
    assert!(a.iter().zip(b.iter()).all(|(x,y)| x.policy_version == y.policy_version));

    let c = generate_matrix_rows(&map, "POLICY_B", 500, "TEST_BASIS");
    assert!(a.iter().zip(c.iter()).any(|(x,y)| x.policy_version != y.policy_version));
}

#[test]
fn rows_serialize_roundtrip() {
    let map = ids();
    let rows = generate_matrix_rows(&map, "SERIALIZE_TEST", 300, "TEST_BASIS");
    for row in rows.iter() {
        let json = serde_json::to_string(&row).expect("serialize");
        let back: MatrixRow = serde_json::from_str(&json).expect("deserialize");
        // Compare a few properties
        assert_eq!(back.donor_id, row.donor_id);
        assert_eq!(back.recipient_id, row.recipient_id);
        assert_eq!(back.policy_version, row.policy_version);
        assert_eq!(back.max_volume_ml, row.max_volume_ml);
    }
}

#[test]
fn edge_abo_rh_cases_are_detected() {
    let map = ids();
    let rows = generate_matrix_rows(&map, "POLICY_V2", 500, "TEST_BASIS");
    // O- donor -> all recipients are SAFE
    let o_neg = map[0].1;
    for (_, rid) in &map {
        let r = rows.iter().find(|r| r.donor_id == o_neg && r.recipient_id == *rid).expect("row");
        assert_eq!(r.class_, CompatibilityClass::SAFE, "O- donor should be SAFE to {rid}");
    }

    // AB+ donor -> recipient O- is UNSAFE
    let ab_pos = map[7].1;
    let o_neg = map[0].1;
    let r = rows.iter().find(|r| r.donor_id == ab_pos && r.recipient_id == o_neg).expect("row");
    assert_eq!(r.class_, CompatibilityClass::UNSAFE);

    // O+ donor -> O- recipient is CONDITIONAL
    let o_pos = map[1].1;
    let r2 = rows.iter().find(|r| r.donor_id == o_pos && r.recipient_id == o_neg).expect("row");
    assert_eq!(r2.class_, CompatibilityClass::CONDITIONAL);
}

#[test]
fn rationale_values_align_with_classes() {
    let map = ids();
    let rows = generate_matrix_rows(&map, "POLICY_V2", 100, "TEST_BASIS");
    for r in rows.iter() {
        match r.class_ {
            CompatibilityClass::SAFE => {
                assert!(format!("{:?}", r.rationale) == "ABO_MATCH" || format!("{:?}", r.rationale) == "ABO_COMPATIBLE" || format!("{:?}", r.rationale) == "RH_MATCH");
            }
            CompatibilityClass::CONDITIONAL => {
                assert_eq!(format!("{:?}", r.rationale), "RH_MISMATCH");
            }
            CompatibilityClass::UNSAFE => {
                assert!(format!("{:?}", r.rationale) == "ABO_MISMATCH" || format!("{:?}", r.rationale) == "RH_MISMATCH");
            }
        }
    }
}

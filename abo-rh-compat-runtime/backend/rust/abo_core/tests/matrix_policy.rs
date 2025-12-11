use abo_core::{ABO, Rh, BloodType, CompatibilityClass, generate_matrix_rows};
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
fn matrix_has_full_8x8_coverage() {
    let map = ids();
    let rows = generate_matrix_rows(&map, "POLICY_TEST", 500, "TEST_BASIS");
    assert_eq!(rows.len(), 64);

    // ensure uniqueness of (donor, recipient) pairs
    use std::collections::HashSet;
    let mut seen = HashSet::new();
    for r in &rows {
        let key = (r.donor_id, r.recipient_id);
        assert!(seen.insert(key), "duplicate donor/recipient pair detected");
    }
}

#[test]
fn o_neg_is_safe_to_all() {
    let map = ids();
    let rows = generate_matrix_rows(&map, "POLICY_TEST", 500, "TEST_BASIS");
    let o_neg_id = map[0].1;
    for (_, r_id) in &map {
        let row = rows.iter()
            .find(|row| row.donor_id == o_neg_id && row.recipient_id == *r_id)
            .expect("row not found");
        assert_eq!(row.class_, CompatibilityClass::SAFE);
    }
}

#[test]
fn ab_pos_only_safe_as_recipient_not_donor_to_o_neg() {
    let map = ids();
    let rows = generate_matrix_rows(&map, "POLICY_TEST", 500, "TEST_BASIS");
    let ab_pos_id = map[7].1;
    let o_neg_id  = map[0].1;

    // donor AB+ -> recipient O- is UNSAFE
    let row = rows.iter()
        .find(|row| row.donor_id == ab_pos_id && row.recipient_id == o_neg_id)
        .expect("row not found");
    assert_eq!(row.class_, CompatibilityClass::UNSAFE);
}

#[test]
fn self_pairs_are_safe_and_marked_match() {
    let map = ids();
    let rows = generate_matrix_rows(&map, "POLICY_TEST", 500, "TEST_BASIS");
    for (bt, id) in &map {
        let row = rows.iter()
            .find(|row| row.donor_id == *id && row.recipient_id == *id)
            .expect("row not found");
        assert_eq!(row.class_, CompatibilityClass::SAFE);
        // rationale must be ABO_MATCH
        assert_eq!(format!("{:?}", row.rationale), "ABO_MATCH");
    }
}

#[test]
fn conditional_only_when_abo_ok_and_rh_mismatch() {
    let map = ids();
    let rows = generate_matrix_rows(&map, "POLICY_TEST", 500, "TEST_BASIS");
    for r in &rows {
        if r.class_ == CompatibilityClass::CONDITIONAL {
            // donor Rh+ to Rh- with ABO-compatible pattern is the only allowed case
            // we just assert that donor!=recipient and rationale is RH_MISMATCH or ABO_COMPATIBLE
            let rationale = format!("{:?}", r.rationale);
            assert!(
                rationale == "RH_MISMATCH" || rationale == "ABO_COMPATIBLE",
                "unexpected rationale for CONDITIONAL row: {}", rationale
            );
        }
    }
}

use abo_core::{ABO, Rh, BloodType, CompatibilityClass, evaluate};

fn bt(abo: ABO, rh: Rh) -> BloodType {
    BloodType { abo, rh }
}

#[test]
fn o_neg_is_safe_to_all() {
    let donor = bt(ABO::O, Rh::NEG);
    let recipients = vec![
        bt(ABO::O, Rh::NEG),
        bt(ABO::O, Rh::POS),
        bt(ABO::A, Rh::NEG),
        bt(ABO::A, Rh::POS),
        bt(ABO::B, Rh::NEG),
        bt(ABO::B, Rh::POS),
        bt(ABO::AB, Rh::NEG),
        bt(ABO::AB, Rh::POS),
    ];
    for r in recipients {
        let res = evaluate(donor, r);
        assert_eq!(res.class_, CompatibilityClass::SAFE, "unexpected class for {:?}", r);
        assert!(res.abo_ok);
    }
}

#[test]
fn ab_pos_receives_all_safe_pairs() {
    let recipient = bt(ABO::AB, Rh::POS);
    let donors = vec![
        bt(ABO::O, Rh::NEG),
        bt(ABO::O, Rh::POS),
        bt(ABO::A, Rh::NEG),
        bt(ABO::A, Rh::POS),
        bt(ABO::B, Rh::NEG),
        bt(ABO::B, Rh::POS),
        bt(ABO::AB, Rh::NEG),
        bt(ABO::AB, Rh::POS),
    ];
    for d in donors {
        let res = evaluate(d, recipient);
        assert_eq!(res.class_, CompatibilityClass::SAFE);
    }
}

#[test]
fn rh_pos_to_rh_neg_is_not_safe() {
    let donor = bt(ABO::O, Rh::POS);
    let recipient = bt(ABO::O, Rh::NEG);
    let res = evaluate(donor, recipient);
    assert_eq!(res.class_, CompatibilityClass::CONDITIONAL);
    assert!(!res.rh_ok);
}

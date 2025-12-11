use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub enum ABO { O, A, B, AB }

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub enum Rh { NEG, POS }

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub enum CompatibilityClass { SAFE, CONDITIONAL, UNSAFE }

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub enum RationaleCode {
    ABO_MATCH,
    ABO_COMPATIBLE,
    ABO_MISMATCH,
    RH_MATCH,
    RH_MISMATCH,
    POLICY_EXCEPTION,
    OTHER,
}

#[derive(Clone, Copy, Debug, Serialize, Deserialize)]
pub struct BloodType {
    pub abo: ABO,
    pub rh:  Rh,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct CompatibilityResult {
    pub donor: BloodType,
    pub recipient: BloodType,
    pub class_: CompatibilityClass,
    pub abo_ok: bool,
    pub rh_ok:  bool,
    pub rationale: RationaleCode,
}

pub fn abo_compatible(d: ABO, r: ABO) -> bool {
    match (d, r) {
        (ABO::O,  _)        => true,
        (ABO::A,  ABO::A)   => true,
        (ABO::A,  ABO::AB)  => true,
        (ABO::B,  ABO::B)   => true,
        (ABO::B,  ABO::AB)  => true,
        (ABO::AB, ABO::AB)  => true,
        _                   => false,
    }
}

pub fn rh_compatible(d: Rh, r: Rh) -> bool {
    match (d, r) {
        (Rh::NEG, _)          => true,
        (Rh::POS, Rh::POS)    => true,
        (Rh::POS, Rh::NEG)    => false,
    }
}

pub fn evaluate(donor: BloodType, recipient: BloodType) -> CompatibilityResult {
    let abo_ok = abo_compatible(donor.abo, recipient.abo);
    let rh_ok  = rh_compatible(donor.rh, recipient.rh);

    let class_ = if abo_ok && rh_ok {
        CompatibilityClass::SAFE
    } else if abo_ok && !rh_ok {
        CompatibilityClass::CONDITIONAL
    } else {
        CompatibilityClass::UNSAFE
    };

    let rationale = if !abo_ok {
        RationaleCode::ABO_MISMATCH
    } else if !rh_ok {
        RationaleCode::RH_MISMATCH
    } else if donor.abo == recipient.abo && donor.rh == recipient.rh {
        RationaleCode::ABO_MATCH
    } else {
        RationaleCode::ABO_COMPATIBLE
    };

    CompatibilityResult { donor, recipient, class_, abo_ok, rh_ok, rationale }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct MatrixRow {
    pub id: Uuid,
    pub donor_id: Uuid,
    pub recipient_id: Uuid,
    pub class_: CompatibilityClass,
    pub rationale: RationaleCode,
    pub max_volume_ml: i32,
    pub policy_version: String,
    pub regulatory_basis: String,
}

pub fn generate_matrix_rows(
    bt_map: &[(BloodType, Uuid)],
    policy_version: &str,
    max_volume_ml: i32,
    regulatory_basis: &str,
) -> Vec<MatrixRow> {
    let mut rows = Vec::with_capacity(bt_map.len() * bt_map.len());
    for (d_bt, d_id) in bt_map {
        for (r_bt, r_id) in bt_map {
            let res = evaluate(*d_bt, *r_bt);
            rows.push(MatrixRow {
                id: Uuid::new_v4(),
                donor_id: *d_id,
                recipient_id: *r_id,
                class_: res.class_,
                rationale: res.rationale,
                max_volume_ml,
                policy_version: policy_version.to_owned(),
                regulatory_basis: regulatory_basis.to_owned(),
            });
        }
    }
    rows
}

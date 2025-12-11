use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ComplianceLevel {
    ResearchGrade,
    ClinicalTrial,
    SurgicalGrade,
    ImplantableISO14708,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NanoswarmNode {
    pub node_id: String,
    pub ops_threshold_tops: f64,
    pub topology_matrix: Vec<f64>, // row-major adjacency, length = n*n
    pub compliance_level: ComplianceLevel,
    pub ai_firmware_version: String,
    pub tissue_temp_max_c: f32,
    pub power_density_max_mw_cm2: f32,
    pub em_exposure_max_v_m: f32,
    pub biocompatibility_matrix: Vec<f32>, // 4x4, scores 0.0–1.0
    pub firmware_sha256_hex: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ValidationResult {
    pub validation_status: bool,
    pub system_metrics: serde_json::Value,
}

fn min_biocompatibility(b: &[f32]) -> f32 {
    b.iter().cloned().fold(1.0, |acc, v| acc.min(v))
}

fn zero_fraction(m: &[f64]) -> f64 {
    if m.is_empty() {
        return 1.0;
    }
    let zeros = m.iter().filter(|v| v.abs() < 1e-9).count() as f64;
    zeros / (m.len() as f64)
}

pub fn validate_nanoswarm_node(node: &NanoswarmNode) -> ValidationResult {
    let compute_ok = node.ops_threshold_tops >= 12.0;
    let topo_ok = node.topology_matrix.iter().filter(|v| v.abs() >= 1e-9).count() >= 8;

    let compliance_ok = matches!(
        node.compliance_level,
        ComplianceLevel::ClinicalTrial
            | ComplianceLevel::SurgicalGrade
            | ComplianceLevel::ImplantableISO14708
    );

    let fw_ok = node.firmware_sha256_hex.len() == 64
        && node
            .firmware_sha256_hex
            .chars()
            .all(|c| c.is_ascii_hexdigit());

    let bio_min = min_biocompatibility(&node.biocompatibility_matrix);
    let bio_ok = bio_min >= 0.90;

    let safe_temp = node.tissue_temp_max_c <= 39.0;
    let safe_power = node.power_density_max_mw_cm2 <= 50.0;
    let safe_em = node.em_exposure_max_v_m <= 61.0;

    let all_ok = compute_ok && topo_ok && compliance_ok && fw_ok && bio_ok && safe_temp && safe_power && safe_em;

    let metrics = serde_json::json!({
        "node_id": node.node_id,
        "ops_threshold_tops": node.ops_threshold_tops,
        "topology_sparsity": zero_fraction(&node.topology_matrix),
        "biocompatibility_min": bio_min,
        "tissue_temp_max_c": node.tissue_temp_max_c,
        "power_density_max_mw_cm2": node.power_density_max_mw_cm2,
        "em_exposure_max_v_m": node.em_exposure_max_v_m,
        "compliance_level": format!("{:?}", node.compliance_level),
        "ai_firmware_version": node.ai_firmware_version,
    });

    ValidationResult {
        validation_status: all_ok,
        system_metrics: metrics,
    }
}

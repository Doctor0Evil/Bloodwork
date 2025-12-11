package med.nano;

import java.util.List;
import java.util.Map;

public final class NanoswarmValidator {

    public enum ComplianceLevel {
        RESEARCH_GRADE,
        CLINICAL_TRIAL,
        SURGICAL_GRADE,
        IMPLANTABLE_ISO14708
    }

    public static final class NanoswarmNode {
        public String nodeId;
        public double opsThresholdTops;
        public double[] topologyMatrix;
        public ComplianceLevel complianceLevel;
        public String aiFirmwareVersion;
        public float tissueTempMaxC;
        public float powerDensityMaxMwCm2;
        public float emExposureMaxVM;
        public float[] biocompatibilityMatrix;
        public String firmwareSha256Hex;
    }

    public static final class ValidationResult {
        public boolean validationStatus;
        public Map<String, Object> systemMetrics;
    }

    private static float minBiocompatibility(float[] m) {
        float min = 1.0f;
        for (float v : m) {
            if (v < min) {
                min = v;
            }
        }
        return min;
    }

    private static double zeroFraction(double[] m) {
        if (m.length == 0) {
            return 1.0;
        }
        int zeros = 0;
        for (double v : m) {
            if (Math.abs(v) < 1e-9) {
                zeros++;
            }
        }
        return (double) zeros / (double) m.length;
    }

    public static ValidationResult validate(NanoswarmNode node) {
        boolean computeOk = node.opsThresholdTops >= 12.0;
        int nonZero = 0;
        for (double v : node.topologyMatrix) {
            if (Math.abs(v) >= 1e-9) {
                nonZero++;
            }
        }
        boolean topoOk = nonZero >= 8;

        boolean complianceOk = node.complianceLevel == ComplianceLevel.CLINICAL_TRIAL
                || node.complianceLevel == ComplianceLevel.SURGICAL_GRADE
                || node.complianceLevel == ComplianceLevel.IMPLANTABLE_ISO14708;

        boolean fwOk = node.firmwareSha256Hex != null
                && node.firmwareSha256Hex.length() == 64
                && node.firmwareSha256Hex.chars().allMatch(c ->
                    (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'));

        float bioMin = minBiocompatibility(node.biocompatibilityMatrix);
        boolean bioOk = bioMin >= 0.90f;

        boolean safeTemp = node.tissueTempMaxC <= 39.0f;
        boolean safePower = node.powerDensityMaxMwCm2 <= 50.0f;
        boolean safeEm = node.emExposureMaxVM <= 61.0f;

        boolean allOk = computeOk && topoOk && complianceOk && fwOk && bioOk && safeTemp && safePower && safeEm;

        ValidationResult result = new ValidationResult();
        result.validationStatus = allOk;
        result.systemMetrics = Map.of(
                "node_id", node.nodeId,
                "ops_threshold_tops", node.opsThresholdTops,
                "topology_sparsity", zeroFraction(node.topologyMatrix),
                "biocompatibility_min", bioMin,
                "tissue_temp_max_c", node.tissueTempMaxC,
                "power_density_max_mw_cm2", node.powerDensityMaxMwCm2,
                "em_exposure_max_v_m", node.emExposureMaxVM,
                "compliance_level", node.complianceLevel.name(),
                "ai_firmware_version", node.aiFirmwareVersion
        );
        return result;
    }
}

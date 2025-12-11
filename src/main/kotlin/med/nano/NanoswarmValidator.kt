package med.nano

data class NanoswarmNode(
    val nodeId: String,
    val opsThresholdTops: Double,
    val topologyMatrix: DoubleArray,
    val complianceLevel: ComplianceLevel,
    val aiFirmwareVersion: String,
    val tissueTempMaxC: Float,
    val powerDensityMaxMwCm2: Float,
    val emExposureMaxVM: Float,
    val biocompatibilityMatrix: FloatArray,
    val firmwareSha256Hex: String,
)

enum class ComplianceLevel {
    RESEARCH_GRADE,
    CLINICAL_TRIAL,
    SURGICAL_GRADE,
    IMPLANTABLE_ISO14708,
}

data class ValidationResult(
    val validationStatus: Boolean,
    val systemMetrics: Map<String, Any>,
)

object NanoswarmValidator {

    private fun minBiocompatibility(m: FloatArray): Float =
        m.fold(1.0f) { acc, v -> if (v < acc) v else acc }

    private fun zeroFraction(m: DoubleArray): Double {
        if (m.isEmpty()) return 1.0
        val zeros = m.count { kotlin.math.abs(it) < 1e-9 }
        return zeros.toDouble() / m.size.toDouble()
    }

    private fun isHex64(s: String): Boolean =
        s.length == 64 && s.all { it.isDigit() || (it.lowercaseChar() in 'a'..'f') }

    fun validate(node: NanoswarmNode): ValidationResult {
        val computeOk = node.opsThresholdTops >= 12.0
        val nonZero = node.topologyMatrix.count { kotlin.math.abs(it) >= 1e-9 }
        val topoOk = nonZero >= 8

        val complianceOk = when (node.complianceLevel) {
            ComplianceLevel.CLINICAL_TRIAL,
            ComplianceLevel.SURGICAL_GRADE,
            ComplianceLevel.IMPLANTABLE_ISO14708 -> true
            else -> false
        }

        val fwOk = isHex64(node.firmwareSha256Hex)
        val bioMin = minBiocompatibility(node.biocompatibilityMatrix)
        val bioOk = bioMin >= 0.90f

        val safeTemp = node.tissueTempMaxC <= 39.0f
        val safePower = node.powerDensityMaxMwCm2 <= 50.0f
        val safeEm = node.emExposureMaxVM <= 61.0f

        val allOk = computeOk && topoOk && complianceOk && fwOk && bioOk && safeTemp && safePower && safeEm

        val metrics = mapOf<String, Any>(
            "node_id" to node.nodeId,
            "ops_threshold_tops" to node.opsThresholdTops,
            "topology_sparsity" to zeroFraction(node.topologyMatrix),
            "biocompatibility_min" to bioMin,
            "tissue_temp_max_c" to node.tissueTempMaxC,
            "power_density_max_mw_cm2" to node.powerDensityMaxMwCm2,
            "em_exposure_max_v_m" to node.emExposureMaxVM,
            "compliance_level" to node.complianceLevel.name,
            "ai_firmware_version" to node.aiFirmwareVersion,
        )

        return ValidationResult(
            validationStatus = allOk,
            systemMetrics = metrics,
        )
    }
}

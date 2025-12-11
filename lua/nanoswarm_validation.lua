local M = {}

local function min_biocompatibility(m)
    local min = 1.0
    for i = 1, #m do
        if m[i] < min then
            min = m[i]
        end
    end
    return min
end

local function zero_fraction(m)
    local n = #m
    if n == 0 then
        return 1.0
    end
    local zeros = 0
    for i = 1, n do
        if math.abs(m[i]) < 1e-9 then
            zeros = zeros + 1
        end
    end
    return zeros / n
end

local function is_hex(s)
    if #s ~= 64 then
        return false
    end
    return not not s:match("^[0-9a-fA-F]+$")
end

function M.validate_nanoswarm_node(node)
    local compute_ok = node.ops_threshold_tops >= 12.0

    local non_zero = 0
    for i = 1, #node.topology_matrix do
        if math.abs(node.topology_matrix[i]) >= 1e-9 then
            non_zero = non_zero + 1
        end
    end
    local topo_ok = non_zero >= 8

    local cl = node.compliance_level
    local compliance_ok = (cl == "clinical-trial" or cl == "surgical-grade" or cl == "implantable-ISO14708")

    local fw_ok = type(node.firmware_sha256_hex) == "string" and is_hex(node.firmware_sha256_hex)

    local bio_min = min_biocompatibility(node.biocompatibility_matrix)
    local bio_ok = bio_min >= 0.90

    local safe_temp = node.tissue_temp_max_c <= 39.0
    local safe_power = node.power_density_max_mw_cm2 <= 50.0
    local safe_em = node.em_exposure_max_v_m <= 61.0

    local all_ok = compute_ok and topo_ok and compliance_ok and fw_ok and bio_ok
        and safe_temp and safe_power and safe_em

    local result = {
        validation_status = all_ok,
        system_metrics = {
            node_id = node.node_id,
            ops_threshold_tops = node.ops_threshold_tops,
            topology_sparsity = zero_fraction(node.topology_matrix),
            biocompatibility_min = bio_min,
            tissue_temp_max_c = node.tissue_temp_max_c,
            power_density_max_mw_cm2 = node.power_density_max_mw_cm2,
            em_exposure_max_v_m = node.em_exposure_max_v_m,
            compliance_level = node.compliance_level,
            ai_firmware_version = node.ai_firmware_version,
        }
    }
    return result
end

return M

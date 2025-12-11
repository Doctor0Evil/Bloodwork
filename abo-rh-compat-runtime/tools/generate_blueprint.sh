#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="${script_dir}/.."
mkdir -p "$repo_root/BLUEPRINT"
cat "$repo_root/db/sql/001_init_schema.sql" \
	"$repo_root/backend/rust/abo_core/src/lib.rs" \
	"$repo_root/neuro_nanoswarm_service/src/http.rs" \
	"$repo_root/neuro_nanoswarm_service/src/domain/cal/mod.rs" \
	"$repo_root/aln/minimal_bodytrack_biosense_calibration_v1_0_0.aln" > "$repo_root/BLUEPRINT/BLUEPRINT.json"
sha256sum "$repo_root/BLUEPRINT/BLUEPRINT.json" > "$repo_root/BLUEPRINT/SHA256.txt"
cat "$repo_root/BLUEPRINT/SHA256.txt"

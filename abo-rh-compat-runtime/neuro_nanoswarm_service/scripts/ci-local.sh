#!/usr/bin/env bash
set -euo pipefail
export LANG=C

# Run the same checks locally that CI runs.
(
  cd backend/rust || cd ..
  cargo fmt --all -- --check
  cargo clippy --all-targets --all-features -- -D warnings
  cargo test --workspace --all-features -- --nocapture
)

(
  cd backend/go || cd ..
  go fmt ./...
  go vet ./...
  go test ./... -run . -v
)

(
  cd tools || cd ..
  chmod +x ./generate_blueprint.sh || true
  ./generate_blueprint.sh || ./generate_blueprint.ps1
)

echo "Local CI checks completed."

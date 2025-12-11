#!/usr/bin/env bash
set -euo pipefail
export LANG=C

# Run local CI checks similar to neuro-ci workflow
(
  cd backend/rust
  cargo fmt --all -- --check
  cargo clippy --all-targets --all-features -- -D warnings
  cargo test --workspace --all-features -- --nocapture
)

(
  cd backend/go
  go fmt ./...
  go vet ./...
  go test ./... -run . -v
)

(
  cd tools
  chmod +x ./generate_blueprint.sh || true
  ./generate_blueprint.sh || ./generate_blueprint.ps1
)

echo "Local CI checks completed."

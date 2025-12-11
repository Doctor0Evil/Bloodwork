# neuro_nanoswarm_service

Neuro nanoswarm service: an Axum + sqlx reference platform for neurotech research and clinical lab use.

This repo contains:
- An Axum HTTP server exposing `/health` for instrumentation and early test integration
- A `VolumeMatrix` domain model (validation and quantisation policy)
- Sqlx migrations and a local DB init for reproducible tests
- Local CI script and GitHub Actions workflow with format, clippy, and test stages

Use responsibly. This framework is a reference implementation and is not production-certified for clinical use.

## Quickstart
- Format & lint checks: `cargo fmt --all --check` and `cargo clippy --all-targets --all-features -- -D warnings`
- Run tests locally: `cargo test --all-features`
- Use `./scripts/ci-local.sh` or `pwsh ci/local-ci.ps1` to run the local CI checks.

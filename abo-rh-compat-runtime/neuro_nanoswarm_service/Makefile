.PHONY: ci fmt lint test

RUSTFLAGS   ?= -C target-cpu=native
FEATURES    ?= telemetry,secure-tpm
PROFILE     ?= release

export RUSTFLAGS
export DEVICE_PROFILE=neuro_nanoswarm_v1
export DB_LATENCY_BUDGET_MS=12

ci: fmt lint test

fmt:
	cargo fmt --all --check

lint:
	cargo clippy --all-targets --all-features -- -D warnings

test:
	RUST_BACKTRACE=1 RUST_LOG=info,sqlx=warn,axum=info \
	cargo test --all-features --profile $(PROFILE)

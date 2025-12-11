param(
    [switch]$SkipFmt,
    [switch]$SkipClippy,
    [switch]$SkipTests,
    [string]$Profile = "release",
    [string]$ExtraFeatures = "telemetry,secure-tpm"
)

$ErrorActionPreference = "Stop"

Write-Host "==> Running local CI with profile '$Profile' and features '$ExtraFeatures'"

if (-not $SkipFmt) {
    cargo fmt --all --check
}

if (-not $SkipClippy) {
    cargo clippy --all-targets --all-features -- -D warnings
}

if (-not $SkipTests) {
    $env:RUST_BACKTRACE = "1"
    $env:RUST_LOG = "info,sqlx=warn,axum=info"
    $env:DEVICE_PROFILE = "neuro_nanoswarm_v1"
    $env:DB_LATENCY_BUDGET_MS = "12"
    cargo test --all-features --profile $Profile
}

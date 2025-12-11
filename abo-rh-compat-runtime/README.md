# ABO/Rh Compatibility Runtime

Clinically grounded, non-fiction ABO/Rh encoding, compatibility matrix,
and audit-safe APIs for transfusion medicine and device integration.

## Blueprint Integrity

This repo implements ABO/Rh compatibility per published transfusion
compatibility charts.[web:58][web:60][web:64]
A canonical BLUEPRINT.json and SHA-256 hash should be generated from the
`db/sql` schema and `abo_core` formulas for external verification.

## Local run quickstart

Build & run Rust API:
	cd backend/rust && cargo run -p abo_api

Build & run Go gateway:
	cd http/go && go run main.go

Apply SQL (with a running PostgreSQL, using env vars):
	psql "$PGURL" -f db/sql/001_init_schema.sql

Seed blood_type LOINC/SNOMED table (optional):
	psql "$PGURL" -f db/sql/010_seed_blood_type_codes.sql

## Next steps
- Push this folder to a new repo named `abo-rh-compat-runtime` on GitHub/GitLab
- Add clinical docs and coding tables (LOINC/SNOMED) into `docs/`.
- Wire real DB migrations (e.g., sqlx, goose, or flyway) using this schema.
- Expose more endpoints using `abo_core` engine for full compatibility_matrix CRUD with immutability rules.

## Docker quickstart

Build and bring up services:

```bash
docker-compose up --build
```

Verify endpoint:

```bash
curl http://localhost:8080/compatibility/example
```

Run full tests (Rust and Go) locally (requires Rust and Go toolchains):

```bash
cd backend/rust && cargo test --workspace
cd http/go && go test ./...

Add the new tests and checks:

Format and lints:

```bash
cd backend/rust
cargo fmt --all
cargo clippy --all-targets --all-features -- -D warnings

cd http/go
go fmt ./...
go vet ./...
```
```

## Make it public on GitHub

Example steps:

PowerShell:

```powershell
cd abo-rh-compat-runtime
git init
git add .
git commit -m "chore: initial scaffold"
gh repo create your-org/abo-rh-compat-runtime --public --source=. --remote=origin
git push -u origin main
```

If you don't use GitHub CLI, create repo in the UI and set remote accordingly.

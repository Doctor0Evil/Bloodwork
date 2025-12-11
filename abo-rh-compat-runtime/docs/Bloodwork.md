# Bloodwork docs

Documentation and clinical coding tables can be added here.

## Calibration & ALN Registry

The `neuro_nanoswarm_service` exposes a minimal Calibration descriptor and listing endpoints used for discovery of body-tracking and biosensing calibration profiles described by the ALN artifacts under `aln/`.

Endpoints:
- GET /calibration/descriptor -> summary registry descriptor
- GET /calibration/device-families -> supported device families
- GET /calibration/bodytrack-profiles -> Body tracking calibration profiles
- GET /calibration/biosense-profiles -> Biosensing calibration profiles
- GET /calibration/logistics-profiles -> Logistics and facility profiles

These endpoints are intentionally read-only and suitable for use in CI, device discovery, or UI-driven configuration tooling.

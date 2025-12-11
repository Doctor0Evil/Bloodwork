# neurotech-bci-eeg-mci-platform

Open neurotech / BCI / EEG / MCI reference platform in Rust & Go for clinics, labs, and device makers.

This repository is a public, versioned reference and promotes safe, auditable design for neurotech and medical research. It includes sample backends, toolchains, and policy engines.

Core: backend/rust (policy engines), backend/go (gateway), db/sql (migrations & seeds), tools (blueprint generation).

## How to contribute
- Fork this repo and make changes on a topic branch
- Ensure tests pass (Rust and Go) and the blueprint matches
- Create a pull request for review

## Legal note
This is a reference implementation and is not medical-grade software. Any deployment used for patient care or clinical decision-making MUST comply with applicable regulations and be validated by a clinical team.

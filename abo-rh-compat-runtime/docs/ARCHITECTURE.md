# Architecture Overview

## Goals

- Provide a reference backend for EEG / BCI / neurotech experiments using modern systems languages.
- Support safe integration with EEG headsets, BCI hardware, and clinical client apps via HTTP / gRPC.
- Offer an auditable policy engine for safety-critical decisions (e.g., transfusion logic, device gating).

## Components

- backend/rust: Rust workspace with core policy engines and signal-processing modules.
- backend/go: Go gateway for HTTP / gRPC endpoints, ideal for dashboards and clinical tools.
- db/sql: SQL migrations and seeds for clinical / research metadata.
- tools: BLUEPRINT generator and hashing tools for structural introspection.

This repo is intentionally modular so organizations can fork, extend, and specialize for their own neurotech and BCI workflows.

# Repo setup & publish steps

1. Create the public repository on GitHub (use the `neurotech-bci-eeg-mci-platform` name) and enable Discussions and Security policy.
2. Clone this repository locally and copy (or subtree import) the `backend/rust`, `backend/go`, `db/sql`, `tools` folders if you're merging from a private repo.
3. Ensure you remove any proprietary keys or PII.
4. Run the local CI checks:

```bash
./scripts/ci-local.sh
```

5. Commit & push:

```bash
git add .
git commit -m "Initial public neurotech BCI/EEG reference platform"
git push -u origin main
```

6. Create a release and tag:

```bash
git tag -a v0.1.0-neurotech-bci-eeg-mci -m "First public release"
git push origin v0.1.0-neurotech-bci-eeg-mci
```

7. Enable GitHub Pages if you want to publish docs from `/docs` or `/public`.
8. Add the following topics to improve discoverability: `neurotech, bci, eeg, eeg-processing, brain-computer-interface, electrophysiology, medical-device, rust, go, grpc, http, websocket`.

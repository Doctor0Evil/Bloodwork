# Tools

- generate_blueprint.sh - Unix script that concatenates SQL schema and `abo_core` and writes `BLUEPRINT/BLUEPRINT.json` containing SHA-256
- generate_blueprint.ps1 - PowerShell equivalent for Windows

Usage examples:

POSIX:

```bash
cd tools
./generate_blueprint.sh
```

PowerShell:

```powershell
cd tools
.\generate_blueprint.ps1
```

Make sure `jq` is installed on POSIX or use PowerShell `ConvertTo-Json` for another approach.

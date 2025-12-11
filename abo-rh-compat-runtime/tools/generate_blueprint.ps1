# Generate a canonical BLUEPRINT.json and SHA256 over the SQL schema and Rust core
param()

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir '..')
$dbSqlPath = Join-Path $projectRoot 'db\sql\*.sql'
$tmpfile = [System.IO.Path]::GetTempFileName()

foreach ($f in (Get-ChildItem -Path $dbSqlPath | Sort-Object Name)) {
    "-- FILE: $($f.FullName)" | Out-File -FilePath $tmpfile -Append
    Get-Content $f.FullName | Out-File -FilePath $tmpfile -Append
    "" | Out-File -FilePath $tmpfile -Append
}

"-- FILE: backend/rust/abo_core/src/lib.rs" | Out-File -FilePath $tmpfile -Append
Get-Content (Join-Path $projectRoot 'backend\rust\abo_core\src\lib.rs') | Out-File -FilePath $tmpfile -Append
"" | Out-File -FilePath $tmpfile -Append
"-- FILE: neuro_nanoswarm_service/src/http.rs" | Out-File -FilePath $tmpfile -Append
Get-Content (Join-Path $projectRoot 'neuro_nanoswarm_service\src\http.rs') | Out-File -FilePath $tmpfile -Append
"" | Out-File -FilePath $tmpfile -Append
"-- FILE: neuro_nanoswarm_service/src/domain/cal/mod.rs" | Out-File -FilePath $tmpfile -Append
Get-Content (Join-Path $projectRoot 'neuro_nanoswarm_service\src\domain\cal\mod.rs') | Out-File -FilePath $tmpfile -Append
"" | Out-File -FilePath $tmpfile -Append
"-- FILE: aln/minimal_bodytrack_biosense_calibration_v1_0_0.aln" | Out-File -FilePath $tmpfile -Append
Get-Content (Join-Path $projectRoot 'aln\minimal_bodytrack_biosense_calibration_v1_0_0.aln') | Out-File -FilePath $tmpfile -Append

# Write combined content into BLUEPRINT/BLUEPRINT.json
Get-Content $tmpfile | Out-File -FilePath (Join-Path $projectRoot 'BLUEPRINT\BLUEPRINT.json') -Force

$shaObj = New-Object -TypeName System.Security.Cryptography.SHA256Managed
$fs = [System.IO.File]::OpenRead($tmpfile)
$hashBytes = $shaObj.ComputeHash($fs)
$fs.Close()
$sha = [BitConverter]::ToString($hashBytes) -replace '-','' | ForEach-Object { $_.ToLower() }

New-Item -ItemType Directory -Path "..\BLUEPRINT" -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $projectRoot 'BLUEPRINT') -Force | Out-Null
Get-FileHash $tmpfile -Algorithm SHA256 | ForEach-Object { $_.Hash } | Out-File (Join-Path $projectRoot 'BLUEPRINT\SHA256.txt')

Write-Output "Generated SHA256.txt with SHA: $sha"

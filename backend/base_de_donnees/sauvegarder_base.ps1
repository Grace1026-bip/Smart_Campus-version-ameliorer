$ErrorActionPreference = 'Stop'

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$racine = Split-Path -Parent $PSScriptRoot
$dossierSauvegarde = Join-Path $racine 'sauvegardes'
$fichierSauvegarde = Join-Path $dossierSauvegarde "smart_faculty_$timestamp.sql"
$mysqldump = 'C:\wamp64\bin\mysql\mysql8.4.7\bin\mysqldump.exe'

New-Item -ItemType Directory -Force -Path $dossierSauvegarde | Out-Null

& $mysqldump `
    --host=127.0.0.1 `
    --port=3307 `
    --user=root `
    --databases smart_faculty `
    --routines `
    --events `
    --single-transaction `
    --result-file=$fichierSauvegarde

Write-Output $fichierSauvegarde

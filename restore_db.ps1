# ==============================================================================
# Fast database restore script for fitness_center_db
# ==============================================================================
$ErrorActionPreference = "Continue"

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "[INFO] Restoring database fitness_center_db from backup_initial_state.sql..." -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

$backupFile = Join-Path $PSScriptRoot "backup_initial_state.sql"
if (-not (Test-Path $backupFile)) {
    Write-Host "[ERROR] Backup file '$backupFile' not found!" -ForegroundColor Red
    exit 1
}

Write-Host "[1/2] Terminating active connections to fitness_center_db..." -ForegroundColor Yellow
docker exec -i fitness-center-db psql -U postgres -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'fitness_center_db' AND pid != pg_backend_pid();" | Out-Null

Write-Host "[2/2] Applying backup dump..." -ForegroundColor Yellow
cmd.exe /c "docker exec -i fitness-center-db psql -U postgres -d postgres < `"$backupFile`""

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==============================================================================" -ForegroundColor Green
    Write-Host "[SUCCESS] Database fitness_center_db successfully restored to initial state!" -ForegroundColor Green
    Write-Host "==============================================================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "==============================================================================" -ForegroundColor Red
    Write-Host "[ERROR] Restore failed with code: $LASTEXITCODE" -ForegroundColor Red
    Write-Host "==============================================================================" -ForegroundColor Red
}

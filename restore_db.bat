@echo off
echo ==============================================================================
echo [INFO] Restoring database fitness_center_db from backup_initial_state.sql...
echo ==============================================================================

echo [1/2] Terminating active connections to fitness_center_db...
docker exec -i fitness-center-db psql -U postgres -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'fitness_center_db' AND pid != pg_backend_pid();" >nul 2>&1

echo [2/2] Applying backup dump...
docker exec -i fitness-center-db psql -U postgres -d postgres < "%~dp0backup_initial_state.sql"

if %ERRORLEVEL% equ 0 (
    echo.
    echo ==============================================================================
    echo [SUCCESS] Database fitness_center_db successfully restored to initial state!
    echo ==============================================================================
) else (
    echo.
    echo ==============================================================================
    echo [ERROR] Restore failed with error code %ERRORLEVEL%.
    echo ==============================================================================
)

@echo off
REM Docker operations for Laravel project (Windows batch)

setlocal enabledelayedexpansion

if "%1"=="" (
    echo Usage: make [command]
    echo Commands:
    echo   up       - Start Docker containers
    echo   down     - Stop Docker containers
    echo   test     - Run tests
    echo   migrate  - Run database migrations
    echo   seed     - Seed database
    echo   lint     - Run code linting
    echo   help     - Show this help
    exit /b 1
)

if "%1"=="up" (
    echo Starting Docker containers...
    docker compose up -d
    if !errorlevel! equ 0 (
        echo Docker containers are now running
    ) else (
        echo Failed to start Docker containers
        exit /b 1
    )
    exit /b 0
)

if "%1"=="down" (
    echo Stopping Docker containers...
    docker compose down
    if !errorlevel! equ 0 (
        echo Docker containers have been stopped
    ) else (
        echo Failed to stop Docker containers
        exit /b 1
    )
    exit /b 0
)

if "%1"=="test" (
    echo Running tests...
    docker compose exec -T app php artisan test %2 %3 %4
    exit /b !errorlevel!
)

if "%1"=="migrate" (
    echo Running database migrations...
    docker compose exec -T app php artisan migrate %2 %3 %4
    exit /b !errorlevel!
)

if "%1"=="seed" (
    echo Seeding database...
    docker compose exec -T app php artisan db:seed %2 %3 %4
    exit /b !errorlevel!
)

if "%1"=="lint" (
    echo Running code linting...
    docker compose exec -T app ./vendor/bin/pint --test
    exit /b !errorlevel!
)

if "%1"=="help" (
    echo Usage: make [command]
    echo Commands:
    echo   up       - Start Docker containers
    echo   down     - Stop Docker containers
    echo   test     - Run tests
    echo   migrate  - Run database migrations
    echo   seed     - Seed database
    echo   lint     - Run code linting
    exit /b 0
)

echo Unknown command: %1
exit /b 1

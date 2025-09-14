@echo off
REM =============================================================================
REM ProductAuth Microservice - Template Setup Script (Windows)
REM =============================================================================
REM This script copies example templates to working configuration files
REM Usage: setup-from-templates.bat

echo 🚀 ProductAuth Microservice - Template Setup
echo ============================================

REM Check if templates exist
if not exist ".env.example" (
    echo ❌ Error: .env.example not found!
    echo    Please ensure you're in the project root directory
    exit /b 1
)

if not exist "docker-compose.example.yml" (
    echo ❌ Error: docker-compose.example.yml not found!
    echo    Please ensure you're in the project root directory
    exit /b 1
)

echo ✅ Template files found

REM Step 1: Environment configuration
echo.
echo 📋 Step 1: Setting up environment configuration
if not exist ".env" (
    copy ".env.example" ".env" >nul
    echo ✅ Created .env from template
) else (
    echo ℹ️  .env file already exists, skipping...
)

REM Step 2: Docker Compose configuration
echo.
echo 📋 Step 2: Setting up Docker Compose configuration
if not exist "docker-compose.yml" (
    copy "docker-compose.example.yml" "docker-compose.yml" >nul
    echo ✅ Created docker-compose.yml from template
) else (
    echo ℹ️  docker-compose.yml already exists, skipping...
)

REM Step 3: Application settings
echo.
echo 📋 Step 3: Setting up application settings
set services=AuthService ProductService Gateway

for %%s in (%services%) do (
    if exist "src\%%s\%%s.API\appsettings.Example.json" (
        if not exist "src\%%s\%%s.API\appsettings.json" (
            copy "src\%%s\%%s.API\appsettings.Example.json" "src\%%s\%%s.API\appsettings.json" >nul
            echo ✅ Created appsettings.json for %%s
        ) else (
            echo ℹ️  appsettings.json for %%s already exists, skipping...
        )
    ) else (
        echo ⚠️  Template appsettings.Example.json for %%s not found
    )
)

REM Step 4: Configuration validation
echo.
echo 📋 Step 4: Configuration validation
findstr /C:"YOUR_" .env >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  WARNING: .env contains placeholder values that need updating:
    findstr /C:"YOUR_" .env
    echo.
) else (
    echo ✅ No placeholder values found in .env
)

REM Final instructions
echo.
echo 🎉 Template setup complete!
echo =========================
echo.
echo 📝 Required actions before deployment:
echo 1. Edit .env file and replace all YOUR_* placeholder values
echo 2. Update passwords and secrets with strong values
echo 3. Verify docker-compose.yml configuration
echo.
echo 🚀 To start the services:
echo    docker-compose up -d
echo.
echo 🌐 Service endpoints (after startup):
echo    - Gateway API: http://localhost:5000
echo    - Auth API: http://localhost:5001
echo    - Product API: http://localhost:5002
echo    - pgAdmin: http://localhost:5050
echo    - RabbitMQ Management: http://localhost:15672
echo.
echo 📚 Documentation:
echo    - README.md (Quick start guide)
echo    - COMPLETE_SETUP_GUIDE.md (Detailed instructions)
echo    - TEMPLATE_SYNC_VERIFICATION.md (Template information)
echo.
pause
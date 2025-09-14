@echo off
REM =============================================================================
REM ProductAuth Microservice - Complete Setup Script (Windows)
REM =============================================================================
REM This script automates the complete setup process including Docker deployment
REM Usage: scripts\quick-setup.bat

echo 🚀 ProductAuth Microservice - Complete Setup
echo =============================================

REM Check prerequisites
echo 📋 Step 1: Checking prerequisites

REM Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not installed. Please install Docker Desktop first.
    echo    Download from: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

REM Check if Docker Compose is available
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker Compose is not available. Please install Docker Desktop with Compose.
    pause
    exit /b 1
)

echo ✅ Docker and Docker Compose are available

REM Check if project templates exist
if not exist ".env.example" (
    echo ❌ .env.example not found. Ensure you're in the project root directory.
    pause
    exit /b 1
)

echo ✅ Project templates found

REM Setup configuration files
echo.
echo 📋 Step 2: Setting up configuration files

REM Copy .env file if it doesn't exist
if not exist ".env" (
    copy ".env.example" ".env" >nul
    echo ✅ Created .env file from template
) else (
    echo ℹ️  .env file already exists, skipping copy
)

REM Copy docker-compose.yml if it doesn't exist
if not exist "docker-compose.yml" (
    copy "docker-compose.example.yml" "docker-compose.yml" >nul
    echo ✅ Created docker-compose.yml from template
) else (
    echo ℹ️  docker-compose.yml already exists, skipping copy
)

REM Copy appsettings.json files
echo.
echo 📋 Step 3: Setting up application settings

set services=AuthService ProductService Gateway
for %%s in (%services%) do (
    if exist "src\%%s\%%s.API\appsettings.Example.json" (
        if not exist "src\%%s\%%s.API\appsettings.json" (
            copy "src\%%s\%%s.API\appsettings.Example.json" "src\%%s\%%s.API\appsettings.json" >nul
            echo ✅ Created appsettings.json for %%s
        ) else (
            echo ℹ️  appsettings.json for %%s already exists, skipping copy
        )
    ) else (
        echo ⚠️  Template for %%s not found
    )
)

REM Configuration security recommendations
echo.
echo 📋 Step 4: Security configuration recommendations
echo.
echo 🔐 IMPORTANT: Update these values in .env and docker-compose.yml:
echo    DB_PASSWORD=^<YourSecurePassword2024^>
echo    REDIS_PASSWORD=^<YourRedisPassword2024^>
echo    RABBITMQ_PASSWORD=^<YourRabbitPassword2024^>
echo    JWT_SECRET_KEY=^<32+CharacterSecretKey^>
echo    ADMIN_PASSWORD=^<YourAdminPassword2024^>
echo.
echo ⚠️  Ensure both .env AND docker-compose.yml use the same values!

REM Docker operations
echo.
echo 📋 Step 5: Docker environment setup

REM Check if containers are already running
docker-compose ps -q >nul 2>&1
if %errorlevel% equ 0 (
    echo ℹ️  Stopping existing containers...
    docker-compose down
)

REM Pull required images
echo.
echo 📋 Step 6: Pulling Docker images
echo This may take several minutes on first run...

docker pull postgres:15-alpine
docker pull redis:7-alpine
docker pull rabbitmq:3.12-management-alpine

echo ✅ Base images downloaded successfully

REM Build and deploy services
echo.
echo 📋 Step 7: Building and deploying services

echo 🔨 Building application images...
docker-compose build

echo 🚀 Starting infrastructure services...
docker-compose up -d postgres redis rabbitmq

echo ⏳ Waiting for infrastructure (30 seconds)...
timeout /t 30 /nobreak >nul

echo 🚀 Starting application services...
docker-compose up -d

REM Health verification
echo.
echo 📋 Step 8: Verifying deployment

echo ⏳ Waiting for services to initialize (60 seconds)...
timeout /t 60 /nobreak >nul

echo.
echo 🏥 Service health check
echo =====================

docker-compose ps

echo.
echo 🔍 Testing API endpoints...

REM Test service endpoints
curl -s -f "http://localhost:5000/health" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Gateway API is healthy
) else (
    echo ❌ Gateway API is not responding
)

curl -s -f "http://localhost:5001/health" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ AuthService is healthy
) else (
    echo ❌ AuthService is not responding
)

curl -s -f "http://localhost:5002/health" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ ProductService is healthy
) else (
    echo ❌ ProductService is not responding
)

REM Deployment complete
echo.
echo 📋 Step 9: Deployment complete!
echo ===============================
echo.
echo 🎉 ProductAuth Microservice is now running!
echo.
echo 🌐 Service URLs:
echo    Gateway API (Main):      http://localhost:5000
echo    AuthService API:         http://localhost:5001
echo    ProductService API:      http://localhost:5002
echo    RabbitMQ Management:     http://localhost:15672
echo    pgAdmin:                 http://localhost:5050
echo.
echo 📖 Quick start:
echo    1. Visit http://localhost:5000 to access the main API
echo    2. Use examples in README.md to test the APIs
echo    3. Access RabbitMQ Management at http://localhost:15672
echo    4. View logs: docker-compose logs -f
echo.
echo 📚 Documentation:
echo    📖 README.md                    (Quick start guide)
echo    🔧 COMPLETE_SETUP_GUIDE.md      (Detailed instructions)
echo    🔒 GIT_SETUP_GUIDE.md           (Git best practices)
echo.
echo �️  Troubleshooting:
echo    📋 View all logs:           docker-compose logs -f
echo    🔄 Restart services:        docker-compose restart
echo    🛑 Stop all services:       docker-compose down
echo    🔍 Service status:          docker-compose ps
echo.
echo ⚠️  SECURITY REMINDER: Update passwords in .env before production use!
echo.
echo ✅ Setup completed successfully! Happy coding! 🚀
echo.
pause
# 🚀 ProductAuth Microservice

A production-ready microservice architecture built with .NET 8, featuring distributed authentication, Redis caching, event-driven communication, and containerized deployment.

## 🏗️ Architecture Overview

```
ProductAuthMicroservice/
├── src/
│   ├── Gateway/Gateway.API/            # API Gateway (Ocelot) - Port 5000
│   ├── AuthService/                    # Authentication & Authorization Service
│   │   ├── AuthService.API/            # ASP.NET Core Web API - Port 5001
│   │   ├── AuthService.Application/    # CQRS (Commands, Queries, Handlers)
│   │   ├── AuthService.Domain/         # Domain Entities (AppUser, AppRole, UserAction)
│   │   └── AuthService.Infrastructure/ # EF DbContext, Identity, Services
│   ├── ProductService/                 # Product Management Service
│   │   ├── ProductService.API/         # ASP.NET Core Web API - Port 5002
│   │   ├── ProductService.Application/ # CQRS (Product, Category, Inventory)
│   │   ├── ProductService.Domain/      # Domain Entities (Product, Category, etc.)
│   │   └── ProductService.Infrastructure/ # EF DbContext, Repositories
│   └── Shared/                         # Common Libraries & Shared Components
│       ├── Commons/                    # Base entities, services, extensions
│       ├── Contracts/                  # Event contracts, DTOs, Interfaces
│       └── EventBus/                   # RabbitMQ event bus implementation
├── scripts/                            # Database initialization scripts
├── docker-compose.yml                  # Container orchestration
├── .env.example                        # Environment variables template
├── docker-compose.example.yml          # Docker compose configuration template
└── appsettings.Example.json            # Configuration examples for each service
```

## 🔧 Infrastructure Components

- **PostgreSQL** (Ports 5433, 5434): Separate databases for AuthService and ProductService
- **Redis** (Port 6379): Distributed cache for shared authentication state
- **RabbitMQ** (Ports 5672, 15672): Message broker for event-driven communication
- **API Gateway** (Port 5000): Ocelot gateway with distributed authentication middleware
- **AuthService** (Port 5001): JWT authentication and user management
- **ProductService** (Port 5002): Product catalog and inventory management

## 🚀 Quick Start Guide

### 1. Prerequisites
```bash
# Required software
- Git
- Docker Desktop
- .NET 8 SDK (for local development)
- Visual Studio 2022 or VS Code (recommended)
```

### 2. Clone and Setup Project
```bash
# Clone repository
git clone <your-repository-url>
cd ProductAuthMicroservice

# Copy configuration files
copy docker-compose.example.yml docker-compose.yml
copy .env.example .env

# Copy appsettings examples (for each service)
copy src\AuthService\AuthService.API\appsettings.Example.json src\AuthService\AuthService.API\appsettings.json
copy src\ProductService\ProductService.API\appsettings.Example.json src\ProductService\ProductService.API\appsettings.json
copy src\Gateway\Gateway.API\appsettings.Example.json src\Gateway\Gateway.API\appsettings.json
```

### 3. Configure Environment Variables
Edit the `.env` file with your actual configuration:

```bash
# Database Configuration
DB_USER=productauth_user
DB_PASSWORD=ProductAuth@2024

# JWT Configuration (Important: Use strong secret key)
JWT_SECRET_KEY=ProductAuthMicroserviceJWTSecretKey2024MustBeAtLeast32CharactersLong

# Redis Configuration
REDIS_PASSWORD=ProductAuthRedis@2024

# RabbitMQ Configuration
RABBITMQ_USER=productauth
RABBITMQ_PASSWORD=ProductAuthRabbit@2024

# Admin Account
ADMIN_EMAIL=admin@yourcompany.com
ADMIN_PASSWORD=AdminPass@2024
```

### 4. Update Docker Compose Configuration
Edit `docker-compose.yml`:

1. **Replace all `your_*` placeholders** with actual values from `.env` file
2. **Update JWT secret key** in all services (must be identical)
3. **Update database credentials**
4. **Update Redis and RabbitMQ passwords**
5. **Update CORS allowed origins** for production

### 5. Start Services
```bash
# Start all services with build
docker-compose up --build -d

# Check services status
docker-compose ps

# View logs for troubleshooting
docker-compose logs -f authservice
docker-compose logs -f productservice
docker-compose logs -f gateway
```

### 6. Verify Installation
```bash
# Check service health
curl http://localhost:5000/health  # Gateway
curl http://localhost:5001/health  # AuthService
curl http://localhost:5002/health  # ProductService

# Check RabbitMQ Management UI
# Browser: http://localhost:15672
# Username/Password: from your RabbitMQ config
```

## 🌐 Service URLs

| Service | URL | Description |
|---------|-----|-------------|
| **API Gateway** | http://localhost:5000 | Main entry point for all API calls |
| **AuthService** | http://localhost:5001 | Direct access to authentication service |
| **ProductService** | http://localhost:5002 | Direct access to product service |
| **RabbitMQ Management** | http://localhost:15672 | Message broker management UI |
| **AuthService DB** | localhost:5433 | PostgreSQL database for AuthService |
| **ProductService DB** | localhost:5434 | PostgreSQL database for ProductService |
| **Redis Cache** | localhost:6379 | Redis distributed cache |

## 🔥 Key Features

### 🔐 **Distributed Authentication with Redis Cache**
- JWT-based authentication with refresh tokens
- **Redis distributed cache** for shared user state across services
- Real-time session validation and invalidation
- Role-based authorization with real-time permissions
- Cross-service authentication state synchronization

### 📡 **Event-Driven Architecture**
- **RabbitMQ message broker** with durable queues
- **Transactional outbox pattern** for reliable messaging
- **Saga choreography** for distributed transactions
- Event sourcing for audit trails and data consistency
- Auto-retry mechanisms with exponential backoff

### 🐳 **Production-Ready Containerization**
- **Multi-stage Docker builds** for optimized images
- **Health checks** for all services with retry logic
- **Automatic database migrations** on startup
- **Volume persistence** for databases and cache
- **Service discovery** and load balancing ready

### 🎯 **Clean Architecture & CQRS**
- **CQRS pattern** with MediatR implementation
- **Domain-driven design** with clear bounded contexts
- **Repository pattern** with Unit of Work
- **Dependency injection** with proper service lifetimes
- **AutoMapper** for object mapping
- **FluentValidation** for comprehensive input validation

### 🚀 **Scalability & Performance**
- **Redis distributed caching** for performance
- **Connection pooling** for database connections
- **Async/await** patterns throughout
- **Memory-efficient** JSON serialization
- **Circuit breaker** patterns for external calls

## 🧪 API Testing Guide

### 1. User Registration & Authentication
```bash
# 1. Register new user via Gateway
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test.user@company.com",
    "password": "SecurePass@123",
    "firstName": "Test",
    "lastName": "User",
    "phoneNumber": "+1234567890"
  }'

# 2. Login to receive JWT token
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test.user@company.com",
    "password": "SecurePass@123"
  }'

# Response will contain:
# {
#     "isSuccess": true,
#     "message": "Login successfully!",
#     "data": {
#         "accessToken": "eyxxxxxxxx",
#         "expiresAt": "2025-09-14T15:27:30.2958115Z",
#         "roles": [
#             "Admin"
#         ]
# }
```

### 2. Product Management with Authentication
```bash
# Save token from login response
TOKEN="your-jwt-token-from-login-response"

# 1. Create new category
curl -X POST http://localhost:5000/api/categories \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Electronics",
    "description": "Electronic devices and accessories",
    "isActive": true
  }'

# 2. Create new product
curl -X POST http://localhost:5000/api/products \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "iPhone 15 Pro",
    "description": "Latest iPhone with advanced features",
    "price": 1199.99,
    "categoryId": "category-id-from-previous-step",
    "stockQuantity": 50,
    "sku": "IPH15PRO128",
    "isActive": true
  }'

# 3. Get products list
curl -X GET "http://localhost:5000/api/products?page=1&pageSize=10" \
  -H "Authorization: Bearer $TOKEN"

# 4. Update product
curl -X PUT http://localhost:5000/api/products/{product-id} \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "iPhone 15 Pro - Updated",
    "price": 1099.99,
    "stockQuantity": 75
  }'
```

### 3. User Profile Management
```bash
# Get current user profile
curl -X GET http://localhost:5000/api/auth/profile \
  -H "Authorization: Bearer $TOKEN"

# Update user profile
curl -X PUT http://localhost:5000/api/auth/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Updated",
    "lastName": "Name",
    "phoneNumber": "+1987654321"
  }'

# Change password
curl -X POST http://localhost:5000/api/auth/change-password \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "currentPassword": "SecurePass@123",
    "newPassword": "NewSecurePass@456"
  }'

# Refresh JWT token
curl -X POST http://localhost:5000/api/auth/refresh-token \
  -H "Content-Type: application/json" \
  -d '{
    "token": "current-jwt-token",
    "refreshToken": "current-refresh-token"
  }'

# Logout (invalidate tokens)
curl -X POST http://localhost:5000/api/auth/logout \
  -H "Authorization: Bearer $TOKEN"
```

## 📊 Technology Stack

### Core Framework
- **.NET 8** - Latest LTS runtime và SDK
- **ASP.NET Core 8** - High-performance web API framework
- **Entity Framework Core 8** - Modern ORM with advanced features
- **C# 12** - Latest language features

### Databases & Caching
- **PostgreSQL 15** - Primary relational database
- **Redis 7** - Distributed caching và session storage
- **Entity Framework Core** - Code-first migrations

### Message Broker & Communication
- **RabbitMQ 3.12** - Reliable message broker
- **Ocelot** - .NET API Gateway with advanced routing
- **HTTP Client Factory** - Resilient HTTP communications

### Architecture & Patterns
- **MediatR** - CQRS và Mediator pattern implementation
- **AutoMapper** - Object-to-object mapping
- **FluentValidation** - Declarative validation rules
- **Polly** - Resilience và transient-fault-handling

### DevOps & Deployment
- **Docker** - Containerization with multi-stage builds
- **Docker Compose** - Multi-container application orchestration
- **Health Checks** - Application và infrastructure monitoring

## 🛠️ Development Setup Options

### Option 1: Full Docker Development (Recommended)
```bash
# 1. Clone và setup
git clone <repository-url>
cd ProductAuthMicroservice

# 2. Copy configurations
copy docker-compose.example.yml docker-compose.yml
copy .env.example .env

# 3. Update configurations trong .env và docker-compose.yml

# 4. Start all services
docker-compose up --build -d

# 5. Check logs
docker-compose logs -f
```

### Option 2: Hybrid Development (Services on host, Infrastructure in Docker)
```bash
# 1. Start only infrastructure services
docker-compose up postgres redis rabbitmq -d

# 2. Update appsettings.json files for local development
# ConnectionStrings sẽ point to localhost ports

# 3. Run services individually trong separate terminals
cd src/AuthService/AuthService.API
dotnet run --urls "http://localhost:5001"

cd src/ProductService/ProductService.API  
dotnet run --urls "http://localhost:5002"

cd src/Gateway/Gateway.API
dotnet run --urls "http://localhost:5000"
```

### Option 3: Full Local Development
```bash
# Prerequisites: Local PostgreSQL, Redis, RabbitMQ installations

# 1. Setup local databases
createdb authservicedb
createdb productservicedb

# 2. Update appsettings.Development.json with local connection strings

# 3. Run migrations
cd src/AuthService/AuthService.API
dotnet ef database update

cd src/ProductService/ProductService.API
dotnet ef database update

# 4. Start services
dotnet run (trong mỗi service directory)
```

## 📚 Detailed Documentation

- **[Complete Setup Guide](MICROSERVICE_SETUP_GUIDE.md)** - Chi tiết setup từ A-Z
- **[Docker Commands Reference](DOCKER_COMMANDS_CHEATSHEET.md)** - Docker command cheatsheet
- **[Configuration Validation](CONFIG_VALIDATION_REPORT.md)** - Configuration troubleshooting
- **[Distributed Auth Guide](DISTRIBUTED_AUTH_IMPLEMENTATION_GUIDE.md)** - Authentication architecture deep dive
- **[Event Bus & RabbitMQ Guide](EVENTBUS_RABBITMQ_TRANSACTION_OUTBOX_GUIDE.md)** - Event-driven patterns
- **[Redis Distributed Cache Guide](REAL_TIME_ROLE_CACHE_GUIDE.md)** - Caching implementation details
- **[Deployment Guide](MICROSERVICES_DEPLOYMENT_GUIDE.md)** - Production deployment strategies

## ⚙️ Configuration Management

### Critical Configuration Files
```
# Template files (safe to commit)
├── .env.example                               # Environment variables template
├── docker-compose.example.yml                # Docker compose template
└── src/*/appsettings.Example.json            # Application settings templates

# Runtime files (excluded from Git)
├── .env                                       # Actual environment variables
├── docker-compose.yml                        # Actual docker compose config
└── src/*/appsettings.json                    # Actual application settings
└── src/*/appsettings.Development.json        # Development overrides
```

### Environment Variables (.env file)
```bash
# Core Configuration
JWT_SECRET_KEY=YourSuperSecretJWTKeyThatIsAtLeast32CharactersLong
DB_USER=productauth_user
DB_PASSWORD=YourSecureDatabasePassword2024

# Infrastructure
REDIS_PASSWORD=YourRedisPassword2024
RABBITMQ_USER=productauth
RABBITMQ_PASSWORD=YourRabbitMQPassword2024

# Application
ADMIN_EMAIL=admin@yourcompany.com
ADMIN_PASSWORD=YourAdminPassword2024
ALLOWED_ORIGINS=https://yourapp.com,https://admin.yourapp.com
```

### appsettings.json Key Sections
```json
{
  "ConnectionConfig": {
    "DefaultConnection": "Host=localhost;Database=authservicedb;Username=user;Password=pass",
    "RetryOnFailure": true,
    "MaxRetryCount": 3
  },
  "JwtConfig": {
    "Key": "Your32CharacterSecretKey",
    "Issuer": "ProductAuthMicroservice",
    "Audience": "ProductAuthMicroservice.Users",
    "ExpireInMinutes": 60
  },
  "Redis": {
    "ConnectionString": "localhost:6379,password=YourRedisPassword",
    "InstanceName": "ProductAuthCache",
    "UserStateCacheMinutes": 120
  },
  "RabbitMQ": {
    "HostName": "localhost",
    "UserName": "user",
    "Password": "pass",
    "ExchangeName": "product_auth_exchange"
  }
}
```

## 🚀 Production Deployment

### Docker Production Deployment
```bash
# 1. Prepare production configurations
cp docker-compose.example.yml docker-compose.prod.yml

# 2. Update production-specific settings
# - Use strong passwords
# - Configure SSL/TLS
# - Set up monitoring
# - Configure log aggregation

# 3. Deploy with production config
docker-compose -f docker-compose.prod.yml up -d

# 4. Verify deployment
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs --tail=50
```

### Scaling Services
```bash
# Scale ProductService for high load
docker-compose up --scale productservice=3 -d

# Scale with specific resource limits
docker-compose up --scale productservice=3 --scale authservice=2 -d

# Monitor scaled services
docker-compose ps
docker stats
```

### Health Monitoring
```bash
# Service health endpoints
curl http://localhost:5000/health                    # Gateway health
curl http://localhost:5001/health/ready             # AuthService readiness
curl http://localhost:5002/health/live              # ProductService liveness

# Infrastructure health
curl http://localhost:15672/api/healthchecks/node   # RabbitMQ health
redis-cli -p 6379 ping                              # Redis health
```

## 🔍 Troubleshooting Guide

### Common Issues & Solutions

#### 1. Authentication Issues
```bash
# Symptom: "User session not found" errors
# Solution: Check Redis connection và JWT configuration

# Verify Redis connection
docker-compose exec redis redis-cli ping
docker-compose logs redis

# Check JWT configuration consistency across services
grep -r "JwtConfig" src/*/appsettings.json
```

#### 2. Database Connection Issues
```bash
# Symptom: Database connection timeouts
# Solution: Check PostgreSQL health và connection strings

# Check database status
docker-compose exec authservice-db psql -U username -d authservicedb -c "SELECT 1;"

# View connection logs
docker-compose logs authservice-db
docker-compose logs productservice-db
```

#### 3. Service Communication Issues
```bash
# Symptom: Services can't communicate
# Solution: Check Docker network và service discovery

# Verify network connectivity
docker network ls
docker network inspect productauth-network

# Test inter-service communication
docker-compose exec gateway curl http://authservice/health
```

#### 4. Event Bus Issues
```bash
# Symptom: Events not being processed
# Solution: Check RabbitMQ queues và connections

# Access RabbitMQ Management UI: http://localhost:15672
# Check queue status
docker-compose exec rabbitmq rabbitmqctl list_queues

# Monitor message flow
docker-compose logs -f rabbitmq
```

### Performance Optimization

#### Redis Cache Optimization
```json
{
  "Redis": {
    "ConnectTimeout": 5000,
    "SyncTimeout": 5000,
    "ConnectRetry": 3,
    "AbortOnConnectFail": false
  },
  "Cache": {
    "UserStateCacheMinutes": 30,
    "MaxCacheSize": 10000,
    "CleanupIntervalMinutes": 60
  }
}
```

#### Database Performance
```json
{
  "ConnectionConfig": {
    "MaxRetryCount": 3,
    "MaxRetryDelay": 30,
    "CommandTimeout": 60,
    "EnableSensitiveDataLogging": false
  }
}
```

### Security Best Practices

#### 1. JWT Security
```json
{
  "JwtConfig": {
    "Key": "Use-Strong-256-Bit-Secret-Key-Here",
    "ValidateIssuer": true,
    "ValidateAudience": true,
    "ValidateLifetime": true,
    "ValidateIssuerSigningKey": true,
    "ClockSkewMinutes": 5
  }
}
```

#### 2. Database Security
```bash
# Use strong passwords
# Enable SSL connections trong production
# Regular backup strategies
# Implement connection encryption
```

#### 3. Redis Security
```bash
# Always use password authentication
# Configure SSL/TLS for production
# Restrict network access
# Regular security updates
```

## 📋 Git Repository Best Practices

### Pre-commit Checklist
```bash
# ✅ Configuration files excluded
git status | grep -E "\.(json|yml|env)$"

# ✅ No sensitive data
git diff --cached | grep -i -E "(password|secret|key|token)"

# ✅ Build artifacts excluded
git status | grep -E "(bin/|obj/|*.log)"

# ✅ All tests passing
dotnet test
```

### Commit Message Convention
```bash
# Format: <type>(<scope>): <description>
feat(auth): add Redis distributed caching
fix(gateway): resolve middleware dependency injection
docs(readme): update setup instructions
refactor(product): improve query performance
test(auth): add integration tests for login flow
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Follow [Git Setup Guide](GIT_SETUP_GUIDE.md) for secure development
4. Commit changes using [conventional commit format](GIT_SETUP_GUIDE.md#-commit-message-conventions)
5. Push to branch (`git push origin feature/amazing-feature`)
6. Open Pull Request

### Development Guidelines
- Follow the [Complete Setup Guide](COMPLETE_SETUP_GUIDE.md) for local development
- Use the provided configuration templates (*.example files)
- Never commit sensitive configuration files
- Write comprehensive tests for new features
- Update documentation for any configuration changes

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Clean Architecture by Robert C. Martin
- Microservices patterns by Chris Richardson
- Event-driven architecture patterns
- .NET community and contributors
- Redis Labs for distributed caching insights
- RabbitMQ team for reliable messaging patterns

---

**Built with ❤️ using .NET 8, Redis distributed caching, and modern microservice patterns**

### 🚀 Quick Links
- 📖 [Complete Setup Guide](COMPLETE_SETUP_GUIDE.md) - Detailed setup from A to Z
- 🔧 [Git Setup Guide](GIT_SETUP_GUIDE.md) - Secure Git repository configuration
- 🐳 [Docker Commands](DOCKER_COMMANDS_CHEATSHEET.md) - Docker command reference
- 🔐 [Security Guide](DISTRIBUTED_AUTH_IMPLEMENTATION_GUIDE.md) - Authentication architecture
- 📡 [Event Bus Guide](EVENTBUS_RABBITMQ_TRANSACTION_OUTBOX_GUIDE.md) - Event-driven patterns
- ⚡ [Performance Guide](REAL_TIME_ROLE_CACHE_GUIDE.md) - Redis caching optimization

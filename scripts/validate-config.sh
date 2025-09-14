#!/bin/bash
# =============================================================================
# Configuration Validation Script
# =============================================================================
# This script validates the configuration files for security and completeness

set -e

echo "🔍 ProductAuth Configuration Validator"
echo "====================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

print_check() {
    echo -e "${BLUE}🔍 Checking: $1${NC}"
}

print_pass() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
    ((WARNINGS++))
}

print_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
    ((ERRORS++))
}

# Check if required files exist
print_check "Required configuration files"

if [ ! -f ".env" ]; then
    print_error ".env file is missing. Copy from .env.example"
else
    print_pass ".env file exists"
fi

if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml file is missing. Copy from docker-compose.example.yml"
else
    print_pass "docker-compose.yml file exists"
fi

# Check appsettings.json files
services=("AuthService" "ProductService" "Gateway")
for service in "${services[@]}"; do
    config_file="src/${service}/${service}.API/appsettings.json"
    if [ ! -f "$config_file" ]; then
        print_error "appsettings.json for $service is missing"
    else
        print_pass "appsettings.json for $service exists"
        
        # Check for placeholder values
        if grep -q "your_" "$config_file"; then
            print_warning "Placeholder values found in $service appsettings.json"
        fi
        
        # Validate JSON syntax
        if python -m json.tool "$config_file" > /dev/null 2>&1; then
            print_pass "$service appsettings.json has valid JSON syntax"
        else
            print_error "$service appsettings.json has invalid JSON syntax"
        fi
    fi
done

# Security checks
print_check "Security configuration"

# Check for weak passwords in .env
if [ -f ".env" ]; then
    # Check password strength
    while IFS= read -r line; do
        if [[ $line =~ ^[A-Z_]+_PASSWORD= ]]; then
            password=$(echo "$line" | cut -d'=' -f2)
            if [ ${#password} -lt 12 ]; then
                print_warning "Weak password detected: $line (should be 12+ characters)"
            elif [[ ! $password =~ [A-Z] ]] || [[ ! $password =~ [a-z] ]] || [[ ! $password =~ [0-9] ]]; then
                print_warning "Weak password complexity: $line (should include uppercase, lowercase, numbers)"
            else
                print_pass "Strong password: $(echo "$line" | cut -d'=' -f1)"
            fi
        fi
        
        # Check JWT secret length
        if [[ $line =~ ^JWT_SECRET_KEY= ]]; then
            secret=$(echo "$line" | cut -d'=' -f2)
            if [ ${#secret} -lt 32 ]; then
                print_error "JWT secret key too short: ${#secret} characters (minimum 32 required)"
            else
                print_pass "JWT secret key length is adequate: ${#secret} characters"
            fi
        fi
    done < ".env"
fi

# Check docker-compose.yml for placeholder values
if [ -f "docker-compose.yml" ]; then
    print_check "Docker Compose configuration"
    
    if grep -q "your_" "docker-compose.yml"; then
        print_warning "Placeholder values found in docker-compose.yml"
        echo "Found placeholders:"
        grep "your_" "docker-compose.yml" | head -5
    else
        print_pass "No placeholder values in docker-compose.yml"
    fi
    
    # Check for consistent JWT keys across services
    jwt_keys=$(grep -o 'JwtConfig__Key.*' "docker-compose.yml" | cut -d'"' -f2 | sort -u)
    jwt_count=$(echo "$jwt_keys" | wc -l)
    
    if [ "$jwt_count" -eq 1 ]; then
        print_pass "JWT keys are consistent across all services"
    else
        print_error "Inconsistent JWT keys found across services"
        echo "Found $jwt_count different JWT keys:"
        echo "$jwt_keys"
    fi
fi

# Check for sensitive files in git staging
print_check "Git security"

if [ -d ".git" ]; then
    # Check if sensitive files are staged
    staged_files=$(git diff --cached --name-only 2>/dev/null || echo "")
    
    if echo "$staged_files" | grep -E "(appsettings\.json|appsettings\.Development\.json|\.env|docker-compose\.yml)$" > /dev/null; then
        print_error "Sensitive configuration files are staged for commit:"
        echo "$staged_files" | grep -E "(appsettings\.json|appsettings\.Development\.json|\.env|docker-compose\.yml)$"
    else
        print_pass "No sensitive files staged for commit"
    fi
    
    # Check gitignore effectiveness
    if git status --ignored | grep -E "(appsettings\.json|\.env|docker-compose\.yml)$" > /dev/null 2>&1; then
        print_warning "Sensitive files found in working directory (should be in .gitignore)"
    else
        print_pass "No sensitive files in working directory"
    fi
else
    print_warning "Not a git repository"
fi

# Network and port checks
print_check "Port availability"

ports=(5000 5001 5002 5433 5434 6379 5672 15672)
for port in "${ports[@]}"; do
    if netstat -tuln 2>/dev/null | grep ":$port " > /dev/null; then
        print_warning "Port $port is already in use"
    else
        print_pass "Port $port is available"
    fi
done

# Docker checks
print_check "Docker environment"

if command -v docker &> /dev/null; then
    if docker info > /dev/null 2>&1; then
        print_pass "Docker is running"
        
        # Check Docker resources
        memory=$(docker system info --format '{{.MemTotal}}' 2>/dev/null || echo "0")
        if [ "$memory" -gt 4000000000 ]; then  # 4GB in bytes
            print_pass "Docker has sufficient memory allocated"
        else
            print_warning "Docker may need more memory (current: $(($memory/1000000))MB, recommended: 4GB+)"
        fi
    else
        print_error "Docker is installed but not running"
    fi
else
    print_error "Docker is not installed"
fi

if command -v docker-compose &> /dev/null; then
    print_pass "Docker Compose is available"
else
    print_error "Docker Compose is not installed"
fi

# Configuration completeness check
print_check "Configuration completeness"

required_env_vars=(
    "DB_USER"
    "DB_PASSWORD"
    "JWT_SECRET_KEY"
    "REDIS_PASSWORD"
    "RABBITMQ_USER"
    "RABBITMQ_PASSWORD"
    "ADMIN_EMAIL"
    "ADMIN_PASSWORD"
)

if [ -f ".env" ]; then
    for var in "${required_env_vars[@]}"; do
        if grep -q "^$var=" ".env"; then
            value=$(grep "^$var=" ".env" | cut -d'=' -f2)
            if [ -n "$value" ] && [[ ! "$value" =~ ^your_ ]]; then
                print_pass "$var is configured"
            else
                print_warning "$var is not properly configured"
            fi
        else
            print_error "$var is missing from .env file"
        fi
    done
fi

# Service-specific checks
print_check "Service configuration"

# Check Redis configuration consistency
if [ -f "docker-compose.yml" ]; then
    redis_passwords=$(grep -o 'password=[^,]*' "docker-compose.yml" | cut -d'=' -f2 | sort -u)
    redis_count=$(echo "$redis_passwords" | wc -l)
    
    if [ "$redis_count" -eq 1 ]; then
        print_pass "Redis passwords are consistent across services"
    else
        print_error "Inconsistent Redis passwords found"
    fi
fi

# Final summary
echo ""
echo "🏁 Configuration Validation Summary"
echo "=================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    print_pass "Configuration validation passed with no issues!"
    echo "🚀 Your configuration is ready for deployment."
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Configuration validation passed with $WARNINGS warning(s).${NC}"
    echo "🚀 Your configuration should work, but please review the warnings above."
else
    echo -e "${RED}❌ Configuration validation failed with $ERRORS error(s) and $WARNINGS warning(s).${NC}"
    echo "🛠️  Please fix the errors above before proceeding."
    exit 1
fi

echo ""
echo "📋 Next steps:"
echo "  1. Review and fix any warnings above"
echo "  2. Run 'docker-compose up --build -d' to start services"
echo "  3. Use 'docker-compose logs -f' to monitor startup"
echo "  4. Test endpoints: http://localhost:5000/health"

exit 0
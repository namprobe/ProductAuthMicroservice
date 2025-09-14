#!/bin/bash
# =============================================================================
# ProductAuth Microservice - Quick Setup Script
# =============================================================================
# This script automates the initial setup process for development environment
# Usage: ./scripts/quick-setup.sh

set -e  # Exit on any error

echo "🚀 ProductAuth Microservice - Quick Setup"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}📋 Step $1: $2${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
print_step "1" "Checking prerequisites"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker Desktop first."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

print_success "Docker and Docker Compose are available"

# Check if .env.example exists
if [ ! -f ".env.example" ]; then
    print_error ".env.example file not found. Please ensure you're in the project root directory."
    exit 1
fi

print_success "Configuration templates found"

# Setup configuration files
print_step "2" "Setting up configuration files"

# Copy .env file if it doesn't exist
if [ ! -f ".env" ]; then
    cp .env.example .env
    print_success "Created .env file from template"
    print_warning "Please update .env file with your actual configuration values"
else
    print_warning ".env file already exists, skipping copy"
fi

# Copy docker-compose.yml if it doesn't exist
if [ ! -f "docker-compose.yml" ]; then
    cp docker-compose.example.yml docker-compose.yml
    print_success "Created docker-compose.yml from template"
    print_warning "Please update docker-compose.yml with your actual configuration values"
else
    print_warning "docker-compose.yml file already exists, skipping copy"
fi

# Copy appsettings.json files
print_step "3" "Setting up appsettings.json files"

services=("AuthService" "ProductService" "Gateway")
for service in "${services[@]}"; do
    src_path="src/${service}/${service}.API/appsettings.Example.json"
    dest_path="src/${service}/${service}.API/appsettings.json"
    
    if [ -f "$src_path" ]; then
        if [ ! -f "$dest_path" ]; then
            cp "$src_path" "$dest_path"
            print_success "Created appsettings.json for $service"
        else
            print_warning "appsettings.json for $service already exists, skipping copy"
        fi
    else
        print_warning "Template file $src_path not found"
    fi
done

# Generate strong passwords
print_step "4" "Configuration recommendations"

echo ""
echo "🔐 For security, please update the following in your configuration files:"
echo ""

# Generate sample strong passwords
DB_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-16)
REDIS_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-16)
RABBITMQ_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-16)
JWT_SECRET=$(openssl rand -base64 48 | tr -d "=+/" | cut -c1-32)
ADMIN_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-16)

echo "📝 Suggested strong passwords (update in .env and docker-compose.yml):"
echo "   DB_PASSWORD=$DB_PASSWORD"
echo "   REDIS_PASSWORD=$REDIS_PASSWORD"
echo "   RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD"
echo "   JWT_SECRET_KEY=ProductAuth${JWT_SECRET}ForSecurity"
echo "   ADMIN_PASSWORD=Admin${ADMIN_PASSWORD}"
echo ""

print_warning "Remember to update both .env AND docker-compose.yml files with the same values!"

# Docker operations
print_step "5" "Docker setup"

# Check if any containers are running
if [ "$(docker-compose ps -q)" ]; then
    print_warning "Some containers are already running. Stopping them first..."
    docker-compose down
fi

# Pull base images
print_step "6" "Pulling base Docker images"
echo "This may take a few minutes on first run..."

docker pull postgres:15-alpine
docker pull redis:7-alpine  
docker pull rabbitmq:3.12-management-alpine

print_success "Base images pulled successfully"

# Build and start services
print_step "7" "Building and starting services"

echo "Building application images..."
docker-compose build

echo "Starting infrastructure services first..."
docker-compose up -d authservice-db productservice-db redis rabbitmq

echo "Waiting for infrastructure to be ready (30 seconds)..."
sleep 30

echo "Starting application services..."
docker-compose up -d

# Health check
print_step "8" "Verifying deployment"

echo "Waiting for services to start (60 seconds)..."
sleep 60

echo ""
echo "🏥 Checking service health..."

# Check container status
echo "📊 Container Status:"
docker-compose ps

echo ""
echo "🔍 Testing service endpoints..."

# Function to test endpoint
test_endpoint() {
    local url=$1
    local service_name=$2
    
    if curl -s -f "$url" > /dev/null; then
        print_success "$service_name is healthy"
    else
        print_error "$service_name is not responding at $url"
    fi
}

# Test endpoints
test_endpoint "http://localhost:5000/health" "Gateway"
test_endpoint "http://localhost:5001/health" "AuthService"  
test_endpoint "http://localhost:5002/health" "ProductService"

# Final instructions
print_step "9" "Setup complete!"

echo ""
echo "🎉 ProductAuth Microservice is now running!"
echo ""
echo "📋 Service URLs:"
echo "   🌐 Gateway (Main API):        http://localhost:5000"
echo "   🔐 AuthService:              http://localhost:5001"
echo "   📦 ProductService:           http://localhost:5002"
echo "   🐰 RabbitMQ Management:      http://localhost:15672"
echo ""
echo "📖 Next Steps:"
echo "   1. Open your browser and visit http://localhost:5000"
echo "   2. Test the API using the examples in README.md"
echo "   3. Access RabbitMQ Management UI at http://localhost:15672"
echo "   4. Read the Complete Setup Guide for detailed configuration"
echo ""
echo "📚 Documentation:"
echo "   📖 Complete Setup Guide:     COMPLETE_SETUP_GUIDE.md"
echo "   🔧 Git Setup Guide:         GIT_SETUP_GUIDE.md"
echo "   🐳 Docker Commands:         DOCKER_COMMANDS_CHEATSHEET.md"
echo ""
echo "🔧 Troubleshooting:"
echo "   📋 View logs:               docker-compose logs -f"
echo "   🔄 Restart services:        docker-compose restart"
echo "   🛑 Stop all services:       docker-compose down"
echo ""

# Configuration reminder
print_warning "IMPORTANT: Remember to update passwords and secrets in your configuration files before production use!"

echo ""
print_success "Setup completed successfully! Happy coding! 🚀"
#!/bin/bash

# Quick Setup Script for ProductAuth Microservices
# This script demonstrates how to use the synchronized example templates

echo "🚀 ProductAuth Microservices - Quick Setup from Templates"
echo "=========================================================="

# Check if templates exist
if [ ! -f ".env.example" ] || [ ! -f "docker-compose.example.yml" ]; then
    echo "❌ Error: Template files not found!"
    echo "   Please ensure .env.example and docker-compose.example.yml exist"
    exit 1
fi

echo "📋 Step 1: Setting up environment configuration..."
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "✅ Created .env from template"
    echo "⚠️  IMPORTANT: Please edit .env file and update the placeholder values:"
    echo "   - DB_PASSWORD=YOUR_SECURE_DB_PASSWORD"
    echo "   - JWT_SECRET_KEY=YOUR_JWT_SECRET_KEY_AT_LEAST_32_CHARS"
    echo "   - REDIS_PASSWORD=YOUR_SECURE_REDIS_PASSWORD"
    echo "   - RABBITMQ_PASSWORD=YOUR_SECURE_RABBITMQ_PASSWORD"
    echo "   - ADMIN_PASSWORD=YOUR_SECURE_ADMIN_PASSWORD"
else
    echo "ℹ️  .env file already exists, skipping..."
fi

echo ""
echo "📋 Step 2: Setting up Docker Compose configuration..."
if [ ! -f "docker-compose.yml" ]; then
    cp docker-compose.example.yml docker-compose.yml
    echo "✅ Created docker-compose.yml from template"
else
    echo "ℹ️  docker-compose.yml already exists, skipping..."
fi

echo ""
echo "📋 Step 3: Setting up application settings..."

# Copy appsettings.Example.json files to appsettings.json if they don't exist
services=("AuthService" "ProductService" "Gateway")
for service in "${services[@]}"; do
    source_file="src/${service}/${service}.API/appsettings.Example.json"
    target_file="src/${service}/${service}.API/appsettings.json"
    
    if [ -f "$source_file" ] && [ ! -f "$target_file" ]; then
        cp "$source_file" "$target_file"
        echo "✅ Created $target_file from template"
    elif [ -f "$target_file" ]; then
        echo "ℹ️  $target_file already exists, skipping..."
    else
        echo "⚠️  Template $source_file not found"
    fi
done

echo ""
echo "📋 Step 4: Validation..."

# Check if .env has placeholder values
if grep -q "YOUR_" .env 2>/dev/null; then
    echo "⚠️  WARNING: .env file still contains placeholder values!"
    echo "   Please update the following placeholders in .env:"
    grep "YOUR_" .env | sed 's/^/   - /'
    echo ""
fi

echo "📋 Step 5: Ready to run!"
echo "=========================================="
echo "1. Make sure you've updated all placeholder values in .env"
echo "2. Run: docker-compose up -d"
echo "3. Wait for all services to be healthy"
echo "4. Access services:"
echo "   - Gateway API: http://localhost:5000"
echo "   - Auth API: http://localhost:5001"
echo "   - Product API: http://localhost:5002"
echo "   - pgAdmin: http://localhost:5050"
echo "   - RabbitMQ Management: http://localhost:15672"
echo ""
echo "📚 For detailed setup instructions, see:"
echo "   - README.md"
echo "   - COMPLETE_SETUP_GUIDE.md"
echo "   - TEMPLATE_SYNC_VERIFICATION.md"
echo ""
echo "🎉 Setup complete! Templates have been copied and are ready for configuration."
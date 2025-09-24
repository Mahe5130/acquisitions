#!/bin/bash

# Development Environment Startup Script
# This script starts the Acquisitions app with Neon Local for development

echo "🚀 Starting Acquisitions Development Environment with Neon Local"

# Check if Docker is running
echo "🔍 Checking Docker..."
if ! docker version >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi
echo "✅ Docker is running"

# Check if .env.development exists
if [ ! -f ".env.development" ]; then
    echo "❌ .env.development file not found. Please create it with your Neon credentials."
    echo "Required variables: NEON_API_KEY, NEON_PROJECT_ID, PARENT_BRANCH_ID"
    exit 1
fi

# Validate environment variables
echo "🔍 Validating environment variables..."
source .env.development

missing_vars=()
if [[ -z "$NEON_API_KEY" || "$NEON_API_KEY" == *"your_"*"_here" ]]; then
    missing_vars+=("NEON_API_KEY")
fi
if [[ -z "$NEON_PROJECT_ID" || "$NEON_PROJECT_ID" == *"your_"*"_here" ]]; then
    missing_vars+=("NEON_PROJECT_ID")
fi
if [[ -z "$PARENT_BRANCH_ID" || "$PARENT_BRANCH_ID" == *"your_"*"_here" ]]; then
    missing_vars+=("PARENT_BRANCH_ID")
fi

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "❌ Missing or placeholder values for: ${missing_vars[*]}"
    echo "Please update .env.development with actual values from your Neon Console"
    exit 1
fi

echo "✅ Environment variables validated"

# Add .neon_local to .gitignore if not already there
if [ -f ".gitignore" ]; then
    if ! grep -q ".neon_local/" .gitignore; then
        echo -e "\n# Neon Local\n.neon_local/" >> .gitignore
        echo "✅ Added .neon_local/ to .gitignore"
    fi
fi

# Stop any existing containers
echo "🛑 Stopping any existing containers..."
docker-compose -f docker-compose.dev.yml down 2>/dev/null || true

# Start the development environment
echo "🏗️ Building and starting containers..."
echo "This may take a few minutes on first run..."

docker-compose --env-file .env.development -f docker-compose.dev.yml up --build

echo ""
echo "🎉 Development environment stopped."
echo "To start again, run: ./start-dev.sh"
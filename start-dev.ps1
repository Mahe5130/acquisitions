# Development Environment Startup Script
# This script starts the Acquisitions app with Neon Local for development

Write-Host "🚀 Starting Acquisitions Development Environment with Neon Local" -ForegroundColor Green

# Check if Docker is running
Write-Host "🔍 Checking Docker..." -ForegroundColor Yellow
try {
    docker version | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

# Check if .env.development exists
if (-not (Test-Path ".env.development")) {
    Write-Host "❌ .env.development file not found. Please create it with your Neon credentials." -ForegroundColor Red
    Write-Host "Required variables: NEON_API_KEY, NEON_PROJECT_ID, PARENT_BRANCH_ID" -ForegroundColor Yellow
    exit 1
}

# Load environment variables from .env.development for validation
Write-Host "🔍 Validating environment variables..." -ForegroundColor Yellow

$envContent = Get-Content ".env.development"
$envVars = @{}
foreach ($line in $envContent) {
    if ($line -match "^([^#][^=]*)=(.*)$") {
        $envVars[$matches[1]] = $matches[2]
    }
}

$requiredVars = @("NEON_API_KEY", "NEON_PROJECT_ID", "PARENT_BRANCH_ID")
$missingVars = @()

foreach ($var in $requiredVars) {
    if (-not $envVars.ContainsKey($var) -or $envVars[$var] -match "your_.*_here") {
        $missingVars += $var
    }
}

if ($missingVars.Count -gt 0) {
    Write-Host "❌ Missing or placeholder values for: $($missingVars -join ', ')" -ForegroundColor Red
    Write-Host "Please update .env.development with actual values from your Neon Console" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Environment variables validated" -ForegroundColor Green

# Add .neon_local to .gitignore if not already there
if (Test-Path ".gitignore") {
    $gitignoreContent = Get-Content ".gitignore" -Raw
    if (-not $gitignoreContent.Contains(".neon_local/")) {
        Add-Content -Path ".gitignore" -Value "`n# Neon Local`n.neon_local/"
        Write-Host "✅ Added .neon_local/ to .gitignore" -ForegroundColor Green
    }
}

# Stop any existing containers
Write-Host "🛑 Stopping any existing containers..." -ForegroundColor Yellow
docker-compose -f docker-compose.dev.yml down 2>$null

# Start the development environment
Write-Host "🏗️ Building and starting containers..." -ForegroundColor Yellow
Write-Host "This may take a few minutes on first run..." -ForegroundColor Gray

docker-compose --env-file .env.development -f docker-compose.dev.yml up --build

Write-Host "`n🎉 Development environment stopped." -ForegroundColor Green
Write-Host "To start again, run: ./start-dev.ps1" -ForegroundColor Yellow
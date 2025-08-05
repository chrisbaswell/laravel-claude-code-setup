#!/bin/bash

# Pre-installation check script for Laravel Claude Code Setup
# Run this before setup.sh to identify potential issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

echo "Laravel Claude Code Setup - Pre-Installation Check"
echo "================================================="
echo ""

ISSUES_FOUND=0

print_header "Laravel Project Verification"

# Check if we're in a Laravel project
if [ ! -f "artisan" ] || [ ! -f "composer.json" ]; then
    print_error "Not a Laravel project directory"
    ((ISSUES_FOUND++))
else
    print_success "Laravel project detected"
fi

# Check .env file
if [ ! -f ".env" ]; then
    print_error ".env file not found"
    print_status "Copy .env.example to .env and configure it"
    ((ISSUES_FOUND++))
else
    print_success ".env file exists"
    
    # Check database configuration
    if ! grep -q "^DB_DATABASE=" .env || grep -q "^DB_DATABASE=$" .env; then
        print_warning "DB_DATABASE not configured in .env"
        print_status "Database MCP integration will be skipped"
        print_status "To fix: Set DB_DATABASE=your_database_name in .env"
    else
        print_success "Database configuration found"
    fi
fi

print_header "System Requirements"

# Check PHP version
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -r "echo PHP_VERSION;")
    if [[ $(echo "$PHP_VERSION 8.3" | awk '{print ($1 >= $2)}') == "1" ]]; then
        print_success "PHP $PHP_VERSION (meets Laravel 12 requirement)"
    else
        print_error "PHP $PHP_VERSION (Laravel 12 requires PHP 8.3+)"
        ((ISSUES_FOUND++))
    fi
else
    print_error "PHP not found"
    ((ISSUES_FOUND++))
fi

# Check Node.js version
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version | sed 's/v//')
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d. -f1)
    if [ "$NODE_MAJOR" -ge 20 ]; then
        print_success "Node.js $NODE_VERSION (meets requirement)"
    else
        print_warning "Node.js $NODE_VERSION (recommended: 20+)"
    fi
else
    print_error "Node.js not found"
    ((ISSUES_FOUND++))
fi

# Check npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    print_success "npm $NPM_VERSION"
else
    print_error "npm not found"
    ((ISSUES_FOUND++))
fi

# Check Git
if command -v git &> /dev/null; then
    print_success "Git available"
else
    print_error "Git not found (required for MCP server installation)"
    ((ISSUES_FOUND++))
fi

# Check Claude Code
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
    print_success "Claude Code installed ($CLAUDE_VERSION)"
else
    print_error "Claude Code not found"
    print_status "Install from: https://claude.ai/code"
    ((ISSUES_FOUND++))
fi

print_header "Optional Dependencies"

# Check Go (for database MCP server)
if command -v go &> /dev/null; then
    GO_VERSION=$(go version | grep -o 'go[0-9]*\.[0-9]*' | grep -o '[0-9]*\.[0-9]*')
    print_success "Go $GO_VERSION (for database MCP server)"
else
    print_warning "Go not found (database MCP server will be skipped)"
    print_status "Install Go from: https://golang.org/dl/"
fi

# Check Laravel Herd
if command -v herd &> /dev/null; then
    print_success "Laravel Herd available"
else
    print_warning "Laravel Herd not found"
    print_status "Install from: https://herd.laravel.com"
    print_status "Recommended for optimal local development experience"
fi

print_header "Project Dependencies"

# Check if composer.json has required packages
if [ -f "composer.json" ]; then
    if grep -q "livewire/flux" composer.json; then
        print_success "FluxUI package found"
    else
        print_warning "FluxUI not installed"
        print_status "Will be installed during setup if you choose"
    fi
    
    if grep -q "livewire/volt" composer.json; then
        print_success "Livewire Volt package found"
    else
        print_warning "Livewire Volt not installed"
        print_status "Will be installed during setup if you choose"
    fi
fi

# Check package.json for Playwright
if [ -f "package.json" ]; then
    if grep -q "@playwright/test" package.json; then
        print_success "Playwright test package found"
    else
        print_warning "Playwright not in package.json"
        print_status "Playwright browsers will need manual installation later"
    fi
fi

echo ""
print_header "Summary"

if [ $ISSUES_FOUND -eq 0 ]; then
    print_success "All requirements met! Ready to run setup.sh"
    echo ""
    echo "Run: ./setup.sh"
else
    print_error "Found $ISSUES_FOUND critical issue(s) that need to be resolved"
    echo ""
    echo "Please fix the issues above before running setup.sh"
fi

echo ""
exit $ISSUES_FOUND 
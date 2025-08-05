#!/bin/bash

# Laravel Claude Code Setup Script v3.1
# Optimized for Laravel 12, FluxUI, and modern MCP servers including Playwright
# Author: Laravel Developer
# Version: 3.1 - Laravel 12 + FluxUI + Playwright MCP server

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}[SETUP]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Check if we're in a Laravel project
check_laravel_project() {
    print_step "Verifying Laravel project..."
    
    if [ ! -f "artisan" ] || [ ! -f "composer.json" ]; then
        print_error "This doesn't appear to be a Laravel project directory!"
        print_error "Please run this script from your Laravel project root."
        exit 1
    fi
    
    # Check if it's Laravel 11+ (which has the new structure)
    if ! grep -q '"laravel/framework"' composer.json; then
        print_error "Could not detect Laravel framework in composer.json"
        exit 1
    fi
    
    # Extract Laravel version
    LARAVEL_VERSION=$(grep '"laravel/framework"' composer.json | grep -o '"[^"]*"' | tail -1 | tr -d '"' | cut -d'^' -f2)
    print_success "Laravel project detected! Version: $LARAVEL_VERSION"
    
    if [ ! -f ".env" ]; then
        print_error ".env file not found! Please ensure your Laravel project is properly set up."
        exit 1
    fi
    
    print_success "Environment file found!"
}

# Better interactive detection that handles curl pipe correctly
can_interact_with_user() {
    # Check if we have a controlling terminal (even if stdin is piped)
    if [ -t 1 ] && [ -t 2 ]; then
        # stdout and stderr are terminals
        # Check if we're NOT in a true non-interactive environment
        if [ -z "$CI" ] && [ -z "$GITHUB_ACTIONS" ] && [ -z "$JENKINS_URL" ]; then
            # Try to access the controlling terminal directly
            if [ -e /dev/tty ]; then
                return 0  # We can interact with the user
            fi
        fi
    fi
    
    return 1  # Cannot interact with user
}

# Helper function to read input from controlling terminal
read_from_user() {
    local prompt="$1"
    local variable_name="$2"
    
    if can_interact_with_user; then
        # Read from controlling terminal instead of stdin
        printf "%s" "$prompt" > /dev/tty
        read -r "$variable_name" < /dev/tty
        return 0
    else
        return 1
    fi
}

# Check GitHub authentication and collect tokens if needed
collect_github_token() {
    print_step "Checking GitHub authentication..."
    echo ""
    
    # Check if GITHUB_TOKEN is already set in environment
    if [ -n "$GITHUB_TOKEN" ]; then
        print_success "Using GITHUB_TOKEN from environment: ${GITHUB_TOKEN:0:8}..."
        
        # Ask if user wants to update token
        if can_interact_with_user; then
            echo ""
            local update_token
            if read_from_user "Do you want to update this GitHub token? (y/n): " update_token; then
                if [ "$update_token" = "y" ] || [ "$update_token" = "yes" ]; then
                    local new_github_token
                    if read_from_user "Enter your new GitHub Personal Access Token: " new_github_token; then
                        if [ ! -z "$new_github_token" ]; then
                            GITHUB_TOKEN="$new_github_token"
                            print_success "GitHub token updated successfully!"
                        fi
                    fi
                fi
            fi
        fi
        return 0
    fi
    
    # Check for existing token in Claude config
    CONFIG_FILE="$HOME/.claude.json"
    if [ -f "$CONFIG_FILE" ] && command -v jq &> /dev/null; then
        EXISTING_TOKEN=$(jq -r '.mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
        
        if [ ! -z "$EXISTING_TOKEN" ] && [ "$EXISTING_TOKEN" != "null" ] && [ "$EXISTING_TOKEN" != "empty" ]; then
            print_success "Found existing GitHub token in Claude config: ${EXISTING_TOKEN:0:8}..."
            GITHUB_TOKEN="$EXISTING_TOKEN"
            return 0
        fi
    fi
    
    # Test SSH authentication with GitHub
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        print_success "GitHub SSH authentication detected!"
        print_warning "However, for MCP integration, a Personal Access Token is recommended."
        
        if can_interact_with_user; then
            echo ""
            echo "Choose GitHub authentication method:"
            echo "1) Use SSH (limited for private repos in MCP)"
            echo "2) Provide Personal Access Token (recommended)"
            local auth_choice
            if read_from_user "Enter choice (1 or 2): " auth_choice; then
                if [ "$auth_choice" = "2" ]; then
                    collect_github_token_interactive
                else
                    print_warning "Using SSH authentication - private repository access may be limited"
                    GITHUB_TOKEN=""
                fi
            fi
        else
            print_warning "Non-interactive mode - using SSH authentication"
            GITHUB_TOKEN=""
        fi
    else
        print_warning "No GitHub SSH authentication detected"
        
        if can_interact_with_user; then
            collect_github_token_interactive
        else
            print_error "This script requires a GitHub token for GitHub MCP integration."
            print_error "Please set the GITHUB_TOKEN environment variable and try again:"
            echo ""
            echo "export GITHUB_TOKEN=your_token_here"
            echo "curl -fsSL https://your-script-url | bash"
            echo ""
            exit 1
        fi
    fi
}

collect_github_token_interactive() {
    local attempts=0
    while [ -z "$GITHUB_TOKEN" ] && [ $attempts -lt 3 ]; do
        echo ""
        print_status "To create a GitHub Personal Access Token:"
        echo "1. Go to GitHub.com → Settings → Developer settings → Personal access tokens → Tokens (classic)"
        echo "2. Click 'Generate new token (classic)'"
        echo "3. Select scopes: repo, read:user, user:email"
        echo "4. Copy the generated token"
        echo ""
        local github_token
        if read_from_user "Enter your GitHub Personal Access Token (or 'skip'): " github_token; then
            if [ "$github_token" = "skip" ]; then
                GITHUB_TOKEN=""
                print_warning "Skipping GitHub MCP integration"
                break
            elif [ ! -z "$github_token" ]; then
                GITHUB_TOKEN="$github_token"
                print_success "GitHub token configured!"
                break
            else
                print_warning "Token is required for GitHub MCP integration!"
                attempts=$((attempts + 1))
            fi
        else
            print_status "Could not read input - skipping GitHub integration"
            GITHUB_TOKEN=""
            break
        fi
    done
}

# Check if Claude Code is installed
check_claude_code() {
    print_step "Checking Claude Code installation..."
    
    if ! command -v claude &> /dev/null; then
        print_error "Claude Code is not installed!"
        print_error "Please install Claude Code first from: https://claude.ai/code"
        exit 1
    fi
    
    # Check Claude Code version
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
    print_success "Claude Code is installed! Version: $CLAUDE_VERSION"
}

# Check if Node.js and npm are installed
check_node() {
    print_step "Checking Node.js and npm..."
    
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed! Please install Node.js first."
        print_status "Install with: brew install node (macOS) or visit https://nodejs.org/"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed! Please install npm first."
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    print_success "Node.js $NODE_VERSION and npm $NPM_VERSION are available!"
}

# Check and install Go if needed
check_go() {
    print_step "Checking Go installation for database MCP server..."
    
    if ! command -v go &> /dev/null; then
        print_warning "Go is not installed. Installing via package manager..."
        
        # Detect OS and install Go
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                print_status "Installing Go via Homebrew..."
                brew install go
            else
                print_error "Homebrew not found. Please install Go manually from https://golang.org/dl/"
                return 1
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            if command -v apt-get &> /dev/null; then
                print_status "Installing Go via apt-get..."
                sudo apt-get update && sudo apt-get install -y golang-go
            elif command -v yum &> /dev/null; then
                print_status "Installing Go via yum..."
                sudo yum install -y golang
            elif command -v pacman &> /dev/null; then
                print_status "Installing Go via pacman..."
                sudo pacman -S go
            else
                print_error "Could not detect package manager. Please install Go manually from https://golang.org/dl/"
                return 1
            fi
        else
            print_error "Unsupported OS. Please install Go manually from https://golang.org/dl/"
            return 1
        fi
    fi
    
    # Verify Go installation and version
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | grep -o 'go[0-9]*\.[0-9]*' | grep -o '[0-9]*\.[0-9]*')
        REQUIRED_VERSION="1.22"
        
        if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
            print_success "Go version $GO_VERSION meets requirements!"
            return 0
        else
            print_error "Go version $GO_VERSION is installed, but version $REQUIRED_VERSION or higher is required."
            print_status "Please update Go: brew upgrade go (macOS) or download from https://golang.org/dl/"
            return 1
        fi
    else
        print_error "Go installation failed"
        return 1
    fi
}

# Create MCP servers directory
create_mcp_directory() {
    print_step "Creating MCP servers directory..."
    
    MCP_DIR="$HOME/.config/claude-code/mcp-servers"
    mkdir -p "$MCP_DIR"
    
    print_success "MCP directory created at: $MCP_DIR"
}

# Install Context7 MCP Server
install_context7() {
    print_step "Installing Context7 MCP Server..."
    
    cd "$MCP_DIR"
    
    # Clean install if directory exists
    if [ -d "context7" ]; then
        print_status "Removing existing context7 installation..."
        rm -rf context7
    fi
    
    print_status "Cloning Context7 repository..."
    if ! git clone https://github.com/upstash/context7.git context7; then
        print_error "Failed to clone Context7 repository"
        return 1
    fi
    
    cd context7
    
    print_status "Installing Context7 dependencies..."
    if ! npm install; then
        print_error "Failed to install Context7 dependencies"
        return 1
    fi
    
    print_status "Building Context7..."
    if ! npm run build; then
        print_error "Failed to build Context7"
        return 1
    fi
    
    # Verify the build was successful
    if [ -f "dist/index.js" ]; then
        print_success "Context7 MCP Server installed and built successfully!"
        return 0
    else
        print_error "Context7 build failed - dist/index.js not found"
        return 1
    fi
}

# Install Database MCP Server (FreePeak version)
install_database() {
    print_step "Installing Database MCP Server (FreePeak)..."
    print_status "Note: Installing database MCP server globally (project-specific config handled later)"
    
    if ! check_go; then
        print_warning "Go installation failed. Skipping database MCP server."
        return 1
    fi
    
    cd "$MCP_DIR"
    
    # Clean install if directory exists
    if [ -d "db-mcp-server" ]; then
        print_status "Removing existing db-mcp-server installation..."
        rm -rf db-mcp-server
    fi
    
    print_status "Cloning db-mcp-server repository..."
    if ! git clone https://github.com/FreePeak/db-mcp-server.git db-mcp-server; then
        print_error "Failed to clone db-mcp-server repository"
        return 1
    fi
    
    cd db-mcp-server
    
    print_status "Building Go database MCP server..."
    
    # Try different build methods
    if [ -f "Makefile" ]; then
        print_status "Using Makefile to build..."
        if make build; then
            print_success "Database MCP server built successfully using Makefile!"
        else
            print_warning "Makefile build failed, trying direct Go build..."
            mkdir -p bin
            if go build -o bin/server ./cmd/server 2>/dev/null || go build -o bin/server .; then
                print_success "Database MCP server built successfully using Go build!"
            else
                print_error "Go build failed. Database MCP server installation failed."
                return 1
            fi
        fi
    else
        print_status "No Makefile found, using direct Go build..."
        mkdir -p bin
        if go build -o bin/server ./cmd/server 2>/dev/null || go build -o bin/server .; then
            print_success "Database MCP server built successfully!"
        else
            print_error "Go build failed. Database MCP server installation failed."
            return 1
        fi
    fi
    
    # Verify the binary was created
    if [ -f "bin/server" ] || [ -f "db-mcp-server" ]; then
        print_success "Database MCP Server installed!"
        return 0
    else
        print_error "Database binary not found after build"
        return 1
    fi
}

# Install Playwright MCP Server (Microsoft version)
install_playwright() {
    print_step "Installing Playwright MCP Server (Microsoft)..."
    
    print_status "Installing Playwright MCP server via npm..."
    if npm install -g @playwright/mcp; then
        print_success "Playwright MCP Server installed!"
        
        # Only install browsers if the project already has @playwright/test
        if [ -f "package.json" ] && grep -q '"@playwright/test"' package.json; then
            print_status "Installing Playwright browsers..."
            if npx playwright install; then
                print_success "Playwright browsers installed successfully!"
            else
                print_warning "Failed to install Playwright browsers"
                print_status "You can install them later with: npx playwright install"
            fi
        else
            print_status "Playwright browsers will be installed when you run 'npm install' in your project"
            print_status "After project setup, run: npx playwright install"
        fi
        
        return 0
    else
        print_error "Failed to install Playwright MCP Server"
        return 1
    fi
}

# Install GitHub MCP Server
install_github() {
    print_step "Installing GitHub MCP Server..."
    
    print_status "Note: Installing official GitHub MCP server (deprecated warnings are expected)"
    if npm install -g @modelcontextprotocol/server-github --silent 2>/dev/null || npm install -g @modelcontextprotocol/server-github; then
        print_success "GitHub MCP Server installed!"
        return 0
    else
        print_error "Failed to install GitHub MCP Server"
        return 1
    fi
}

# Install Memory MCP Server
install_memory() {
    print_step "Installing Memory MCP Server..."
    
    if npm install -g @modelcontextprotocol/server-memory; then
        print_success "Memory MCP Server installed!"
        return 0
    else
        print_error "Failed to install Memory MCP Server"
        return 1
    fi
}

# Install Filesystem MCP Server
install_filesystem() {
    print_step "Installing Filesystem MCP Server..."
    
    if npm install -g @modelcontextprotocol/server-filesystem; then
        print_success "Filesystem MCP Server installed!"
        return 0
    else
        print_error "Failed to install Filesystem MCP Server"
        return 1
    fi
}

# Install Fetch MCP Server (zcaceres version - enhanced capabilities)
install_fetch() {
    print_step "Installing Fetch MCP Server (zcaceres - enhanced version)..."
    
    cd "$MCP_DIR"
    
    if [ -d "fetch-mcp" ]; then
        print_status "Removing existing fetch-mcp installation..."
        rm -rf fetch-mcp
    fi
    
    print_status "Cloning zcaceres fetch-mcp repository..."
    if ! git clone https://github.com/zcaceres/fetch-mcp.git fetch-mcp; then
        print_error "Failed to clone zcaceres fetch-mcp repository"
        return 1
    fi
    
    cd fetch-mcp
    
    print_status "Installing fetch-mcp dependencies..."
    # Suppress npm warnings and fix security vulnerabilities
    if npm install --silent 2>/dev/null || npm install; then
        print_status "Fixing security vulnerabilities..."
        npm audit fix --force 2>/dev/null || true
    else
        print_error "Failed to install fetch-mcp dependencies"
        return 1
    fi
    
    print_status "Building fetch-mcp..."
    if npm run build; then
        print_success "Enhanced Fetch MCP Server installed!"
        return 0
    else
        print_error "Failed to build fetch-mcp"
        return 1
    fi
}

# Parse Laravel .env file
parse_env() {
    print_step "Parsing Laravel .env file..."
    
    # Source the .env file safely
    if [ -f ".env" ]; then
        # Parse .env more reliably
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^[[:space:]]*# ]] && continue
            [[ -z $key ]] && continue
            
            # Clean key and value
            key=$(echo "$key" | tr -d '[:space:]')
            # Remove surrounding quotes only (double or single)
            if [[ $value =~ ^\".*\"$ ]]; then
                value="${value:1:${#value}-2}"
            elif [[ $value =~ ^\'.*\'$ ]]; then
                value="${value:1:${#value}-2}"
            fi
            export "$key=$value"
        done < .env
    fi
    
    # Get database connection details with defaults
    DB_CONNECTION=${DB_CONNECTION:-mysql}
    DB_HOST=${DB_HOST:-127.0.0.1}
    DB_PORT=${DB_PORT:-3306}
    DB_DATABASE=${DB_DATABASE:-}
    DB_USERNAME=${DB_USERNAME:-}
    DB_PASSWORD=${DB_PASSWORD:-}
    
    print_success "Environment variables parsed!"
    print_status "Database: $DB_CONNECTION on $DB_HOST:$DB_PORT"
    
    # Debug: Show what we parsed for DB_DATABASE
    if [ -f ".env" ] && grep -q "^DB_DATABASE=" .env; then
        local env_db_value=$(grep "^DB_DATABASE=" .env | cut -d'=' -f2- | sed 's/^["\x27]\|["\x27]$//g')
        print_status "Found DB_DATABASE in .env: '$env_db_value'"
    fi
    
    if [ ! -z "$DB_DATABASE" ] && [ "$DB_DATABASE" != "" ]; then
        print_status "Database name: $DB_DATABASE"
    else
        print_warning "No database name configured in .env file"
        print_status "To enable database MCP integration, set DB_DATABASE in your .env file"
        print_status "Example: DB_DATABASE=your_project_name"
    fi
}

# Generate database configuration for the MCP server
generate_database_config() {
    print_step "Generating database configuration..."
    print_status "Creating project-specific database MCP configuration..."
    
    PROJECT_PATH="$PWD"
    
    if [ -z "$DB_DATABASE" ] || [ "$DB_DATABASE" = "" ]; then
        print_warning "No database name found. Skipping project-specific database MCP configuration."
        print_status "Note: Database MCP server is installed globally but won't be configured for this project"
        print_status "To enable database MCP integration for this project:"
        print_status "1. Set DB_DATABASE in your .env file (e.g., DB_DATABASE=your_project_name)"
        print_status "2. Create the database in MySQL/PostgreSQL"
        print_status "3. Run the setup script again to configure database MCP access"
        return 0
    fi
    
    # Determine the correct database type
    case "$DB_CONNECTION" in
        "mysql")
            DB_TYPE="mysql"
            ;;
        "pgsql"|"postgres"|"postgresql")
            DB_TYPE="postgres"
            ;;
        "sqlite")
            DB_TYPE="sqlite"
            if [[ "$DB_DATABASE" == /* ]]; then
                DB_PATH="$DB_DATABASE"
            else
                DB_PATH="$PROJECT_PATH/database/$DB_DATABASE"
            fi
            ;;
        *)
            DB_TYPE="mysql"
            print_warning "Unknown database type '$DB_CONNECTION', defaulting to mysql"
            ;;
    esac
    
    # Create the database configuration file
    CONFIG_FILE="$PROJECT_PATH/database-config.json"
    
    if [ "$DB_CONNECTION" = "sqlite" ]; then
        cat > "$CONFIG_FILE" << EOF
{
  "connections": [
    {
      "id": "laravel",
      "type": "sqlite",
      "database": "$DB_PATH",
      "query_timeout": 60,
      "max_open_conns": 10,
      "max_idle_conns": 2,
      "conn_max_lifetime_seconds": 300,
      "conn_max_idle_time_seconds": 60
    }
  ]
}
EOF
    else
        cat > "$CONFIG_FILE" << EOF
{
  "connections": [
    {
      "id": "laravel",
      "type": "$DB_TYPE",
      "host": "$DB_HOST",
      "port": $DB_PORT,
      "name": "$DB_DATABASE",
      "user": "$DB_USERNAME",
      "password": "$DB_PASSWORD",
      "query_timeout": 60,
      "max_open_conns": 20,
      "max_idle_conns": 5,
      "conn_max_lifetime_seconds": 300,
      "conn_max_idle_time_seconds": 60
    }
  ]
}
EOF
    fi
    
    print_success "Database configuration created at: $CONFIG_FILE"
    return 0
}

# Configure Claude Code MCP Servers
configure_claude_mcp() {
    print_step "Configuring Claude Code MCP servers..."
    
    PROJECT_PATH="$PWD"
    PROJECT_NAME=$(basename "$PROJECT_PATH")
    
    # Create a project identifier for unique MCP server names
    PROJECT_ID=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
    if [ -z "$PROJECT_ID" ]; then
        PROJECT_ID="laravel$(date +%s)"
    fi
    
    print_status "Project: $PROJECT_NAME (ID: $PROJECT_ID)"
    
    # Check if claude command is available
    if ! command -v claude &> /dev/null; then
        print_error "Claude Code CLI not found. Please ensure Claude Code is properly installed."
        return 1
    fi
    
    print_header "Setting up global MCP servers..."
    
    # Configure GitHub MCP server (global)
    if ! claude mcp list 2>/dev/null | grep -q "^github:"; then
        print_status "Adding global GitHub MCP server..."
        if claude mcp add "github" npx @modelcontextprotocol/server-github; then
            print_success "Global GitHub MCP server added"
            
            # Configure token if available
            if [ ! -z "$GITHUB_TOKEN" ]; then
                print_status "Configuring GitHub token..."
                update_github_token_in_config "$GITHUB_TOKEN" "$PROJECT_PATH"
            fi
        else
            print_error "Failed to add GitHub MCP server"
        fi
    else
        print_success "Global GitHub MCP server already configured"
        
        # Update token if provided
        if [ ! -z "$GITHUB_TOKEN" ]; then
            print_status "Updating GitHub token..."
            update_github_token_in_config "$GITHUB_TOKEN" "$PROJECT_PATH"
        fi
    fi
    
    # Add global Memory MCP server
    if ! claude mcp list 2>/dev/null | grep -q "^memory:"; then
        print_status "Adding global Memory MCP server..."
        if claude mcp add "memory" npx @modelcontextprotocol/server-memory; then
            print_success "Global Memory MCP server added"
        else
            print_warning "Failed to add global Memory MCP server"
        fi
    else
        print_success "Global Memory MCP server already configured"
    fi
    
    # Add global Context7 MCP server
    if [ -f "$MCP_DIR/context7/dist/index.js" ]; then
        if ! claude mcp list 2>/dev/null | grep -q "^context7:"; then
            print_status "Adding global Context7 MCP server..."
            if claude mcp add "context7" node "$MCP_DIR/context7/dist/index.js"; then
                print_success "Global Context7 MCP server added"
            else
                print_warning "Failed to add global Context7 MCP server"
            fi
        else
            print_success "Global Context7 MCP server already configured"
        fi
    fi
    
    # Add global Playwright MCP server
    if command -v npx &> /dev/null && npx @playwright/mcp --version &> /dev/null 2>&1; then
        if ! claude mcp list 2>/dev/null | grep -q "^playwright:"; then
            print_status "Adding global Playwright MCP server..."
            if claude mcp add "playwright" npx @playwright/mcp; then
                print_success "Global Playwright MCP server added"
            else
                print_warning "Failed to add global Playwright MCP server"
            fi
        else
            print_success "Global Playwright MCP server already configured"
        fi
    else
        print_warning "Playwright MCP server not found - skipping configuration"
    fi
    
    # Add global Fetch MCP server (zcaceres enhanced version)
    if [ -f "$MCP_DIR/fetch-mcp/dist/index.js" ]; then
        if ! claude mcp list 2>/dev/null | grep -q "^fetch:"; then
            print_status "Adding global Enhanced Fetch MCP server..."
            if claude mcp add "fetch" node "$MCP_DIR/fetch-mcp/dist/index.js"; then
                print_success "Global Enhanced Fetch MCP server added"
            else
                print_warning "Failed to add global Enhanced Fetch MCP server"
            fi
        else
            print_success "Global Enhanced Fetch MCP server already configured"
        fi
    else
        print_warning "Enhanced Fetch MCP server not found - skipping configuration"
    fi
    
    print_header "Setting up project-specific MCP servers..."
    
    # Clean up old project-specific servers
    print_status "Cleaning up existing project-specific MCP servers..."
    claude mcp list 2>/dev/null | grep -E "^(filesystem|database)-$PROJECT_ID" | awk '{print $1}' | xargs -I {} claude mcp remove {} 2>/dev/null || true
    
    # Add Filesystem MCP server (project-specific)
    print_status "Adding Filesystem MCP server for $PROJECT_NAME..."
    if claude mcp list 2>/dev/null | grep -q "^filesystem-$PROJECT_ID:"; then
        print_success "Filesystem MCP server already configured: filesystem-$PROJECT_ID"
    elif claude mcp add "filesystem-$PROJECT_ID" npx @modelcontextprotocol/server-filesystem "$PROJECT_PATH"; then
        print_success "Filesystem MCP server added: filesystem-$PROJECT_ID"
    else
        print_warning "Failed to add Filesystem MCP server"
    fi
    
    # Add Database MCP server (project-specific)
    if [ -f "$PROJECT_PATH/database-config.json" ] && [ ! -z "$DB_DATABASE" ]; then
        # Find database binary
        DB_BINARY=""
        if [ -f "$MCP_DIR/db-mcp-server/bin/server" ]; then
            DB_BINARY="$MCP_DIR/db-mcp-server/bin/server"
        elif [ -f "$MCP_DIR/db-mcp-server/db-mcp-server" ]; then
            DB_BINARY="$MCP_DIR/db-mcp-server/db-mcp-server"
        fi
        
        if [ ! -z "$DB_BINARY" ] && [ -x "$DB_BINARY" ]; then
            print_status "Adding Database MCP server for $PROJECT_NAME..."
            if claude mcp add "database-$PROJECT_ID" "$DB_BINARY" -- -t stdio -c "$PROJECT_PATH/database-config.json"; then
                print_success "Database MCP server added: database-$PROJECT_ID"
            else
                print_warning "Failed to add Database MCP server"
            fi
        else
            print_warning "Database binary not found or not executable"
        fi
    else
        if [ -z "$DB_DATABASE" ] || [ "$DB_DATABASE" = "" ]; then
            print_status "No database name in .env file, skipping project-specific Database MCP server"
            print_status "Note: Global database MCP server is still available for manual configuration"
        else
            print_warning "Database configuration file not found (database-config.json missing)"
        fi
    fi
    
    # Display final configuration
    print_header "MCP Server Configuration Summary:"
    claude mcp list
    
    print_success "Claude Code MCP configuration completed!"
    
    # Show summary
    echo ""
    print_status "Global MCP servers (shared across all projects):"
    claude mcp list | grep -E "^(github|memory|context7|playwright|fetch):" | sed 's/^/  ✅ /' || true
    echo ""
    print_status "Project-specific MCP servers for $PROJECT_NAME:"
    claude mcp list | grep -E "^(filesystem|database)-$PROJECT_ID" | sed 's/^/  ✅ /' || true
    echo ""
    
    return 0
}

# Helper function to update GitHub token in config
update_github_token_in_config() {
    local TOKEN="$1"
    local PROJECT_PATH="$2"
    local CONFIG_FILE="$HOME/.claude.json"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        print_warning "Claude config file not found at $CONFIG_FILE"
        return 1
    fi
    
    # Create a backup
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
    
    # Try jq first (cleanest method)
    if command -v jq &> /dev/null; then
        if jq --arg token "$TOKEN" --arg project "$PROJECT_PATH" \
           '# Update global config if it exists
            if .mcpServers.github then
              .mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN = $token
            else . end |
            # Update project-specific config
            if .projects[$project].mcpServers.github then
              .projects[$project].mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN = $token
            else . end' \
           "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"; then
            print_success "GitHub token configured successfully!"
            return 0
        fi
    fi
    
    # Try Python fallback
    if command -v python3 &> /dev/null; then
        cat > /tmp/update_github_token.py << PYTHON_EOF
#!/usr/bin/env python3
import json
import sys

try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    
    # Update global config if it exists
    if 'mcpServers' in config:
        if 'github' not in config['mcpServers']:
            config['mcpServers']['github'] = {}
        if 'env' not in config['mcpServers']['github']:
            config['mcpServers']['github']['env'] = {}
        config['mcpServers']['github']['env']['GITHUB_PERSONAL_ACCESS_TOKEN'] = '$TOKEN'
    
    # Update project-specific config
    if 'projects' in config and '$PROJECT_PATH' in config['projects']:
        project = config['projects']['$PROJECT_PATH']
        if 'mcpServers' in project and 'github' in project['mcpServers']:
            if 'env' not in project['mcpServers']['github']:
                project['mcpServers']['github']['env'] = {}
            project['mcpServers']['github']['env']['GITHUB_PERSONAL_ACCESS_TOKEN'] = '$TOKEN'
    
    with open('$CONFIG_FILE', 'w') as f:
        json.dump(config, f, indent=2)
    print("SUCCESS")
except Exception as e:
    print(f"ERROR: {e}")
PYTHON_EOF
        
        RESULT=$(python3 /tmp/update_github_token.py 2>&1)
        rm -f /tmp/update_github_token.py
        
        if [ "$RESULT" = "SUCCESS" ]; then
            print_success "GitHub token configured using Python!"
            return 0
        fi
    fi
    
    print_warning "Could not automatically configure GitHub token"
    print_status "Please manually edit ~/.claude.json and add your token"
    return 1
}

# Create project-specific Claude context files
create_project_context() {
    print_step "Creating project-specific Claude context files..."
    
    # Get current project details
    PROJECT_NAME=$(basename "$PWD")
    PROJECT_PATH="$PWD"
    
    # Create .claude directory with explicit error checking
    if ! mkdir -p ".claude/context"; then
        print_error "Failed to create .claude/context directory in $PROJECT_PATH"
        return 1
    fi
    
    # Create project context file
    print_status "Creating project context file..."
    cat > ".claude/context/project-context.md" << EOF
# ${PROJECT_NAME} - Laravel 12 Project Context

## Project Overview
- **Project Name**: ${PROJECT_NAME}
- **Framework**: Laravel 12
- **Frontend Stack**: Livewire 3.x + Alpine.js + FluxUI + Tailwind CSS
- **Database**: ${DB_CONNECTION}
- **Development Focus**: Modern Laravel 12 development with FluxUI components

## Tech Stack Details

## Tech Stack Details

### Backend
- **Laravel 12**: Latest framework features including new Attribute class
- **PHP 8.3+**: Modern PHP with typed properties and attributes
- **Database**: ${DB_CONNECTION} (${DB_HOST}:${DB_PORT})
- **Authentication**: Laravel Breeze/Sanctum/Passport (as configured)

### Frontend
- **Livewire 3.x**: Server-side rendered components with reactivity
- **Livewire Volt**: Functional component API (preferred over class components)
- **FluxUI**: Pre-built, beautiful components for Livewire
- **Alpine.js**: Minimal JavaScript framework for interactivity
- **Tailwind CSS**: Utility-first CSS framework
- **Vite**: Fast build tool and development server

### Development Tools
- **Claude Code**: AI-powered development assistant
- **MCP Servers**: Context7, GitHub, Memory, Database, Playwright, Enhanced Fetch, Filesystem
- **Testing**: Pest PHP for feature and unit testing
- **Code Quality**: Laravel Pint for code formatting

## Laravel 12 Conventions

### Model Patterns
Use the new Attribute class for accessors and mutators:

\`\`\`php
use Illuminate\Database\Eloquent\Casts\Attribute;

class User extends Model
{
    protected function firstName(): Attribute
    {
        return Attribute::make(
            get: fn (string \$value) => ucfirst(\$value),
            set: fn (string \$value) => strtolower(\$value),
        );
    }
}
\`\`\`

### FluxUI Integration
Always use FluxUI components instead of custom HTML:

\`\`\`blade
{{-- Use FluxUI components --}}
<flux:button variant="primary">Save</flux:button>
<flux:input wire:model="name" placeholder="Enter name" />
<flux:card>
    <flux:card.header>
        <flux:heading>Title</flux:heading>
    </flux:card.header>
    <flux:card.body>
        Content here
    </flux:card.body>
</flux:card>
\`\`\`

### Modern Laravel Features
- Constructor property promotion for cleaner code
- Typed properties throughout the application
- Enhanced validation with new Laravel 12 features
- Improved query builder methods
- Better testing patterns with Pest PHP

## Available MCP Tools

### Global Tools
- **GitHub**: Repository management and code analysis
- **Memory**: Persistent knowledge across sessions
- **Context7**: Access to latest Laravel documentation
- **Web Fetch**: External API and resource access

### Project-Specific Tools
- **Filesystem**: Read and modify project files
- **Database**: Direct database queries and schema analysis

## Development Guidelines

1. **Always use FluxUI components** instead of building custom UI
2. **Follow Laravel 12 patterns** including the new Attribute class
3. **Use Livewire** for dynamic components over vanilla JavaScript
4. **Write tests** using Pest PHP for new functionality
5. **Follow PSR-12** coding standards with Laravel Pint
6. **Use typed properties** and constructor promotion where possible
7. **Leverage MCP tools** for enhanced development workflow

## Project Structure
- Standard Laravel 12 structure with Livewire components
- FluxUI components integrated throughout views
- Modern testing setup with Pest PHP
- Optimized for AI-assisted development with Claude Code

Generated: $(date)
EOF

    # Create coding standards file
    print_status "Creating coding standards file..."
    cat > ".claude/context/coding-standards.md" << EOF
# Coding Standards for ${PROJECT_NAME}

## Laravel 12 Conventions

### Models
- Use the new Attribute class for accessors/mutators
- Implement typed properties with proper casting
- Use constructor property promotion where applicable
- Follow singular naming conventions (User, Post, not Users, Posts)

### Controllers
- Use plural resource names (UsersController, PostsController)
- Stick to RESTful conventions (index, create, store, show, edit, update, destroy)
- Use typed method parameters and return types
- Extract complex logic to service classes

### Livewire Components
- Keep components focused and single-purpose
- Use public properties for data binding with proper validation
- Implement real-time validation where appropriate
- Use FluxUI components exclusively for UI elements

### FluxUI Usage
- Always prefer FluxUI components over custom HTML/CSS
- Use proper component structure (flux:field, flux:label, flux:input, flux:error)
- Leverage FluxUI's built-in styling and accessibility features
- Customize only when FluxUI doesn't provide the needed functionality

### Database
- Use descriptive migration names and proper column types
- Implement proper foreign key constraints
- Use Laravel 12's enhanced migration features
- Follow snake_case for database columns, camelCase for model attributes

### Testing
- Use Pest PHP for all new tests
- Write feature tests for user interactions
- Write unit tests for business logic
- Follow descriptive test naming conventions

### Code Quality
- Use Laravel Pint for code formatting
- Follow PSR-12 standards
- Use meaningful variable and method names
- Write self-documenting code with minimal comments

## FluxUI Component Patterns

### Forms
\`\`\`blade
<flux:field>
    <flux:label>Field Label</flux:label>
    <flux:input wire:model="property" />
    <flux:error name="property" />
    <flux:description>Helper text</flux:description>
</flux:field>
\`\`\`

### Buttons
\`\`\`blade
<flux:button variant="primary" wire:click="action">
    Primary Action
</flux:button>
\`\`\`

### Data Display
\`\`\`blade
<flux:table>
    <flux:columns>
        <flux:column>Name</flux:column>
        <flux:column>Actions</flux:column>
    </flux:columns>
    <flux:rows>
        @foreach(\$items as \$item)
            <flux:row>
                <flux:cell>{{ \$item->name }}</flux:cell>
                <flux:cell>
                    <flux:button size="sm">Edit</flux:button>
                </flux:cell>
            </flux:row>
        @endforeach
    </flux:rows>
</flux:table>
\`\`\`

Generated: $(date)
EOF

    # Copy or download all context files from the repository
    SCRIPT_DIR="$(dirname "$0")"
    REPO_BASE_URL="https://raw.githubusercontent.com/chrisbaswell/laravel-claude-code-setup/main"
    
    # Function to copy local file or download from repo
    copy_or_download_context_file() {
        local filename="$1"
        local description="$2"
        
        print_status "Installing $description..."
        if [ -f "$SCRIPT_DIR/.claude/context/$filename" ]; then
            cp "$SCRIPT_DIR/.claude/context/$filename" ".claude/context/"
            print_success "$description copied from local repository"
        else
            print_status "$description not found locally, downloading from repository..."
            if curl -fsSL "$REPO_BASE_URL/.claude/context/$filename" -o ".claude/context/$filename"; then
                print_success "$description downloaded successfully"
            else
                print_warning "Failed to download $description, creating basic version"
                return 1
            fi
        fi
        return 0
    }
    
    # Install Laravel 12 guidelines
    if ! copy_or_download_context_file "laravel12_guidelines.md" "Laravel 12 guidelines"; then
        cat > ".claude/context/laravel12_guidelines.md" << 'EOF'
# Laravel 12 Development Guidelines

## Core Laravel 12 Features

### New Attribute Class for Accessors/Mutators
Laravel 12 introduces the `Attribute` class for cleaner accessor and mutator definitions.

### Modern Application Configuration
Use the streamlined Application class in `bootstrap/app.php`.

### Enhanced Validation
Leverage Laravel 12's improved validation features.

Generated: $(date)
EOF
    fi
    
    # Install Livewire Volt guidelines
    if ! copy_or_download_context_file "livewire_volt_guidelines.md" "Livewire Volt guidelines"; then
        cat > ".claude/context/livewire_volt_guidelines.md" << 'EOF'
# Livewire Volt Development Guidelines

## Volt Functional Components
Use Volt for modern, functional component development with Livewire.

Generated: $(date)
EOF
    fi
    
    # Install FluxUI guidelines
    if ! copy_or_download_context_file "fluxui_guidelines.md" "FluxUI guidelines"; then
        cat > ".claude/context/fluxui_guidelines.md" << 'EOF'
# FluxUI Development Guidelines

## Component Usage
Always prefer FluxUI components over custom HTML/CSS.

Generated: $(date)
EOF
    fi
    
    # Install Livewire Alpine context
    if ! copy_or_download_context_file "livewire_alpine_context.md" "Livewire Alpine context"; then
        cat > ".claude/context/livewire_alpine_context.md" << 'EOF'
# Livewire + Alpine.js Integration

## Best Practices
Combine Livewire with Alpine.js for optimal interactivity.

Generated: $(date)
EOF
    fi
    
    # Install project structure guide
    if ! copy_or_download_context_file "project_structure.md" "project structure guide"; then
        cat > ".claude/context/project_structure.md" << 'EOF'
# Project Structure Guide

## Laravel 12 Project Organization
Follow Laravel 12 conventions for project structure.

Generated: $(date)
EOF
    fi
    
    # Install Playwright testing guide
    if ! copy_or_download_context_file "playwright_testing.md" "Playwright testing guide"; then
        cat > ".claude/context/playwright_testing.md" << 'EOF'
# Playwright Testing Guide

## End-to-End Testing
Use Playwright for comprehensive E2E testing.

Generated: $(date)
EOF
    fi
    
    # Install web automation guide
    if ! copy_or_download_context_file "web_automation_guide.md" "web automation guide"; then
        cat > ".claude/context/web_automation_guide.md" << 'EOF'
# Web Automation Guide

## Playwright vs Fetch MCP
Choose the right tool for web automation tasks.

Generated: $(date)
EOF
    fi
    
    # Install Herd development guide
    if ! copy_or_download_context_file "herd_development.md" "Herd development guide"; then
        cat > ".claude/context/herd_development.md" << 'EOF'
# Laravel Herd Development Guide

## Local Development with Herd
Use Laravel Herd for zero-configuration local development.

Generated: $(date)
EOF
    fi
    
    # Install NetSuite context (optional)
    copy_or_download_context_file "netsuite_context.md" "NetSuite context" || print_status "NetSuite context skipped (project-specific)"

    # Create FluxUI quick reference
    print_status "Creating FluxUI quick reference..."
    cat > ".claude/context/fluxui-reference.md" << EOF
# FluxUI Quick Reference for ${PROJECT_NAME}

## Essential Components

### Form Components
- \`<flux:input>\` - Text inputs with built-in styling
- \`<flux:textarea>\` - Multi-line text input
- \`<flux:select>\` - Dropdown selection with search capability
- \`<flux:checkbox>\` - Checkbox inputs
- \`<flux:radio>\` - Radio button inputs
- \`<flux:field>\` - Form field wrapper with label/error support

### Layout Components
- \`<flux:card>\` - Content containers with header/body/footer
- \`<flux:modal>\` - Overlays and dialogs
- \`<flux:tabs>\` - Tabbed navigation
- \`<flux:table>\` - Data tables with sorting and pagination

### Action Components
- \`<flux:button>\` - Buttons with variants (primary, outline, danger)
- \`<flux:button.group>\` - Grouped button sets

### Display Components
- \`<flux:badge>\` - Status indicators and labels
- \`<flux:avatar>\` - User profile images and initials
- \`<flux:progress>\` - Progress bars and loading indicators
- \`<flux:spinner>\` - Loading spinners

### Navigation Components
- \`<flux:navlist>\` - Navigation menus
- \`<flux:breadcrumbs>\` - Breadcrumb navigation

## Common Patterns

### Form with Validation
\`\`\`blade
<form wire:submit="save">
    <flux:field>
        <flux:label>Name</flux:label>
        <flux:input wire:model="form.name" />
        <flux:error name="form.name" />
    </flux:field>
    
    <flux:button type="submit" variant="primary">
        Save
    </flux:button>
</form>
\`\`\`

### Data Table
\`\`\`blade
<flux:table>
    <flux:columns>
        <flux:column sortable wire:click="sortBy('name')">Name</flux:column>
        <flux:column>Status</flux:column>
        <flux:column>Actions</flux:column>
    </flux:columns>
    <flux:rows>
        @foreach(\$users as \$user)
            <flux:row>
                <flux:cell>{{ \$user->name }}</flux:cell>
                <flux:cell>
                    <flux:badge color="{{ \$user->is_active ? 'green' : 'red' }}">
                        {{ \$user->is_active ? 'Active' : 'Inactive' }}
                    </flux:badge>
                </flux:cell>
                <flux:cell>
                    <flux:button size="sm" wire:click="edit({{ \$user->id }})">
                        Edit
                    </flux:button>
                </flux:cell>
            </flux:row>
        @endforeach
    </flux:rows>
</flux:table>
\`\`\`

### Modal Form
\`\`\`blade
<flux:modal wire:model="showModal" name="user-modal">
    <flux:modal.header>
        <flux:heading>{{ \$editing ? 'Edit' : 'Create' }} User</flux:heading>
    </flux:modal.header>
    
    <flux:modal.body>
        <div class="space-y-4">
            <flux:field>
                <flux:label>Name</flux:label>
                <flux:input wire:model="form.name" />
                <flux:error name="form.name" />
            </flux:field>
            
            <flux:field>
                <flux:label>Email</flux:label>
                <flux:input wire:model="form.email" type="email" />
                <flux:error name="form.email" />
            </flux:field>
        </div>
    </flux:modal.body>
    
    <flux:modal.footer>
        <flux:button variant="primary" wire:click="save">
            {{ \$editing ? 'Update' : 'Create' }}
        </flux:button>
        <flux:button variant="outline" wire:click="\$set('showModal', false)">
            Cancel
        </flux:button>
    </flux:modal.footer>
</flux:modal>
\`\`\`

## Styling Guidelines

### Component Variants
- **primary**: Main actions (save, submit, confirm)
- **outline**: Secondary actions (cancel, back)
- **danger**: Destructive actions (delete, remove)

### Colors
- **blue**: Primary/info states
- **green**: Success states
- **red**: Error/danger states
- **yellow**: Warning states
- **gray**: Neutral states

### Sizes
- **sm**: Small components for compact layouts
- **md**: Default size for most use cases
- **lg**: Large components for emphasis

Generated: $(date)
EOF

    # Create shortcuts file
    print_status "Creating development shortcuts..."
    cat > ".claude/shortcuts.sh" << EOF
#!/bin/bash

# Laravel 12 Development Shortcuts for ${PROJECT_NAME}

# Artisan shortcuts
alias pa='php artisan'
alias pam='php artisan migrate'
alias pams='php artisan migrate --seed'
alias par='php artisan route:list'
alias pat='php artisan test'
alias paq='php artisan queue:work'
alias herd-link='herd link'
alias herd-open='herd open'

# Livewire shortcuts
alias make-livewire='php artisan make:livewire'
alias make-component='php artisan make:component'

# Testing shortcuts (Pest PHP)
alias pest='./vendor/bin/pest'
alias pest-coverage='./vendor/bin/pest --coverage'
alias pest-parallel='./vendor/bin/pest --parallel'

# Playwright E2E testing shortcuts
alias test-e2e='npm run test:e2e'
alias test-e2e-ui='npm run test:e2e:ui'
alias test-e2e-debug='npx playwright test --debug'

# Asset shortcuts
alias npm-dev='npm run dev'
alias npm-watch='npm run watch'
alias npm-build='npm run build'

# Code quality shortcuts
alias pint='./vendor/bin/pint'
alias pint-test='./vendor/bin/pint --test'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Project shortcuts
alias fresh='php artisan migrate:fresh --seed'
alias tinker='php artisan tinker'
alias optimize='php artisan optimize'
alias clear-all='php artisan cache:clear && php artisan config:clear && php artisan route:clear && php artisan view:clear'

echo "🚀 Laravel 12 development shortcuts loaded for ${PROJECT_NAME}!"
echo "Use 'pa' for php artisan, 'herd-link' to link project, 'pest' for Laravel testing, 'test-e2e' for Playwright E2E testing"
EOF

    chmod +x ".claude/shortcuts.sh"
    
    # Create README
    print_status "Creating project README..."
    cat > ".claude/README.md" << EOF
# Claude Code Setup for ${PROJECT_NAME}

This Laravel 12 project has been configured with Claude Code and optimized MCP servers for modern development.

## Available MCP Servers

### Global Servers (shared across all projects)
- **GitHub** - Repository access and management
- **Memory** - Shared knowledge base across projects  
- **Context7** - Latest Laravel 12 documentation access
- **Web Fetch** - External API and resource access

### Project-Specific Servers
- **Filesystem** - Access to this project's files
- **Database** - Direct database access for this project (${DB_CONNECTION})

## Tech Stack

- **Laravel 12** - Modern PHP framework with latest features
- **Livewire 3.x** - Server-side rendering with reactivity
- **FluxUI** - Beautiful pre-built components for Livewire
- **Alpine.js** - Minimal JavaScript for enhanced interactivity
- **Tailwind CSS** - Utility-first styling framework
- **Pest PHP** - Modern testing framework

## Getting Started

1. Load development shortcuts:
   \`\`\`bash
   source .claude/shortcuts.sh
   \`\`\`

2. Install FluxUI (if not already installed):
   \`\`\`bash
   composer require livewire/flux
   php artisan flux:install
   \`\`\`

3. Start development:
   \`\`\`bash
   npm run dev    # Start Vite dev server
   pas           # Start Laravel development server
   \`\`\`

## Key Features

### Laravel 12 Patterns
- New Attribute class for accessors/mutators
- Enhanced validation and request handling
- Modern testing with Pest PHP
- Improved query builder features

### FluxUI Integration
- Pre-built, accessible components
- Seamless Livewire integration
- Consistent design system
- Reduced custom CSS needs

### AI-Enhanced Development
- Claude Code with specialized MCP servers
- Context-aware assistance
- Project-specific knowledge retention
- Enhanced productivity tools

## Usage Tips

- Use FluxUI components instead of building custom UI
- Follow Laravel 12 conventions (especially the new Attribute class)
- Leverage Claude Code's MCP servers for enhanced development
- Write tests using Pest PHP for better readability
- Use the provided shortcuts for common development tasks

## Documentation

- Project context: \`.claude/context/project-context.md\`
- Coding standards: \`.claude/context/coding-standards.md\`
- FluxUI reference: \`.claude/context/fluxui-reference.md\`

Generated: $(date)
Happy coding with Laravel 12 + FluxUI + Claude Code! 🚀
EOF

    # Verify all files were created
    local files_created=0
    local required_files=(
        "context/project-context.md" 
        "context/coding-standards.md" 
        "context/fluxui-reference.md"
        "context/laravel12_guidelines.md"
        "context/livewire_volt_guidelines.md"
        "context/fluxui_guidelines.md"
        "context/livewire_alpine_context.md"
        "context/project_structure.md"
        "context/playwright_testing.md"
        "context/web_automation_guide.md"
        "context/herd_development.md"
        "shortcuts.sh" 
        "README.md"
    )
    
    local optional_files=(
        "context/netsuite_context.md"
    )
    
    # Count required files
    for file in "${required_files[@]}"; do
        if [ -f ".claude/$file" ]; then
            ((files_created++))
        else
            print_error "Failed to create required file: .claude/$file"
        fi
    done
    
    # Count optional files
    local optional_created=0
    for file in "${optional_files[@]}"; do
        if [ -f ".claude/$file" ]; then
            ((files_created++))
            ((optional_created++))
        fi
    done
    
    local total_possible_files=$((${#required_files[@]} + ${#optional_files[@]}))
    
    if [ $files_created -ge ${#required_files[@]} ]; then
        print_success "All required context files created! ($files_created/$total_possible_files files total)"
        if [ $optional_created -gt 0 ]; then
            print_status "Optional files installed: $optional_created"
        fi
        return 0
    else
        print_error "Only $files_created/$total_possible_files project files were created successfully"
        print_error "Missing required files. Check the installation output above."
        return 1
    fi
}

# Install FluxUI and Volt if not already installed
install_fluxui_and_volt() {
    print_step "Checking FluxUI and Livewire Volt installation..."
    
    # Check if FluxUI is already installed
    FLUX_INSTALLED=false
    if grep -q "livewire/flux" composer.json 2>/dev/null; then
        print_success "FluxUI is already installed!"
        FLUX_INSTALLED=true
    fi
    
    VOLT_INSTALLED=false
    if grep -q "livewire/volt" composer.json 2>/dev/null; then
        print_success "Livewire Volt is already installed!"
        VOLT_INSTALLED=true
    fi
    
    # If both are installed, return early
    if [ "$FLUX_INSTALLED" = true ] && [ "$VOLT_INSTALLED" = true ]; then
        return 0
    fi
    
    # Ask user if they want to install missing packages
    if can_interact_with_user; then
        if [ "$FLUX_INSTALLED" = false ] || [ "$VOLT_INSTALLED" = false ]; then
            echo ""
            print_status "Missing packages detected:"
            [ "$FLUX_INSTALLED" = false ] && echo "  - FluxUI (livewire/flux) - Beautiful Livewire components"
            [ "$VOLT_INSTALLED" = false ] && echo "  - Livewire Volt (livewire/volt) - Functional component API"
            
            local install_packages
            if read_from_user "Would you like to install the missing packages now? (y/n): " install_packages; then
                if [ "$install_packages" = "y" ] || [ "$install_packages" = "yes" ]; then
                    
                    # Install FluxUI
                    if [ "$FLUX_INSTALLED" = false ]; then
                        print_status "Installing FluxUI..."
                        if composer require livewire/flux; then
                            print_success "FluxUI package installed!"
                            
                            # Run FluxUI installation
                            if php artisan flux:install; then
                                print_success "FluxUI setup completed!"
                            else
                                print_warning "FluxUI installation command failed, but package is installed"
                            fi
                            FLUX_INSTALLED=true
                        else
                            print_error "Failed to install FluxUI package"
                        fi
                    fi
                    
                    # Install Volt
                    if [ "$VOLT_INSTALLED" = false ]; then
                        print_status "Installing Livewire Volt..."
                        if composer require livewire/volt; then
                            print_success "Livewire Volt package installed!"
                            
                            # Run Volt installation
                            if php artisan volt:install; then
                                print_success "Livewire Volt setup completed!"
                            else
                                print_warning "Volt installation command failed, but package is installed"
                            fi
                            VOLT_INSTALLED=true
                        else
                            print_error "Failed to install Livewire Volt package"
                        fi
                    fi
                    
                else
                    print_status "Skipping package installation"
                    print_warning "You can install them later with:"
                    [ "$FLUX_INSTALLED" = false ] && echo "  composer require livewire/flux && php artisan flux:install"
                    [ "$VOLT_INSTALLED" = false ] && echo "  composer require livewire/volt && php artisan volt:install"
                fi
            fi
        fi
    else
        print_status "Non-interactive mode - skipping package installation"
        print_status "Install packages later with:"
        [ "$FLUX_INSTALLED" = false ] && echo "  composer require livewire/flux && php artisan flux:install"
        [ "$VOLT_INSTALLED" = false ] && echo "  composer require livewire/volt && php artisan volt:install"
    fi
    
    return 0
}

# Main installation function
main() {
    echo "================================================"
    echo "Laravel Claude Code Setup Script v3.3"
    echo "Laravel 12 + FluxUI + Playwright MCP Server"
    echo "================================================"
    echo ""
    
    # Store the original directory
    ORIGINAL_DIR="$PWD"
    
    # Pre-flight checks
    print_header "Running pre-flight checks..."
    check_laravel_project
    check_claude_code
    check_node
    
    # Collect authentication tokens
    print_header "Collecting authentication credentials..."
    collect_github_token
    
    # Parse environment
    print_header "Analyzing project configuration..."
    parse_env
    generate_database_config
    
    # Create MCP directory
    create_mcp_directory
    
    # Install MCP servers
    print_header "Installing MCP servers..."
    
    # Install each server and return to original directory
    install_context7
    cd "$ORIGINAL_DIR"
    
    install_database
    cd "$ORIGINAL_DIR"
    
    install_playwright
    cd "$ORIGINAL_DIR"
    
    install_fetch
    cd "$ORIGINAL_DIR"
    
    install_github
    cd "$ORIGINAL_DIR"
    
    install_memory
    cd "$ORIGINAL_DIR"
    
    install_filesystem
    cd "$ORIGINAL_DIR"
    
    # Configure Claude Code MCP servers
    print_header "Configuring Claude Code..."
    configure_claude_mcp
    cd "$ORIGINAL_DIR"
    
    # Create project-specific files
    print_header "Creating project-specific files..."
    if create_project_context; then
        print_success "Project context files created successfully"
    else
        print_error "Failed to create project context files"
        exit 1
    fi
    
    # Install FluxUI and Volt
    print_header "Setting up FluxUI and Livewire Volt..."
    install_fluxui_and_volt
    cd "$ORIGINAL_DIR"
    
    # Final verification
    print_header "Verifying installation..."
    if [ -d ".claude" ] && [ -f ".claude/shortcuts.sh" ] && [ -f ".claude/README.md" ]; then
        print_success "All project files created successfully!"
        
        # Show created files
        echo ""
        print_status "Created files:"
        find .claude -type f | sed 's/^/  ✅ /'
    else
        print_error "Project files verification failed"
        exit 1
    fi
    
    echo ""
    echo "================================================"
    print_success "🎉 Setup completed successfully!"
    echo "================================================"
    echo ""
    
    # Display summary
    print_header "Installation Summary"
    echo ""
    print_status "✅ Laravel 12 project verified and configured"
    print_status "✅ Claude Code MCP servers installed and configured"
    print_status "✅ Project-specific context files created"
    print_status "✅ Development shortcuts and documentation ready"
    
    # Check FluxUI status
    if grep -q "livewire/flux" composer.json 2>/dev/null; then
        print_status "✅ FluxUI installed and ready"
    else
        print_status "⚠️  FluxUI not installed (optional)"
    fi
    
    echo ""
    print_status "📋 Installed MCP Servers:"
    echo ""
    echo "  Global Servers:"
    claude mcp list | grep -E "^(github|memory|context7|playwright|fetch):" | sed 's/^/    🌐 /' || true
    echo ""
    echo "  Project-Specific Servers:"
    PROJECT_ID=$(echo "$(basename "$PWD")" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
    claude mcp list | grep -E "^(filesystem|database)-$PROJECT_ID" | sed 's/^/    📁 /' || true
    echo ""
    
    print_header "Next Steps"
    echo ""
    echo "1. Load development shortcuts:"
    echo "   source .claude/shortcuts.sh"
    echo ""
    echo "2. Start development servers:"
    echo "   npm run dev    # Vite development server"
    echo "   herd open      # Open project in browser (Herd automatically serves Laravel)"
    echo ""
    echo "3. Test Claude Code integration:"
    echo "   - Ask Claude: 'What MCP servers are available?'"
    echo "   - Try: 'Show me the project structure'"
    echo "   - Test: 'What's in my database?' (if database is configured)"
    echo ""
    echo "4. Start building with FluxUI:"
    echo "   - Use FluxUI components instead of custom HTML"
    echo "   - Follow Laravel 12 patterns (new Attribute class)"
    echo "   - Write tests with Pest PHP"
    echo ""
    
    print_success "🚀 Your Laravel 12 + FluxUI + Claude Code environment is ready!"
    echo ""
    
    # Count successful installations
    TOTAL_MCP_COUNT=$(claude mcp list | wc -l | tr -d ' ')
    if [ "$TOTAL_MCP_COUNT" -ge 3 ]; then
        print_success "✅ Core MCP servers installed successfully! (Total: $TOTAL_MCP_COUNT)"
    else
        print_warning "⚠️ Some MCP servers may have failed to install (Total: $TOTAL_MCP_COUNT)"
    fi
    
    echo ""
    print_status "💡 Pro Tips:"
    echo "  • Use 'pa' instead of 'php artisan' (from shortcuts)"
    echo "  • Use 'pest' for running tests"
    echo "  • Use 'pint' for code formatting"
    echo "  • FluxUI components are in resources/views/flux/"
    echo "  • Project context is preserved in .claude/ directory"
    echo ""
    
    print_success "Happy coding with Laravel 12 + FluxUI! 🎨✨"
}

# Run the main function
main "$@"
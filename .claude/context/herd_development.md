# Laravel Herd Development Guide

## Overview

This project is optimized for [Laravel Herd](https://herd.laravel.com), the fastest way to run Laravel locally. Herd provides a zero-configuration local development environment with automatic PHP, Nginx, and database management.

## Why Laravel Herd?

### **Advantages over Traditional Development Stacks**
- ⚡ **Zero Configuration**: No complex setup or Docker overhead
- 🚀 **Instant Start**: Projects are immediately accessible
- 🔄 **Automatic Management**: PHP versions, databases, and services handled automatically
- 🎯 **Laravel-Optimized**: Built specifically for Laravel development
- 💾 **Lightweight**: Minimal system resource usage
- 🔧 **Multiple PHP Versions**: Easy switching between PHP versions per project

### **Herd vs Docker for Local Development**
| Feature | Laravel Herd | Docker |
|---------|--------------|---------|
| **Setup Time** | Instant | Complex configuration |
| **Resource Usage** | Minimal | High memory/CPU usage |
| **PHP Version Switching** | One command | Rebuild containers |
| **Database Management** | Automatic | Manual container setup |
| **File Permissions** | Native | Permission issues |
| **Performance** | Native speed | Virtualization overhead |

## Herd Setup for This Project

### **1. Install Laravel Herd**
```bash
# Download from https://herd.laravel.com
# Or install via Homebrew (macOS)
brew install --cask herd
```

### **2. Link Your Project**
```bash
# Navigate to your project directory
cd /path/to/your/laravel-project

# Link the project to Herd
herd link

# Your project is now available at:
# http://your-project-name.test
```

### **3. Set PHP Version (if needed)**
```bash
# Use PHP 8.3 for this project (Laravel 12 requirement)
herd use php@8.3

# Verify PHP version
php --version
```

### **4. Database Configuration**
```bash
# Herd includes MySQL and PostgreSQL
# Update your .env file:
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=your_project_name
DB_USERNAME=root
DB_PASSWORD=

# Create database
herd mysql
CREATE DATABASE your_project_name;
```

## Development Workflow with Herd

### **Starting Development**
```bash
# 1. Ensure Herd is running (automatic on system start)
herd status

# 2. Navigate to project and link if not done
herd link

# 3. Install dependencies
composer install
npm install

# 4. Set up environment
cp .env.example .env
php artisan key:generate

# 5. Run migrations
php artisan migrate --seed

# 6. Start frontend development
npm run dev

# 7. Open in browser
herd open
```

### **Daily Development Commands**
```bash
# Quick project access
herd open                    # Open project in browser
herd open --secure          # Open with HTTPS

# Database management
herd mysql                   # Access MySQL CLI
herd tinker                  # Laravel Tinker

# PHP version management
herd use php@8.3            # Switch to PHP 8.3
herd php --version          # Check current PHP version

# Service management
herd restart                 # Restart all services
herd logs                   # View service logs
```

## Herd Integration with Project Tools

### **Playwright Testing with Herd**
```javascript
// playwright.config.js automatically detects Herd URLs
// Tests run against http://your-project.test

// Example test
test('homepage loads correctly', async ({ page }) => {
  await page.goto('/');  // Uses Herd's URL automatically
  await expect(page).toHaveTitle(/Laravel/);
});
```

### **FluxUI Development**
```bash
# Herd serves your project instantly
# FluxUI components are immediately available at:
# http://your-project.test

# Watch for changes
npm run dev  # Vite hot reload works seamlessly with Herd
```

### **Livewire Development**
```bash
# Livewire components update in real-time
# No additional configuration needed with Herd

# Test Livewire components
php artisan livewire:make UserForm
# Available immediately at http://your-project.test
```

## Herd-Specific Environment Configuration

### **.env Configuration for Herd**
```bash
# Application
APP_NAME="Laravel 12 Project"
APP_ENV=local
APP_URL=http://your-project.test  # Herd's automatic URL

# Database (Herd's MySQL)
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=your_project_name
DB_USERNAME=root
DB_PASSWORD=

# Cache/Session (use database for local development)
CACHE_DRIVER=database
SESSION_DRIVER=database
QUEUE_CONNECTION=database

# Mail (use Herd's built-in mail testing)
MAIL_MAILER=log
```

### **Herd Services Configuration**
```bash
# Check available services
herd services

# Available by default:
# - PHP (multiple versions)
# - Nginx
# - MySQL
# - Redis (if installed)
# - Mailpit (for email testing)
```

## Advanced Herd Features

### **HTTPS/SSL Support**
```bash
# Enable HTTPS for your project
herd secure your-project

# Your project is now available at:
# https://your-project.test

# Disable HTTPS
herd unsecure your-project
```

### **Custom Domains**
```bash
# Use custom domain
herd link --name=my-awesome-app
# Available at: http://my-awesome-app.test

# Multiple domains for same project
herd link --name=api
# API available at: http://api.test
```

### **Environment Isolation**
```bash
# Herd automatically isolates projects
# Each project gets its own:
# - PHP version
# - Database
# - Environment variables
# - Dependencies
```

## Performance Optimization with Herd

### **OPcache Configuration**
```bash
# Herd optimizes PHP automatically
# For development, OPcache is disabled by default
# For production testing, enable OPcache:

herd php -d opcache.enable=1 artisan optimize
```

### **Database Optimization**
```bash
# Herd's MySQL is pre-configured for development
# For performance testing:

# Increase memory limits
herd mysql
SET GLOBAL innodb_buffer_pool_size = 128M;
```

## Testing with Herd

### **Running Tests**
```bash
# Laravel tests (Pest)
php artisan test
# or
pest

# Playwright E2E tests
npm run test:e2e
# Tests automatically use Herd's URL

# Test with different PHP versions
herd use php@8.2
php artisan test
herd use php@8.3  # Switch back
```

### **Test Database Setup**
```bash
# Create separate test database
herd mysql
CREATE DATABASE your_project_test;

# Update .env.testing
DB_DATABASE=your_project_test
```

## Troubleshooting

### **Common Issues**

1. **Project not accessible**
   ```bash
   herd restart
   herd unlink && herd link
   ```

2. **Database connection issues**
   ```bash
   herd mysql  # Verify MySQL is running
   # Check .env database credentials
   ```

3. **PHP version conflicts**
   ```bash
   herd use php@8.3  # Ensure correct PHP version
   php --version     # Verify
   ```

4. **Port conflicts**
   ```bash
   herd stop
   # Stop other web servers (Apache, XAMPP, etc.)
   herd start
   ```

### **Herd Logs**
```bash
# View Herd logs for debugging
herd logs

# View Nginx logs
herd logs nginx

# View PHP logs
herd logs php
```

## Migration from Other Development Environments

### **From Laravel Valet**
```bash
# Valet projects work seamlessly with Herd
# Simply install Herd and your sites continue working
```

### **From Docker/Sail**
```bash
# 1. Stop Docker containers
docker-compose down

# 2. Install Herd and link project
herd link

# 3. Update .env for Herd's MySQL
# 4. Run migrations
php artisan migrate
```

### **From XAMPP/MAMP**
```bash
# 1. Stop XAMPP/MAMP
# 2. Install Herd
# 3. Link existing projects
herd link

# 4. Update database configuration
# 5. Import existing databases if needed
```

## Integration with Claude Code MCP Servers

### **MCP Server Testing**
```bash
# All MCP servers work seamlessly with Herd
# Playwright MCP uses Herd's URLs automatically
# Database MCP connects to Herd's MySQL
# Fetch MCP can test Herd-served endpoints
```

### **Development Workflow**
```bash
# 1. Herd serves your Laravel app instantly
# 2. Claude Code can interact with your app via MCP servers
# 3. Playwright tests run against Herd URLs
# 4. Database queries work with Herd's MySQL
# 5. File operations access Herd-managed project files
```

## Best Practices

### **Project Organization**
- Keep projects in organized directories
- Use descriptive project names for Herd linking
- Maintain separate databases per project
- Use version control for environment configurations

### **Performance**
- Use database caching for local development
- Enable OPcache for production testing
- Monitor Herd logs for performance issues
- Optimize asset compilation with Vite

### **Security**
- Use HTTPS for projects requiring security testing
- Keep Herd updated for security patches
- Use environment-specific configurations
- Test with realistic data volumes

Laravel Herd provides the perfect foundation for this Laravel 12 + FluxUI + Claude Code development environment, offering unprecedented speed and simplicity for local development while maintaining full compatibility with all project tools and MCP servers. 
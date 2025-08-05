# Claude Code Setup for Laravel Project

This Laravel 12 project has been configured with Claude Code and optimized MCP servers for modern development with FluxUI and Livewire Volt.

## Available MCP Servers

### Global Servers (shared across all projects)
- **GitHub** - Repository access and management
- **Memory** - Shared knowledge base across projects  
- **Context7** - Latest Laravel 12 documentation access
- **Playwright** - Browser automation and testing capabilities (Microsoft MCP)
- **Fetch** - Enhanced HTTP requests, web scraping, and content transformation (zcaceres/fetch-mcp)

### Project-Specific Servers
- **Filesystem** - Access to this project's files
- **Database** - Direct database access for this project (FreePeak db-mcp-server)

## Tech Stack

- **Laravel 12** - Modern PHP framework with latest features
- **Livewire 3.x + Volt** - Server-side rendering with functional components
- **FluxUI** - Beautiful pre-built components for Livewire
- **Alpine.js** - Minimal JavaScript for enhanced interactivity
- **Tailwind CSS** - Utility-first styling framework
- **Pest PHP** - Modern testing framework

## Getting Started

### Prerequisites
- **Laravel Herd** - For local development environment ([Download Herd](https://herd.laravel.com))
- **Node.js 20+** - For frontend asset compilation
- **Claude Code** - AI development assistant

### Installation Options

**Option 1: One-line installation (recommended)**
```bash
curl -fsSL https://raw.githubusercontent.com/chrisbaswell/laravel-claude-code-setup/main/setup.sh | bash
```

**Option 2: Download and run manually**
```bash
curl -O https://raw.githubusercontent.com/chrisbaswell/laravel-claude-code-setup/main/setup.sh
chmod +x setup.sh
./setup.sh
```

**Option 3: Clone the repository**
```bash
git clone https://github.com/chrisbaswell/laravel-claude-code-setup.git
cd laravel-claude-code-setup
./setup.sh
# Copy setup files to your Laravel project when prompted
```

### Setup Steps

1. **Run pre-installation check (recommended):**
   ```bash
   ./pre-check.sh
   ```
   This will verify all requirements and identify potential issues before installation.

2. **Start Herd services:**
   ```bash
   # Herd automatically manages PHP, Nginx, and databases
   # Just ensure Herd is running and serving your project
   ```

3. **Load development shortcuts:**
   ```bash
   source .claude/shortcuts.sh
   ```

4. **Install dependencies:**
   ```bash
   composer install
   npm install
   ```

5. **Install FluxUI and Volt (if not already installed):**
   ```bash
   composer require livewire/flux livewire/volt
   php artisan flux:install
   php artisan volt:install
   ```

6. **Install Playwright for end-to-end testing:**
   ```bash
   npx playwright install
   ```

7. **Start development:**
   ```bash
   npm run dev    # Start Vite dev server
   # Herd automatically serves your Laravel app
   ```

8. **Run tests:**
   ```bash
   pest           # Run Laravel tests
   npm run test:e2e  # Run Playwright E2E tests
   ```

## Key Laravel 12 Features

### New Attribute Class for Accessors/Mutators
```php
use Illuminate\Database\Eloquent\Casts\Attribute;

class User extends Model
{
    protected function fullName(): Attribute
    {
        return Attribute::make(
            get: fn (mixed $value, array $attributes) => 
                $attributes['first_name'] . ' ' . $attributes['last_name']
        );
    }
}
```

### #[Scope] Attribute for Query Scopes
```php
use Illuminate\Database\Eloquent\Attributes\Scope;

class Product extends Model
{
    #[Scope]
    public function active($query)
    {
        return $query->where('is_active', true);
    }
    
    #[Scope]
    public function inPriceRange($query, float $min, float $max)
    {
        return $query->whereBetween('price', [$min, $max]);
    }
}

// Usage: Product::active()->inPriceRange(10, 100)->get();
```

### Application Class Configuration
```php
// bootstrap/app.php
return Application::configure(basePath: dirname(__DIR__))
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->append([
            \App\Http\Middleware\TrustProxies::class,
        ]);
    })
    ->withEvents(discover: [
        __DIR__.'/../app/Listeners',
    ])
    ->create();
```

## Livewire Volt Functional Components

### Preferred Component Style
```blade
<?php
use function Livewire\Volt\{state, rules};

state(['name' => '', 'email' => '']);
rules(['name' => 'required', 'email' => 'required|email']);

$save = function () {
    $this->validate();
    User::create($this->all());
    $this->reset();
};
?>

<flux:card>
    <flux:card.header>
        <flux:heading>Create User</flux:heading>
    </flux:card.header>
    <flux:card.body>
        <flux:field>
            <flux:label>Name</flux:label>
            <flux:input wire:model="name" />
            <flux:error name="name" />
        </flux:field>
        <flux:field>
            <flux:label>Email</flux:label>
            <flux:input wire:model="email" type="email" />
            <flux:error name="email" />
        </flux:field>
    </flux:card.body>
    <flux:card.footer>
        <flux:button variant="primary" wire:click="save">
            Create User
        </flux:button>
    </flux:card.footer>
</flux:card>
```

## FluxUI Integration

FluxUI provides beautiful, pre-built components that work seamlessly with Livewire:

### Form Components
- `<flux:input>` - Text inputs with built-in styling
- `<flux:select>` - Dropdown selection with search
- `<flux:textarea>` - Multi-line text input
- `<flux:checkbox>` - Checkbox inputs
- `<flux:field>` - Form field wrapper with label/error support

### Layout Components
- `<flux:card>` - Content containers with header/body/footer
- `<flux:modal>` - Overlays and dialogs
- `<flux:table>` - Data tables with sorting
- `<flux:tabs>` - Tabbed navigation

### Action Components
- `<flux:button>` - Buttons with variants (primary, outline, danger)
- `<flux:badge>` - Status indicators and labels

## Modern Development Patterns

### Component Choice Guidelines

**✅ Use Livewire Volt For:**
- Form handling and CRUD operations
- Data tables and lists
- Modal dialogs and simple interactions
- Dashboard widgets
- Most UI components

**✅ Use Traditional Class Components For:**
- Complex business logic spanning multiple methods
- Heavy dependency injection requirements
- Components needing traits or inheritance

### Database Patterns
```php
// Modern migration with Laravel 12 features
Schema::create('products', function (Blueprint $table) {
    $table->id();
    $table->string('name')->index();
    $table->decimal('price', 10, 2);
    $table->json('metadata')->nullable();
    $table->boolean('is_active')->default(true);
    $table->timestamps();
    
    $table->index(['is_active', 'created_at']);
    $table->fullText(['name', 'description']);
});
```

### Testing with Pest PHP
```php
use function Pest\Laravel\{get, post, assertDatabaseHas};

it('can create a product', function () {
    $productData = [
        'name' => 'Test Product',
        'price' => 99.99,
    ];
    
    post(route('products.store'), $productData)
        ->assertRedirect()
        ->assertSessionHas('success');
        
    assertDatabaseHas('products', ['name' => 'Test Product']);
});
```

## End-to-End Testing with Playwright

The project includes [Microsoft's Playwright MCP server](https://github.com/microsoft/playwright-mcp) for comprehensive browser testing:

### Key Features
- **Multi-browser Support**: Chrome, Firefox, Safari
- **Mobile Testing**: iPhone, Android device emulation  
- **Visual Testing**: Screenshots, PDF generation
- **Network Monitoring**: Track API calls and responses
- **Accessibility Testing**: Built-in a11y checks

### Example FluxUI Test
```javascript
import { test, expect } from '@playwright/test';

test('FluxUI form submission works', async ({ page }) => {
  await page.goto('/users/create');
  
  // Fill FluxUI form components
  await page.fill('[data-testid="name-input"]', 'John Doe');
  await page.fill('[data-testid="email-input"]', 'john@example.com');
  
  // Submit form
  await page.click('[data-testid="submit-button"]');
  
  // Verify success notification
  await expect(page.locator('.flux-toast')).toContainText('User created');
});
```

### Running Playwright Tests
```bash
npm run test:e2e              # Run all E2E tests
npm run test:e2e:ui          # Run with interactive UI
npx playwright test --debug  # Debug mode
```

## AI-Enhanced Development

### Available MCP Tools
- **Context7**: Access to latest Laravel 12 documentation
- **GitHub**: Repository management and code analysis
- **Memory**: Persistent knowledge across sessions
- **Database**: Direct database queries and schema analysis
- **Playwright**: Browser automation, testing, and web scraping
- **Fetch**: Enhanced HTTP requests with HTML, JSON, text, and Markdown parsing
- **Filesystem**: Read and modify project files

### Usage Tips
- Use FluxUI components instead of building custom UI
- Follow Laravel 12 conventions (Attribute class, #[Scope] attribute)
- Prefer Livewire Volt functional components over classes
- Leverage Claude Code's MCP servers for enhanced development
- Write tests using Pest PHP for better readability
- Use the provided shortcuts for common development tasks

## Project Context Files

The setup script automatically creates comprehensive documentation in `.claude/context/`:

### Core Development Guides
- **Laravel 12 guidelines** (`laravel12_guidelines.md`) - Latest Laravel 12 features and patterns
- **Livewire Volt patterns** (`livewire_volt_guidelines.md`) - Functional component development
- **FluxUI reference** (`fluxui_guidelines.md`) - Component usage and best practices
- **Livewire + Alpine.js** (`livewire_alpine_context.md`) - Frontend integration patterns

### Project Organization  
- **Project context** (`project-context.md`) - Tech stack overview and conventions
- **Project structure** (`project_structure.md`) - File organization guidelines
- **Coding standards** (`coding-standards.md`) - Project-specific code quality rules

### Testing & Automation
- **Playwright testing** (`playwright_testing.md`) - End-to-end testing with Playwright MCP
- **Web automation guide** (`web_automation_guide.md`) - Playwright vs Fetch MCP usage
- **Herd development** (`herd_development.md`) - Local development with Laravel Herd

### Quick References
- **FluxUI quick reference** (`fluxui-reference.md`) - Component cheat sheet

### Optional Project-Specific
- **NetSuite integration** (`netsuite_context.md`) - Business system integration (if applicable)

## Documentation

## Development Shortcuts

After running `source .claude/shortcuts.sh`:

- `pa` - php artisan
- `pam` - php artisan migrate
- `herd-link` - Link project to Herd (herd link)
- `herd-open` - Open project in browser (herd open)
- `pest` - Run Laravel tests (Pest PHP)
- `pint` - Format code (Laravel Pint)
- `npm-dev` - npm run dev
- `test-e2e` - npm run test:e2e (Playwright)
- `test-e2e-ui` - npm run test:e2e:ui (Playwright UI mode)

## Troubleshooting

### Common Installation Issues

**Database MCP Integration Skipped**
```bash
# Issue: "No database configured in .env file"
# Solution: Configure database in .env
DB_DATABASE=your_project_name
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USERNAME=root
DB_PASSWORD=
```

**Playwright Browser Installation Warning**
```bash
# Issue: Playwright warns about missing dependencies
# Solution: Install Playwright in your project first
npm install @playwright/test
npx playwright install
```

**Filesystem MCP Server Already Exists**
```bash
# Issue: "MCP server filesystem-[name] already exists"
# Solution: This is normal and safe to ignore - server is already configured
```

**npm Security Vulnerabilities**
```bash
# Issue: High severity vulnerabilities in fetch-mcp
# Solution: Vulnerabilities are automatically fixed during installation
# Or manually run: npm audit fix --force
```

**Deprecated Package Warnings**
```bash
# Issue: GitHub MCP server shows deprecation warning
# Solution: This is expected - the official server is deprecated but still functional
```

### Quick Fixes

```bash
# Reset MCP servers if issues occur
claude mcp remove --all
./setup.sh

# Check MCP server status
claude mcp list

# Reinstall specific server
cd ~/.config/claude-code/mcp-servers/
rm -rf fetch-mcp
# Run setup.sh again
```

Happy coding with Laravel 12 + FluxUI + Livewire Volt + Claude Code! 🚀

## Production Deployment

While this project is optimized for Laravel Herd in local development, a production-ready `Dockerfile` is included for containerized deployment. The Docker configuration is specifically designed for:

- **Production environments** (staging, production servers)
- **CI/CD pipelines** (automated testing and deployment)
- **Cloud deployments** (AWS ECS, Google Cloud Run, etc.)
- **Kubernetes clusters**

### Production Docker Build
```bash
# Build production image
docker build -t laravel-app .

# Run with environment variables
docker run -p 80:9000 \
  -e APP_ENV=production \
  -e DB_HOST=your-db-host \
  laravel-app
```

### Local Development
For local development, use **Laravel Herd** instead of Docker for optimal performance and developer experience. See the [Laravel Herd development guide](.claude/context/herd_development.md) for complete setup instructions.

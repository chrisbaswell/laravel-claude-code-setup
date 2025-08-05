# Playwright Testing Guidelines for Laravel 12 + FluxUI

## Overview

This project includes Microsoft's Playwright MCP server for advanced browser automation, testing, and web scraping capabilities. Playwright provides robust end-to-end testing for your Laravel + FluxUI application.

## Playwright MCP Server Features

Based on [Microsoft's Playwright MCP server](https://github.com/microsoft/playwright-mcp), this integration provides:

### Browser Automation
- **Navigation**: Navigate to URLs, go back/forward
- **Interaction**: Click, type, hover, select options
- **Form Handling**: Fill forms, upload files, handle dialogs
- **Screenshots**: Capture page or element screenshots
- **PDF Generation**: Save pages as PDF documents

### Advanced Capabilities
- **Multi-tab Management**: Open, close, and switch between tabs
- **Network Monitoring**: Track network requests and responses
- **Element Inspection**: Take accessibility snapshots
- **Coordinate-based Actions**: Precise mouse movements and clicks
- **Keyboard Shortcuts**: Send key combinations and special keys

### Browser Support
- **Chromium**: Google Chrome, Microsoft Edge
- **Firefox**: Mozilla Firefox
- **WebKit**: Safari (macOS)
- **Mobile Devices**: iPhone, iPad, Android emulation

## Testing Structure

```
tests/
├── Browser/                    # Playwright E2E tests
│   ├── Auth/
│   │   ├── LoginTest.js       # Authentication flows
│   │   └── RegistrationTest.js
│   ├── Components/
│   │   ├── FluxUITest.js      # FluxUI component tests
│   │   └── LivewireTest.js    # Livewire component tests
│   └── Features/
│       ├── DashboardTest.js   # Page-level tests
│       └── UserManagementTest.js
├── Feature/                   # Laravel Feature tests (Pest)
└── Unit/                     # Laravel Unit tests (Pest)
```

## Configuration

The project includes a pre-configured `playwright.config.js` with:

- **Multi-browser Testing**: Chrome, Firefox, Safari
- **Mobile Device Emulation**: iPhone, Android
- **Herd Integration**: Works seamlessly with Laravel Herd for local development
- **CI/CD Ready**: Automatically starts Laravel server in CI environments
- **Screenshot/Video Capture**: On test failures
- **Parallel Execution**: Faster test runs

## Writing Tests

### Basic FluxUI Component Test

```javascript
import { test, expect } from '@playwright/test';

test('FluxUI button interaction', async ({ page }) => {
  await page.goto('/dashboard');
  
  // Test FluxUI button click
  await page.click('[data-testid="create-user-button"]');
  
  // Verify modal appears
  await expect(page.locator('[data-testid="user-modal"]')).toBeVisible();
  
  // Fill FluxUI form
  await page.fill('[data-testid="user-name"]', 'John Doe');
  await page.fill('[data-testid="user-email"]', 'john@example.com');
  
  // Submit form
  await page.click('[data-testid="submit-button"]');
  
  // Verify success
  await expect(page.locator('.flux-toast')).toContainText('User created successfully');
});
```

### Livewire Component Test

```javascript
test('Livewire real-time updates', async ({ page }) => {
  await page.goto('/users');
  
  // Wait for Livewire to load
  await page.waitForSelector('[wire\\:id]');
  
  // Test search functionality
  await page.fill('[data-testid="search-input"]', 'john');
  
  // Wait for Livewire update
  await page.waitForTimeout(500);
  
  // Verify filtered results
  const userRows = page.locator('[data-testid="user-row"]');
  await expect(userRows).toHaveCount(1);
  await expect(userRows.first()).toContainText('John Doe');
});
```

### Mobile Responsive Test

```javascript
test('Mobile navigation works correctly', async ({ page }) => {
  // Emulate mobile viewport
  await page.setViewportSize({ width: 375, height: 667 });
  
  await page.goto('/');
  
  // Test mobile menu
  await page.click('[data-testid="mobile-menu-button"]');
  await expect(page.locator('[data-testid="mobile-nav"]')).toBeVisible();
  
  // Test navigation
  await page.click('[data-testid="mobile-nav"] a[href="/dashboard"]');
  await expect(page).toHaveURL('/dashboard');
});
```

## Testing FluxUI Components

### Form Testing Patterns

```javascript
// Test FluxUI field validation
test('FluxUI form validation', async ({ page }) => {
  await page.goto('/users/create');
  
  // Submit empty form
  await page.click('[data-testid="submit-button"]');
  
  // Check FluxUI error messages
  await expect(page.locator('[data-flux-error="name"]')).toBeVisible();
  await expect(page.locator('[data-flux-error="email"]')).toBeVisible();
  
  // Fill valid data
  await page.fill('[data-testid="name-input"]', 'Jane Doe');
  await page.fill('[data-testid="email-input"]', 'jane@example.com');
  
  // Verify errors are cleared
  await expect(page.locator('[data-flux-error="name"]')).not.toBeVisible();
});
```

### Modal Testing

```javascript
test('FluxUI modal interactions', async ({ page }) => {
  await page.goto('/dashboard');
  
  // Open modal
  await page.click('[data-testid="open-modal"]');
  await expect(page.locator('[data-flux-modal]')).toBeVisible();
  
  // Test backdrop close
  await page.click('[data-flux-modal-backdrop]');
  await expect(page.locator('[data-flux-modal]')).not.toBeVisible();
  
  // Test escape key close
  await page.click('[data-testid="open-modal"]');
  await page.keyboard.press('Escape');
  await expect(page.locator('[data-flux-modal]')).not.toBeVisible();
});
```

## Running Tests

### Command Line
```bash
# Run all Playwright tests
npm run test:e2e

# Run tests with UI mode
npm run test:e2e:ui

# Run specific test file
npx playwright test tests/Browser/Auth/LoginTest.js

# Run tests in specific browser
npx playwright test --project=chromium

# Debug mode
npx playwright test --debug
```

### Laravel Integration

```bash
# With Laravel Herd (local development)
herd link                    # Link your project to Herd
herd open                    # Open in browser
npm run test:e2e            # Run Playwright tests (uses Herd's URL)

# Prepare test database
php artisan migrate:fresh --seed --env=testing

# Run Playwright tests
npm run test:e2e
```

## Best Practices

### 1. Data Test IDs
Use `data-testid` attributes for reliable element selection:

```blade
{{-- FluxUI component with test ID --}}
<flux:button data-testid="create-user-button" variant="primary">
    Create User
</flux:button>
```

### 2. Wait Strategies
```javascript
// Wait for Livewire updates
await page.waitForSelector('[wire\\:id]');

// Wait for network requests
await page.waitForResponse('**/api/users');

// Wait for element state
await page.waitForSelector('[data-testid="loading"]', { state: 'hidden' });
```

### 3. Page Object Model
```javascript
// pages/UserPage.js
export class UserPage {
  constructor(page) {
    this.page = page;
    this.createButton = page.locator('[data-testid="create-user"]');
    this.nameInput = page.locator('[data-testid="name-input"]');
  }

  async createUser(name, email) {
    await this.createButton.click();
    await this.nameInput.fill(name);
    // ... more actions
  }
}
```

### 4. Test Data Management
```javascript
// Use Laravel factories for consistent test data
test.beforeEach(async ({ page }) => {
  // Reset database state
  await page.goto('/test/reset-database');
});
```

## Debugging Tips

### 1. Visual Debugging
```javascript
// Take screenshot for debugging
await page.screenshot({ path: 'debug.png' });

// Highlight elements
await page.locator('[data-testid="button"]').highlight();
```

### 2. Console Logs
```javascript
// Listen to console messages
page.on('console', msg => console.log(msg.text()));

// Check for JavaScript errors
page.on('pageerror', error => console.log(error.message));
```

### 3. Network Debugging
```javascript
// Log all network requests
page.on('request', request => console.log(request.url()));
page.on('response', response => console.log(response.status()));
```

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Run Playwright Tests
  run: |
    npm ci
    npx playwright install --with-deps
    npm run test:e2e
```

### Laravel Dusk Migration
If migrating from Laravel Dusk:
- Convert `$browser` methods to Playwright `page` methods
- Update selectors to use `data-testid` attributes
- Adapt wait strategies for Livewire components

## Production Considerations

### Security Testing
- Test authentication flows thoroughly
- Verify CSRF protection
- Check authorization boundaries
- Test file upload security

### Performance Testing
- Monitor page load times
- Test with realistic data volumes
- Verify responsive design performance
- Check for memory leaks in SPAs

### Accessibility Testing
```javascript
// Basic accessibility check
await expect(page).toHaveAccessibleName('Create User');
await expect(page.locator('button')).toHaveAttribute('aria-label');
```

This comprehensive Playwright integration provides robust testing capabilities for your Laravel 12 + FluxUI application, ensuring reliable end-to-end testing across all browsers and devices. 
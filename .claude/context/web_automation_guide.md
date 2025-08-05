# Web Automation & Data Retrieval Guide

## Overview

This project includes both **Playwright MCP** and **Fetch MCP** servers to provide comprehensive web interaction capabilities. Each serves different purposes and understanding when to use which tool is crucial for effective agent tasks.

## Playwright MCP vs Fetch MCP: When to Use Which

### 🎭 **Playwright MCP** - For Complex Browser Interactions

**Use Playwright when you need:**
- **Visual Testing**: Screenshots, visual comparisons, UI testing
- **JavaScript-Heavy Sites**: Sites that require JavaScript execution
- **Form Interactions**: Complex form filling, file uploads, multi-step wizards
- **Authentication Flows**: Login sequences, OAuth flows, session management
- **Mobile Testing**: Device emulation, responsive design testing
- **User Journey Testing**: Multi-page workflows, shopping cart flows
- **Dynamic Content**: Content that loads via AJAX, infinite scroll, real-time updates

**Example Use Cases:**
```javascript
// Test FluxUI component interactions
await page.goto('/dashboard');
await page.click('[data-testid="create-user-button"]');
await page.fill('[data-testid="name-input"]', 'John Doe');
await page.screenshot({ path: 'dashboard-test.png' });

// Scrape JavaScript-rendered content
await page.goto('https://spa-website.com');
await page.waitForSelector('.dynamic-content');
const content = await page.textContent('.dynamic-content');
```

### 🔍 **Fetch MCP** - For Lightweight Data Retrieval

**Use Fetch when you need:**
- **API Calls**: REST API consumption, data retrieval
- **Simple Web Scraping**: Static HTML content extraction
- **Information Gathering**: Research tasks, data collection
- **Fast Requests**: Lightweight operations without browser overhead
- **Bulk Data Processing**: Multiple rapid requests
- **RSS/XML Parsing**: Feed processing, data syndication
- **Health Checks**: Server monitoring, uptime checks

**Example Use Cases:**
```bash
# Research tasks
"Fetch the latest Laravel documentation for validation rules"
"Get the current weather data from OpenWeatherMap API"
"Retrieve the latest GitHub releases for Laravel framework"

# API integration
"Fetch user data from the CRM API"
"Get product information from the inventory system"
"Retrieve exchange rates from the financial API"
```

## Complementary Use Cases

### **Research & Development Workflow**

1. **Fetch MCP**: Gather initial information
   - "Get the latest Laravel 12 features from the official docs"
   - "Fetch best practices for FluxUI from the documentation"
   - "Retrieve current package versions from NPM"

2. **Playwright MCP**: Validate implementations
   - Test the implemented features visually
   - Verify responsive design across devices
   - Ensure accessibility compliance

### **E-commerce Integration**

1. **Fetch MCP**: Data synchronization
   - Pull product catalogs from supplier APIs
   - Sync inventory levels from ERP systems
   - Retrieve order status from fulfillment centers

2. **Playwright MCP**: User experience testing
   - Test checkout flows end-to-end
   - Verify payment gateway integration
   - Validate mobile shopping experience

### **Content Management**

1. **Fetch MCP**: Content aggregation
   - Gather blog posts from multiple sources
   - Retrieve social media content via APIs
   - Fetch SEO data from analytics platforms

2. **Playwright MCP**: Content validation
   - Test content rendering across browsers
   - Verify layout consistency
   - Ensure proper meta tag implementation

## Performance Considerations

### **Fetch MCP Performance**
- ⚡ **Fast**: Minimal overhead, direct HTTP requests
- 💾 **Lightweight**: Low memory usage
- 🔄 **Scalable**: Handle multiple concurrent requests
- 📊 **Efficient**: Perfect for bulk data operations

### **Playwright MCP Performance**
- 🐌 **Slower**: Full browser execution overhead
- 💾 **Heavy**: Higher memory and CPU usage
- 🎯 **Thorough**: Complete page rendering and JavaScript execution
- 🔍 **Detailed**: Rich debugging and inspection capabilities

## Integration Patterns

### **Laravel Service Integration**

```php
// For API-based integrations (use Fetch MCP)
class ExternalDataService
{
    public function fetchUserData(string $userId): array
    {
        // Claude can use Fetch MCP to retrieve this data
        return $this->makeApiRequest("/api/users/{$userId}");
    }
}

// For complex UI testing (use Playwright MCP)
class ComponentTestService
{
    public function validateFluxUIComponent(string $component): bool
    {
        // Claude can use Playwright MCP to test this
        // Works seamlessly with Laravel Herd for local development
        return $this->runPlaywrightTest($component);
    }
}
```

### **Data Pipeline Example**

```php
// Step 1: Fetch MCP - Gather data
$apiData = fetch('https://api.example.com/products');

// Step 2: Process in Laravel
Product::upsert($apiData, ['external_id'], ['name', 'price']);

// Step 3: Playwright MCP - Verify UI
playwright('test product display on frontend');
```

## Agent Task Examples

### **Research Tasks** (Fetch MCP)
```
Agent: "Research the latest Laravel 12 security features"
→ Fetch: Laravel docs, security guides, release notes
→ Result: Comprehensive security feature summary
```

### **Testing Tasks** (Playwright MCP)
```
Agent: "Test the user registration flow with FluxUI components"
→ Playwright: Navigate, fill forms, submit, verify success
→ Result: Complete flow validation with screenshots
```

### **Integration Tasks** (Both)
```
Agent: "Integrate and test a new payment provider"
→ Fetch: Get API documentation, endpoint details
→ Laravel: Implement integration code
→ Playwright: Test payment flow end-to-end
→ Result: Fully tested payment integration
```

## Best Practices

### **Choose Fetch MCP When:**
- The content is static HTML
- You need simple data extraction
- Performance is critical
- You're making API calls
- The site doesn't require JavaScript

### **Choose Playwright MCP When:**
- Content is JavaScript-generated
- You need to interact with the page
- Visual validation is required
- Testing user workflows
- Authentication is involved

### **Use Both When:**
- Building comprehensive testing suites
- Implementing complex integrations
- Validating data accuracy across systems
- Creating robust monitoring solutions

## Security Considerations

### **Fetch MCP Security**
- Implement rate limiting for API calls
- Use authentication tokens securely
- Validate and sanitize all retrieved data
- Monitor for API abuse

### **Playwright MCP Security**
- Run in isolated environments
- Avoid executing untrusted scripts
- Limit file system access
- Use headless mode in production

## Monitoring & Debugging

### **Fetch MCP Debugging**
```bash
# Monitor API response times
# Log request/response pairs
# Track rate limit usage
# Alert on failed requests
```

### **Playwright MCP Debugging**
```bash
# Capture screenshots on failures
# Record video of test runs
# Export trace files for analysis
# Monitor browser resource usage
```

This dual approach ensures you have both **lightweight data retrieval** (Fetch MCP) and **comprehensive browser automation** (Playwright MCP) capabilities, making your Laravel application truly production-ready for any web interaction scenario. 
# NetSuite Integration Guidelines

## Overview
NetSuite is a cloud-based ERP system that provides comprehensive business management capabilities. This guide covers integration patterns for Laravel applications.

## SuiteQL (NetSuite Query Language)

### What is SuiteQL?
SuiteQL is NetSuite's SQL-like query language that allows you to query NetSuite data using familiar SQL syntax. It provides better performance and more flexibility than traditional record searches.

### Key Features
- SQL-like syntax for querying NetSuite records
- Join capabilities across multiple record types
- Aggregation functions (SUM, COUNT, AVG, etc.)
- Subqueries and complex filtering
- Better performance than traditional searches
- Access to system fields and custom fields

### Common SuiteQL Examples

#### Basic Customer Query
```sql
SELECT 
    id,
    companyname,
    email,
    phone,
    datecreated
FROM customer 
WHERE isinactive = 'F'
ORDER BY datecreated DESC
```

#### Sales Order with Customer Information
```sql
SELECT 
    so.id,
    so.tranid,
    so.trandate,
    so.total,
    c.companyname,
    c.email
FROM transaction so
INNER JOIN customer c ON so.entity = c.id
WHERE so.type = 'SalesOrd'
    AND so.status IN ('Pending Approval', 'Pending Fulfillment')
ORDER BY so.trandate DESC
```

#### Item Inventory Query
```sql
SELECT 
    i.id,
    i.itemid,
    i.displayname,
    i.quantityavailable,
    i.averagecost,
    i.lastpurchaseprice
FROM item i
WHERE i.isinactive = 'F'
    AND i.quantityavailable > 0
ORDER BY i.quantityavailable DESC
```

#### Complex Query with Aggregation
```sql
SELECT 
    c.companyname,
    COUNT(t.id) as order_count,
    SUM(t.total) as total_sales,
    AVG(t.total) as avg_order_value
FROM customer c
INNER JOIN transaction t ON c.id = t.entity
WHERE t.type = 'SalesOrd'
    AND t.trandate >= TO_DATE('2024-01-01', 'YYYY-MM-DD')
GROUP BY c.id, c.companyname
HAVING SUM(t.total) > 10000
ORDER BY total_sales DESC
```

## Laravel NetSuite Service Implementation

### Service Structure
```php
<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Collection;

class NetSuiteService
{
    protected string $baseUrl;
    protected string $consumerKey;
    protected string $consumerSecret;
    protected string $tokenId;
    protected string $tokenSecret;
    protected string $realm;

    public function __construct()
    {
        $this->baseUrl = config('services.netsuite.base_url');
        $this->consumerKey = config('services.netsuite.consumer_key');
        $this->consumerSecret = config('services.netsuite.consumer_secret');
        $this->tokenId = config('services.netsuite.token_id');
        $this->tokenSecret = config('services.netsuite.token_secret');
        $this->realm = config('services.netsuite.realm');
    }

    public function query(string $sql): Collection
    {
        $response = Http::withHeaders($this->getAuthHeaders())
            ->post("{$this->baseUrl}/services/rest/query/v1/suiteql", [
                'q' => $sql
            ]);

        if ($response->failed()) {
            throw new \Exception('NetSuite query failed: ' . $response->body());
        }

        return collect($response->json('items', []));
    }

    protected function getAuthHeaders(): array
    {
        // OAuth 1.0 signature implementation
        // This is simplified - use a proper OAuth library in production
        return [
            'Authorization' => $this->generateOAuthHeader(),
            'Content-Type' => 'application/json',
        ];
    }
}
```

### Configuration Setup
Add to `config/services.php`:
```php
'netsuite' => [
    'base_url' => env('NETSUITE_BASE_URL'),
    'consumer_key' => env('NETSUITE_CONSUMER_KEY'),
    'consumer_secret' => env('NETSUITE_CONSUMER_SECRET'),
    'token_id' => env('NETSUITE_TOKEN_ID'),
    'token_secret' => env('NETSUITE_TOKEN_SECRET'),
    'realm' => env('NETSUITE_REALM'),
],
```

## Common Integration Patterns

### Customer Synchronization
```php
class SyncCustomersFromNetSuite
{
    public function __construct(
        private NetSuiteService $netSuite,
    ) {}

    public function handle(): void
    {
        $customers = $this->netSuite->query("
            SELECT 
                id,
                companyname,
                email,
                phone,
                datecreated,
                lastmodifieddate
            FROM customer 
            WHERE isinactive = 'F'
                AND lastmodifieddate >= ?
        ", [now()->subHours(24)]);

        foreach ($customers as $customer) {
            Customer::updateOrCreate(
                ['netsuite_id' => $customer['id']],
                [
                    'name' => $customer['companyname'],
                    'email' => $customer['email'],
                    'phone' => $customer['phone'],
                    'netsuite_created_at' => $customer['datecreated'],
                    'netsuite_updated_at' => $customer['lastmodifieddate'],
                ]
            );
        }
    }
}
```

### Order Processing
```php
class ProcessNetSuiteOrders
{
    public function getRecentOrders(): Collection
    {
        return $this->netSuite->query("
            SELECT 
                so.id,
                so.tranid,
                so.trandate,
                so.total,
                so.status,
                c.companyname,
                c.email
            FROM transaction so
            INNER JOIN customer c ON so.entity = c.id
            WHERE so.type = 'SalesOrd'
                AND so.trandate >= ?
            ORDER BY so.trandate DESC
        ", [now()->subDays(7)]);
    }
}
```

## REST API Endpoints

### RESTlets
Custom RESTlets for specific business logic:
```javascript
// NetSuite RESTlet example
function get(context) {
    var customerId = context.customer_id;
    
    var customerRecord = record.load({
        type: record.Type.CUSTOMER,
        id: customerId
    });
    
    return {
        id: customerRecord.id,
        name: customerRecord.getValue('companyname'),
        email: customerRecord.getValue('email'),
        balance: customerRecord.getValue('balance')
    };
}
```

### Laravel RESTlet Integration
```php
class NetSuiteRestletService
{
    public function getCustomerDetails(int $customerId): array
    {
        $response = Http::withHeaders($this->getAuthHeaders())
            ->get("{$this->baseUrl}/app/site/hosting/restlet.nl", [
                'script' => config('services.netsuite.customer_restlet_id'),
                'deploy' => '1',
                'customer_id' => $customerId,
            ]);

        return $response->json();
    }
}
```

## Error Handling

### Common NetSuite Errors
- Rate limiting (429 responses)
- Authentication failures
- Invalid SuiteQL syntax
- Record not found
- Permission issues

### Error Handling Pattern
```php
class NetSuiteException extends Exception {}

class RateLimitException extends NetSuiteException {}
class AuthenticationException extends NetSuiteException {}
class InvalidQueryException extends NetSuiteException {}

// In service method
try {
    $response = Http::withHeaders($this->getAuthHeaders())
        ->timeout(30)
        ->retry(3, 1000)
        ->post($url, $data);
        
    if ($response->status() === 429) {
        throw new RateLimitException('NetSuite rate limit exceeded');
    }
    
    if ($response->status() === 401) {
        throw new AuthenticationException('NetSuite authentication failed');
    }
    
    return $response->json();
} catch (RequestException $e) {
    throw new NetSuiteException('NetSuite request failed: ' . $e->getMessage());
}
```

## Performance Considerations

### Query Optimization
- Use appropriate indexes
- Limit result sets with LIMIT clauses
- Use specific field selection instead of SELECT *
- Implement pagination for large datasets

### Caching Strategy
```php
class CachedNetSuiteService
{
    public function getCustomers(): Collection
    {
        return Cache::remember('netsuite.customers', 3600, function () {
            return $this->netSuite->query("
                SELECT id, companyname, email 
                FROM customer 
                WHERE isinactive = 'F'
            ");
        });
    }
}
```

### Background Processing
Use Laravel queues for heavy NetSuite operations:
```php
class SyncNetSuiteData implements ShouldQueue
{
    public function handle(): void
    {
        // Heavy NetSuite synchronization logic
    }
}
```

## Security Best Practices

### Environment Variables
```env
NETSUITE_BASE_URL=https://account.suitetalk.api.netsuite.com
NETSUITE_CONSUMER_KEY=your_consumer_key
NETSUITE_CONSUMER_SECRET=your_consumer_secret
NETSUITE_TOKEN_ID=your_token_id
NETSUITE_TOKEN_SECRET=your_token_secret
NETSUITE_REALM=your_account_id
```

### OAuth Implementation
Use proper OAuth 1.0 libraries for production:
- `firebase/php-jwt` for JWT handling
- `guzzlehttp/oauth-subscriber` for OAuth signatures

### Data Validation
Always validate data from NetSuite before using in your application:
```php
$validated = validator($netSuiteData, [
    'id' => 'required|integer',
    'companyname' => 'required|string|max:255',
    'email' => 'nullable|email',
])->validate();
```
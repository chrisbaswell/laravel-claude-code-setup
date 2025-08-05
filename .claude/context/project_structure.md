# Laravel Project Structure Guidelines

## Directory Structure

```
app/
├── Console/
│   └── Commands/
├── Exceptions/
├── Http/
│   ├── Controllers/
│   │   ├── Api/
│   │   └── Web/
│   ├── Middleware/
│   ├── Requests/
│   └── Resources/
├── Livewire/
│   ├── Forms/
│   ├── Modals/
│   └── Tables/
├── Models/
├── Providers/
├── Services/
│   ├── NetSuite/
│   └── External/
├── Jobs/
├── Mail/
├── Notifications/
├── Events/
├── Listeners/
├── Policies/
├── Rules/
└── View/
    └── Components/

config/
├── app.php
├── database.php
├── services.php
└── netsuite.php

database/
├── factories/
├── migrations/
├── seeders/
└── schema/

resources/
├── css/
│   └── app.css
├── js/
│   ├── app.js
│   ├── components/
│   └── utils/
├── views/
│   ├── components/
│   ├── layouts/
│   ├── livewire/
│   └── pages/
└── lang/

routes/
├── web.php
├── api.php
├── console.php
└── channels.php

tests/
├── Feature/
│   ├── Http/
│   ├── Livewire/
│   └── Services/
└── Unit/
    ├── Models/
    └── Services/
```

## Service Layer Organization

### NetSuite Services
```php
// app/Services/NetSuite/NetSuiteService.php
namespace App\Services\NetSuite;

class NetSuiteService
{
    // Base NetSuite integration
}

// app/Services/NetSuite/CustomerService.php
namespace App\Services\NetSuite;

class CustomerService extends NetSuiteService
{
    public function syncCustomers(): void
    {
        // Customer-specific logic
    }
}

// app/Services/NetSuite/OrderService.php
namespace App\Services\NetSuite;

class OrderService extends NetSuiteService
{
    public function syncOrders(): void
    {
        // Order-specific logic
    }
}
```

### External Services
```php
// app/Services/External/PaymentService.php
namespace App\Services\External;

class PaymentService
{
    // Payment gateway integration
}

// app/Services/External/EmailService.php
namespace App\Services\External;

class EmailService
{
    // Email service integration
}
```

## Livewire Component Organization

### Forms
```php
// app/Livewire/Forms/CustomerForm.php
namespace App\Livewire\Forms;

use Livewire\Form;

class CustomerForm extends Form
{
    // Customer form logic
}

// app/Livewire/Forms/OrderForm.php
namespace App\Livewire\Forms;

use Livewire\Form;

class OrderForm extends Form
{
    // Order form logic
}
```

### Tables
```php
// app/Livewire/Tables/CustomerTable.php
namespace App\Livewire\Tables;

use Livewire\Component;

class CustomerTable extends Component
{
    // Customer table logic
}
```

### Modals
```php
// app/Livewire/Modals/CustomerModal.php
namespace App\Livewire\Modals;

use Livewire\Component;

class CustomerModal extends Component
{
    // Customer modal logic
}
```

## Model Organization

### Base Model
```php
// app/Models/BaseModel.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

abstract class BaseModel extends Model
{
    use SoftDeletes;

    protected $guarded = ['id'];

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
            'deleted_at' => 'datetime',
        ];
    }
}
```

### Domain Models
```php
// app/Models/Customer.php
namespace App\Models;

use Illuminate\Database\Eloquent\Relations\HasMany;

class Customer extends BaseModel
{
    protected function casts(): array
    {
        return array_merge(parent::casts(), [
            'metadata' => 'array',
            'preferences' => 'array',
        ]);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeSearch($query, string $search)
    {
        return $query->where(function ($q) use ($search) {
            $q->where('name', 'like', "%{$search}%")
              ->orWhere('email', 'like', "%{$search}%");
        });
    }
}
```

## Configuration Files

### NetSuite Configuration
```php
// config/netsuite.php
return [
    'base_url' => env('NETSUITE_BASE_URL'),
    'credentials' => [
        'consumer_key' => env('NETSUITE_CONSUMER_KEY'),
        'consumer_secret' => env('NETSUITE_CONSUMER_SECRET'),
        'token_id' => env('NETSUITE_TOKEN_ID'),
        'token_secret' => env('NETSUITE_TOKEN_SECRET'),
    ],
    'realm' => env('NETSUITE_REALM'),
    'timeout' => env('NETSUITE_TIMEOUT', 30),
    'retry_attempts' => env('NETSUITE_RETRY_ATTEMPTS', 3),
    'cache_ttl' => env('NETSUITE_CACHE_TTL', 3600),
];
```

### Services Configuration
```php
// config/services.php additions
'netsuite' => [
    'base_url' => env('NETSUITE_BASE_URL'),
    'consumer_key' => env('NETSUITE_CONSUMER_KEY'),
    'consumer_secret' => env('NETSUITE_CONSUMER_SECRET'),
    'token_id' => env('NETSUITE_TOKEN_ID'),
    'token_secret' => env('NETSUITE_TOKEN_SECRET'),
    'realm' => env('NETSUITE_REALM'),
],

'mailgun' => [
    'domain' => env('MAILGUN_DOMAIN'),
    'secret' => env('MAILGUN_SECRET'),
    'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
    'scheme' => 'https',
],
```

## View Organization

### Layouts
```blade
{{-- resources/views/layouts/app.blade.php --}}
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>{{ config('app.name', 'Laravel') }}</title>

    @vite(['resources/css/app.css', 'resources/js/app.js'])
    @livewireStyles
</head>
<body class="font-sans antialiased">
    <div class="min-h-screen bg-gray-100">
        @include('layouts.navigation')

        <main>
            {{ $slot }}
        </main>
    </div>

    @livewireScripts
</body>
</html>
```

### Components
```blade
{{-- resources/views/components/button.blade.php --}}
@props([
    'variant' => 'primary',
    'size' => 'md',
    'disabled' => false,
])

@php
$classes = match($variant) {
    'primary' => 'bg-blue-600 hover:bg-blue-700 text-white',
    'secondary' => 'bg-gray-600 hover:bg-gray-700 text-white',
    'danger' => 'bg-red-600 hover:bg-red-700 text-white',
    default => 'bg-blue-600 hover:bg-blue-700 text-white',
};

$sizeClasses = match($size) {
    'sm' => 'px-2 py-1 text-sm',
    'md' => 'px-4 py-2',
    'lg' => 'px-6 py-3 text-lg',
    default => 'px-4 py-2',
};
@endphp

<button 
    {{ $attributes->merge([
        'type' => 'button',
        'class' => "inline-flex items-center justify-center rounded-md font-medium transition-colors {$classes} {$sizeClasses}" . ($disabled ? ' opacity-50 cursor-not-allowed' : ''),
        'disabled' => $disabled,
    ]) }}
>
    {{ $slot }}
</button>
```

### Livewire Views
```blade
{{-- resources/views/livewire/customer-list.blade.php --}}
<div>
    <div class="mb-6 flex justify-between items-center">
        <h1 class="text-2xl font-bold text-gray-900">Customers</h1>
        <x-button wire:click="$dispatch('openModal', { component: 'customer-modal' })">
            Add Customer
        </x-button>
    </div>

    <div class="mb-4 flex space-x-4">
        <div class="flex-1">
            <input 
                type="text" 
                wire:model.live.debounce.300ms="search"
                placeholder="Search customers..."
                class="w-full rounded-md border-gray-300 shadow-sm"
            >
        </div>
        <div>
            <select wire:model.live="filter" class="rounded-md border-gray-300 shadow-sm">
                <option value="all">All</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
            </select>
        </div>
    </div>

    <div class="bg-white shadow overflow-hidden sm:rounded-md">
        @forelse($customers as $customer)
            <div class="px-4 py-4 border-b border-gray-200">
                {{-- Customer item --}}
            </div>
        @empty
            <div class="px-4 py-8 text-center text-gray-500">
                No customers found.
            </div>
        @endforelse
    </div>

    <div class="mt-4">
        {{ $customers->links() }}
    </div>
</div>
```

## Testing Structure

### Feature Tests
```php
// tests/Feature/Livewire/CustomerListTest.php
namespace Tests\Feature\Livewire;

use App\Livewire\CustomerList;
use App\Models\Customer;
use Livewire\Livewire;
use Tests\TestCase;

class CustomerListTest extends TestCase
{
    public function test_can_render_component(): void
    {
        Customer::factory()->count(5)->create();

        Livewire::test(CustomerList::class)
            ->assertStatus(200)
            ->assertSee('Customers');
    }

    public function test_can_search_customers(): void
    {
        Customer::factory()->create(['name' => 'John Doe']);
        Customer::factory()->create(['name' => 'Jane Smith']);

        Livewire::test(CustomerList::class)
            ->set('search', 'John')
            ->assertSee('John Doe')
            ->assertDontSee('Jane Smith');
    }
}
```

### Unit Tests
```php
// tests/Unit/Services/NetSuiteServiceTest.php
namespace Tests\Unit\Services;

use App\Services\NetSuite\NetSuiteService;
use Tests\TestCase;

class NetSuiteServiceTest extends TestCase
{
    public function test_can_build_query(): void
    {
        $service = new NetSuiteService();
        
        $query = $service->buildQuery('customer', ['name', 'email'], ['status' => 'active']);
        
        $this->assertStringContainsString('SELECT name, email FROM customer', $query);
        $this->assertStringContainsString('WHERE status = ?', $query);
    }
}
```

## Environment Configuration

### Development .env
```env
APP_NAME="Your App Name"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=your_database
DB_USERNAME=your_username
DB_PASSWORD=your_password

# NetSuite Configuration
NETSUITE_BASE_URL=https://your-account.suitetalk.api.netsuite.com
NETSUITE_CONSUMER_KEY=your_consumer_key
NETSUITE_CONSUMER_SECRET=your_consumer_secret
NETSUITE_TOKEN_ID=your_token_id
NETSUITE_TOKEN_SECRET=your_token_secret
NETSUITE_REALM=your_account_id

# Mail Configuration
MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"

# Queue Configuration
QUEUE_CONNECTION=database

# Cache Configuration
CACHE_DRIVER=file
SESSION_DRIVER=file
SESSION_LIFETIME=120
```
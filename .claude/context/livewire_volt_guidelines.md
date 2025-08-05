# Livewire Volt Guidelines

## What is Livewire Volt?

Livewire Volt is a functional API for Livewire that allows you to build components using a more concise, functional approach directly in your Blade templates. It eliminates the need for traditional class-based components in many cases.

## Installation

Volt comes with Livewire 3.x but needs to be installed:

```bash
composer require livewire/volt
php artisan volt:install
```

## Core Volt Patterns

### Functional Components (Preferred)

Instead of traditional class-based components, use Volt's functional API:

#### Basic Volt Component
```blade
<?php
use function Livewire\Volt\{state, computed};

state(['count' => 0]);

$increment = fn () => $this->count++;
$decrement = fn () => $this->count--;

$doubleCount = computed(fn () => $this->count * 2);
?>

<div>
    <h1>Counter: {{ $this->count }}</h1>
    <p>Double: {{ $this->doubleCount }}</p>
    
    <flux:button wire:click="increment">+</flux:button>
    <flux:button wire:click="decrement">-</flux:button>
</div>
```

#### Form Component with Validation
```blade
<?php
use function Livewire\Volt\{state, rules};
use App\Models\User;

state([
    'name' => '',
    'email' => '',
    'password' => '',
]);

rules([
    'name' => 'required|string|max:255',
    'email' => 'required|email|unique:users,email',
    'password' => 'required|string|min:8',
]);

$save = function () {
    $this->validate();
    
    User::create([
        'name' => $this->name,
        'email' => $this->email,
        'password' => Hash::make($this->password),
    ]);
    
    session()->flash('success', 'User created successfully!');
    $this->reset();
};
?>

<div>
    <flux:card>
        <flux:card.header>
            <flux:heading size="lg">Create User</flux:heading>
        </flux:card.header>
        
        <flux:card.body class="space-y-4">
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
            
            <flux:field>
                <flux:label>Password</flux:label>
                <flux:input wire:model="password" type="password" />
                <flux:error name="password" />
            </flux:field>
        </flux:card.body>
        
        <flux:card.footer>
            <flux:button variant="primary" wire:click="save">
                Create User
            </flux:button>
        </flux:card.footer>
    </flux:card>
</div>
```

### Data Table with Volt
```blade
<?php
use function Livewire\Volt\{state, computed, with};
use App\Models\User;

state([
    'search' => '',
    'sortField' => 'created_at',
    'sortDirection' => 'desc',
]);

$users = computed(function () {
    return User::query()
        ->when($this->search, fn($query) => 
            $query->where('name', 'like', "%{$this->search}%")
                  ->orWhere('email', 'like', "%{$this->search}%")
        )
        ->orderBy($this->sortField, $this->sortDirection)
        ->paginate(10);
});

$sortBy = function (string $field) {
    if ($this->sortField === $field) {
        $this->sortDirection = $this->sortDirection === 'asc' ? 'desc' : 'asc';
    } else {
        $this->sortField = $field;
        $this->sortDirection = 'asc';
    }
};

$deleteUser = function (User $user) {
    $user->delete();
    session()->flash('success', 'User deleted successfully!');
};
?>

<div>
    <div class="mb-4">
        <flux:input 
            wire:model.live.debounce.300ms="search" 
            placeholder="Search users..." 
        />
    </div>

    <flux:table>
        <flux:columns>
            <flux:column sortable wire:click="sortBy('name')">
                Name
                @if($sortField === 'name')
                    <span class="ml-1">{{ $sortDirection === 'asc' ? '↑' : '↓' }}</span>
                @endif
            </flux:column>
            <flux:column sortable wire:click="sortBy('email')">
                Email
                @if($sortField === 'email')
                    <span class="ml-1">{{ $sortDirection === 'asc' ? '↑' : '↓' }}</span>
                @endif
            </flux:column>
            <flux:column>Actions</flux:column>
        </flux:columns>
        
        <flux:rows>
            @foreach($this->users as $user)
                <flux:row wire:key="{{ $user->id }}">
                    <flux:cell>{{ $user->name }}</flux:cell>
                    <flux:cell>{{ $user->email }}</flux:cell>
                    <flux:cell>
                        <flux:button 
                            size="sm" 
                            variant="danger" 
                            wire:click="deleteUser({{ $user->id }})"
                            wire:confirm="Are you sure you want to delete this user?"
                        >
                            Delete
                        </flux:button>
                    </flux:cell>
                </flux:row>
            @endforeach
        </flux:rows>
    </flux:table>

    <div class="mt-4">
        {{ $this->users->links() }}
    </div>
</div>
```

### Modal Component with Volt
```blade
<?php
use function Livewire\Volt\{state, rules};
use App\Models\User;

state([
    'showModal' => false,
    'user' => null,
    'name' => '',
    'email' => '',
]);

rules([
    'name' => 'required|string|max:255',
    'email' => 'required|email',
]);

$openModal = function (?User $user = null) {
    $this->user = $user;
    
    if ($user) {
        $this->name = $user->name;
        $this->email = $user->email;
    } else {
        $this->reset(['name', 'email']);
    }
    
    $this->showModal = true;
};

$closeModal = function () {
    $this->showModal = false;
    $this->reset(['user', 'name', 'email']);
};

$save = function () {
    $this->validate();
    
    if ($this->user) {
        $this->user->update([
            'name' => $this->name,
            'email' => $this->email,
        ]);
        $message = 'User updated successfully!';
    } else {
        User::create([
            'name' => $this->name,
            'email' => $this->email,
        ]);
        $message = 'User created successfully!';
    }
    
    session()->flash('success', $message);
    $this->closeModal();
};
?>

<div>
    <flux:button variant="primary" wire:click="openModal">
        Add User
    </flux:button>

    <flux:modal wire:model="showModal" name="user-modal">
        <flux:modal.header>
            <flux:heading size="lg">
                {{ $user ? 'Edit User' : 'Create User' }}
            </flux:heading>
        </flux:modal.header>
        
        <flux:modal.body>
            <div class="space-y-4">
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
            </div>
        </flux:modal.body>
        
        <flux:modal.footer>
            <flux:button variant="primary" wire:click="save">
                {{ $user ? 'Update' : 'Create' }}
            </flux:button>
            <flux:button variant="outline" wire:click="closeModal">
                Cancel
            </flux:button>
        </flux:modal.footer>
    </flux:modal>
</div>
```

## Advanced Volt Features

### Lifecycle Hooks
```blade
<?php
use function Livewire\Volt\{state, mount, updated};

state(['name' => '']);

mount(function () {
    $this->name = auth()->user()->name ?? '';
});

updated(['name' => function ($value) {
    // Called when name is updated
    logger('Name updated to: ' . $value);
}]);
?>

<div>
    <flux:input wire:model.live="name" />
</div>
```

### With Computed Properties and Dependencies
```blade
<?php
use function Livewire\Volt\{state, computed, with};
use App\Models\{Category, Product};

state([
    'selectedCategory' => null,
    'search' => '',
]);

$categories = computed(fn () => Category::all());

$products = computed(function () {
    return Product::query()
        ->when($this->selectedCategory, fn($q) => $q->where('category_id', $this->selectedCategory))
        ->when($this->search, fn($q) => $q->where('name', 'like', "%{$this->search}%"))
        ->get();
});
?>

<div>
    <div class="mb-4 space-y-4">
        <flux:select wire:model.live="selectedCategory" placeholder="Select category">
            @foreach($this->categories as $category)
                <flux:option value="{{ $category->id }}">{{ $category->name }}</flux:option>
            @endforeach
        </flux:select>
        
        <flux:input wire:model.live.debounce.300ms="search" placeholder="Search products..." />
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        @foreach($this->products as $product)
            <flux:card wire:key="{{ $product->id }}">
                <flux:card.header>
                    <flux:heading size="md">{{ $product->name }}</flux:heading>
                </flux:card.header>
                <flux:card.body>
                    <p class="text-gray-600">{{ $product->description }}</p>
                    <p class="font-bold text-lg">${{ number_format($product->price, 2) }}</p>
                </flux:card.body>
            </flux:card>
        @endforeach
    </div>
</div>
```

## Class-Based Components (When Needed)

While Volt functional components are preferred, use traditional class-based components for:

1. **Complex business logic** that spans multiple methods
2. **Heavy state management** with many properties
3. **Components that need traits** or inheritance
4. **When you need fine-grained control** over Livewire lifecycle methods

### Traditional Class Component (When Volt isn't suitable)
```php
<?php

namespace App\Livewire;

use Livewire\Component;
use Livewire\WithPagination;
use App\Services\ReportService;

class ComplexReportDashboard extends Component
{
    use WithPagination;

    public array $filters = [];
    public string $reportType = 'daily';
    public ?string $dateRange = null;
    
    public function __construct(
        private ReportService $reportService
    ) {}

    public function mount(): void
    {
        $this->initializeFilters();
    }

    public function generateReport(): void
    {
        // Complex report generation logic
        $this->reportService->generate($this->filters, $this->reportType);
    }

    public function exportToExcel(): void
    {
        // Export functionality
    }

    public function render()
    {
        return view('livewire.complex-report-dashboard', [
            'reportData' => $this->getReportData(),
        ]);
    }

    private function initializeFilters(): void
    {
        // Complex initialization logic
    }

    private function getReportData(): array
    {
        // Complex data processing
        return $this->reportService->getProcessedData($this->filters);
    }
}
```

## Best Practices for Volt

### 1. File Organization
```
resources/views/livewire/
├── components/
│   ├── user-form.blade.php          # Volt functional component
│   ├── product-card.blade.php       # Volt functional component
│   └── data-table.blade.php         # Volt functional component
├── pages/
│   ├── dashboard.blade.php          # Volt page component
│   └── settings.blade.php           # Volt page component
└── complex/
    └── report-dashboard.blade.php   # Traditional class component
```

### 2. State Management
```blade
<?php
// ✅ Good: Clear, descriptive state
state([
    'user' => null,
    'isEditing' => false,
    'formData' => [
        'name' => '',
        'email' => '',
    ],
]);

// ❌ Avoid: Unclear or overly complex state
state(['data', 'stuff', 'things']);
?>
```

### 3. Action Naming
```blade
<?php
// ✅ Good: Descriptive action names
$saveUser = function () { /* ... */ };
$deleteUser = function (User $user) { /* ... */ };
$toggleUserStatus = function (User $user) { /* ... */ };

// ❌ Avoid: Generic or unclear names
$save = function () { /* ... */ };
$doStuff = function () { /* ... */ };
?>
```

### 4. Validation Patterns
```blade
<?php
// ✅ Good: Clear validation rules
rules([
    'formData.name' => 'required|string|max:255',
    'formData.email' => 'required|email|unique:users,email',
]);

// ✅ Good: Conditional validation
$validateAndSave = function () {
    $rules = [
        'name' => 'required|string|max:255',
        'email' => 'required|email',
    ];
    
    if (!$this->user) {
        $rules['email'] .= '|unique:users,email';
    }
    
    $this->validate($rules);
    // Save logic here...
};
?>
```

## Integration with FluxUI

Volt components work seamlessly with FluxUI:

```blade
<?php
use function Livewire\Volt\{state, rules};

state([
    'formData' => [
        'title' => '',
        'content' => '',
        'category_id' => null,
        'is_published' => false,
    ],
]);

rules([
    'formData.title' => 'required|string|max:255',
    'formData.content' => 'required|string',
    'formData.category_id' => 'required|exists:categories,id',
]);

$save = function () {
    $this->validate();
    
    Post::create($this->formData);
    
    session()->flash('success', 'Post created successfully!');
    $this->reset('formData');
};
?>

<flux:card>
    <flux:card.header>
        <flux:heading>Create New Post</flux:heading>
    </flux:card.header>
    
    <flux:card.body class="space-y-4">
        <flux:field>
            <flux:label>Title</flux:label>
            <flux:input wire:model="formData.title" />
            <flux:error name="formData.title" />
        </flux:field>
        
        <flux:field>
            <flux:label>Content</flux:label>
            <flux:textarea wire:model="formData.content" rows="6" />
            <flux:error name="formData.content" />
        </flux:field>
        
        <flux:field>
            <flux:label>Category</flux:label>
            <flux:select wire:model="formData.category_id" placeholder="Select category">
                @foreach($categories as $category)
                    <flux:option value="{{ $category->id }}">{{ $category->name }}</flux:option>
                @endforeach
            </flux:select>
            <flux:error name="formData.category_id" />
        </flux:field>
        
        <flux:checkbox wire:model="formData.is_published">
            Publish immediately
        </flux:checkbox>
    </flux:card.body>
    
    <flux:card.footer>
        <flux:button variant="primary" wire:click="save">
            Create Post
        </flux:button>
    </flux:card.footer>
</flux:card>
```

## When to Use Class vs Volt

### Use Volt Functional Components When:
- ✅ Building simple to medium complexity components
- ✅ Form handling with straightforward validation
- ✅ Data tables and lists
- ✅ Modal dialogs
- ✅ Dashboard widgets
- ✅ CRUD operations

### Use Traditional Class Components When:
- ✅ Complex business logic spanning multiple methods
- ✅ Heavy state management with many interdependent properties
- ✅ Need for traits, inheritance, or dependency injection
- ✅ Complex lifecycle management
- ✅ Integration with complex third-party services
- ✅ Components requiring extensive testing with method-level granularity

Volt represents the modern, preferred approach for most Livewire components, offering cleaner syntax and better developer experience while maintaining all of Livewire's powerful features.
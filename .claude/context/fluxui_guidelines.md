# FluxUI Integration Guidelines

## What is FluxUI?

FluxUI is a component library for Laravel Livewire that provides beautiful, pre-styled components built with Tailwind CSS. It offers a comprehensive set of UI components that work seamlessly with Livewire, eliminating the need to build custom components from scratch.

## Installation

FluxUI is typically installed via Composer:
```bash
composer require livewire/flux
php artisan flux:install
```

## Core FluxUI Components

### Form Components

#### Input Fields
```blade
{{-- Basic input --}}
<flux:input wire:model="name" placeholder="Enter your name" />

{{-- Input with label --}}
<flux:field>
    <flux:label>Full Name</flux:label>
    <flux:input wire:model="name" placeholder="John Doe" />
    <flux:error name="name" />
</flux:field>

{{-- Input with icon --}}
<flux:input wire:model="email" icon="envelope" placeholder="email@example.com" />

{{-- Password input --}}
<flux:input type="password" wire:model="password" placeholder="Password" />

{{-- Number input --}}
<flux:input type="number" wire:model="age" min="18" max="100" />
```

#### Select Fields
```blade
{{-- Basic select --}}
<flux:select wire:model="category" placeholder="Select category">
    <flux:option value="electronics">Electronics</flux:option>
    <flux:option value="clothing">Clothing</flux:option>
    <flux:option value="books">Books</flux:option>
</flux:select>

{{-- Select with search --}}
<flux:select wire:model="country" searchable placeholder="Search countries">
    @foreach($countries as $country)
        <flux:option value="{{ $country->id }}">{{ $country->name }}</flux:option>
    @endforeach
</flux:select>

{{-- Multi-select --}}
<flux:select wire:model="tags" multiple placeholder="Select tags">
    @foreach($availableTags as $tag)
        <flux:option value="{{ $tag->id }}">{{ $tag->name }}</flux:option>
    @endforeach
</flux:select>
```

#### Textarea
```blade
<flux:field>
    <flux:label>Description</flux:label>
    <flux:textarea wire:model="description" rows="4" placeholder="Enter description..." />
    <flux:error name="description" />
</flux:field>
```

#### Checkboxes and Radio Buttons
```blade
{{-- Checkbox --}}
<flux:checkbox wire:model="agree_terms">
    I agree to the terms and conditions
</flux:checkbox>

{{-- Radio buttons --}}
<flux:field>
    <flux:label>Subscription Type</flux:label>
    <flux:radio.group wire:model="subscription_type">
        <flux:radio value="basic" label="Basic ($9/month)" />
        <flux:radio value="premium" label="Premium ($19/month)" />
        <flux:radio value="enterprise" label="Enterprise ($49/month)" />
    </flux:radio.group>
    <flux:error name="subscription_type" />
</flux:field>
```

### Buttons and Actions

#### Basic Buttons
```blade
{{-- Primary button --}}
<flux:button variant="primary" wire:click="save">
    Save Changes
</flux:button>

{{-- Secondary button --}}
<flux:button variant="outline" wire:click="cancel">
    Cancel
</flux:button>

{{-- Danger button --}}
<flux:button variant="danger" wire:click="delete" wire:confirm="Are you sure?">
    Delete
</flux:button>

{{-- Button with icon --}}
<flux:button icon="plus" wire:click="create">
    Add New Item
</flux:button>

{{-- Loading state --}}
<flux:button wire:click="processPayment" wire:loading.attr="disabled">
    <span wire:loading.remove>Process Payment</span>
    <span wire:loading>Processing...</span>
</flux:button>
```

#### Button Groups
```blade
<flux:button.group>
    <flux:button variant="outline">Left</flux:button>
    <flux:button variant="outline">Center</flux:button>
    <flux:button variant="outline">Right</flux:button>
</flux:button.group>
```

### Layout Components

#### Cards
```blade
<flux:card>
    <flux:card.header>
        <flux:heading size="lg">User Profile</flux:heading>
    </flux:card.header>
    
    <flux:card.body>
        <p>User information and settings go here.</p>
    </flux:card.body>
    
    <flux:card.footer>
        <flux:button variant="primary">Save</flux:button>
        <flux:button variant="outline">Cancel</flux:button>
    </flux:card.footer>
</flux:card>
```

#### Modals
```blade
<flux:modal wire:model="showModal" name="user-modal">
    <flux:modal.header>
        <flux:heading size="lg">Edit User</flux:heading>
    </flux:modal.header>
    
    <flux:modal.body>
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
    </flux:modal.body>
    
    <flux:modal.footer>
        <flux:button variant="primary" wire:click="save">
            Save Changes
        </flux:button>
        <flux:button variant="outline" wire:click="$set('showModal', false)">
            Cancel
        </flux:button>
    </flux:modal.footer>
</flux:modal>
```

#### Tables
```blade
<flux:table>
    <flux:columns>
        <flux:column>Name</flux:column>
        <flux:column>Email</flux:column>
        <flux:column>Role</flux:column>
        <flux:column>Actions</flux:column>
    </flux:columns>
    
    <flux:rows>
        @foreach($users as $user)
            <flux:row>
                <flux:cell>{{ $user->name }}</flux:cell>
                <flux:cell>{{ $user->email }}</flux:cell>
                <flux:cell>
                    <flux:badge color="blue">{{ $user->role }}</flux:badge>
                </flux:cell>
                <flux:cell>
                    <flux:button size="sm" wire:click="editUser({{ $user->id }})">
                        Edit
                    </flux:button>
                    <flux:button size="sm" variant="danger" wire:click="deleteUser({{ $user->id }})">
                        Delete
                    </flux:button>
                </flux:cell>
            </flux:row>
        @endforeach
    </flux:rows>
</flux:table>
```

### Navigation Components

#### Tabs
```blade
<flux:tabs wire:model="activeTab">
    <flux:tab name="profile">Profile</flux:tab>
    <flux:tab name="settings">Settings</flux:tab>
    <flux:tab name="billing">Billing</flux:tab>
    
    <flux:tab.panel name="profile">
        {{-- Profile content --}}
    </flux:tab.panel>
    
    <flux:tab.panel name="settings">
        {{-- Settings content --}}
    </flux:tab.panel>
    
    <flux:tab.panel name="billing">
        {{-- Billing content --}}
    </flux:tab.panel>
</flux:tabs>
```

#### Navigation Menu
```blade
<flux:navlist>
    <flux:navlist.item icon="home" href="{{ route('dashboard') }}">
        Dashboard
    </flux:navlist.item>
    <flux:navlist.item icon="users" href="{{ route('users') }}">
        Users
    </flux:navlist.item>
    <flux:navlist.item icon="cog" href="{{ route('settings') }}">
        Settings
    </flux:navlist.item>
</flux:navlist>
```

### Data Display Components

#### Badges
```blade
<flux:badge color="green">Active</flux:badge>
<flux:badge color="red">Inactive</flux:badge>
<flux:badge color="blue">Premium</flux:badge>
<flux:badge variant="outline" color="gray">Draft</flux:badge>
```

#### Avatars
```blade
{{-- Image avatar --}}
<flux:avatar src="{{ $user->avatar_url }}" alt="{{ $user->name }}" />

{{-- Initials avatar --}}
<flux:avatar>
    {{ substr($user->name, 0, 2) }}
</flux:avatar>

{{-- Different sizes --}}
<flux:avatar size="sm" src="{{ $user->avatar_url }}" />
<flux:avatar size="lg" src="{{ $user->avatar_url }}" />
```

#### Progress Indicators
```blade
{{-- Progress bar --}}
<flux:progress value="{{ $progress }}" max="100" />

{{-- Loading spinner --}}
<flux:spinner />

{{-- Loading spinner with text --}}
<div class="flex items-center space-x-2">
    <flux:spinner size="sm" />
    <span>Loading...</span>
</div>
```

## Livewire Volt Integration Patterns

### Volt Functional Component with FluxUI
```blade
<?php
use function Livewire\Volt\{state, rules};
use App\Models\User;

state([
    'name' => '',
    'email' => '',
    'password' => '',
    'is_active' => true,
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
        'is_active' => $this->is_active,
    ]);
    
    session()->flash('success', 'User created successfully!');
    $this->reset();
};
?>

<div>
    <flux:card>
        <flux:card.header>
            <flux:heading size="lg">Create New User</flux:heading>
        </flux:card.header>
        
        <flux:card.body class="space-y-6">
            <flux:field>
                <flux:label>Full Name</flux:label>
                <flux:input wire:model="name" placeholder="John Doe" />
                <flux:error name="name" />
            </flux:field>
            
            <flux:field>
                <flux:label>Email Address</flux:label>
                <flux:input wire:model="email" type="email" placeholder="john@example.com" />
                <flux:error name="email" />
            </flux:field>
            
            <flux:field>
                <flux:label>Password</flux:label>
                <flux:input wire:model="password" type="password" />
                <flux:error name="password" />
            </flux:field>
            
            <flux:checkbox wire:model="is_active">
                Active User
            </flux:checkbox>
        </flux:card.body>
        
        <flux:card.footer>
            <flux:button variant="primary" wire:click="save" wire:loading.attr="disabled">
                <span wire:loading.remove>Create User</span>
                <span wire:loading>Creating...</span>
            </flux:button>
        </flux:card.footer>
    </flux:card>
</div>
```

### Volt Data Table Component
```blade
<?php
use function Livewire\Volt\{state, computed};
use App\Models\User;

state([
    'search' => '',
    'sortField' => 'created_at',
    'sortDirection' => 'desc',
    'selectedUsers' => [],
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

$deleteSelected = function () {
    User::whereIn('id', $this->selectedUsers)->delete();
    $this->selectedUsers = [];
    session()->flash('success', 'Selected users deleted successfully!');
};
?>

<div>
    <div class="mb-4 flex justify-between items-center">
        <flux:input 
            wire:model.live.debounce.300ms="search" 
            placeholder="Search users..."
            class="max-w-md"
        />
        
        @if(count($selectedUsers) > 0)
            <flux:button 
                variant="danger" 
                wire:click="deleteSelected"
                wire:confirm="Are you sure you want to delete the selected users?"
            >
                Delete Selected ({{ count($selectedUsers) }})
            </flux:button>
        @endif
    </div>

    <flux:table>
        <flux:columns>
            <flux:column>
                <flux:checkbox wire:model="selectAll" />
            </flux:column>
            <flux:column sortable wire:click="sortBy('name')">
                Name
                @if($sortField === 'name')
                    <span class="ml-1">{{ $sortDirection === 'asc' ? '↑' : '↓' }}</span>
                @endif
            </flux:column>
            <flux:column sortable wire:click="sortBy('email')">Email</flux:column>
            <flux:column>Status</flux:column>
            <flux:column>Actions</flux:column>
        </flux:columns>
        
        <flux:rows>
            @foreach($this->users as $user)
                <flux:row wire:key="{{ $user->id }}">
                    <flux:cell>
                        <flux:checkbox wire:model="selectedUsers" value="{{ $user->id }}" />
                    </flux:cell>
                    <flux:cell>{{ $user->name }}</flux:cell>
                    <flux:cell>{{ $user->email }}</flux:cell>
                    <flux:cell>
                        <flux:badge color="{{ $user->is_active ? 'green' : 'red' }}">
                            {{ $user->is_active ? 'Active' : 'Inactive' }}
                        </flux:badge>
                    </flux:cell>
                    <flux:cell>
                        <flux:button size="sm" wire:click="editUser({{ $user->id }})">
                            Edit
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

## FluxUI Best Practices

### 1. Consistent Component Usage
Always use FluxUI components instead of building custom HTML/CSS:

```blade
{{-- ✅ Good: Use FluxUI button --}}
<flux:button variant="primary">Save</flux:button>

{{-- ❌ Avoid: Custom button --}}
<button class="bg-blue-500 text-white px-4 py-2 rounded">Save</button>
```

### 2. Proper Form Structure
```blade
{{-- ✅ Good: Proper form structure --}}
<form wire:submit="save">
    <flux:field>
        <flux:label>Name</flux:label>
        <flux:input wire:model="name" />
        <flux:error name="name" />
        <flux:description>Enter your full name</flux:description>
    </flux:field>
    
    <flux:button type="submit">Save</flux:button>
</form>
```

### 3. Accessibility
FluxUI components come with built-in accessibility features:
- Proper ARIA labels
- Keyboard navigation
- Screen reader support
- Focus management

### 4. Customization
When you need to customize FluxUI components:

```blade
{{-- Use Tailwind classes to extend styling --}}
<flux:button class="w-full" variant="primary">
    Full Width Button
</flux:button>

{{-- Use slots for complex content --}}
<flux:card>
    <x-slot name="header">
        <div class="flex justify-between items-center">
            <flux:heading>Custom Header</flux:heading>
            <flux:button size="sm">Action</flux:button>
        </div>
    </x-slot>
    
    <p>Card content here</p>
</flux:card>
```

### 5. Theme Configuration
FluxUI allows theme customization through configuration:

```php
// config/flux.php
return [
    'theme' => [
        'colors' => [
            'primary' => 'blue',
            'secondary' => 'gray',
            'success' => 'green',
            'warning' => 'yellow',
            'danger' => 'red',
        ],
        'radius' => 'md', // sm, md, lg, xl
        'scale' => 'md',  // sm, md, lg
    ],
];
```

## Integration with Laravel 12

FluxUI works seamlessly with Laravel 12 features:

### Form Requests with FluxUI
```php
class CreateProductRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'price' => ['required', 'numeric', 'min:0'],
            'category_id' => ['required', 'exists:categories,id'],
        ];
    }
}
```

```blade
<flux:field>
    <flux:label>Product Name</flux:label>
    <flux:input wire:model="form.name" />
    <flux:error name="form.name" />
</flux:field>
```

### Model Attributes with FluxUI
```php
class Product extends Model
{
    protected function formattedPrice(): Attribute
    {
        return Attribute::make(
            get: fn () => '$' . number_format($this->price, 2)
        );
    }
}
```

```blade
<flux:cell>{{ $product->formatted_price }}</flux:cell>
```

FluxUI eliminates the need for custom component development while providing a consistent, professional look across your Laravel 12 application.
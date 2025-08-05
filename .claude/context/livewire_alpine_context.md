# Livewire & Alpine.js Integration Guidelines

## Livewire Best Practices

### Component Structure using Laravel Volt
```php
<?php

namespace App\Livewire;

use Livewire\Component;
use Livewire\WithPagination;
use Livewire\Attributes\Validate;
use Livewire\Attributes\Url;
use Livewire\Attributes\Computed;

class CustomerList extends Component
{
    use WithPagination;

    #[Validate('required|string|min:2')]
    #[Url]
    public string $search = '';

    #[Validate('in:active,inactive,all')]
    public string $filter = 'active';

    public int $perPage = 10;

    public function updatedSearch(): void
    {
        $this->resetPage();
    }

    public function updatedFilter(): void
    {
        $this->resetPage();
    }

    public function render()
    {
        return view('livewire.customer-list');
    }

    #[Computed]
    public function customers()
    {
        return Customer::query()
            ->when($this->search, fn($query) => $query->search($this->search))
            ->when($this->filter !== 'all', fn($query) => $query->where('status', $this->filter))
            ->paginate($this->perPage);
    }
}
```

### Form Components
```php
<?php

namespace App\Livewire\Forms;

use Livewire\Form;
use Livewire\Attributes\Validate;
use App\Models\Customer;

class CustomerForm extends Form
{
    #[Validate('required|string|max:255')]
    public string $name = '';

    #[Validate('required|email|unique:customers,email')]
    public string $email = '';

    #[Validate('nullable|string|max:20')]
    public string $phone = '';

    #[Validate('required|in:active,inactive')]
    public string $status = 'active';

    public function store(): Customer
    {
        $this->validate();

        return Customer::create($this->all());
    }

    public function update(Customer $customer): bool
    {
        $this->validate();

        return $customer->update($this->all());
    }

    public function setCustomer(Customer $customer): void
    {
        $this->name = $customer->name;
        $this->email = $customer->email;
        $this->phone = $customer->phone;
        $this->status = $customer->status;
    }
}
```

### Real-time Features
```php
class OrderStatus extends Component
{
    public Order $order;

    protected $listeners = ['orderUpdated' => 'refreshOrder'];

    public function mount(Order $order): void
    {
        $this->order = $order;
    }

    public function refreshOrder(): void
    {
        $this->order->refresh();
    }

    public function updateStatus(string $status): void
    {
        $this->order->update(['status' => $status]);
        
        $this->dispatch('orderUpdated', orderId: $this->order->id);
    }

    public function render()
    {
        return view('livewire.order-status');
    }
}
```

## Alpine.js Integration

### Basic Alpine Patterns
```html
<!-- Modal Component -->
<div x-data="{ open: false }">
    <button @click="open = true" class="btn btn-primary">
        Open Modal
    </button>
    
    <div x-show="open" 
         x-transition
         @click.away="open = false"
         class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center">
        <div class="bg-white p-6 rounded-lg max-w-md w-full">
            <h2 class="text-xl font-bold mb-4">Modal Title</h2>
            <p class="mb-4">Modal content goes here.</p>
            <button @click="open = false" class="btn btn-secondary">
                Close
            </button>
        </div>
    </div>
</div>
```

### Form Enhancements
```html
<!-- Enhanced Form with Alpine -->
<form wire:submit="save" x-data="customerForm()">
    <div class="mb-4">
        <label for="name" class="block text-sm font-medium text-gray-700">Name</label>
        <input 
            type="text" 
            id="name" 
            wire:model="form.name"
            x-model="form.name"
            @input="validateField('name')"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
            :class="{ 'border-red-500': errors.name }"
        >
        @error('form.name') 
            <p class="mt-1 text-sm text-red-600">{{ $message }}</p> 
        @enderror
    </div>

    <div class="mb-4">
        <label for="email" class="block text-sm font-medium text-gray-700">Email</label>
        <input 
            type="email" 
            id="email" 
            wire:model="form.email"
            x-model="form.email"
            @input="validateField('email')"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
            :class="{ 'border-red-500': errors.email }"
        >
        @error('form.email') 
            <p class="mt-1 text-sm text-red-600">{{ $message }}</p> 
        @enderror
    </div>

    <button 
        type="submit" 
        wire:loading.attr="disabled"
        :disabled="!isValid"
        class="btn btn-primary"
        :class="{ 'opacity-50 cursor-not-allowed': !isValid }"
    >
        <span wire:loading.remove>Save Customer</span>
        <span wire:loading>Saving...</span>
    </button>
</form>

<script>
function customerForm() {
    return {
        form: {
            name: '',
            email: ''
        },
        errors: {},
        
        validateField(field) {
            // Client-side validation
            switch(field) {
                case 'name':
                    this.errors.name = this.form.name.length < 2 ? 'Name must be at least 2 characters' : null;
                    break;
                case 'email':
                    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                    this.errors.email = !emailRegex.test(this.form.email) ? 'Invalid email format' : null;
                    break;
            }
        },
        
        get isValid() {
            return this.form.name.length >= 2 && 
                   this.form.email.length > 0 && 
                   !this.errors.name && 
                   !this.errors.email;
        }
    }
}
</script>
```

### Data Tables with Sorting
```html
<div x-data="dataTable()" wire:ignore>
    <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
            <tr>
                <th @click="sort('name')" class="cursor-pointer px-6 py-3 text-left">
                    <span class="flex items-center">
                        Name
                        <span x-show="sortField === 'name'" class="ml-1">
                            <span x-show="sortDirection === 'asc'">↑</span>
                            <span x-show="sortDirection === 'desc'">↓</span>
                        </span>
                    </span>
                </th>
                <th @click="sort('email')" class="cursor-pointer px-6 py-3 text-left">
                    <span class="flex items-center">
                        Email
                        <span x-show="sortField === 'email'" class="ml-1">
                            <span x-show="sortDirection === 'asc'">↑</span>
                            <span x-show="sortDirection === 'desc'">↓</span>
                        </span>
                    </span>
                </th>
            </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
            <template x-for="customer in sortedData" :key="customer.id">
                <tr>
                    <td class="px-6 py-4 whitespace-nowrap" x-text="customer.name"></td>
                    <td class="px-6 py-4 whitespace-nowrap" x-text="customer.email"></td>
                </tr>
            </template>
        </tbody>
    </table>
</div>

<script>
function dataTable() {
    return {
        data: @json($customers),
        sortField: 'name',
        sortDirection: 'asc',
        
        sort(field) {
            if (this.sortField === field) {
                this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
            } else {
                this.sortField = field;
                this.sortDirection = 'asc';
            }
        },
        
        get sortedData() {
            return [...this.data].sort((a, b) => {
                let aVal = a[this.sortField];
                let bVal = b[this.sortField];
                
                if (this.sortDirection === 'desc') {
                    return bVal.localeCompare(aVal);
                }
                return aVal.localeCompare(bVal);
            });
        }
    }
}
</script>
```

## Livewire + Alpine Patterns

### Dynamic Forms
```html
<div x-data="dynamicForm()" wire:ignore>
    <div class="mb-4">
        <button @click="addField()" class="btn btn-secondary">
            Add Field
        </button>
    </div>
    
    <template x-for="(field, index) in fields" :key="field.id">
        <div class="mb-4 p-4 border rounded">
            <div class="flex justify-between items-center mb-2">
                <h4 class="font-medium" x-text="`Field ${index + 1}`"></h4>
                <button @click="removeField(index)" class="text-red-600 hover:text-red-800">
                    Remove
                </button>
            </div>
            
            <div class="grid grid-cols-2 gap-4">
                <input 
                    x-model="field.name"
                    placeholder="Field Name"
                    class="form-input"
                >
                <select x-model="field.type" class="form-select">
                    <option value="text">Text</option>
                    <option value="email">Email</option>
                    <option value="number">Number</option>
                </select>
            </div>
        </div>
    </template>
    
    <button @click="saveFields()" class="btn btn-primary">
        Save Form
    </button>
</div>

<script>
function dynamicForm() {
    return {
        fields: [],
        nextId: 1,
        
        addField() {
            this.fields.push({
                id: this.nextId++,
                name: '',
                type: 'text'
            });
        },
        
        removeField(index) {
            this.fields.splice(index, 1);
        },
        
        saveFields() {
            Livewire.dispatch('saveFormFields', { fields: this.fields });
        }
    }
}
</script>
```

### File Upload with Progress
```html
<div x-data="fileUpload()" wire:ignore>
    <div class="mb-4">
        <input 
            type="file" 
            @change="handleFiles($event)" 
            multiple 
            accept="image/*"
            class="form-input"
        >
    </div>
    
    <div x-show="files.length > 0" class="space-y-2">
        <template x-for="file in files" :key="file.id">
            <div class="flex items-center space-x-2 p-2 bg-gray-50 rounded">
                <span x-text="file.name" class="flex-1"></span>
                <div class="w-32 bg-gray-200 rounded-full h-2">
                    <div 
                        class="bg-blue-600 h-2 rounded-full transition-all duration-300"
                        :style="`width: ${file.progress}%`"
                    ></div>
                </div>
                <span x-text="`${file.progress}%`" class="text-sm text-gray-600"></span>
            </div>
        </template>
    </div>
</div>

<script>
function fileUpload() {
    return {
        files: [],
        
        handleFiles(event) {
            Array.from(event.target.files).forEach(file => {
                const fileObj = {
                    id: Date.now() + Math.random(),
                    name: file.name,
                    progress: 0,
                    file: file
                };
                
                this.files.push(fileObj);
                this.uploadFile(fileObj);
            });
        },
        
        uploadFile(fileObj) {
            const formData = new FormData();
            formData.append('file', fileObj.file);
            
            fetch('/upload', {
                method: 'POST',
                body: formData,
                headers: {
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
                }
            })
            .then(response => response.json())
            .then(data => {
                fileObj.progress = 100;
                Livewire.dispatch('fileUploaded', { fileId: data.id });
            });
        }
    }
}
</script>
```

## Performance Optimization

### Lazy Loading
```php
class LazyDataTable extends Component
{
    public bool $loadData = false;

    public function loadData(): void
    {
        $this->loadData = true;
    }

    public function render()
    {
        return view('livewire.lazy-data-table', [
            'customers' => $this->loadData ? Customer::paginate(10) : collect(),
        ]);
    }
}
```

```html
<div>
    @if(!$loadData)
        <button wire:click="loadData" class="btn btn-primary">
            Load Data
        </button>
    @else
        <div wire:loading.remove>
            @foreach($customers as $customer)
                <!-- Customer data -->
            @endforeach
        </div>
        <div wire:loading>
            Loading...
        </div>
    @endif
</div>
```

### Debounced Search
```html
<input 
    type="text" 
    wire:model.live.debounce.300ms="search"
    placeholder="Search customers..."
    class="form-input"
>
```

### Alpine Store for Global State
```html
<script>
document.addEventListener('alpine:init', () => {
    Alpine.store('notifications', {
        items: [],
        
        add(notification) {
            this.items.push({
                id: Date.now(),
                ...notification
            });
            
            setTimeout(() => this.remove(notification.id), 5000);
        },
        
        remove(id) {
            this.items = this.items.filter(item => item.id !== id);
        }
    });
});
</script>

<!-- Notification Component -->
<div x-data x-show="$store.notifications.items.length > 0" class="fixed top-4 right-4 space-y-2">
    <template x-for="notification in $store.notifications.items" :key="notification.id">
        <div 
            x-show="true"
            x-transition
            class="bg-green-500 text-white p-4 rounded shadow"
            x-text="notification.message"
        ></div>
    </template>
</div>
```
# Laravel 12 Development Guidelines

## Core Laravel 12 Features

### New Attribute Class for Accessors/Mutators
Laravel 12 introduces the `Attribute` class for cleaner accessor and mutator definitions:

```php
use Illuminate\Database\Eloquent\Casts\Attribute;

class User extends Model
{
    // NEW Laravel 12 way - using Attribute class
    protected function firstName(): Attribute
    {
        return Attribute::make(
            get: fn (string $value) => ucfirst($value),
            set: fn (string $value) => strtolower($value),
        );
    }
    
    // Multiple accessors can be combined
    protected function fullName(): Attribute
    {
        return Attribute::make(
            get: fn (mixed $value, array $attributes) => 
                $attributes['first_name'] . ' ' . $attributes['last_name']
        );
    }
    
    // For computed properties
    protected function isAdmin(): Attribute
    {
        return Attribute::make(
            get: fn () => $this->role === 'admin',
        );
    }
}
```

### Application Bootstrap Patterns

Laravel 12 introduces a streamlined Application class in `bootstrap/app.php` for registering middleware, events, and other application concerns:

#### Modern Application Configuration
```php
<?php
// bootstrap/app.php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        // Register global middleware
        $middleware->append([
            \App\Http\Middleware\TrustProxies::class,
            \App\Http\Middleware\HandleCors::class,
        ]);
        
        // Register middleware groups
        $middleware->group('web', [
            \App\Http\Middleware\EncryptCookies::class,
            \Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse::class,
            \Illuminate\Session\Middleware\StartSession::class,
            \Illuminate\View\Middleware\ShareErrorsFromSession::class,
            \App\Http\Middleware\VerifyCsrfToken::class,
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ]);
        
        $middleware->group('api', [
            \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
            'throttle:api',
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ]);
        
        // Register route middleware aliases
        $middleware->alias([
            'auth' => \App\Http\Middleware\Authenticate::class,
            'auth.basic' => \Illuminate\Auth\Middleware\AuthenticateWithBasicAuth::class,
            'cache.headers' => \Illuminate\Http\Middleware\SetCacheHeaders::class,
            'can' => \Illuminate\Auth\Middleware\Authorize::class,
            'guest' => \App\Http\Middleware\RedirectIfAuthenticated::class,
            'signed' => \Illuminate\Routing\Middleware\ValidateSignature::class,
            'throttle' => \Illuminate\Routing\Middleware\ThrottleRequests::class,
            'verified' => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
        ]);
        
        // Conditional middleware registration
        if (app()->environment('local')) {
            $middleware->append(\App\Http\Middleware\DebugMiddleware::class);
        }
    })
    ->withEvents(discover: [
        __DIR__.'/../app/Listeners',
    ])
    ->withExceptions(function (Exceptions $exceptions) {
        // Custom exception handling
        $exceptions->render(function (ValidationException $e, Request $request) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422);
        });
    })
    ->create();
```

#### Event Discovery Configuration
```php
// In bootstrap/app.php
->withEvents(discover: [
    __DIR__.'/../app/Listeners',
    __DIR__.'/../app/Observers',
])

// Or manual event registration
use App\Events\{UserCreated, OrderProcessed};
use App\Listeners\{SendWelcomeEmail, UpdateInventory};

->withEvents(function () {
    Event::listen(UserCreated::class, SendWelcomeEmail::class);
    Event::listen(OrderProcessed::class, UpdateInventory::class);
})
```

### Model Query Scoping with #[Scope] Attribute

Laravel 12 introduces the `#[Scope]` attribute for cleaner query scope definitions:

#### Traditional Scope (Still Valid)
```php
class User extends Model
{
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
    
    public function scopeByRole($query, string $role)
    {
        return $query->where('role', $role);
    }
}
```

#### New #[Scope] Attribute (Preferred)
```php
use Illuminate\Database\Eloquent\Attributes\Scope;

class User extends Model
{
    #[Scope]
    public function active($query)
    {
        return $query->where('is_active', true);
    }
    
    #[Scope]
    public function byRole($query, string $role)
    {
        return $query->where('role', $role);
    }
    
    #[Scope]
    public function recentlyCreated($query, int $days = 30)
    {
        return $query->where('created_at', '>=', now()->subDays($days));
    }
    
    #[Scope]
    public function withMinimumPurchases($query, int $minimum = 1)
    {
        return $query->has('purchases', '>=', $minimum);
    }
}

// Usage remains the same
$activeUsers = User::active()->get();
$admins = User::byRole('admin')->get();
$recentUsers = User::recentlyCreated(7)->get();
```

#### Complex Scopes with #[Scope]
```php
class Product extends Model
{
    #[Scope]
    public function available($query)
    {
        return $query->where('is_active', true)
                    ->where('stock', '>', 0)
                    ->whereNotNull('published_at')
                    ->where('published_at', '<=', now());
    }
    
    #[Scope]
    public function inPriceRange($query, float $min, float $max)
    {
        return $query->whereBetween('price', [$min, $max]);
    }
    
    #[Scope]
    public function withCategory($query, string $categorySlug)
    {
        return $query->whereHas('category', function ($q) use ($categorySlug) {
            $q->where('slug', $categorySlug);
        });
    }
    
    #[Scope]
    public function featured($query, bool $featured = true)
    {
        return $query->where('is_featured', $featured);
    }
}

// Usage examples
$products = Product::available()
    ->inPriceRange(10.00, 100.00)
    ->withCategory('electronics')
    ->featured()
    ->get();
```

#### Global Scopes with #[Scope]
```php
use Illuminate\Database\Eloquent\Attributes\Scope;

class Post extends Model
{
    // Global scope applied automatically to all queries
    #[Scope('global')]
    public function published($query)
    {
        return $query->whereNotNull('published_at')
                    ->where('published_at', '<=', now());
    }
    
    // Regular scope
    #[Scope]
    public function byAuthor($query, User $author)
    {
        return $query->where('author_id', $author->id);
    }
}

// All Post queries automatically include the published scope
$posts = Post::all(); // Only published posts
$authorPosts = Post::byAuthor($user)->get(); // Only published posts by author

// To remove global scope
$allPosts = Post::withoutGlobalScope('published')->get();
```

#### New Validation Methods
```php
class CreateUserRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'email' => ['required', 'email', 'unique:users'],
            'password' => ['required', 'min:8', 'confirmed'],
            'age' => ['required', 'integer', 'between:18,120'],
            'preferences' => ['array'],
            'preferences.*' => ['string', 'in:email,sms,push'],
        ];
    }
    
    // Laravel 12 enhanced validation messages
    public function messages(): array
    {
        return [
            'preferences.*.in' => 'Each preference must be one of: email, sms, push',
        ];
    }
}
```

### Enhanced Relationships
```php
class Post extends Model
{
    // Enhanced relationship with better type hinting
    public function comments(): HasMany
    {
        return $this->hasMany(Comment::class)
            ->where('is_approved', true)
            ->orderBy('created_at', 'desc');
    }
    
    // New polymorphic relationship features
    public function tags(): MorphToMany
    {
        return $this->morphToMany(Tag::class, 'taggable')
            ->withTimestamps()
            ->withPivot(['order', 'metadata']);
    }
    
    // Relationship with custom attributes
    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'author_id')
            ->select(['id', 'name', 'email', 'avatar_url']);
    }
}
```

### Modern Controller Patterns
```php
class ProductController extends Controller
{
    public function __construct(
        private readonly ProductService $productService,
        private readonly CacheManager $cache,
    ) {}
    
    public function index(Request $request): JsonResponse|View
    {
        $products = $this->productService->paginate(
            filters: $request->validated(),
            perPage: $request->integer('per_page', 15)
        );
        
        return $request->wantsJson() 
            ? response()->json($products)
            : view('products.index', compact('products'));
    }
    
    public function store(CreateProductRequest $request): RedirectResponse
    {
        $product = $this->productService->create($request->validated());
        
        return redirect()
            ->route('products.show', $product)
            ->with('success', 'Product created successfully!');
    }
}
```

### Advanced Query Builder Features
```php
class ProductService
{
    public function search(array $filters): Collection
    {
        return Product::query()
            ->when($filters['search'] ?? null, fn ($query, $search) =>
                $query->where('name', 'like', "%{$search}%")
                      ->orWhere('description', 'like', "%{$search}%")
            )
            ->when($filters['category'] ?? null, fn ($query, $category) =>
                $query->where('category_id', $category)
            )
            ->when($filters['price_range'] ?? null, fn ($query, $range) =>
                $query->whereBetween('price', $range)
            )
            ->with(['category', 'tags'])
            ->orderBy('created_at', 'desc')
            ->get();
    }
}
```

## Laravel 12 Testing Best Practices

### Pest PHP Integration
```php
use function Pest\Laravel\{get, post, assertDatabaseHas};

it('can create a product', function () {
    $productData = [
        'name' => 'Test Product',
        'price' => 99.99,
        'category_id' => Category::factory()->create()->id,
    ];
    
    post(route('products.store'), $productData)
        ->assertRedirect()
        ->assertSessionHas('success');
        
    assertDatabaseHas('products', [
        'name' => 'Test Product',
        'price' => 99.99,
    ]);
});

it('validates required fields', function () {
    post(route('products.store'), [])
        ->assertSessionHasErrors(['name', 'price', 'category_id']);
});
```

### Feature Testing with Laravel 12
```php
class ProductTest extends TestCase
{
    use RefreshDatabase;
    
    public function test_user_can_view_product_list(): void
    {
        Product::factory()->count(5)->create();
        
        $response = $this->get('/products');
        
        $response->assertStatus(200)
                ->assertViewIs('products.index')
                ->assertViewHas('products');
    }
    
    public function test_authenticated_user_can_create_product(): void
    {
        $user = User::factory()->create();
        $category = Category::factory()->create();
        
        $this->actingAs($user)
            ->post('/products', [
                'name' => 'New Product',
                'price' => 149.99,
                'category_id' => $category->id,
            ])
            ->assertRedirect()
            ->assertSessionHas('success');
            
        $this->assertDatabaseHas('products', [
            'name' => 'New Product',
            'price' => 149.99,
        ]);
    }
}
```

## Database and Migration Patterns

### Laravel 12 Migration Features
```php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('name')->index();
            $table->text('description')->nullable();
            $table->decimal('price', 10, 2);
            $table->foreignId('category_id')
                  ->constrained()
                  ->onDelete('cascade');
            $table->json('metadata')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
            
            // Laravel 12 enhanced indexing
            $table->index(['is_active', 'published_at']);
            $table->fullText(['name', 'description']);
        });
    }
    
    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
```

### Factory Patterns
```php
class ProductFactory extends Factory
{
    protected $model = Product::class;
    
    public function definition(): array
    {
        return [
            'name' => fake()->productName(),
            'description' => fake()->paragraph(),
            'price' => fake()->randomFloat(2, 10, 1000),
            'category_id' => Category::factory(),
            'is_active' => fake()->boolean(80),
            'metadata' => [
                'weight' => fake()->randomFloat(2, 0.1, 50),
                'dimensions' => [
                    'length' => fake()->numberBetween(1, 100),
                    'width' => fake()->numberBetween(1, 100),
                    'height' => fake()->numberBetween(1, 100),
                ],
            ],
            'published_at' => fake()->optional()->dateTimeBetween('-1 year'),
        ];
    }
    
    public function inactive(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_active' => false,
            'published_at' => null,
        ]);
    }
    
    public function expensive(): static
    {
        return $this->state(fn (array $attributes) => [
            'price' => fake()->randomFloat(2, 500, 5000),
        ]);
    }
}
```

## Livewire Volt Integration

Laravel 12 works seamlessly with Livewire Volt for functional components. Prefer Volt functional components over traditional class-based components:

### Volt Functional Component (Preferred)
```blade
<?php
use function Livewire\Volt\{state, rules, computed};
use App\Models\Product;

state([
    'name' => '',
    'price' => 0,
    'category_id' => null,
]);

rules([
    'name' => 'required|string|max:255',
    'price' => 'required|numeric|min:0',
    'category_id' => 'required|exists:categories,id',
]);

$categories = computed(fn () => Category::all());

$save = function () {
    $this->validate();
    
    Product::create([
        'name' => $this->name,
        'price' => $this->price,
        'category_id' => $this->category_id,
    ]);
    
    session()->flash('success', 'Product created!');
    $this->reset();
};
?>

<div>
    <!-- FluxUI components here -->
</div>
```

### Traditional Class Component (When Volt isn't suitable)
```php
<?php

namespace App\Livewire;

use Livewire\Component;
use App\Services\ComplexReportService;

class ComplexReportDashboard extends Component
{
    public function __construct(
        private readonly ComplexReportService $reportService
    ) {}

    // Use class components for complex business logic
    // that spans multiple methods or requires DI
}
```

### Repository Pattern (Optional)
```php
interface ProductRepositoryInterface
{
    public function find(int $id): ?Product;
    public function create(array $data): Product;
    public function update(Product $product, array $data): Product;
    public function delete(Product $product): bool;
    public function paginate(array $filters = [], int $perPage = 15): LengthAwarePaginator;
}

class ProductRepository implements ProductRepositoryInterface
{
    public function find(int $id): ?Product
    {
        return Product::with(['category', 'tags'])->find($id);
    }
    
    public function create(array $data): Product
    {
        return Product::create($data);
    }
    
    public function paginate(array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        return Product::query()
            ->filter($filters)
            ->with(['category', 'tags'])
            ->latest()
            ->paginate($perPage);
    }
}
```

## Laravel 12 Configuration Patterns

### Modern Config Structure
```php
// config/app.php
return [
    'name' => env('APP_NAME', 'Laravel'),
    'env' => env('APP_ENV', 'production'),
    'debug' => (bool) env('APP_DEBUG', false),
    'url' => env('APP_URL', 'http://localhost'),
    
    // Laravel 12 enhanced timezone handling
    'timezone' => env('APP_TIMEZONE', 'UTC'),
    'locale' => env('APP_LOCALE', 'en'),
    'fallback_locale' => env('APP_FALLBACK_LOCALE', 'en'),
    
    // Enhanced security settings
    'cipher' => 'AES-256-CBC',
    'key' => env('APP_KEY'),
    'previous_keys' => [
        ...array_filter(
            explode(',', env('APP_PREVIOUS_KEYS', ''))
        ),
    ],
];
```

### Service Provider Patterns
```php
class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Bind services
        $this->app->bind(
            ProductRepositoryInterface::class,
            ProductRepository::class
        );
        
        // Conditional service binding
        if ($this->app->environment('local')) {
            $this->app->register(TelescopeServiceProvider::class);
        }
    }
    
    public function boot(): void
    {
        // Global query scopes
        Product::addGlobalScope('active', function ($query) {
            $query->where('is_active', true);
        });
        
        // Model observers
        Product::observe(ProductObserver::class);
        
        // Custom validation rules
        Validator::extend('slug', function ($attribute, $value, $parameters, $validator) {
            return preg_match('/^[a-z0-9-]+$/', $value);
        });
    }
}
```

## Best Practices Summary

1. **Use the new Attribute class** for all accessors and mutators
2. **Use the #[Scope] attribute** for query scopes instead of traditional scope methods
3. **Configure application concerns** in bootstrap/app.php using the Application class
4. **Leverage typed properties** throughout your application
5. **Implement proper service layers** for complex business logic
6. **Use Pest PHP** for more readable tests
7. **Follow PSR-12** coding standards strictly
8. **Use constructor property promotion** where appropriate
9. **Register middleware and events** through the Application class configuration
10. **Implement proper error handling** with try-catch blocks
11. **Use Laravel's built-in features** before creating custom solutions
12. **Write comprehensive tests** for all functionality
13. **Follow SOLID principles** in your class design
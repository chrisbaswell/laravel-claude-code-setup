APP_NAME="Laravel 12"
APP_ENV=local
APP_KEY=base64:fqs5xKZDFOi8NOtKNqVx1QrsoAWvg9KvTSIUB6NZDXI=
APP_DEBUG=true
APP_URL=https://laravel.test

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here
GOOGLE_REDIRECT_URI=https://laravel.test/auth/google/callback

# Allowed email domains for automatic registration
ALLOWED_REGISTRATION_DOMAINS=southernshirt.com

APP_LOCALE=en
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=en_US

APP_MAINTENANCE_DRIVER=file
# APP_MAINTENANCE_STORE=database

PHP_CLI_SERVER_WORKERS=4

BCRYPT_ROUNDS=12

LOG_CHANNEL=stack
LOG_STACK=single
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ssco_pm
DB_USERNAME=root
DB_PASSWORD=

SESSION_DRIVER=database
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
SESSION_PATH=/
SESSION_DOMAIN=null

BROADCAST_CONNECTION=log
FILESYSTEM_DISK=s3
QUEUE_CONNECTION=database

CACHE_STORE=database
# CACHE_PREFIX=

MEMCACHED_HOST=127.0.0.1

REDIS_CLIENT=phpredis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_SCHEME=null
MAIL_HOST=127.0.0.1
MAIL_PORT=2525
MAIL_USERNAME="Ssco Pm"
MAIL_PASSWORD=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"

VITE_APP_NAME="${APP_NAME}"

TRANSLOADIT_AUTH_KEY=your_transloadit_auth_key_here
TRANSLOADIT_AUTH_SECRET=your_transloadit_auth_secret_here
TRANSLOADIT_TEMPLATE_DOCUMENT_TO_PNG=your_transloadit_template_document_to_png_here
TRANSLOADIT_AWS_CREDENTIALS=your_transloadit_aws_credentials_here

AWS_ACCESS_KEY_ID=your_aws_access_key_id_here
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key_here
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=your_aws_bucket_here
AWS_USE_PATH_STYLE_ENDPOINT=false

# NetSuite Configuration
NETSUITE_BASE_URL=https://your-account.suitetalk.api.netsuite.com
NETSUITE_CONSUMER_KEY=your_consumer_key_here
NETSUITE_CONSUMER_SECRET=your_consumer_secret_here
NETSUITE_TOKEN_ID=your_token_id_here
NETSUITE_TOKEN_SECRET=your_token_secret_here
NETSUITE_REALM=your_account_id_here
NETSUITE_TIMEOUT=30
NETSUITE_RETRY_ATTEMPTS=3
NETSUITE_CACHE_TTL=3600

# Optional: Additional database for testing
DB_TEST_CONNECTION=sqlite
DB_TEST_DATABASE=:memory:

# Production Settings
APP_URL=https://your-domain.com

# Queue Configuration (use redis in production)
QUEUE_CONNECTION=redis

# Session Configuration (use redis in production)  
SESSION_DRIVER=redis

# Cache Configuration (use redis in production)
CACHE_STORE=redis

# Broadcasting (for real-time features)
BROADCAST_CONNECTION=redis

# Health Check Configuration (spatie/laravel-health)
HEALTH_FAILURE_NOTIFICATION_MAIL=admin@your-domain.com

# Horizon Configuration (Laravel Horizon for queue monitoring)
HORIZON_DOMAIN=your-domain.com
HORIZON_PREFIX=horizon:

# Sentry Configuration (Error Monitoring)
SENTRY_LARAVEL_DSN=your_sentry_dsn_here
SENTRY_TRACES_SAMPLE_RATE=1.0

# Backup Configuration (spatie/laravel-backup)
BACKUP_ARCHIVE_PASSWORD=your_backup_password_here
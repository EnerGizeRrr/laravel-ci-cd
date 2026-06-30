# Laravel Docker Setup Documentation

## Structure

```
.
├── Dockerfile                 # Multi-stage build (dev, prod)
├── docker-compose.yml        # Services definition
├── .dockerignore             # Build optimization
├── docker/
│   ├── nginx/
│   │   ├── conf.d/
│   │   │   └── default.conf  # Nginx configuration
│   │   └── ssl/              # SSL certificates (optional)
│   ├── php/
│   │   └── conf.d/
│   │       ├── opcache.ini   # Opcache settings
│   │       └── xdebug.ini    # Xdebug settings (dev only)
│   ├── mysql/
│   │   └── my.cnf            # MySQL configuration
│   ├── .env.docker           # Docker environment template
│   └── scripts/
│       ├── migrate.sh        # Run migrations
│       └── shell.sh          # Access app shell
└── docker-setup.sh           # Initial setup script
```

## Services

| Service | Container | Port | Image |
|---------|-----------|------|-------|
| **app** | laravel_app | 9000 | PHP 8.4-FPM Alpine |
| **nginx** | laravel_nginx | 80, 443 | Nginx Alpine |
| **db** | laravel_db | 3306 | MySQL 8.0 |
| **redis** | laravel_redis | 6379 | Redis 7 Alpine |

## Getting Started

### 1. Initial Setup

```bash
# Copy Docker environment file
cp docker/.env.docker .env

# Start services
docker compose up -d

# Install dependencies
docker compose exec app composer install
docker compose exec app npm install

# Build frontend
docker compose exec app npm run build

# Generate app key
docker compose exec app php artisan key:generate

# Run migrations
docker compose exec app php artisan migrate
```

### 2. Quick Start

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f app

# Access the application
# Web: http://localhost
# API: http://localhost/api

# Stop services
docker compose down
```

## Database

### Migrations

Run migrations inside the container:

```bash
# Run migrations
docker compose exec app php artisan migrate

# Rollback
docker compose exec app php artisan migrate:rollback

# Reset database
docker compose exec app php artisan migrate:reset

# Refresh with seed
docker compose exec app php artisan migrate:refresh --seed
```

### MySQL Access

```bash
# Via Docker Compose
docker compose exec db mysql -u laravel_user -p laravel

# Credentials:
# Host: db (localhost:3306 from host)
# User: laravel_user
# Password: laravel_password (set in .env)
# Database: laravel
```

## Redis

### Access Redis CLI

```bash
docker compose exec redis redis-cli

# Common commands
ping
dbsize
flushall
keys *
```

### Redis Connections

The app connects to Redis at `redis:6379` for:
- Cache store
- Session storage
- Queue driver

## Development

### Access Application Shell

```bash
docker compose exec app sh
```

### View Logs

```bash
# App logs
docker compose logs -f app

# Nginx logs
docker compose logs -f nginx

# MySQL logs
docker compose logs -f db

# Redis logs
docker compose logs -f redis

# All services
docker compose logs -f
```

### Run Tests

```bash
docker compose exec app php artisan test
```

### Use Tinker (REPL)

```bash
docker compose exec app php artisan tinker
```

### Xdebug (Development)

The dev stage includes Xdebug configured for remote debugging:

- **Mode**: debug
- **Client Host**: host.docker.internal
- **Client Port**: 9003
- **IDE Key**: laravel

Configure your IDE to listen on port 9003.

## Building Images

### Production Build

```bash
docker compose build --target prod
```

### Development Build

```bash
docker compose build --target dev
```

### Force Rebuild

```bash
docker compose build --no-cache
```

## Health Checks

All services include health checks:

```bash
# View service health
docker compose ps

# Check specific service
docker inspect laravel_app | grep -A 10 "Health"
```

## Volumes

| Volume | Mount | Purpose |
|--------|-------|---------|
| **app-storage** | /app/storage | Logs, sessions, cache |
| **db-storage** | /var/lib/mysql | Database files |
| **redis-storage** | /data | Redis persistence |

## Troubleshooting

### Container won't start

```bash
# View logs
docker compose logs app

# Check health
docker compose ps
```

### Database connection error

```bash
# Verify MySQL is running
docker compose exec db mysqladmin ping -u root -p

# Check connection from app
docker compose exec app php artisan tinker
# In tinker: DB::connection()->getPdo();
```

### Permission issues

```bash
# Fix storage permissions
docker compose exec app chmod -R 775 storage bootstrap/cache
```

### Clear caches

```bash
# All caches
docker compose exec app php artisan cache:clear

# View cache
docker compose exec app php artisan cache:forget

# Optimize
docker compose exec app php artisan optimize
```

## Production Deployment

### Build for Production

```bash
docker build -t myapp:latest --target prod .
```

### Environment Variables

Set in production:
- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_KEY=<generated-key>`
- Database credentials
- Redis credentials (if needed)

### Health Endpoints

- **App**: `GET http://localhost:9000/ping`
- **Web**: `GET http://localhost/up`

## Cleanup

```bash
# Stop all services
docker compose down

# Remove volumes (WARNING: deletes data)
docker compose down -v

# Remove images
docker compose down --rmi all

# System cleanup
docker system prune -a
```

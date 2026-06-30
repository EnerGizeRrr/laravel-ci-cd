#!/usr/bin/env bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Laravel Docker - Run Migrations${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${YELLOW}Running migrations...${NC}"
docker compose exec app php artisan migrate

echo -e "${GREEN}✓ Migrations completed${NC}"

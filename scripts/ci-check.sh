#!/bin/bash

# Local CI simulation - runs the same checks as GitHub Actions

set -e

echo "═══════════════════════════════════════════════════════"
echo "       Local CI Pipeline Simulation"
echo "═══════════════════════════════════════════════════════"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

failed_stages=()

# Stage 1: Lint & Static Analysis
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Stage 1: Lint & Static Analysis${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "1.1) Running PHP Lint (Pint)..."
if docker compose exec -T app ./vendor/bin/pint --test > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PHP Lint passed${NC}"
else
    echo -e "${RED}✗ PHP Lint failed${NC}"
    failed_stages+=("Lint")
fi
echo ""

echo "1.2) Checking PHP Syntax..."
if docker compose exec -T app find app -name "*.php" -exec php -l {} \; > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PHP Syntax check passed${NC}"
else
    echo -e "${RED}✗ PHP Syntax check failed${NC}"
    failed_stages+=("Syntax")
fi
echo ""

echo "1.3) Running PHPStan (Static Analysis)..."
if docker compose exec -T app ./vendor/bin/phpstan analyse > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PHPStan passed${NC}"
else
    echo -e "${YELLOW}⚠ PHPStan issues found (non-blocking)${NC}"
fi
echo ""

# Stage 2: Tests
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Stage 2: Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "2.1) Running database migrations..."
if docker compose exec -T app php artisan migrate --force > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Migrations passed${NC}"
else
    echo -e "${RED}✗ Migrations failed${NC}"
    failed_stages+=("Migrations")
fi
echo ""

echo "2.2) Running tests..."
if docker compose exec -T app php artisan test --without-tty; then
    echo -e "${GREEN}✓ Tests passed${NC}"
else
    echo -e "${RED}✗ Tests failed${NC}"
    failed_stages+=("Tests")
fi
echo ""

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ ${#failed_stages[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "You can now safely push your code:"
    echo "  git push origin main"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some checks failed:${NC}"
    for stage in "${failed_stages[@]}"; do
        echo -e "  ${RED}✗${NC} $stage"
    done
    echo ""
    echo "Please fix these issues before pushing."
    echo ""
    exit 1
fi

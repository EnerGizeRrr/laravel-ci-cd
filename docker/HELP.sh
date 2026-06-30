#!/usr/bin/env bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Docker Compose Help${NC}"
echo -e "${BLUE}========================================${NC}"

echo ""
echo -e "${GREEN}Quick Start Commands:${NC}"
echo ""
echo -e "${YELLOW}1. Start Services:${NC}"
echo -e "   ${BLUE}docker compose up -d${NC}"
echo ""
echo -e "${YELLOW}2. Run Migrations:${NC}"
echo -e "   ${BLUE}docker compose exec app php artisan migrate${NC}"
echo ""
echo -e "${YELLOW}3. Seed Database:${NC}"
echo -e "   ${BLUE}docker compose exec app php artisan db:seed${NC}"
echo ""
echo -e "${YELLOW}4. Build Assets:${NC}"
echo -e "   ${BLUE}docker compose exec app npm run build${NC}"
echo ""
echo -e "${YELLOW}5. Stop Services:${NC}"
echo -e "   ${BLUE}docker compose down${NC}"
echo ""

echo -e "${GREEN}Development Commands:${NC}"
echo ""
echo -e "${YELLOW}View Logs:${NC}"
echo -e "   ${BLUE}docker compose logs -f app${NC}"
echo -e "   ${BLUE}docker compose logs -f nginx${NC}"
echo ""
echo -e "${YELLOW}Application Shell:${NC}"
echo -e "   ${BLUE}docker compose exec app sh${NC}"
echo ""
echo -e "${YELLOW}Run Tests:${NC}"
echo -e "   ${BLUE}docker compose exec app php artisan test${NC}"
echo ""
echo -e "${YELLOW}Tinker (REPL):${NC}"
echo -e "   ${BLUE}docker compose exec app php artisan tinker${NC}"
echo ""
echo -e "${YELLOW}Database Shell:${NC}"
echo -e "   ${BLUE}docker compose exec db mysql -u laravel_user -p laravel${NC}"
echo ""
echo -e "${YELLOW}Redis CLI:${NC}"
echo -e "   ${BLUE}docker compose exec redis redis-cli${NC}"
echo ""

echo -e "${GREEN}Database & Cleanup:${NC}"
echo ""
echo -e "${YELLOW}Reset Database:${NC}"
echo -e "   ${BLUE}docker compose exec app php artisan migrate:reset${NC}"
echo ""
echo -e "${YELLOW}Prune Services:${NC}"
echo -e "   ${BLUE}docker system prune -a${NC}"
echo ""
echo -e "${YELLOW}View Volumes:${NC}"
echo -e "   ${BLUE}docker volume ls${NC}"
echo ""

echo -e "${GREEN}Service Status:${NC}"
echo ""
echo -e "   ${BLUE}docker compose ps${NC}"
echo ""

echo -e "${BLUE}========================================${NC}"

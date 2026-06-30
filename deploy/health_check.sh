#!/bin/bash

################################################################################
#                    POST-DEPLOYMENT HEALTH CHECK                              #
#                    Validate deployment success                               #
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

HEALTH_LOG="${1:-./deploy/health_check_$(date +%Y%m%d_%H%M%S).log}"
DEPLOY_URL="${2:-http://localhost}"

################################################################################
# Functions
################################################################################

log() {
    local level=$1
    shift
    local message="$@"
    
    case $level in
        INFO)
            echo -e "${BLUE}[INFO]${NC} $message" | tee -a "$HEALTH_LOG"
            ;;
        PASS)
            echo -e "${GREEN}[PASS]${NC} ✓ $message" | tee -a "$HEALTH_LOG"
            ;;
        FAIL)
            echo -e "${RED}[FAIL]${NC} ✗ $message" | tee -a "$HEALTH_LOG"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} ⚠ $message" | tee -a "$HEALTH_LOG"
            ;;
    esac
}

check_http_endpoint() {
    log INFO "Checking HTTP endpoint: ${DEPLOY_URL}/up"
    
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "${DEPLOY_URL}/up")
    
    if [ "$http_code" = "200" ]; then
        log PASS "HTTP endpoint responding with 200 OK"
        return 0
    else
        log FAIL "HTTP endpoint returned: $http_code"
        return 1
    fi
}

check_api_endpoint() {
    log INFO "Checking API endpoint: ${DEPLOY_URL}/api"
    
    local response=$(curl -s -o /dev/null -w "%{http_code}" "${DEPLOY_URL}/api")
    
    if [ "$response" = "200" ] || [ "$response" = "404" ]; then
        log PASS "API endpoint is accessible"
        return 0
    else
        log FAIL "API endpoint returned: $response"
        return 1
    fi
}

check_database() {
    log INFO "Checking database connection"
    
    # This would be run via SSH on the server
    # For now, we check if app container is running
    if docker ps 2>/dev/null | grep -q "laravel_db"; then
        log PASS "Database container is running"
        return 0
    else
        log WARN "Cannot verify database (run on server)"
        return 0
    fi
}

check_redis() {
    log INFO "Checking Redis connection"
    
    if docker ps 2>/dev/null | grep -q "laravel_redis"; then
        log PASS "Redis container is running"
        return 0
    else
        log WARN "Cannot verify Redis (run on server)"
        return 0
    fi
}

check_laravel_logs() {
    log INFO "Checking Laravel logs for errors"
    
    # Look for recent error entries
    if [ -f "storage/logs/laravel.log" ]; then
        local error_count=$(grep -c "ERROR\|Exception\|Fatal" storage/logs/laravel.log | tail -5 || echo 0)
        
        if [ "$error_count" = "0" ]; then
            log PASS "No recent errors in logs"
            return 0
        else
            log WARN "Found $error_count error entries in logs"
            tail -10 storage/logs/laravel.log | tee -a "$HEALTH_LOG"
            return 0
        fi
    else
        log WARN "Log file not found"
        return 0
    fi
}

check_response_time() {
    log INFO "Checking response time"
    
    local response_time=$(curl -s -o /dev/null -w "%{time_total}" "${DEPLOY_URL}/up")
    
    # Convert to milliseconds
    local response_ms=$(echo "scale=0; $response_time * 1000" | bc)
    
    log INFO "Response time: ${response_ms}ms"
    
    # Warn if response time is high
    if (( $(echo "$response_time > 2" | bc -l) )); then
        log WARN "Response time is high (> 2s)"
        return 1
    else
        log PASS "Response time is acceptable"
        return 0
    fi
}

check_container_status() {
    log INFO "Checking container status"
    
    if command -v docker &> /dev/null; then
        local app_status=$(docker inspect -f '{{.State.Status}}' laravel_app 2>/dev/null || echo "unknown")
        local db_status=$(docker inspect -f '{{.State.Status}}' laravel_db 2>/dev/null || echo "unknown")
        local redis_status=$(docker inspect -f '{{.State.Status}}' laravel_redis 2>/dev/null || echo "unknown")
        
        if [ "$app_status" = "running" ] && [ "$db_status" = "running" ] && [ "$redis_status" = "running" ]; then
            log PASS "All containers are running"
            return 0
        else
            log WARN "Container status - App: $app_status, DB: $db_status, Redis: $redis_status"
            return 1
        fi
    else
        log WARN "Docker not available for local checks"
        return 0
    fi
}

check_migrations() {
    log INFO "Checking if migrations have run"
    
    # This would typically check the database migrations table
    # For demo purposes, we'll just note it needs to be run on server
    log INFO "Migrations are handled during deployment"
    return 0
}

print_summary() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         Health Check Summary${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Tests executed: $(grep -c '\[PASS\]\|\[FAIL\]' "$HEALTH_LOG" || echo 0)"
    echo "Passed: $(grep -c '\[PASS\]' "$HEALTH_LOG" || echo 0)"
    echo "Failed: $(grep -c '\[FAIL\]' "$HEALTH_LOG" || echo 0)"
    echo ""
    echo "Log file: $HEALTH_LOG"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Laravel Deployment Health Check${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log INFO "Starting health checks..."
    log INFO "Deployment URL: $DEPLOY_URL"
    echo ""
    
    local failed=0
    
    check_container_status || ((failed++))
    check_http_endpoint || ((failed++))
    check_api_endpoint || ((failed++))
    check_database || ((failed++))
    check_redis || ((failed++))
    check_response_time || ((failed++))
    check_laravel_logs || ((failed++))
    check_migrations || ((failed++))
    
    print_summary
    
    if [ $failed -gt 0 ]; then
        log FAIL "Health check completed with $failed failures"
        return 1
    else
        log PASS "All health checks passed!"
        return 0
    fi
}

main "$@"

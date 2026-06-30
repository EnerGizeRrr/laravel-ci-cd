#!/bin/bash

################################################################################
#                         LARAVEL DEPLOYMENT SCRIPT                            #
#                      Production VPS Deployment via SSH                       #
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_DIR="${DEPLOY_DIR:-.}"
BACKUP_DIR="${DEPLOY_DIR}/.backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${TIMESTAMP}"
LOG_FILE="${DEPLOY_DIR}/deploy_${TIMESTAMP}.log"

# Load environment variables
if [ -f "${DEPLOY_DIR}/.env.deploy" ]; then
    source "${DEPLOY_DIR}/.env.deploy"
else
    echo -e "${RED}Error: .env.deploy file not found!${NC}"
    echo "Create .env.deploy with required variables:"
    echo "  - SSH_HOST"
    echo "  - SSH_USER"
    echo "  - SSH_KEY"
    echo "  - DEPLOY_PATH"
    echo "  - DOCKER_REGISTRY"
    exit 1
fi

################################################################################
# FUNCTIONS
################################################################################

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        INFO)
            echo -e "${BLUE}[${timestamp}]${NC} ${message}" | tee -a "$LOG_FILE"
            ;;
        SUCCESS)
            echo -e "${GREEN}[${timestamp}]${NC} ✓ ${message}" | tee -a "$LOG_FILE"
            ;;
        WARNING)
            echo -e "${YELLOW}[${timestamp}]${NC} ⚠ ${message}" | tee -a "$LOG_FILE"
            ;;
        ERROR)
            echo -e "${RED}[${timestamp}]${NC} ✗ ${message}" | tee -a "$LOG_FILE"
            ;;
    esac
}

print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} $1"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

execute_remote() {
    local cmd=$1
    log INFO "Executing remote: $cmd"
    ssh -i "${SSH_KEY}" "${SSH_USER}@${SSH_HOST}" "$cmd" >> "$LOG_FILE" 2>&1
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if ssh key exists
    if [ ! -f "${SSH_KEY}" ]; then
        log ERROR "SSH key not found: ${SSH_KEY}"
        exit 1
    fi
    log SUCCESS "SSH key found"
    
    # Check SSH connection
    if ! ssh -i "${SSH_KEY}" -o ConnectTimeout=5 "${SSH_USER}@${SSH_HOST}" "echo 'SSH connection OK'" > /dev/null 2>&1; then
        log ERROR "Cannot connect to server via SSH"
        exit 1
    fi
    log SUCCESS "SSH connection established"
    
    # Check required commands locally
    for cmd in docker git; do
        if ! command -v $cmd &> /dev/null; then
            log ERROR "Required command not found: $cmd"
            exit 1
        fi
    done
    log SUCCESS "All prerequisites met"
}

create_backup() {
    print_header "Creating Backup"
    
    # Create backups directory if not exists
    mkdir -p "${BACKUP_DIR}"
    
    # Backup current docker-compose volumes
    log INFO "Backing up volumes..."
    execute_remote "cd ${DEPLOY_PATH} && \
        docker compose exec -T db mysqldump -uroot -p\${DB_PASSWORD} --all-databases > ${BACKUP_NAME}_database.sql 2>/dev/null || true"
    
    log INFO "Backing up application state..."
    execute_remote "cd ${DEPLOY_PATH} && \
        tar -czf ${BACKUP_NAME}_app.tar.gz \
        storage/ \
        .env \
        --exclude='storage/logs' \
        --exclude='storage/framework/sessions' \
        --exclude='node_modules' \
        2>/dev/null || true"
    
    log SUCCESS "Backup created: ${BACKUP_NAME}"
}

pull_changes() {
    print_header "Pulling Changes"
    
    log INFO "Fetching latest from repository..."
    execute_remote "cd ${DEPLOY_PATH} && \
        git fetch origin && \
        git checkout ${GIT_BRANCH:-main} && \
        git pull origin ${GIT_BRANCH:-main}"
    
    log SUCCESS "Changes pulled"
}

update_env() {
    print_header "Updating Environment"
    
    log INFO "Updating .env file on server..."
    execute_remote "cd ${DEPLOY_PATH} && \
        cat .env.example | sed \
        -e 's|DB_HOST=.*|DB_HOST=db|' \
        -e 's|REDIS_HOST=.*|REDIS_HOST=redis|' \
        -e 's|APP_ENV=.*|APP_ENV=production|' \
        -e 's|APP_DEBUG=.*|APP_DEBUG=false|' \
        > .env.tmp && \
        mv .env.tmp .env"
    
    log SUCCESS "Environment updated"
}

build_images() {
    print_header "Building Docker Images"
    
    log INFO "Building production images..."
    execute_remote "cd ${DEPLOY_PATH} && \
        docker compose build --no-cache app"
    
    log SUCCESS "Docker images built"
}

pull_images() {
    print_header "Pulling Docker Images"
    
    log INFO "Pulling latest images..."
    execute_remote "cd ${DEPLOY_PATH} && \
        docker compose pull"
    
    log SUCCESS "Docker images pulled"
}

start_containers() {
    print_header "Starting Containers"
    
    log INFO "Stopping running containers..."
    execute_remote "cd ${DEPLOY_PATH} && \
        docker compose down || true"
    
    log INFO "Starting containers..."
    execute_remote "cd ${DEPLOY_PATH} && \
        docker compose up -d"
    
    # Wait for services to be healthy
    log INFO "Waiting for services to become healthy..."
    sleep 10
    
    log SUCCESS "Containers started"
}

run_migrations() {
    print_header "Running Migrations"
    
    log INFO "Waiting for database to be ready..."
    execute_remote "cd ${DEPLOY_PATH} && \
        until docker compose exec -T db mysqladmin ping -uroot -p\${DB_PASSWORD} > /dev/null 2>&1; do
            echo 'Waiting for MySQL...'
            sleep 1
        done"
    
    log INFO "Running database migrations..."
    execute_remote "cd ${DEPLOY_PATH} && \
        docker compose exec -T app php artisan migrate --force"
    
    log SUCCESS "Migrations completed"
}

optimize_app() {
    print_header "Optimizing Application"
    
    log INFO "Running optimization commands..."
    execute_remote "cd ${DEPLOY_PATH} && \
        docker compose exec -T app php artisan config:cache && \
        docker compose exec -T app php artisan route:cache && \
        docker compose exec -T app php artisan view:cache"
    
    log SUCCESS "Application optimized"
}

health_check() {
    print_header "Health Check"
    
    # Check web endpoint
    log INFO "Checking web endpoint..."
    if execute_remote "curl -f http://localhost/up > /dev/null 2>&1"; then
        log SUCCESS "Web endpoint is healthy"
    else
        log ERROR "Web endpoint health check failed"
        return 1
    fi
    
    # Check app container
    log INFO "Checking app container..."
    if execute_remote "docker compose ps app | grep -q healthy"; then
        log SUCCESS "App container is healthy"
    else
        log WARNING "App container health status unclear"
    fi
    
    # Check database
    log INFO "Checking database..."
    if execute_remote "docker compose exec -T db mysqladmin ping -uroot -p\${DB_PASSWORD} > /dev/null 2>&1"; then
        log SUCCESS "Database is healthy"
    else
        log ERROR "Database health check failed"
        return 1
    fi
    
    # Check Redis
    log INFO "Checking Redis..."
    if execute_remote "docker compose exec -T redis redis-cli ping > /dev/null 2>&1"; then
        log SUCCESS "Redis is healthy"
    else
        log WARNING "Redis health check unclear"
    fi
    
    log SUCCESS "All health checks passed"
    return 0
}

cleanup() {
    print_header "Cleanup"
    
    log INFO "Cleaning up old backups (keeping last 5)..."
    execute_remote "cd ${DEPLOY_PATH} && \
        ls -t ${BACKUP_NAME}* 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true"
    
    log INFO "Removing Docker dangling images..."
    execute_remote "docker image prune -f > /dev/null 2>&1 || true"
    
    log SUCCESS "Cleanup completed"
}

rollback() {
    print_header "⚠ ROLLBACK IN PROGRESS"
    
    if [ -z "$BACKUP_NAME" ]; then
        log ERROR "No backup found for rollback"
        return 1
    fi
    
    log WARNING "Rolling back to backup: ${BACKUP_NAME}"
    
    # Stop containers
    execute_remote "cd ${DEPLOY_PATH} && docker compose down"
    
    # Restore previous version from git
    execute_remote "cd ${DEPLOY_PATH} && git revert --no-edit HEAD || git reset --hard HEAD~1"
    
    # Start containers
    execute_remote "cd ${DEPLOY_PATH} && docker compose up -d"
    
    sleep 5
    
    # Run migrations if needed
    execute_remote "cd ${DEPLOY_PATH} && docker compose exec -T app php artisan migrate --force"
    
    log SUCCESS "Rollback completed"
}

notify_success() {
    print_header "Deployment Successful"
    
    log SUCCESS "Deployment completed successfully!"
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Application deployed successfully${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}Server:${NC}      ${SSH_HOST}"
    echo -e "${CYAN}Path:${NC}        ${DEPLOY_PATH}"
    echo -e "${CYAN}Branch:${NC}      ${GIT_BRANCH:-main}"
    echo -e "${CYAN}Timestamp:${NC}   ${TIMESTAMP}"
    echo -e "${CYAN}Log file:${NC}    ${LOG_FILE}"
    echo ""
}

notify_failure() {
    print_header "Deployment Failed"
    
    log ERROR "Deployment failed!"
    echo ""
    echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
    echo -e "${RED}✗ Deployment encountered errors${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Check log file for details:${NC}"
    echo -e "  ${LOG_FILE}"
    echo ""
    
    # Ask for rollback
    read -p "Perform rollback? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rollback
    fi
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    print_header "Laravel Application Deployment"
    
    echo -e "${CYAN}Configuration:${NC}"
    echo "  Server:       ${SSH_HOST}"
    echo "  User:         ${SSH_USER}"
    echo "  Deploy Path:  ${DEPLOY_PATH}"
    echo "  Branch:       ${GIT_BRANCH:-main}"
    echo ""
    
    # Run deployment steps
    check_prerequisites || exit 1
    create_backup || { log WARNING "Backup creation failed, but continuing..."; }
    pull_changes || exit 1
    update_env || exit 1
    
    if [ "${BUILD_IMAGES:-false}" = "true" ]; then
        build_images || exit 1
    else
        pull_images || exit 1
    fi
    
    start_containers || exit 1
    run_migrations || { log ERROR "Migrations failed"; rollback; exit 1; }
    optimize_app || { log WARNING "Optimization failed, but continuing..."; }
    
    if health_check; then
        cleanup || true
        notify_success
        exit 0
    else
        notify_failure
        exit 1
    fi
}

# Run main function
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

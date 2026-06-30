# 🚀 CD: Deployment Guide

## Overview

Complete CD (Continuous Deployment) pipeline for deploying Laravel application to a VPS via SSH.

**Flow:**
```
Push to main
  ↓
Pre-deployment checks (tests, lint)
  ↓
Build & push Docker image
  ↓
Deploy to production VPS
  ↓
Health checks
  ↓
Success/Rollback
```

---

## 📋 Prerequisites

### Local Machine
- Git
- SSH client
- Docker (optional, for local testing)

### VPS Server
- SSH server running
- Docker & Docker Compose
- Git
- Enough disk space for application & database

### GitHub Secrets
```
DEPLOY_HOST              # VPS hostname or IP
DEPLOY_USER              # SSH username
DEPLOY_SSH_KEY           # SSH private key (ed25519 recommended)
DEPLOY_PATH              # Remote deployment directory
DEPLOY_DB_PASSWORD       # Database password
DEPLOY_APP_KEY           # Laravel APP_KEY
SLACK_WEBHOOK            # Optional: Slack notifications
```

---

## 🔑 Setup Guide

### Step 1: Generate SSH Key Pair

**On your local machine:**

```bash
# Generate ed25519 key (recommended for security)
ssh-keygen -t ed25519 -f ~/.ssh/deploy_key -N ""

# Or use RSA if ed25519 not available
ssh-keygen -t rsa -b 4096 -f ~/.ssh/deploy_key -N ""

# Display private key for GitHub
cat ~/.ssh/deploy_key
```

### Step 2: Configure VPS SSH Access

**On your VPS:**

```bash
# Login to VPS
ssh user@your-vps-host

# Add your public key to authorized_keys
mkdir -p ~/.ssh
echo "$(cat ~/.ssh/deploy_key.pub)" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Step 3: Setup Application Directory

**On your VPS:**

```bash
# Create application directory
sudo mkdir -p /home/deploy/laravel
sudo chown deploy:deploy /home/deploy/laravel

# Clone repository (first time only)
cd /home/deploy/laravel
git clone https://github.com/your-org/your-repo.git .

# Create required directories
mkdir -p storage/logs storage/framework/{sessions,views,cache}
mkdir -p .backups deploy/logs

# Set permissions
chmod -R 755 storage bootstrap/cache
```

### Step 4: Add GitHub Secrets

**In GitHub:**
```
Settings → Secrets and variables → Actions → New repository secret

DEPLOY_HOST              = your-vps-host.com
DEPLOY_USER              = deploy
DEPLOY_SSH_KEY           = (paste private key from Step 1)
DEPLOY_PATH              = /home/deploy/laravel
DEPLOY_DB_PASSWORD       = your-secure-password
DEPLOY_APP_KEY           = base64:your-app-key-here
SLACK_WEBHOOK            = https://hooks.slack.com/services/...
```

### Step 5: Create .env.deploy

**Locally (development only):**

```bash
# Copy template
cp deploy/.env.example deploy/.env.deploy

# Edit with your values
nano deploy/.env.deploy

# Set permissions
chmod 600 deploy/.env.deploy

# Add to .gitignore (never commit secrets!)
echo "deploy/.env.deploy" >> .gitignore
```

---

## 📝 Deployment Scripts

### deploy/deploy.sh
Main deployment script. Handles:
- SSH connection verification
- Backup creation
- Git pull
- Docker image pull/build
- Container restart
- Database migrations
- Health checks
- Rollback on failure

**Usage:**

```bash
# Automated (via GitHub Actions)
./deploy/deploy.sh

# Manual deployment
SSH_HOST=your-vps.com \
SSH_USER=deploy \
SSH_KEY=~/.ssh/deploy_key \
DEPLOY_PATH=/home/deploy/laravel \
./deploy/deploy.sh
```

### deploy/health_check.sh
Post-deployment validation. Checks:
- HTTP endpoint (GET /up)
- API endpoint
- Container status
- Response times
- Error logs

**Usage:**

```bash
# Local health check
./deploy/health_check.sh

# Remote health check
./deploy/health_check.sh "https://your-domain.com"
```

---

## 🔄 GitHub Actions Workflow

### Trigger Events
- ✅ Push to `main` branch - Automatic deployment
- ✅ Manual trigger (`workflow_dispatch`) - On-demand deployment

### Jobs

#### 1. Pre-Deployment Checks
```yaml
✅ Lint code (Pint)
✅ Run tests (PHPUnit)
✅ Verify dependencies
```

#### 2. Build and Push Docker Image
```yaml
✅ Build prod stage
✅ Push to GHCR
✅ Create deployment artifact
```

#### 3. Deploy to Production
```yaml
✅ SSH connection
✅ Create backup
✅ Pull latest code
✅ Pull Docker images
✅ Start containers
✅ Run migrations
✅ Health checks
```

#### 4. Rollback (On Failure)
```yaml
✅ Detect deployment failure
✅ Revert to previous version
✅ Notify team
```

---

## 📊 Deployment Stages

### Stage 1: Pre-Deployment (Local)
```
Running on GitHub Actions runner
├── Checkout code
├── Run linter
├── Run tests
└── Create summary
```

### Stage 2: Build (Local)
```
Build Docker image
├── Compile code
├── Install dependencies
├── Optimize for production
└── Push to registry
```

### Stage 3: Deploy (Remote - SSH)
```
Connect to VPS via SSH
├── Create backup
├── Pull latest code
├── Pull Docker images
├── Stop old containers
├── Start new containers
├── Wait for services
├── Run migrations
├── Optimize application
└── Health check
```

### Stage 4: Verify (Remote - SSH)
```
Health checks
├── HTTP endpoint (GET /up)
├── API availability
├── Database connection
├── Redis connection
├── Container status
├── Response times
└── Error logs
```

---

## 🔒 Secret Management

### Never commit secrets to Git

**File:** `deploy/.env.deploy`
```
❌ DO NOT COMMIT
✅ Add to .gitignore
✅ Store in GitHub Secrets
```

### Best Practices

1. **Use strong passwords**
   ```
   DB_PASSWORD=your-super-secure-password-with-special-chars!@#$%
   ```

2. **Rotate secrets regularly**
   - Change database password every 90 days
   - Rotate SSH keys annually

3. **Limit permissions**
   - SSH user should only access `/home/deploy/laravel`
   - Database user should only access application database

4. **Monitor access**
   - Review deployment logs
   - Check SSH audit logs
   - Monitor failed login attempts

---

## 🛡️ Security Checklist

- ✅ SSH key pair generated (ed25519)
- ✅ Public key on VPS (authorized_keys)
- ✅ Private key stored in GitHub Secrets (never in repo)
- ✅ .env.deploy in .gitignore
- ✅ Database user has limited privileges
- ✅ SSH user can't access other directories
- ✅ Firewall configured (only necessary ports)
- ✅ SSL/TLS certificate configured
- ✅ Regular backups enabled
- ✅ Monitoring/alerts setup

---

## 📈 Deployment Examples

### Example 1: Standard Deployment
```
$ git commit -m "feat: add feature"
$ git push origin main

GitHub Actions automatically:
1. Runs tests ✅
2. Builds image ✅
3. Deploys to VPS ✅
4. Verifies health ✅
5. Notifies Slack ✅
```

### Example 2: Manual Deployment
```bash
# Trigger manually via GitHub UI
GitHub → Actions → CD - Deploy to Production → Run workflow

# Or use GitHub CLI
gh workflow run deploy.yml
```

### Example 3: Local Deployment (Emergency)
```bash
./deploy/deploy.sh

# With custom settings
SSH_HOST=backup-server.com \
DEPLOY_PATH=/opt/app \
./deploy/deploy.sh
```

---

## 🚨 Troubleshooting

### SSH Connection Failed
```
❌ Error: Cannot connect to server via SSH

Solutions:
1. Check SSH key: ssh-keyscan -H your-vps.com
2. Verify key in authorized_keys: cat ~/.ssh/authorized_keys
3. Check firewall: sudo ufw allow 22
4. Test connection: ssh -i ~/.ssh/deploy_key deploy@your-vps.com
```

### Docker Image Pull Failed
```
❌ Error: Failed to pull Docker image

Solutions:
1. Check registry credentials
2. Verify image exists: docker pull ghcr.io/your-org/your-repo:main
3. Check GitHub token has package access
```

### Migration Failed
```
❌ Error: Database migration error

Solutions:
1. Check database connection
2. Review migration files
3. Check logs: docker compose logs app
4. Run manually: docker compose exec app php artisan migrate --force
5. Rollback if needed
```

### Health Check Failed
```
❌ Error: Health check did not pass

Solutions:
1. Check application logs: docker compose logs app
2. Verify database is running: docker ps
3. Check network connectivity
4. Manual rollback will be triggered
```

---

## 📊 Monitoring & Logs

### Deployment Logs
```bash
# GitHub Actions logs
GitHub → Actions → CD - Deploy to Production → Run details

# Server logs
/home/deploy/laravel/deploy/deploy_YYYYMMDD_HHMMSS.log
/home/deploy/laravel/storage/logs/laravel.log
```

### Health Check Logs
```bash
./deploy/health_check_YYYYMMDD_HHMMSS.log
```

### Docker Logs
```bash
# On server
ssh deploy@your-vps.com
cd /home/deploy/laravel

docker compose logs app      # Application logs
docker compose logs db       # Database logs
docker compose logs redis    # Redis logs
docker compose logs nginx    # Web server logs
```

---

## 🔄 Rollback Procedure

### Automatic Rollback
```
Deployment fails
  ↓
Health check detects issue
  ↓
Automatically revert to previous commit
  ↓
Restart containers with old code
  ↓
Notify team via Slack
```

### Manual Rollback
```bash
ssh deploy@your-vps.com
cd /home/deploy/laravel

# Revert to previous version
git revert --no-edit HEAD
# or
git reset --hard HEAD~1

# Restart
docker compose down
docker compose up -d

# Run migrations if needed
docker compose exec app php artisan migrate --force
```

---

## 📞 Notifications

### Slack Integration
```yaml
On deployment success:
✅ Deployment successful
  - Commit hash
  - Author
  - Deployment URL
  - Timestamp

On deployment failure:
❌ Deployment failed
  - Error details
  - Action logs link
  - Rollback status
```

### Email Notifications (Optional)
Configure in `.env.deploy`:
```env
NOTIFY_EMAIL=devops@example.com
```

---

## 🎯 Best Practices

1. **Test locally first**
   - Run tests: `make test`
   - Check lint: `make lint`
   - Build image: `docker compose build`

2. **Use meaningful commit messages**
   - Good: "feat: add user authentication"
   - Bad: "update stuff"

3. **Keep deployments small**
   - Small commits are easier to rollback
   - Deploy frequently (multiple times per day)

4. **Monitor after deployment**
   - Watch error logs
   - Monitor performance metrics
   - Check user feedback

5. **Backup before deploy**
   - Automatic backup before every deploy
   - Keep last 5 backups
   - Test restore procedure

---

## 📚 Related Documentation

- [Docker Setup](../DOCKER_SETUP.md) - Container configuration
- [CI Pipeline](../CI_PIPELINE_SETUP.md) - Build & test automation
- [Make Commands](../ASSIGNMENT_3_REVIEW.md) - Development commands
- [Production Checklist](../FINAL_CHECKLIST.md) - Pre-launch verification

---

## ✅ Deployment Checklist

Before first deployment:
- [ ] SSH key pair generated
- [ ] VPS server prepared
- [ ] GitHub Secrets configured
- [ ] Database backup tested
- [ ] SSL/TLS certificate installed
- [ ] DNS records updated
- [ ] Monitoring configured
- [ ] Slack webhook configured
- [ ] Team notified
- [ ] Runbook created

---

**Your deployment pipeline is ready! 🚀**

# 🚀 Quick Deployment Setup (5 Minutes)

## Step 1: Generate SSH Key (1 min)

```bash
# Generate key
ssh-keygen -t ed25519 -f ~/.ssh/deploy_key -N ""

# View private key (for GitHub)
cat ~/.ssh/deploy_key
```

## Step 2: Setup VPS (2 min)

```bash
# On your VPS:
ssh user@your-vps.com

# Add your SSH public key
mkdir -p ~/.ssh
echo "YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Create app directory
sudo mkdir -p /home/deploy/laravel
sudo chown deploy:deploy /home/deploy/laravel
cd /home/deploy/laravel

# Clone repository
git clone https://github.com/your-org/your-repo.git .

# Create directories
mkdir -p storage/{logs,framework/{sessions,views,cache}} .backups deploy/logs
chmod -R 755 storage bootstrap/cache
```

## Step 3: Add GitHub Secrets (2 min)

**GitHub UI → Settings → Secrets → Actions → New Secret**

```
DEPLOY_HOST              = your-vps.com
DEPLOY_USER              = deploy
DEPLOY_SSH_KEY           = (paste private key)
DEPLOY_PATH              = /home/deploy/laravel
DEPLOY_DB_PASSWORD       = secure-password-123
DEPLOY_APP_KEY           = base64:xxxx...
SLACK_WEBHOOK            = (optional)
```

## Step 4: Test Deployment

```bash
# Option 1: Push to main (automatic)
git push origin main

# Option 2: Manual trigger
GitHub → Actions → CD - Deploy → Run workflow
```

---

## ✅ Deployment Flow

```
1. Push to main
   ↓
2. Tests run
   ✓ Lint check
   ✓ Unit tests
   ✓ Feature tests
   ↓
3. Docker image built & pushed
   ✓ Production build
   ✓ Push to registry
   ↓
4. Deploy to VPS
   ✓ SSH to server
   ✓ Pull code
   ✓ Pull images
   ✓ Start containers
   ✓ Run migrations
   ↓
5. Health checks
   ✓ HTTP endpoint
   ✓ Database
   ✓ Redis
   ↓
6. Success! 🎉
```

---

## 🔑 Key Files

| File | Purpose |
|------|---------|
| `deploy/deploy.sh` | Main deployment script |
| `deploy/health_check.sh` | Validate deployment |
| `deploy/.env.example` | Configuration template |
| `.github/workflows/deploy.yml` | GitHub Actions workflow |
| `deploy/DEPLOYMENT_GUIDE.md` | Full documentation |

---

## 📋 Manual Deployment

```bash
# Create .env.deploy
cp deploy/.env.example deploy/.env.deploy
nano deploy/.env.deploy  # Edit with your values

# Run deployment
chmod +x deploy/deploy.sh
./deploy/deploy.sh

# Check health
chmod +x deploy/health_check.sh
./deploy/health_check.sh https://your-domain.com
```

---

## 🚨 Rollback

On deployment failure:
1. GitHub Actions detects failure
2. Previous version automatically restored
3. Slack notification sent
4. Team notified

Or manually:
```bash
ssh deploy@your-vps.com
cd /home/deploy/laravel
git reset --hard HEAD~1
docker compose down && docker compose up -d
```

---

## 📊 Monitoring

```bash
# Watch deployment
GitHub Actions → CD - Deploy → Live logs

# View server logs
ssh deploy@your-vps.com
cd /home/deploy/laravel
docker compose logs -f app

# Check health
./deploy/health_check.sh https://your-domain.com
```

---

## ✨ Tips

- **Test locally first:** `make test && make lint`
- **Small commits:** Deploy multiple times per day
- **Watch logs:** First 10 minutes after deploy
- **Keep backups:** Last 5 backups kept automatically

---

**You're all set! 🚀**

Next: Read [`deploy/DEPLOYMENT_GUIDE.md`](./DEPLOYMENT_GUIDE.md) for detailed information.

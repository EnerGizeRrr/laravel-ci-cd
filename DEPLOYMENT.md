# Развертывание

## Быстрый старт

```bash
git init
git remote add origin https://github.com/[USERNAME]/laravel-docker-app
git add .
git commit -m "Initial commit"
git branch -M main
git push -u origin main
```

Замени `[USERNAME]` на свой никнейм GitHub.

## URL Pipeline

После push смотри на:
```
https://github.com/[USERNAME]/laravel-docker-app/actions/workflows/ci.yml
```

Жди зеленую галочку (3-5 минут).

## VPS Развертывание

Смотри `deploy/DEPLOYMENT_GUIDE.md` для production развертывания через SSH.

## Docker локально

```bash
make up
make migrate
make test
```

Доступ: `http://localhost`

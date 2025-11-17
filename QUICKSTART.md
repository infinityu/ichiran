# Quick Start Guide - Deploy to Railway

## 🚀 Deploy in 3 Steps

### 1. Push to GitHub

```bash
git add .
git commit -m "Add Railway deployment configuration"
git push origin master
```

### 2. Deploy to Railway

1. Go to [railway.app](https://railway.app)
2. Click **"New Project"** → **"Deploy from GitHub repo"**
3. Select your `ichiran` repository
4. Railway will automatically:
   - Detect the `Dockerfile`
   - Build the container (~10-15 minutes first time)
   - Deploy and provide a public URL

### 3. Test Your API

Replace `YOUR-APP.railway.app` with your Railway URL:

```bash
curl -X POST https://YOUR-APP.railway.app/api/romanize \
  -H "Content-Type: application/json" \
  -d '{"text":"一覧は最高だぞ"}'
```

Expected response:
```json
{
  "romanized": "ichiran wa saikō da zo",
  "words": [
    {
      "word": "ichiran",
      "text": "一覧",
      "kana": "いちらん",
      "glosses": [...]
    },
    ...
  ]
}
```

## 📝 What Was Created

```
ichiran/
├── api/
│   ├── package.json          # Node.js dependencies
│   └── server.js             # Express API server
├── Dockerfile                # Railway deployment configuration
├── start.sh                  # Startup script
├── railway.json              # Railway settings
├── supervisor.conf           # Process management
├── .railwayignore           # Files to ignore during build
├── RAILWAY_DEPLOYMENT.md     # Detailed deployment guide
├── API_EXAMPLES.md           # API usage examples
└── QUICKSTART.md            # This file
```

## 🔍 API Endpoints

### Health Check
```bash
GET /health
```

### Romanize (Simple)
```bash
POST /api/romanize
Body: { "text": "日本語のテキスト" }
```

### Romanize (Full)
```bash
POST /api/romanize/full
Body: { "text": "日本語のテキスト", "limit": 5 }
```

## 📚 Documentation

- **[RAILWAY_DEPLOYMENT.md](RAILWAY_DEPLOYMENT.md)** - Complete deployment guide
- **[API_EXAMPLES.md](API_EXAMPLES.md)** - Code examples in multiple languages

## ⚙️ Local Testing

Test locally before deploying:

```bash
docker build -t ichiran-railway .
docker run -p 3000:3000 ichiran-railway

# In another terminal:
curl -X POST http://localhost:3000/api/romanize \
  -H "Content-Type: application/json" \
  -d '{"text":"こんにちは"}'
```

## 💡 Tips

- **First deployment**: Takes 10-15 minutes (database initialization)
- **Subsequent deployments**: Much faster (~3-5 minutes)
- **Memory required**: At least 2GB RAM
- **Storage**: ~5GB for database

## 🐛 Troubleshooting

**Deployment timeout?**
- Check Railway logs for progress
- Database restoration takes the longest time

**API not responding?**
- Check health endpoint: `GET /health`
- Review deployment logs in Railway dashboard

**Need help?**
- See [RAILWAY_DEPLOYMENT.md](RAILWAY_DEPLOYMENT.md) for detailed troubleshooting

## 🎉 You're Done!

Your Ichiran API is now live and ready to analyze Japanese text!

Example command with your deployed URL:
```bash
curl -X POST https://YOUR-APP.railway.app/api/romanize \
  -H "Content-Type: application/json" \
  -d '{"text":"ありがとうございます"}'
```


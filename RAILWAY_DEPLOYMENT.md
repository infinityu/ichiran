# Railway Deployment Guide for Ichiran

This guide explains how to deploy the Ichiran Japanese text analyzer to Railway with an integrated API service.

## Overview

The deployment includes:
- PostgreSQL database (running in the same container)
- Ichiran SBCL system with CLI tools
- Node.js Express API server

## Deployment Steps

### 1. Prerequisites

- A Railway account (sign up at https://railway.app)
- This repository pushed to GitHub

### 2. Deploy to Railway

1. Log in to Railway
2. Click "New Project"
3. Select "Deploy from GitHub repo"
4. Choose this repository
5. Railway will automatically detect the `Dockerfile` and begin building

### 3. Configuration

Railway will use the following configuration automatically:
- Build: Uses the `Dockerfile` in the root directory
- Start command: `/start.sh` (defined in `railway.json`)
- Health check: `/health` endpoint
- Port: Automatically assigned via `PORT` environment variable

### 4. Environment Variables (Optional)

No environment variables are required for basic operation. The following are set automatically in the startup script:

- `ICHIRAN_CONNECTION`: PostgreSQL connection string
- `PORT`: API server port (provided by Railway)

### 5. First Deployment

The first deployment will take approximately 10-15 minutes because it needs to:
1. Download and restore the Ichiran database (~4.7 GB)
2. Build the SBCL core image
3. Compile the Ichiran CLI
4. Initialize all caches

Subsequent deployments will be faster if the database volume persists.

## API Usage

Once deployed, Railway will provide you with a public URL (e.g., `https://your-app.railway.app`).

### Health Check

```bash
GET https://your-app.railway.app/health
```

Response:
```json
{
  "status": "ok",
  "service": "ichiran-api"
}
```

### Romanize Text (Simple)

```bash
POST https://your-app.railway.app/api/romanize
Content-Type: application/json

{
  "text": "一覧は最高だぞ"
}
```

Response:
```json
{
  "romanized": "ichiran wa saikō da zo",
  "words": [
    {
      "word": "ichiran",
      "text": "一覧",
      "kana": "いちらん",
      "glosses": [
        {
          "pos": "n,vs",
          "info": "",
          "definition": "look; glance; sight; inspection"
        },
        {
          "pos": "n",
          "info": "",
          "definition": "summary; list; table; catalog; catalogue"
        }
      ]
    },
    ...
  ]
}
```

### Romanize Text (Full JSON)

For advanced segmentation with multiple alternatives:

```bash
POST https://your-app.railway.app/api/romanize/full
Content-Type: application/json

{
  "text": "一覧は最高だぞ",
  "limit": 5
}
```

This returns the full segmentation JSON from ichiran-cli with up to 5 alternative segmentations.

## Testing Locally with Docker

Before deploying to Railway, you can test the setup locally:

```bash
# Build the Docker image
docker build -t ichiran-railway .

# Run the container
docker run -p 3000:3000 ichiran-railway

# Test the API
curl -X POST http://localhost:3000/api/romanize \
  -H "Content-Type: application/json" \
  -d '{"text":"一覧は最高だぞ"}'
```

## Troubleshooting

### Deployment timeout

If the deployment times out during the first build:
- Railway provides up to 500 seconds for builds
- The database initialization is the most time-consuming step
- Check the deployment logs for progress

### API not responding

Check that:
1. The health check endpoint returns OK: `GET /health`
2. PostgreSQL is running: Check logs for "PostgreSQL is ready"
3. Ichiran is initialized: Check logs for "Ichiran initialization complete"

### Database issues

The database is initialized automatically on first run. The startup script:
1. Creates the PostgreSQL data directory
2. Starts PostgreSQL
3. Creates the `jmdict` database
4. Restores from the dump file

If you need to reset the database, redeploy the service (Railway doesn't persist data between deployments by default).

## Performance Notes

- First request may be slow (~2-3 seconds) as caches warm up
- Subsequent requests are much faster (~100-300ms)
- The container requires at least 2GB RAM for smooth operation
- Database size: ~4.7 GB

## Cost Estimates

Railway pricing (as of 2025):
- Hobby plan: $5/month for 500 hours of usage
- Developer plan: $20/month for unlimited usage
- Memory usage: ~2-3 GB
- Storage: ~5 GB

Typical usage on Developer plan: $10-20/month depending on request volume.

## Support

For issues with:
- Ichiran itself: https://github.com/tshatrov/ichiran
- Railway deployment: Check Railway documentation or this guide
- API server: Check the source code in `api/server.js`


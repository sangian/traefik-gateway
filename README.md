# Traefik Gateway

Standalone Traefik reverse proxy with automatic Let's Encrypt SSL. Deploy once per VPS, then connect any app by joining the `traefik-network` Docker network.

## Quick Start

```bash
cp .env.example .env
# Edit .env with your domain, email, and dashboard credentials
./generate-password.sh  # Generate htpasswd for dashboard auth
docker compose up -d
```

## Connecting Apps

Any Docker Compose service on the same host can route through Traefik by joining the external network and adding labels:

```yaml
services:
  myapp:
    # ...
    networks:
      - traefik-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`app.yourdomain.com`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
      - "traefik.http.services.myapp.loadbalancer.server.port=8080"

networks:
  traefik-network:
    external: true
```

## Custom Entrypoints

If an app needs additional ports (e.g., gRPC on 4317), add entrypoints to the Traefik `command` in `docker-compose.yml`:

```yaml
- "--entrypoints.otlp-grpc.address=:4317"
```

And expose the port in `ports`.

## Dashboard

Access at `https://<TRAEFIK_DOMAIN>/dashboard/` (trailing slash required).

## Rate Limiting

Built-in rate limiting middleware protects your infrastructure from traffic spikes and abuse.

### Quick Setup

1. **Auto-calculate recommended limits** based on your server specs:
   ```bash
   ./configure-rate-limit.sh
   ```
   This analyzes your CPU cores and RAM, then outputs recommended values.

2. **Add the values to your `.env` file:**
   ```bash
   RATE_LIMIT_AVERAGE=200
   RATE_LIMIT_BURST=400
   RATE_LIMIT_API_AVERAGE=50
   RATE_LIMIT_API_BURST=100
   ```

3. **Restart Traefik:**
   ```bash
   docker compose up -d
   ```

### Using Rate Limiting

**For individual apps**, add the middleware to your service labels:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myapp.middlewares=rate-limit-global"
  # Or for stricter API limits:
  - "traefik.http.routers.myapi.middlewares=rate-limit-api"
  # ... other labels
```

**To disable rate limiting** for an app, simply don't add the middleware.

### Advanced Options

**Adjust limits on-the-fly** by updating `.env` and restarting:
```bash
# Temporarily increase limits
RATE_LIMIT_AVERAGE=500
RATE_LIMIT_BURST=1000
```

**Per-IP rate limiting** (uncomment in `middlewares.yml`):
```yaml
rate-limit-per-ip:
  rateLimit:
    average: 100
    burst: 200
    sourcecriterion:
      ipstrategy:
        depth: 1   # count per client IP
```

### Tuning Recommendations

| Server Size | Average | Burst |
|-------------|---------|-------|
| Small (1-2 cores, 1-2GB) | 50 | 100 |
| Medium (2-4 cores, 4-8GB) | 200 | 400 |
| Large (8+ cores, 16GB+) | 500 | 1000 |

Adjust based on your app's actual traffic patterns. Higher is not always better—unnecessary rate limiting can hurt legitimate users.

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Traefik service definition |
| `.env.example` | Configuration template |
| `traefik/traefik.yml` | Static config (minimal) |
| `traefik/dynamic/middlewares.yml` | Rate limiting and security middleware |
| `generate-password.sh` | htpasswd helper |
| `configure-rate-limit.sh` | Calculate optimal rate limits for your server |


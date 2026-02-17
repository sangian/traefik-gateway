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

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Traefik service definition |
| `.env.example` | Configuration template |
| `traefik/traefik.yml` | Static config (minimal) |
| `traefik/dynamic/` | Dynamic config (middlewares, etc.) |
| `generate-password.sh` | htpasswd helper |

# Nginx Geo Monitoring — Gigapipe + ClickHouse + Grafana

Track user access locations from Nginx logs using GeoIP2, Promtail, Gigapipe (qryn), ClickHouse, and Grafana.

Dashboard: [13865 - Analytics NGINX / LOKI v2+](https://grafana.com/grafana/dashboards/13865)

## Architecture

```
┌──────────┐  JSON logs   ┌──────────┐  /loki/api/v1/push  ┌──────────────────────────┐
│  Nginx   │ ───────────► │ Promtail │ ───────────────────► │  Gigapipe (qryn)         │
│ (GeoIP2) │              │          │                      │  Loki-compatible API     │
└──────────┘              └──────────┘                      └──────────┬───────────────┘
                                                                       │ SQL write/read
                                                                       ▼
                                                            ┌──────────────────────────┐
                                                            │  ClickHouse              │
                                                            │  (columnar storage)      │
                                                            └──────────┬───────────────┘
                                                                       │ LogQL query
                                                            ┌──────────▼───────────────┐
                                                            │  Grafana                 │
                                                            │  datasource type: Loki   │
                                                            │  url: gigapipe:3100      │
                                                            └──────────────────────────┘
```

## Stack

| Component  | Image                              | Port | Role                              |
|------------|------------------------------------|------|-----------------------------------|
| Nginx      | custom build (GeoIP2)              | 8080 | Web server + JSON access logs     |
| Promtail   | grafana/promtail:2.9.4             | 9080 | Log shipper → Gigapipe            |
| Gigapipe   | ghcr.io/metrico/gigapipe:latest    | 3100 | Loki-compatible API + query layer |
| ClickHouse | clickhouse/clickhouse-server:24.1  | 8123 | Columnar storage backend          |
| Grafana    | grafana/grafana:10.3.1             | 3000 | Visualization                     |

## Why Gigapipe?

Gigapipe (powered by **qryn**) is drop-in replacement for Loki:
- **API identic** — Promtail, Grafana, and all Loki client doesn't need to change
- **ClickHouse backend** — query performance so much better wth highest volume
- **Full support LogQL** — all query in `query.md` quickly running
- **Polyglot** — build in support Prometheus, Tempo, InfluxDB, etc in 1 endpoint

## Prerequisites

- Docker + Docker Compose or kube cluster
- MaxMind GeoLite2 `.mmdb` files ([register here](https://www.maxmind.com/en/geolite2/signup))

## Setup

### 1. Add GeoIP2 database files

```bash
cp GeoLite2-Country.mmdb ./nginx/geoip/
cp GeoLite2-City.mmdb    ./nginx/geoip/
```

### 2. Run the stack

```bash
docker compose up -d --build
```

Automate startup runtime :
1. ClickHouse (healthcheck till ready)
2. Gigapipe (waiting for ClickHouse)
3. Nginx + Promtail + Grafana

### 3. Verify

```bash
# Cek all running container
docker compose ps

# Cek Gigapipe ready to accept logs
curl http://localhost:3100/ready

# Cek labels from Promtail
curl http://localhost:3100/loki/api/v1/labels
```

### 4. Grafana

Access http://localhost:3000 (user: `<user>`, password: `<password>`)

Datasource **Gigapipe** (type: Loki) auto-provisioned

### 5. Generate Dummy Traffic

```bash
chmod +x generate_logs.sh
./generate_logs.sh burst 200
./generate_logs.sh stream 1
```

## Repo Stucture

```
.
├── docker-compose.yml
├── generate_logs.sh
├── nginx/
│   ├── Dockerfile
│   ├── nginx.conf              # JSON log format (json_analytics)
│   └── geoip/                  # .mmdb files
├── promtail/
│   └── promtail-config.yml     # Push to http://gigapipe:3100/loki/api/v1/push
├── clickhouse/
│   └── config/
│       └── users.xml           # ClickHouse user config for Gigapipe
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   └── loki.yml        # Datasource: Gigapipe (type: Loki)
│       └── dashboards/
│           └── dashboards.yml
└── kube-manifest/
    ├── namespace.yaml
    ├── clickhouse.yaml
    ├── gigapipe.yaml
    ├── nginx.yaml
    ├── promtail.yaml
    ├── grafana.yaml
    └── readme.md
```

## Referensi

- [Gigapipe OSS Docs](https://gigapipe.com/docs/oss.html)
- [Gigapipe API Docs](https://gigapipe.com/docs/api.html)
- [Gigapipe GitHub](https://github.com/metrico/gigapipe)
- [Grafana Dashboard 13865](https://grafana.com/grafana/dashboards/13865)

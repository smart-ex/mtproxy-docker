# MTProxy — VPS deployment via Docker

Ready-to-use Dockerfile and docker-compose for quick deployment of the [official MTProxy](https://github.com/TelegramMessenger/MTProxy) on a VPS. Builds from source for the latest proxy version.

**Important:** Do not publish the `.env` file or commit your secret to the repository. Copy `.env.example` to `.env`, set `SECRET`, and never commit `.env`.

---

## Requirements

- VPS with Linux (Ubuntu, Debian, CentOS, etc.)
- Docker and Docker Compose

Docker and Docker Compose installation:

- [Official Docker documentation](https://docs.docker.com/engine/install/)
- Quick install: `curl -fsSL https://get.docker.com | sh`
- Docker Compose v2: usually included with Docker Desktop or as the built-in `docker compose` command

---

## Step-by-step guide

### 1. Preparation

Copy the project to your VPS (via git clone or scp):

```bash
git clone <YOUR_REPO_URL> mtp-proxy
cd mtp-proxy
```

### 2. Secret generation

Generate a secret (32 hex characters):

```bash
./generate-secret.sh
```

Or manually:

```bash
head -c 16 /dev/urandom | xxd -ps
```

Copy the output — you will need it for `.env`.

### 3. Configuration

Create `.env` from the example:

```bash
cp .env.example .env
```

Edit `.env` and set the generated secret:

```bash
nano .env   # or vim, vi, etc.
```

You must set `SECRET=`. Other parameters are optional:

- `PROXY_TAG` — tag from @MTProxybot (after registering your proxy)
- `WORKERS` — number of workers (default: 1)
- `HOST_PORT` — proxy port inside container (default: 443)
- `STATS_PORT` — stats port (default: 8888)

### 4. Start

```bash
docker compose up -d
```

Check logs:

```bash
docker compose logs -f mtproxy
```

### 5. Client link

Build the connection link for Telegram:

```
tg://proxy?server=<IP_OR_DOMAIN>&port=443&secret=<YOUR_SECRET>
```

Example:

```
tg://proxy?server=192.168.1.100&port=443&secret=abcd1234ef567890abcd1234ef567890
```

Or short link:

```
https://t.me/proxy?server=<IP_OR_DOMAIN>&port=443&secret=<YOUR_SECRET>
```

If you use a different port (e.g. 8443), replace `port=443` with `port=8443` and configure port mapping in `docker-compose.yml` (e.g. `"8443:443"`).

### 6. Register with @MTProxybot (optional)

1. Open [@MTProxybot](https://t.me/MTProxybot) in Telegram
2. Send your proxy link
3. Receive the tag
4. Add to `.env`: `PROXY_TAG=<RECEIVED_TAG>`
5. Restart: `docker compose up -d --force-recreate`

### 7. Statistics

Stats are available at `http://localhost:8888/stats`:

```bash
curl http://localhost:8888/stats
```

Or from the host if port 8888 is mapped in `docker-compose.yml` (already configured by default).

For production, it is recommended to bind the stats port to localhost only so it is not exposed externally. In `docker-compose.yml`:

```yaml
ports:
  - "443:443"
  - "127.0.0.1:8888:8888"   # stats only on localhost
```

### 8. Firewall

Open port 443 for incoming connections:

**UFW (Ubuntu/Debian):**

```bash
sudo ufw allow 443/tcp
sudo ufw reload
```

**firewalld (CentOS/RHEL):**

```bash
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

Port 8888 (stats) should remain localhost-only — do not expose it externally unless needed.

### 9. Updating Telegram config

Telegram periodically updates its server list. Restart the container about once per day — on startup it fetches the latest `proxy-secret` and `proxy-multi.conf`:

```bash
docker compose restart mtproxy
```

You can set up cron:

```bash
0 4 * * * cd /path/to/mtp-proxy && docker compose restart mtproxy
```

### 10. Stop

```bash
docker compose down
```

---

## Additional notes

### Random padding (DPI bypass)

If your ISP blocks MTProxy by packet size, add the `dd` prefix to the secret in the link: `dd` + your secret. See: [MTProxy README](https://github.com/TelegramMessenger/MTProxy#random-padding).

### Port 443 in use

If port 443 is already in use on the VPS (e.g. by a web server), change the port mapping in `docker-compose.yml`:

```yaml
ports:
  - "8443:443"   # clients connect to 8443
  - "8888:8888"
```

And use `port=8443` in the link.

### Platform

The default `docker-compose.yml` uses `platform: linux/amd64`. For ARM (e.g. Raspberry Pi), adjust the platform or build accordingly.

---

## Project structure

```
mtp-proxy/
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── generate-secret.sh
├── .env.example
├── .gitignore
├── LICENSE
└── README.md
```

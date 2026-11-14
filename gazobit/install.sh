#!/usr/bin/env bash
set -Eeuo pipefail

DOMAIN="gazobit.ember-burger.ru"
BASE="https://raw.githubusercontent.com/zerodancing/Metamorph-Creative-Menu/gazobit-vps-deploy-2026/gazobit"
ROOT="/var/www/gazobit.ember-burger.ru"
CONF="/etc/nginx/sites-available/gazobit.ember-burger.ru.conf"
ENABLED="/etc/nginx/sites-enabled/gazobit.ember-burger.ru.conf"

if [ "$(id -u)" != 0 ]; then
  echo "Run this installer as root." >&2
  exit 1
fi
for app in nginx curl systemctl; do
  command -v "$app" >/dev/null || { echo "Missing required program: $app" >&2; exit 1; }
done
nginx -t
if [ -e "$CONF" ] || [ -L "$ENABLED" ] || nginx -T 2>/dev/null | grep -Eq '^[[:space:]]*server_name[[:space:]]+[^;]*gazobit[.]ember-burger[.]ru([;[:space:]]|$)'; then
  echo "GAZOBIT host already configured. No changes made; refusing to overwrite." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "Downloading GAZOBIT..."
curl -fLSs --retry 3 --connect-timeout 15 --max-time 120 "$BASE/index.html" -o "$TMP/index.html"
curl -fLSs --retry 3 --connect-timeout 15 --max-time 120 "$BASE/preview.webp" -o "$TMP/preview.webp"
test "$(wc -c < "$TMP/index.html")" -gt 1000000 || { echo "Downloaded HTML appears incomplete." >&2; exit 1; }
grep -q '<title>ГАЗОБИТ' "$TMP/index.html" || { echo "Unexpected page." >&2; exit 1; }
grep -q '</html>' "$TMP/index.html" || { echo "Incomplete HTML." >&2; exit 1; }
test "$(wc -c < "$TMP/preview.webp")" -gt 100000 || { echo "Preview is incomplete." >&2; exit 1; }
python3 - "$TMP/index.html" <<'PY'
import sys
p = sys.argv[1]
with open(p, encoding="utf-8") as f: html = f.read()
html = html.replace('<meta name="twitter:card" content="summary">', '<meta name="twitter:card" content="summary_large_image">\n<meta property="og:image" content="https://gazobit.ember-burger.ru/preview.webp">')
with open(p, 'w', encoding="utf-8") as f: f.write(html)
PY

cat > "$TMP/nginx.conf" <<'NGINX'
server {
    listen 80;
    server_name gazobit.ember-burger.ru;
    root /var/www/gazobit.ember-burger.ru;
    index index.html;
    charset utf-8;
    autoindex off;
    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy strict-origin-when-cross-origin always;
    location / { try_files $uri $uri/ /index.html; add_header Cache-Control "no-store" always; }
    location = /preview.webp { expires 1d; }
}
NGINX

echo "Creating isolated GAZOBIT site..."
install -d -m 0755 "$ROOT"
install -m 0644 "$TMP/index.html" "$ROOT/index.html.new"
mv -f "$ROOT/index.html.new" "$ROOT/index.html"
install -m 0644 "$TMP/preview.webp" "$ROOT/preview.webp"
install -m 0644 "$TMP/nginx.conf" "$CONF"
ln -s "$CONF" "$ENABLED"
if ! nginx -t; then
  rm -f "$ENABLED" "$CONF"
  echo "New Nginx configuration rolled back; Ember Burger unchanged." >&2
  exit 1
fi
systemctl reload nginx
echo "GAZOBIT installed over HTTP."

if ! command -v certbot >/dev/null 2>&1; then
  echo "Certbot missing. HTTPS was not configured. Install certbot and python3-certbot-nginx first." >&2
  exit 0
fi
if ! getent ahostsv4 "$DOMAIN" | awk '{print $1}' | grep -Fxq "193.124.67.26"; then
  echo "DNS is not resolving to 193.124.67.26 yet. HTTPS can be enabled later with:"
  echo "certbot --nginx -d $DOMAIN --redirect"
  exit 0
fi

echo "Requesting a dedicated HTTPS certificate..."
if certbot --nginx --non-interactive --agree-tos --register-unsafely-without-email --redirect -d "$DOMAIN"; then
  nginx -t
  systemctl reload nginx
  echo "SUCCESS https://$DOMAIN"
else
  echo "HTTP deployment is complete, but HTTPS failed. Retry later:"
  echo "certbot --nginx -d $DOMAIN --redirect"
  exit 1
fi

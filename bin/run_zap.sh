#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

APP_URL="http://localhost:3000"
ZAP_TARGET="http://host.docker.internal:3000"
SWAGGER_SRC="swagger/v1/swagger.json"
ZAP_SPEC="tmp/zap_openapi.json"
REPORT_FILE="tmp/zap_report.html"
LOGIN_EMAIL="admin@oficina.local"
LOGIN_PASSWORD="oficina123"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}ℹ ${NC}$1"; }
log_success() { echo -e "${GREEN}✓ ${NC}$1"; }
log_warn()    { echo -e "${YELLOW}⚠ ${NC}$1"; }
log_error()   { echo -e "${RED}✗ ${NC}$1"; }

COMMAND="${1:-scan}"

case "$COMMAND" in
  scan)
    log_info "Starting OWASP ZAP API scan..."
    ;;
  report)
    if [ ! -f "$REPORT_FILE" ]; then
      log_error "No report found at $REPORT_FILE. Run '$0 scan' first."
      exit 1
    fi
    log_info "Opening ZAP report..."
    if command -v open &>/dev/null; then
      open "$REPORT_FILE"
    elif command -v xdg-open &>/dev/null; then
      xdg-open "$REPORT_FILE"
    else
      log_warn "Could not open browser. Visit manually: $REPO_ROOT/$REPORT_FILE"
    fi
    exit 0
    ;;
  *)
    cat <<EOF
Usage: $0 [COMMAND]

Commands:
  scan    Run OWASP ZAP API scan against the running app (default)
  report  Open the last generated report in browser

Examples:
  $0 scan    # Run the scan (app must be running)
  $0 report  # Open tmp/zap_report.html in browser
EOF
    exit 0
    ;;
esac

# Step 1: Check the app is running
log_info "Step 1/4: Checking app is running at $APP_URL..."
if ! curl -sf "$APP_URL/up" > /dev/null 2>&1; then
  log_error "App is not running at $APP_URL"
  echo ""
  echo "Start it first with:  docker compose up -d"
  echo "Then re-run:          $0 scan"
  exit 1
fi
log_success "App is up"

# Step 2: Authenticate and get JWT token
log_info "Step 2/4: Authenticating as $LOGIN_EMAIL..."
LOGIN_RESPONSE=$(curl -sf -X POST "$APP_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$LOGIN_EMAIL\",\"password\":\"$LOGIN_PASSWORD\"}" 2>/dev/null || true)

TOKEN=$(python3 -c "
import json, sys
try:
    data = json.loads('''$LOGIN_RESPONSE''')
    print(data.get('access_token', ''))
except Exception:
    print('')
" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  log_error "Failed to obtain JWT token. Check credentials or run 'docker compose run --rm web bin/rails db:seed'."
  exit 1
fi
log_success "JWT token obtained"

# Step 3: Prepare OpenAPI spec with servers section
log_info "Step 3/4: Preparing OpenAPI spec..."
mkdir -p tmp

python3 - <<PYEOF
import json

with open("$SWAGGER_SRC") as f:
    spec = json.load(f)

spec["servers"] = [{"url": "$ZAP_TARGET"}]

with open("$ZAP_SPEC", "w") as f:
    json.dump(spec, f, indent=2)
PYEOF

log_success "Spec written to $ZAP_SPEC"

# Step 4: Run ZAP API scan
log_info "Step 4/4: Running OWASP ZAP API scan (this may take a few minutes)..."

ZAP_AUTH_OPTS="replacer.full_list(0).description=auth"
ZAP_AUTH_OPTS+="&replacer.full_list(0).enabled=true"
ZAP_AUTH_OPTS+="&replacer.full_list(0).matchtype=REQ_HEADER"
ZAP_AUTH_OPTS+="&replacer.full_list(0).matchstr=Authorization"
ZAP_AUTH_OPTS+="&replacer.full_list(0).regex=false"
ZAP_AUTH_OPTS+="&replacer.full_list(0).replacement=Bearer ${TOKEN}"

if docker run --rm \
  -v "${REPO_ROOT}/tmp:/zap/wrk:rw" \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-api-scan.py \
    -t "/zap/wrk/zap_openapi.json" \
    -f openapi \
    -r zap_report.html \
    -I \
    -z "$ZAP_AUTH_OPTS" 2>&1; then
  log_success "ZAP scan complete"
else
  log_warn "ZAP exited with warnings (check the report for details)"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
log_success "OWASP ZAP scan finished!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📊 Report: $REPORT_FILE"
echo ""
echo "Commands:"
echo "  Open report:  $0 report"
echo "  Re-run scan:  $0 scan"
echo ""

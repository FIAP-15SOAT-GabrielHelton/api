#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

COMPOSE_SONAR="compose.sonar.yml"
NETWORK="oficina-mecanica-sonar_sonar"
SONAR_URL="http://localhost:9000"
DASHBOARD_URL="$SONAR_URL/dashboard?id=oficina_mecanica"
ADMIN_USER="admin"
ADMIN_PASS="admin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
log_info() {
  echo -e "${BLUE}ℹ ${NC}$1"
}

log_success() {
  echo -e "${GREEN}✓ ${NC}$1"
}

log_warn() {
  echo -e "${YELLOW}⚠ ${NC}$1"
}

log_error() {
  echo -e "${RED}✗ ${NC}$1"
}

# Check if Docker Compose file exists
if [ ! -f "$COMPOSE_SONAR" ]; then
  log_error "compose.sonar.yml not found in $REPO_ROOT"
  exit 1
fi

# Parse command line arguments
COMMAND="${1:-analyze}"

case "$COMMAND" in
  analyze)
    log_info "Starting SonarQube analysis..."
    ;;
  stop)
    log_info "Stopping SonarQube..."
    docker compose -f "$COMPOSE_SONAR" down -v
    log_success "SonarQube stopped and volumes removed"
    exit 0
    ;;
  dashboard)
    log_info "Opening SonarQube dashboard at $DASHBOARD_URL"
    if command -v open &>/dev/null; then
      open "$DASHBOARD_URL"
    elif command -v xdg-open &>/dev/null; then
      xdg-open "$DASHBOARD_URL"
    else
      log_warn "Could not open browser. Visit manually: $DASHBOARD_URL"
    fi
    exit 0
    ;;
  *)
    cat <<EOF
Usage: $0 [COMMAND]

Commands:
  analyze      Run SonarQube analysis (default)
  stop         Stop SonarQube server and remove volumes
  dashboard    Open SonarQube dashboard in browser

Examples:
  $0 analyze      # Start server and run analysis
  $0 stop         # Stop the server
  $0 dashboard    # Open the report in browser
EOF
    exit 0
    ;;
esac

# Step 1: Run tests with coverage
log_info "Step 1/5: Generating coverage report..."
if docker compose run --rm web sh -c "COVERAGE=1 bundle exec rspec" > /dev/null 2>&1; then
  log_success "Coverage report generated (coverage/coverage.json)"
else
  log_error "RSpec tests failed"
  exit 1
fi

# Step 2: Start SonarQube
log_info "Step 2/5: Starting SonarQube server..."
docker compose -f "$COMPOSE_SONAR" up sonarqube -d > /dev/null 2>&1
sleep 3
log_success "SonarQube container started"

# Step 3: Wait for server to be ready
log_info "Step 3/5: Waiting for SonarQube to be operational (this may take 30-60s)..."
WAIT_COUNTER=0
MAX_WAIT=60
while [ $WAIT_COUNTER -lt $MAX_WAIT ]; do
  if curl -s "$SONAR_URL/api/system/status" 2>/dev/null | grep -q '"status":"UP"'; then
    log_success "SonarQube is operational"
    break
  fi
  WAIT_COUNTER=$((WAIT_COUNTER + 3))
  sleep 3
  echo -n "."
done

if [ $WAIT_COUNTER -ge $MAX_WAIT ]; then
  log_error "SonarQube startup timed out"
  log_info "Check logs: docker compose -f $COMPOSE_SONAR logs sonarqube"
  exit 1
fi

# Step 4: Generate authentication token
log_info "Step 4/5: Generating authentication token..."
TOKEN=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" \
  -X POST "$SONAR_URL/api/user_tokens/generate?name=scanner" \
  2>/dev/null | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  log_error "Failed to generate token"
  exit 1
fi

log_success "Token generated"

# Step 5: Run sonar-scanner
log_info "Step 5/5: Running SonarQube analysis..."
if docker run --rm \
  --network "$NETWORK" \
  -e SONAR_HOST_URL="http://sonarqube:9000" \
  -e SONAR_TOKEN="$TOKEN" \
  -v "$REPO_ROOT:/usr/src" \
  sonarsource/sonar-scanner-cli:latest > /dev/null 2>&1; then
  log_success "Analysis complete"
else
  log_error "SonarQube analysis failed"
  exit 1
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════════"
log_success "SonarQube analysis finished!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📊 Dashboard: $DASHBOARD_URL"
echo "🔑 Login: $ADMIN_USER / (your password)"
echo ""
echo "Commands:"
echo "  Open dashboard:    $0 dashboard"
echo "  Stop server:       $0 stop"
echo "  Re-run analysis:   $0 analyze"
echo ""

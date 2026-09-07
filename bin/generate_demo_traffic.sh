#!/usr/bin/env bash
set -euo pipefail

# Gera tráfego real contra a API em produção (via API Gateway) para popular os
# dashboards do New Relic com dados de negócio: volume de OS, tempo por etapa
# (diagnóstico/execução/finalização), erros/falhas de processamento e latência.
#
# As durações entre etapas aqui são comprimidas (segundos, via STEP_DELAY) só
# para o script terminar rápido — não representam o tempo real de uma oficina.
#
# Uso:
#   bin/generate_demo_traffic.sh <API_GATEWAY_URL> [CYCLES]
#
# Requisitos: curl, jq. Assume os dados do seed padrão (db/seeds.rb):
# usuários admin/mechanic e clientes João Silva (CPF 12345678909) e
# Maria Souza (CPF 11144477735), cada um com pelo menos 1 veículo cadastrado.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

BASE_URL="${1:-${API_BASE_URL:-}}"
CYCLES="${2:-${CYCLES:-4}}"
STEP_DELAY="${STEP_DELAY:-6}"

ADMIN_EMAIL="${SEED_ADMIN_EMAIL:-admin@oficina.local}"
ADMIN_PASSWORD="${SEED_ADMIN_PASSWORD:-oficina123}"
MECHANIC_EMAIL="${SEED_MECHANIC_EMAIL:-mechanic@oficina.local}"
MECHANIC_PASSWORD="${SEED_MECHANIC_PASSWORD:-oficina123}"
CUSTOMER_CPFS=("12345678909" "11144477735")

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}i ${NC}$1"; }
log_success() { echo -e "${GREEN}v ${NC}$1"; }
log_warn()    { echo -e "${YELLOW}! ${NC}$1"; }
log_error()   { echo -e "${RED}x ${NC}$1"; }

if [ -z "$BASE_URL" ]; then
  log_error "Uso: $0 <API_GATEWAY_URL> [CYCLES]  (ou defina API_BASE_URL)"
  exit 1
fi
BASE_URL="${BASE_URL%/}"

for bin in curl jq; do
  if ! command -v "$bin" &>/dev/null; then
    log_error "'$bin' não encontrado no PATH."
    exit 1
  fi
done

HTTP_STATUS=""
HTTP_BODY=""

# call METHOD PATH [TOKEN] [JSON_BODY] — seta HTTP_STATUS/HTTP_BODY globais.
# Não usa -f: respostas 4xx/5xx são esperadas (falhas deliberadas) e tratadas
# pelo chamador, não devem abortar o script.
call() {
  local method="$1" path="$2" token="${3:-}" body="${4:-}"
  local args=(-sS -X "$method" "${BASE_URL}${path}" -H "Content-Type: application/json")
  [ -n "$token" ] && args+=(-H "Authorization: Bearer $token")
  [ -n "$body" ] && args+=(-d "$body")

  local resp
  resp=$(curl "${args[@]}" -w $'\n%{http_code}')
  HTTP_STATUS="${resp##*$'\n'}"
  HTTP_BODY="${resp%$'\n'*}"
}

expect() {
  local label="$1" expected="$2"
  if [ "$HTTP_STATUS" = "$expected" ]; then
    log_success "$label -> $HTTP_STATUS"
  else
    log_warn "$label -> $HTTP_STATUS (esperado $expected) — body: $(echo "$HTTP_BODY" | head -c 200)"
  fi
}

step() { log_info "  [sleep ${STEP_DELAY}s]"; sleep "$STEP_DELAY"; }

# === Login staff (admin cobre todos os papéis de staff: mechanic/receptionist) ==

log_info "Autenticando staff..."
call POST /api/v1/auth/login "" "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}"
expect "login admin" 200
ADMIN_TOKEN=$(echo "$HTTP_BODY" | jq -r '.access_token')

call POST /api/v1/auth/login "" "{\"email\":\"$MECHANIC_EMAIL\",\"password\":\"$MECHANIC_PASSWORD\"}"
expect "login mechanic (só para obter o id)" 200
MECHANIC_ID=$(echo "$HTTP_BODY" | jq -r '.user.id')
log_info "mechanic_id=$MECHANIC_ID"

# Catálogo (staff) — usado para montar os itens de linha das OS.
call GET /api/v1/services "$ADMIN_TOKEN"
SERVICE_ID=$(echo "$HTTP_BODY" | jq -r '.[0].id')
call GET /api/v1/inventory_items "$ADMIN_TOKEN"
PART_ID=$(echo "$HTTP_BODY" | jq -r '.[0].id')
log_info "service_id=$SERVICE_ID part_id=$PART_ID"

PROTOCOLS=()

fail_scenarios=0
run_failure_scenario() {
  local n=$((fail_scenarios % 5))
  fail_scenarios=$((fail_scenarios + 1))
  case "$n" in
    0)
      call GET /api/v1/work_orders/999999999 "$ADMIN_TOKEN"
      expect "falha proposital: OS inexistente" 404
      ;;
    1)
      call POST /api/v1/auth/login "" "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"senha-errada\"}"
      expect "falha proposital: login com senha errada" 401
      ;;
    2)
      call POST /api/v1/auth/customer "" '{"cpf":"00000000000"}'
      expect "falha proposital: CPF inválido" 422
      ;;
    3)
      call GET /api/v1/admin/metrics "$CUSTOMER_TOKEN"
      expect "falha proposital: customer acessando rota admin" 403
      ;;
    4)
      # $WO_ID (se já setado) está delivered/completed — transição inválida.
      call PATCH "/api/v1/work_orders/${WO_ID:-0}/diagnose" "$ADMIN_TOKEN"
      expect "falha proposital: transição de status inválida" 422
      ;;
  esac
}

for i in $(seq 1 "$CYCLES"); do
  echo ""
  log_info "=== Ciclo $i/$CYCLES ==="

  cpf="${CUSTOMER_CPFS[$(( (i - 1) % 2 ))]}"
  call POST /api/v1/auth/customer "" "{\"cpf\":\"$cpf\"}"
  expect "auth customer ($cpf)" 200
  CUSTOMER_TOKEN=$(echo "$HTTP_BODY" | jq -r '.access_token')
  CUSTOMER_ID=$(echo "$HTTP_BODY" | jq -r '.customer.id')

  call GET /api/v1/vehicles "$CUSTOMER_TOKEN"
  VEHICLE_ID=$(echo "$HTTP_BODY" | jq -r '.[0].id')

  # Falha proposital antes de criar a OS de verdade (mantém o volume "real" limpo).
  run_failure_scenario

  call POST /api/v1/work_orders "$CUSTOMER_TOKEN" \
    "{\"customer_id\":$CUSTOMER_ID,\"vehicle_id\":$VEHICLE_ID,\"problem_description\":\"Revisao de demonstracao (script de observabilidade) - ciclo $i\"}"
  expect "criar OS" 201
  WO_ID=$(echo "$HTTP_BODY" | jq -r '.id')
  PROTOCOL=$(echo "$HTTP_BODY" | jq -r '.protocol')
  PROTOCOLS+=("$PROTOCOL")
  log_info "OS criada: id=$WO_ID protocol=$PROTOCOL (received)"

  call PATCH "/api/v1/work_orders/$WO_ID/assign" "$ADMIN_TOKEN" "{\"mechanic_id\":$MECHANIC_ID}"
  expect "assign" 200

  call POST "/api/v1/work_orders/$WO_ID/line_items" "$ADMIN_TOKEN" \
    "{\"item_type\":\"service\",\"reference_id\":$SERVICE_ID,\"quantity\":1}"
  expect "add_line_item (service)" 201

  call POST "/api/v1/work_orders/$WO_ID/line_items" "$ADMIN_TOKEN" \
    "{\"item_type\":\"part\",\"reference_id\":$PART_ID,\"quantity\":1}"
  expect "add_line_item (part)" 201
  step

  call PATCH "/api/v1/work_orders/$WO_ID/diagnose" "$ADMIN_TOKEN"
  expect "diagnose (gera evento de duracao: diagnostico)" 200

  call GET "/api/v1/work_orders/$WO_ID" "$ADMIN_TOKEN"
  QUOTE_ID=$(echo "$HTTP_BODY" | jq -r '.quote.id')

  call PATCH "/api/v1/quotes/$QUOTE_ID/send_to_customer" "$ADMIN_TOKEN"
  expect "send_to_customer" 200

  call PATCH "/api/v1/quotes/$QUOTE_ID/approve" "$CUSTOMER_TOKEN"
  expect "approve quote (cliente)" 200

  call PATCH "/api/v1/work_orders/$WO_ID/execute" "$ADMIN_TOKEN"
  expect "execute" 200

  SERVICE_LINE_ITEM_ID=$(echo "$HTTP_BODY" | jq -r '.line_items[] | select(.item_type=="service") | .id' | head -n1)
  call PATCH "/api/v1/work_orders/$WO_ID/line_items/$SERVICE_LINE_ITEM_ID/start" "$ADMIN_TOKEN"
  expect "start_line_item" 200
  step

  # Finalizar o único item de serviço já completa a OS automaticamente
  # (WorkOrders::FinishLineItemService#perform), gerando o evento de duracao: execucao.
  call PATCH "/api/v1/work_orders/$WO_ID/line_items/$SERVICE_LINE_ITEM_ID/finish" "$ADMIN_TOKEN"
  expect "finish_line_item (gera evento de duracao: execucao)" 200
  step

  call PATCH "/api/v1/work_orders/$WO_ID/deliver" "$ADMIN_TOKEN"
  expect "deliver (gera evento de duracao: finalizacao)" 200

  # Tráfego de leitura extra (varia a latência amostrada, exercita a rota
  # pública de tracking via HTTP_PROXY).
  call GET /api/v1/work_orders "$ADMIN_TOKEN"
  call GET "/api/v1/tracking/$PROTOCOL" ""
  expect "tracking público" 200
done

log_info "Verificando healthcheck público algumas vezes..."
for _ in 1 2 3; do
  call GET /up ""
  expect "healthcheck /up" 200
  sleep 2
done

echo ""
log_success "Concluído. OS criadas/completadas: ${PROTOCOLS[*]}"
log_info "Os dados levam ~1-3 minutos para aparecer no New Relic (APM/eventos) e ~1 minuto para métricas de Kubernetes (nri-kubernetes)."

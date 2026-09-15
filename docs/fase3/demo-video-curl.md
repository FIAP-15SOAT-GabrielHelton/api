# Roteiro cURL — Vídeo demonstrativo (Fase 3)

Comandos prontos para os blocos **1** (Auth por CPF + JWT) e **2** (Consumo de APIs protegidas + RBAC) do roteiro de gravação. Copie e cole em sequência durante a gravação.

Assume os dados do seed padrão (`db/seeds.rb`): cliente **João Silva** (CPF `12345678909`) e usuário staff `admin@oficina.local`/`oficina123`.

Defina a URL base uma vez (a URL pública do **API Gateway**, repositório `auth-serverless` — não a do Service do Kubernetes):

```bash
export API_URL="<URL_DO_API_GATEWAY>"
```

---

## Bloco 1 — Autenticação por CPF e geração do JWT

### 1.1 Autentica com CPF válido e recebe o JWT

```bash
AUTH_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/auth/customer" \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678909"}')

echo "$AUTH_RESPONSE" | jq

export CUSTOMER_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.access_token')
export CUSTOMER_ID=$(echo "$AUTH_RESPONSE" | jq -r '.customer.id')
```

### 1.2 CPF com checksum inválido — rejeitado antes de consultar o banco

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" -X POST "$API_URL/api/v1/auth/customer" \
  -H "Content-Type: application/json" \
  -d '{"cpf":"00000000000"}'
```

---

## Bloco 2 — Consumo de APIs protegidas e RBAC

### 2.1 Rota protegida chamada sem token

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" "$API_URL/api/v1/vehicles"
```

### 2.2 Cria uma Ordem de Serviço usando o JWT do cliente

```bash
export VEHICLE_ID=$(curl -s "$API_URL/api/v1/vehicles" \
  -H "Authorization: Bearer $CUSTOMER_TOKEN" | jq -r '.[0].id')

curl -s -X POST "$API_URL/api/v1/work_orders" \
  -H "Authorization: Bearer $CUSTOMER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"customer_id\":$CUSTOMER_ID,\"vehicle_id\":$VEHICLE_ID,\"problem_description\":\"Demonstracao em video - ruido no motor\"}" | jq
```

### 2.3 Cliente autenticado tentando acessar rota exclusiva de admin

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" "$API_URL/api/v1/admin/metrics" \
  -H "Authorization: Bearer $CUSTOMER_TOKEN"
```

### 2.4 (Bônus, se der tempo) Mesma rota, agora com token de admin

```bash
export ADMIN_TOKEN=$(curl -s -X POST "$API_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@oficina.local","password":"oficina123"}' | jq -r '.access_token')

curl -s "$API_URL/api/v1/admin/metrics" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq
```

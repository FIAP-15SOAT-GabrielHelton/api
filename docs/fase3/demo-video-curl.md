# Roteiro cURL — Vídeo demonstrativo (Fase 3)

Comandos prontos para os blocos **1** (Auth por CPF + JWT) e **2** (Consumo de APIs protegidas + RBAC) do roteiro de gravação. Copie e cole em sequência durante a gravação — não precisa digitar nada na hora.

Assume os dados do seed padrão (`db/seeds.rb`): cliente **João Silva** (CPF `12345678909`) e usuário staff `admin@oficina.local`/`oficina123`.

Defina a URL base uma vez (a URL pública do **API Gateway**, repositório `auth-serverless` — não a do Service do Kubernetes):

```bash
export API_URL="<URL_DO_API_GATEWAY>"
```

---

## Bloco 1 — Autenticação por CPF e geração do JWT

### 1.1 Autenticar com CPF válido → recebe o JWT

```bash
curl -s -X POST "$API_URL/api/v1/auth/customer" \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678909"}' | jq
```

**O que apontar:** a Lambda `auth_customer` validou o CPF, consultou o status do cliente no Rails e devolveu `access_token` (JWT) + os dados do cliente. Copie o token da resposta:

```bash
AUTH_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/auth/customer" \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678909"}')

export CUSTOMER_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.access_token')
export CUSTOMER_ID=$(echo "$AUTH_RESPONSE" | jq -r '.customer.id')

echo "token=$CUSTOMER_TOKEN customer_id=$CUSTOMER_ID"
```

### 1.2 Falha proposital — CPF inválido → 422

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" -X POST "$API_URL/api/v1/auth/customer" \
  -H "Content-Type: application/json" \
  -d '{"cpf":"00000000000"}'
```

**O que apontar:** validação do checksum do CPF acontece antes de qualquer chamada ao Rails — falha rápido, sem consultar o banco.

---

## Bloco 2 — Consumo de APIs protegidas e RBAC

### 2.1 Rota protegida sem token → 401

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" "$API_URL/api/v1/vehicles"
```

### 2.2 Com o JWT do cliente → 200 (cria uma Ordem de Serviço)

```bash
export VEHICLE_ID=$(curl -s "$API_URL/api/v1/vehicles" \
  -H "Authorization: Bearer $CUSTOMER_TOKEN" | jq -r '.[0].id')

curl -s -X POST "$API_URL/api/v1/work_orders" \
  -H "Authorization: Bearer $CUSTOMER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"customer_id\":$CUSTOMER_ID,\"vehicle_id\":$VEHICLE_ID,\"problem_description\":\"Demonstracao em video - ruido no motor\"}" | jq
```

**O que apontar:** o mesmo JWT emitido no Bloco 1 autoriza a criação da OS — sem novo login.

### 2.3 Cliente tentando acessar rota administrativa (staff-only) → 403

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" "$API_URL/api/v1/admin/metrics" \
  -H "Authorization: Bearer $CUSTOMER_TOKEN"
```

**O que apontar:** o JWT é válido (não é 401), mas o papel (`customer`) não tem permissão para essa rota — RBAC bloqueando, não autenticação.

### 2.4 (Bônus, se der tempo) Staff admin acessando a mesma rota → 200

```bash
export ADMIN_TOKEN=$(curl -s -X POST "$API_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@oficina.local","password":"oficina123"}' | jq -r '.access_token')

curl -s "$API_URL/api/v1/admin/metrics" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq
```

**O que apontar:** mesma rota, token de papel diferente (`admin`) → 200. Fecha a demonstração de RBAC com o contraste 403 vs. 200.

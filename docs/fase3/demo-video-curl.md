# Demo Walkthrough — Autenticação por CPF, JWT e RBAC (Fase 3)

Este walkthrough cobre a autenticação de clientes por CPF (via `auth-serverless`) e o controle de acesso por papel (RBAC) nas rotas protegidas da API. Para o ciclo de vida completo de uma Ordem de Serviço, veja [`docs/fase1/demo.md`](../fase1/demo.md) e [`docs/fase2/demo.md`](../fase2/demo.md).

Os dados usados são os do seed padrão (`db/seeds.rb`): o cliente **João Silva** (CPF `12345678909`) e o usuário staff `admin@oficina.local`/`oficina123`.

Defina a URL base uma vez — a URL pública do **API Gateway** (repositório `auth-serverless`), não a do Service do Kubernetes:

```bash
export API_URL="<URL_DO_API_GATEWAY>"
```

## Autenticação por CPF

A autenticação de clientes não passa por login com senha: o cliente informa o CPF, a função serverless valida o formato/checksum, consulta a existência e o status do cliente na API Rails e, se autorizado, devolve um JWT.

```bash
AUTH_RESPONSE=$(curl -s -X POST "$API_URL/api/v1/auth/customer" \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678909"}')

echo "$AUTH_RESPONSE" | jq

export CUSTOMER_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.access_token')
export CUSTOMER_ID=$(echo "$AUTH_RESPONSE" | jq -r '.customer.id')
```

A resposta traz o `access_token` (JWT) e os dados do cliente. Os comandos acima já guardam o token e o id em variáveis de ambiente para uso nos próximos passos.

Um CPF com checksum inválido é rejeitado antes de qualquer consulta ao banco:

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" -X POST "$API_URL/api/v1/auth/customer" \
  -H "Content-Type: application/json" \
  -d '{"cpf":"00000000000"}'
```

## Consumo de APIs protegidas e RBAC

Toda rota da API (exceto autenticação, healthcheck e tracking público) exige um JWT válido. Chamar sem token retorna `401`:

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" "$API_URL/api/v1/vehicles"
```

Com o JWT do cliente, é possível listar os próprios veículos e abrir uma Ordem de Serviço — o mesmo token emitido na autenticação por CPF é reutilizado, sem novo login:

```bash
export VEHICLE_ID=$(curl -s "$API_URL/api/v1/vehicles" \
  -H "Authorization: Bearer $CUSTOMER_TOKEN" | jq -r '.[0].id')

curl -s -X POST "$API_URL/api/v1/work_orders" \
  -H "Authorization: Bearer $CUSTOMER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"customer_id\":$CUSTOMER_ID,\"vehicle_id\":$VEHICLE_ID,\"problem_description\":\"Ruido no motor ao acelerar\"}" | jq
```

Nem toda rota protegida está liberada para qualquer papel autenticado. `/api/v1/admin/metrics` exige o papel `admin`; um cliente autenticado recebe `403` (token válido, mas sem permissão — diferente do `401` de token ausente/inválido):

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" "$API_URL/api/v1/admin/metrics" \
  -H "Authorization: Bearer $CUSTOMER_TOKEN"
```

Com um token de staff com papel `admin`, a mesma rota responde `200`:

```bash
export ADMIN_TOKEN=$(curl -s -X POST "$API_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@oficina.local","password":"oficina123"}' | jq -r '.access_token')

curl -s "$API_URL/api/v1/admin/metrics" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq
```

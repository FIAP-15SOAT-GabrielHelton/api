# Demo Walkthrough — Fase 2 (endpoints refatorados e adicionados)

Este walkthrough cobre só o que mudou nesta fase: abertura de OS já com serviços/peças, listagem priorizada, rejeição direta de OS e os webhooks públicos de aprovação/recusa de orçamento. Para o ciclo de vida completo de uma OS (login, diagnóstico, execução, entrega), veja [`docs/fase1/demo.md`](../fase1/demo.md).

Os dados de demo (clientes, veículos, catálogo) são criados pelo `db:seed`. Os comandos usam `customer_id=2` (Maria Souza), `vehicle_id=3` (Toyota Corolla) e `mechanic_id=2` (Default Mechanic) — mesmos IDs do walkthrough da Fase 1. Confirme os IDs reais no resumo impresso pelo seed.

Para os passos de webhook (6 e 7), copie `.env.example` para `.env` e garanta um valor em `QUOTE_WEBHOOK_TOKEN` — é o mesmo valor usado abaixo como `<WEBHOOK_TOKEN>`.

---

## 1. Login — obtém o `access_token` de staff

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@oficina.local","password":"oficina123"}'
```

Copie o `access_token` da resposta. Os próximos passos autenticados por staff usam `Authorization: Bearer <TOKEN>`.

## 2. Abrir OS já com serviços e peças na criação

Antes, `line_items` só entravam depois de aberta a OS. Agora `POST /api/v1/work_orders` aceita `line_items` já no corpo da criação:

```bash
curl -X POST http://localhost:3000/api/v1/work_orders \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": 2,
    "vehicle_id": 3,
    "problem_description": "Carro morrendo no semáforo, possível problema na injeção eletrônica.",
    "line_items": [
      {"item_type": "service", "reference_id": 5, "quantity": 1},
      {"item_type": "part", "reference_id": 8, "quantity": 4}
    ]
  }'
```

Anote o `data.id` como `<WORK_ORDER_ID>`. A OS abre como `received`, já com os `line_items` anexados — chamar sem `line_items` continua funcionando como antes.

> Confirme os IDs reais de serviço/peça via `GET /api/v1/services` e `GET /api/v1/inventory_items`.

## 3. Listar OS — ordenada por prioridade, sem `completed`/`delivered`

```bash
curl http://localhost:3000/api/v1/work_orders \
  -H "Authorization: Bearer <TOKEN>"
```

A listagem agora ordena por prioridade operacional (`in_progress → awaiting_approval → diagnosing → received`, mais antigas primeiro) e oculta OS `completed`/`delivered` do resultado padrão.

## 4. Rejeitar OS diretamente — `received`/`diagnosing` → `rejected` (endpoint novo)

```bash
curl -X PATCH http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/reject \
  -H "Authorization: Bearer <TOKEN>"
```

Use o `<WORK_ORDER_ID>` do passo 2 — ele segue em `received`. Esse endpoint é para o staff registrar uma recusa sem passar pelo fluxo de orçamento.

## 5. Preparar um orçamento para os testes de webhook

Os passos abaixo (assumir, diagnosticar, enviar orçamento) não mudaram na Fase 2 — veja [`docs/fase1/demo.md`](../fase1/demo.md) para detalhes. Abra uma nova OS para não reaproveitar a que foi rejeitada no passo 4:

```bash
curl -X POST http://localhost:3000/api/v1/work_orders \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"customer_id": 2, "vehicle_id": 3, "problem_description": "Revisão geral."}'
# anote o novo <WORK_ORDER_ID>

curl -X PATCH http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/assign \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"mechanic_id": 2}'

curl -X POST http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/line_items \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"item_type":"part","reference_id":8,"quantity":4}'

curl -X PATCH http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/diagnose \
  -H "Authorization: Bearer <TOKEN>"

curl http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID> \
  -H "Authorization: Bearer <TOKEN>"
# anote o "quote": { "id": ... } como <QUOTE_ID>

curl -X PATCH http://localhost:3000/api/v1/quotes/<QUOTE_ID>/send_to_customer \
  -H "Authorization: Bearer <TOKEN>"
```

O orçamento agora está `sent`, pronto para os passos 6/7.

## 6. Aprovar orçamento via webhook externo (endpoint novo)

Diferente do `PATCH /api/v1/quotes/:id/approve` (staff, exige JWT), este endpoint é público e pensado para um sistema externo (ex.: quem coletou a resposta do cliente por e-mail/WhatsApp) reportar a aprovação. Autenticação é um segredo estático no header `X-Webhook-Token` — sem JWT:

```bash
curl -X PATCH http://localhost:3000/api/v1/webhooks/quotes/<QUOTE_ID>/approve \
  -H "X-Webhook-Token: <WEBHOOK_TOKEN>"
```

Por trás, o webhook delega para o mesmo use case `Quotes::ApproveQuote` usado pelo endpoint de staff: o orçamento vira `approved`, a OS transiciona `awaiting_approval → approved` e o estoque é decrementado — nenhuma regra de negócio é duplicada no adapter.

## 7. Recusar orçamento via webhook externo

Mesma rota, ação de recusa — repita o passo 5 até `send_to_customer` para ter um novo orçamento em `sent` e chame:

```bash
curl -X PATCH http://localhost:3000/api/v1/webhooks/quotes/<QUOTE_ID>/reject \
  -H "X-Webhook-Token: <WEBHOOK_TOKEN>"
```

Sem o header (ou com um token errado), a resposta é `401`:

```bash
curl -X PATCH http://localhost:3000/api/v1/webhooks/quotes/<QUOTE_ID>/reject
```

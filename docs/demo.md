# Demo Walkthrough — Ciclo de vida de uma OS

Os comandos abaixo cobrem o fluxo completo de uma Ordem de Serviço, da abertura à finalização.

Os dados de demo (clientes, veículos, catálogo) são criados pelo `db:seed`. Ao final do seed o terminal imprime um resumo com IDs e protocols. Os comandos usam `customer_id=2` (Maria Souza), `vehicle_id=3` (Toyota Corolla) e `mechanic_id=2` (Default Mechanic) — todos válidos para um banco recém-criado. Confirme os IDs reais no resumo impresso pelo seed.

---

## 1. Login — obtém o `access_token`

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@oficina.local","password":"oficina123"}'
```

Copie o `access_token` da resposta. Os próximos passos usam `Authorization: Bearer <TOKEN>`.

## 2. (Opcional) Inspecionar dados pré-carregados

```bash
curl http://localhost:3000/api/v1/services           -H "Authorization: Bearer <TOKEN>"
curl http://localhost:3000/api/v1/inventory_items    -H "Authorization: Bearer <TOKEN>"
curl http://localhost:3000/api/v1/work_orders        -H "Authorization: Bearer <TOKEN>"
curl http://localhost:3000/api/v1/admin/metrics      -H "Authorization: Bearer <TOKEN>"
```

## 3. Criar OS — status `received`

```bash
curl -X POST http://localhost:3000/api/v1/work_orders \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": 2,
    "vehicle_id": 3,
    "problem_description": "Carro morrendo no semáforo, possível problema na injeção eletrônica."
  }'
```

Anote o `data.id` como `<WORK_ORDER_ID>`.

## 4. Mecânico assume a OS — `received` → `diagnosing`

```bash
curl -X PATCH http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/assign \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"mechanic_id": 2}'
```

## 5. Adicionar serviços e peças

```bash
# Serviço: Diagnóstico eletrônico (reference_id=5)
curl -X POST http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/line_items \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"item_type":"service","reference_id":5,"quantity":1}'

# Peça: Velas de ignição (reference_id=8, qty=4)
curl -X POST http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/line_items \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"item_type":"part","reference_id":8,"quantity":4}'
```

> Confirme os IDs reais via `GET /api/v1/services` e `GET /api/v1/inventory_items` (passo 2).

## 6. Diagnosticar — `diagnosing` → `awaiting_approval` (cria Quote automaticamente)

```bash
curl -X PATCH http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/diagnose \
  -H "Authorization: Bearer <TOKEN>"
```

Consulte os detalhes da OS — o campo `"quote": { "id": ... }` está aninhado na resposta:

```bash
curl http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID> \
  -H "Authorization: Bearer <TOKEN>"
```

Na resposta, procure o objeto `"quote"` e anote o `id` como `<QUOTE_ID>` (não confundir com o `id` dos `line_items`, que ficam listados antes).

## 7. Enviar orçamento ao cliente — Quote `created` → `sent`

```bash
curl -X PATCH http://localhost:3000/api/v1/quotes/<QUOTE_ID>/send_to_customer \
  -H "Authorization: Bearer <TOKEN>"
```

## 8. Cliente aprova — Quote `approved`, OS `awaiting_approval` → `approved`, estoque decrementado

```bash
curl -X PATCH http://localhost:3000/api/v1/quotes/<QUOTE_ID>/approve \
  -H "Authorization: Bearer <TOKEN>"
```

## 9. Iniciar execução — `approved` → `in_progress`

```bash
curl -X PATCH http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/execute \
  -H "Authorization: Bearer <TOKEN>"
```

## 10. Iniciar e finalizar cada serviço (registra duração)

Para cada `line_item` com `item_type: service`:

```bash
curl -X PATCH http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/line_items/<LINE_ITEM_ID>/start \
  -H "Authorization: Bearer <TOKEN>"

curl -X PATCH http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/line_items/<LINE_ITEM_ID>/finish \
  -H "Authorization: Bearer <TOKEN>"
```

Quando o último serviço é finalizado, a OS transiciona automaticamente para `completed`.

## 11. Consulta pública pelo `protocol` (sem autenticação)

```bash
curl http://localhost:3000/api/v1/tracking/<PROTOCOL>
```

## 12. Métricas administrativas

```bash
curl http://localhost:3000/api/v1/admin/metrics \
  -H "Authorization: Bearer <TOKEN>"
```

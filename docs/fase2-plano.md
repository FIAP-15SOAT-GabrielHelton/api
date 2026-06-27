# Plano — Tech Challenge Fase 2 (Oficina Mecânica)

## Contexto

A aplicação da Fase 1 (Rails 8.1 API-only, Ruby 3.4.9, PostgreSQL 17, DDD em camadas,
97 testes RSpec com 80% de cobertura, CI/CD para AWS ECS) precisa evoluir para a Fase 2,
que cobre **60% da nota** de todas as disciplinas. O foco da Fase 2 é qualidade/resiliência/
escalabilidade via infraestrutura moderna.

**Boa notícia:** a base arquitetural já atende grande parte dos requisitos de "Evolução da
aplicação" (Clean Architecture/DDD em camadas, testes automatizados, APIs de OS). Os **gaps
reais** são, em ordem de esforço:

1. **Infraestrutura nova:** Kubernetes (`/k8s`) + Terraform (`/infra`) + migração do CD de ECS → K8s.
2. **Notificação de status por e-mail** (mailers hoje vazios).
3. **Ajuste da listagem de OS** para a ordenação/exclusão exigidas pelo PDF.
4. **Entregáveis:** README, diagrama de arquitetura, vídeo, PDF no portal.

**Decisões tomadas:** Cluster **AWS EKS** via Terraform; banco **RDS gerenciado**;
CD **substitui** o deploy ECS por deploy K8s; e-mail via **SendGrid** (API key como Secret).

---

## Parte A — Evolução da aplicação (Rails)

### A1. Listagem de OS conforme spec (ajuste)
O requisito exige ordenação específica e exclusão lógica que **hoje não existem**.
- **Estado atual:** `WorkOrders::ListWorkOrders` + `ActiveRecordWorkOrderRepository#search`
  ordenam por `created_at: :desc` e **não** excluem finalizadas/entregues
  (`app/application/work_orders/list_work_orders.rb`,
  `app/infrastructure/persistence/work_orders/active_record_work_order_repository.rb:41`).
- **Mudança:** no `#search`, quando não houver filtro de status explícito:
  - Excluir (lógica, via `where.not(status: %w[completed delivered])`) — não apagar.
  - Ordenar por **prioridade de status**: `in_progress > awaiting_approval > diagnosing > received`
    (usar `ORDER BY CASE status ...` ou array de prioridade), e em seguida `created_at: :asc`
    (mais antigas primeiro).
- Manter paginação atual. Adicionar testes em `spec/infrastructure/...repository` e
  `spec/application/work_orders/list_work_orders_spec.rb`.

### A2. Notificação de status via e-mail com SendGrid (novo)
Requisito obrigatório: "Atualização de status da OS via alguma ferramenta como e-mail".
**Provedor escolhido: SendGrid.** A API key do SendGrid é o "token de serviço externo" que o PDF
cita como exemplo para **K8s Secret** — então notificação + Secret se reforçam (mata dois requisitos).
- Criar `app/mailers/work_order_mailer.rb` (herda de `ApplicationMailer`, hoje só base em
  `app/mailers/application_mailer.rb`) com método `status_changed(work_order, customer_email)`.
- Criar template em `app/views/work_order_mailer/status_changed.{html,text}.erb`.
- **Integração SendGrid via SMTP** (não precisa de SDK): ActionMailer `delivery_method = :smtp`
  apontando para `smtp.sendgrid.net` (porta 587, user `apikey`, senha = API key). Alternativa:
  gem `sendgrid-ruby` — preferir SMTP por ser mais simples e padrão Rails.
- Disparo **assíncrono** via Solid Queue (já configurado, serviço `jobs` no compose):
  `WorkOrderMailer.status_changed(...).deliver_later`.
- **Ponto de gatilho:** chamar nas transições de status. Para não acoplar mailer ao domínio puro,
  disparar na **camada de aplicação** (use cases que mudam status: `DiagnoseWorkOrder`,
  `ApproveQuote`/`ApproveWorkOrder`, `CompleteWorkOrder`, `DeliverWorkOrder`) ou num
  `Notifier` injetado por DI seguindo o padrão atual de injeção dos controllers.
  Recomendado: criar `Application::Shared::WorkOrderNotifier` injetável, default em produção
  e mockável nos testes — preserva pureza do domínio.
- **Config por ambiente:**
  - Produção/K8s: SMTP SendGrid, `SENDGRID_API_KEY` lido de **K8s Secret** (nunca commitar);
    remetente (`MAILER_FROM`) verificado no SendGrid (Single Sender ou domínio).
  - Dev local: pode usar `letter_opener`/log ou a mesma key SendGrid via `.env` — sem expor key no git.
- **Pré-requisito operacional (fora do código):** criar conta SendGrid, gerar API key e
  **verificar o remetente** (Single Sender Verification) para os e-mails saírem. Free tier ~100/dia.
- Testes: `spec/mailers/work_order_mailer_spec.rb` + asserts de `have_enqueued_mail` nos use cases
  (sem chamar a API real — usar `ActionMailer::Base.delivery_method = :test` no ambiente de teste).

### A3. Aprovação de orçamento (verificar/expor)
- Já existe `PATCH /api/v1/quotes/:id/approve` e `/reject`
  (`app/controllers/api/v1/quotes_controller.rb`). Isso satisfaz "receber notificações externas
  de aprovação/recusa".
- **Ação:** confirmar que esses endpoints aceitam chamada externa (ex.: token de serviço externo
  guardado em Secret) e documentar como webhook no README/Swagger. Sem reescrita de lógica.

### A4. Clean Code / Arquitetura / Testes
- Arquitetura DDD em camadas já satisfaz "Clean Architecture/Hexagonal". **Não refatorar a esmo.**
- Garantir que toda feature nova mantenha cobertura ≥80% (enforced pela CI) e passe RuboCop.

---

## Parte B — Infraestrutura

### B1. Docker (revisão leve)
- `Dockerfile` (prod, multi-stage) e `compose.yml` já existem e estão bons.
- Revisar variáveis de ambiente para apontar ao RDS em produção (host via Secret).
- Confirmar `docker-compose` (`compose.yml`) cobre dev local (db + web + jobs) — já cobre.

### B2. Kubernetes — `/k8s` (novo)
Criar manifestos YAML:
- `k8s/namespace.yaml`
- `k8s/configmap.yaml` — vars não sensíveis (RAILS_ENV, RAILS_LOG_TO_STDOUT, etc).
- `k8s/secret.yaml` (template/exemplo, valores reais via CI) — `RAILS_MASTER_KEY`,
  credenciais RDS, **`SENDGRID_API_KEY`** (token de serviço externo, exemplo literal do PDF),
  token de aprovação externa.
- `k8s/web-deployment.yaml` + `k8s/web-service.yaml` (ClusterIP/LoadBalancer) — app Rails (porta 80/3000).
  Incluir `readiness`/`liveness` probes em `/up` (endpoint já existe em `routes.rb:6`).
  Definir `resources.requests/limits` de CPU/memória (necessário para HPA).
- `k8s/jobs-deployment.yaml` — worker Solid Queue (`bin/jobs`).
- `k8s/hpa.yaml` — HorizontalPodAutoscaler do web, escalando por CPU (ex.: min 2, max 10, target 60% CPU).
- `k8s/migrate-job.yaml` — Job para `bin/rails db:prepare` (migrações no deploy).
- **DB:** RDS gerenciado (não roda no cluster). App acessa via Secret com host/credenciais.
- **Pré-requisito p/ HPA:** metrics-server (EKS) — instalar via Terraform/Helm ou manifesto.

### B3. Terraform — `/infra` (novo)
Provider `aws`. Recursos:
- `infra/vpc.tf` — VPC, subnets públicas/privadas (ou usar módulo `terraform-aws-modules/vpc`).
- `infra/eks.tf` — cluster EKS + managed node group (módulo `terraform-aws-modules/eks`).
- `infra/rds.tf` — PostgreSQL gerenciado (instância, subnet group, security group).
- `infra/ecr.tf` — reaproveitar/declarar o repositório ECR `oficina-mecanica` já usado no CD.
- `infra/addons.tf` — metrics-server (HPA) e demais add-ons via Helm/provider kubernetes.
- `infra/variables.tf`, `outputs.tf` (endpoint do cluster, endpoint RDS), `versions.tf`, `backend.tf`.
- **Documentar** em `/infra/README.md`: recursos criados, ordem de `terraform init/plan/apply`,
  variáveis necessárias, custo/cuidados (EKS+RDS geram custo — destruir após o vídeo).

### B4. CI/CD — substituir ECS por K8s
- **CI** (`.github/workflows/ci.yml`) já faz scan/lint/test com coverage 80% — manter.
- **CD** (`.github/workflows/cd.yml`): reescrever os passos de deploy ECS para:
  1. Build da aplicação + execução de testes (ou depender do CI verde, como hoje).
  2. Build/push da imagem Docker para **ECR** (manter OIDC `vars.AWS_ROLE_ARN`, region us-east-1).
  3. `aws eks update-kubeconfig` para autenticar no cluster.
  4. Aplicar Secrets (a partir de GitHub Secrets) + `kubectl apply -f k8s/`.
  5. Rodar Job de migração do banco (`db:prepare`).
  6. `kubectl rollout status` (web + jobs) para aguardar estabilidade.
- Remover os passos específicos de ECS (`ecs-render-task-definition`, `ecs-deploy-task-definition`,
  svc-web/svc-jobs) do `cd.yml`.

---

## Parte C — Entregáveis e documentação

- **README.md:** atualizar para Fase 2 — descrição/objetivos, **diagrama de arquitetura**
  (componentes da app, infra provisionada EKS/RDS/ECR, fluxo de deploy CI→CD→K8s), instruções de
  execução local (docker compose), deploy em K8s (kubectl), provisionamento Terraform.
- **Collection das APIs:** link do Swagger (já gerado via rswag em `/api-docs`) + opcional export Postman.
- **Vídeo (≤15 min, YouTube/Vimeo)** demonstrando: deploy da app, execução do CI/CD, consumo das APIs,
  e **escalabilidade automática** (gerar carga, ex.: `k6`/`hey`, e mostrar HPA escalando pods).
- **PDF no portal:** link do repositório GitHub compartilhado com usuário **`soat-architecture`**,
  desenho da arquitetura e link do vídeo.

---

## Ordem de execução sugerida

1. **App (rápido, desbloqueia testes):** A1 listagem, A2 e-mail, A3 verificação de aprovação. Testes verdes + cobertura ≥80%.
2. **K8s manifests** (`/k8s`) — validar localmente (kind/minikube ou `kubectl --dry-run`).
3. **Terraform** (`/infra`) — EKS + RDS + ECR + addons; aplicar e validar cluster.
4. **CD** — reescrever `cd.yml` p/ K8s; rodar pipeline ponta a ponta.
5. **Docs** — README + diagrama; gravar vídeo; montar PDF do portal.

## Verificação (end-to-end)

- **Local:** `docker compose up -d` → `docker compose exec web bin/rails db:prepare` → Swagger em
  `http://localhost:3000/api-docs`; rodar `bundle exec rspec` (97+ testes, cobertura ≥80%).
- **E-mail (no cluster, p/ o vídeo):** com a app já deployada no K8s, consumir a API real para
  transicionar o status de uma OS e confirmar a notificação enviada via **SendGrid** (key lida do
  K8s Secret) chegando numa caixa real — não apenas em ambiente local.
- **Listagem:** `GET /api/v1/work_orders` retorna sem finalizadas/entregues, ordenado por
  prioridade de status e mais antigas primeiro.
- **K8s:** `kubectl apply -f k8s/` → `kubectl get pods,svc,hpa -n <ns>`; acessar via Service/LB.
- **HPA:** gerar carga (`k6`/`hey`) → `kubectl get hpa -w` mostra réplicas aumentando.
- **CI/CD:** push na `main` → CI verde → CD faz build/push ECR + apply K8s + rollout estável.
- **Terraform:** `terraform plan`/`apply` cria EKS+RDS; `outputs` mostram endpoints; `destroy` ao final.

## Arquivos-chave

| Área | Arquivos |
|------|----------|
| Listagem | `app/application/work_orders/list_work_orders.rb`, `app/infrastructure/persistence/work_orders/active_record_work_order_repository.rb` |
| E-mail | `app/mailers/work_order_mailer.rb` (novo), `app/views/work_order_mailer/*` (novo), use cases de transição em `app/application/work_orders/` |
| Aprovação | `app/controllers/api/v1/quotes_controller.rb`, `config/routes.rb` |
| K8s | `k8s/*.yaml` (novo) |
| Terraform | `infra/*.tf` + `infra/README.md` (novo) |
| CI/CD | `.github/workflows/cd.yml` (reescrever), `.github/workflows/ci.yml` (manter) |
| Docs | `README.md`, diagrama de arquitetura |

---

## Checklist de requisitos do PDF

| Requisito | Status atual | Ação Fase 2 |
|-----------|--------------|-------------|
| Clean Code | ✅ Atendido (DDD) | Manter |
| Clean Architecture / Hexagonal | ✅ Atendido (camadas) | Documentar |
| Testes automatizados | ✅ 97 testes, 80% | Cobrir features novas |
| API Abertura de OS | ✅ `POST /work_orders` | — |
| API Consulta de status | ✅ `GET /work_orders/:id`, `/tracking/:protocol` | — |
| API Aprovação de orçamento | ✅ `PATCH /quotes/:id/approve\|reject` | Expor/documentar como webhook |
| Listagem ordenada + exclusão lógica | ⚠️ Parcial | **A1 — ajustar** |
| Atualização de status via e-mail | ❌ Mailers vazios | **A2 — implementar (SendGrid via SMTP + Secret)** |
| Docker + docker-compose | ✅ Existe | Revisão leve |
| K8s (Deploy/Service/ConfigMap/Secret/HPA) | ❌ Inexistente | **B2 — criar** |
| Terraform (cluster + DB) | ❌ Inexistente | **B3 — criar (EKS+RDS)** |
| CI/CD (build/test/image/deploy K8s/DB/manifests) | ⚠️ Existe p/ ECS | **B4 — migrar p/ K8s** |
| README + diagrama + instruções | ⚠️ Fase 1 | **C — atualizar** |
| Collection de APIs (Swagger/Postman) | ✅ Swagger rswag | Linkar |
| Vídeo ≤15min | ❌ | **C — gravar** |
| PDF no portal (repo + soat-architecture + diagrama + vídeo) | ❌ | **C — montar** |

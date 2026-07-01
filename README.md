# 15SOAT - Fase 2 - Tech Challenge - Grupo 183

Sistema de gestão de oficina mecânica: uma API Rails que cobre todo o ciclo de vida de uma Ordem de Serviço (OS), da abertura ao orçamento, aprovação e entrega do veículo. A Fase 1 (Tech Challenge de pós-graduação FIAP) entregou a aplicação em **Domain-Driven Design (DDD)**; a Fase 2 evolui o projeto para **infraestrutura em nuvem produtiva**: cluster **Kubernetes (AWS EKS)** provisionado via **Terraform**, banco gerenciado **RDS**, deploy automatizado por **CI/CD** e **escalabilidade automática (HPA)**.

> A documentação completa da Fase 1 (arquitetura DDD, bounded contexts, event storming, walkthrough da API e scanners de segurança) foi preservada em [`docs/fase1/`](docs/fase1/README.md).

## Objetivos desta fase

- Migrar o deploy de ECS para **Kubernetes (EKS)**, com toda a infraestrutura como código.
- Provisionar a infraestrutura (VPC, cluster, banco, registry) de forma **reproduzível e descartável** via Terraform — essencial no AWS Academy, onde a conta é temporária.
- Automatizar o ciclo completo via **GitHub Actions**: provisionar → buildar imagem → aplicar manifests → autodestruir por segurança.
- Expor **autoscaling horizontal (HPA)** da aplicação conforme a carga de CPU/memória.
- Manter as regras de negócio e a arquitetura DDD da Fase 1 intactas — esta fase é sobre infraestrutura, não sobre reescrever domínio.

## Arquitetura

### Componentes da aplicação

| Componente          | O que é                                            | Onde roda                       |
| ------------------- | --------------------------------------------------- | -------------------------------- |
| **web**              | API Rails (Puma), exposta via `/up`, `/api/v1/*`, `/api-docs` | `Deployment` `oficina-mecanica-web` + `Service` LoadBalancer |
| **jobs**             | Worker do Solid Queue (e-mails via SendGrid, jobs assíncronos) | `Deployment` `oficina-mecanica-jobs` |
| **db-prepare**       | `bin/rails db:prepare` (migrations + seed) — roda uma vez por deploy | `Job` do Kubernetes, com `kubectl wait` bloqueando o deploy até concluir |
| **PostgreSQL**       | Banco único (app + Solid Queue), gerenciado          | RDS (fora do cluster) |
| **HPA**              | Escala o `web` por CPU (70%) e memória (80%), 1 a 3 réplicas | `HorizontalPodAutoscaler` + `metrics-server` |

A separação em camadas DDD (`domains → application → infrastructure`, `controllers/jobs` como interface) permanece igual à Fase 1 — [detalhes aqui](docs/fase1/README.md#arquitetura).

### Infraestrutura provisionada (Terraform, `infra/`)

```
                         ┌───────────────────────────── VPC (10.0.0.0/16) ─────────────────────────────┐
                         │                                                                              │
Internet ── IGW ── Route │  Subnet pública A (us-east-1a)          Subnet pública B (us-east-1b)        │
     Table (0.0.0.0/0)   │  ┌──────────────────────────┐           ┌──────────────────────────┐        │
                         │  │  EKS Node Group           │           │  EKS Node Group           │        │
                         │  │  (t3.medium, 1–3 nodes)   │◄────────► │  (t3.medium, 1–3 nodes)   │        │
                         │  └────────────┬─────────────┘           └──────────────┬────────────┘        │
                         │               │  EKS Control Plane (endpoint público)  │                     │
                         │               └──────────────────┬──────────────────────┘                    │
                         └──────────────────────────────────┼───────────────────────────────────────────┘
                                                              │
                                              ┌───────────────┴────────────────┐
                                              │  RDS PostgreSQL (privado)       │
                                              └─────────────────────────────────┘

ECR (registry da imagem Docker) ── metrics-server (Helm, add-on do HPA) ── S3 (backend do tfstate)
```

- **VPC** própria (`infra/vpc.tf`) com 2 subnets públicas (multi-AZ), Internet Gateway e route table — simplificada de propósito (sem NAT Gateway) para reduzir custo/complexidade no AWS Academy.
- **EKS** (`infra/eks.tf`, `infra/node_group.tf`): cluster gerenciado + node group de 1 a 3 instâncias `t3.medium`, usando o `LabRole` já disponível na conta AWS Academy (não é possível criar IAM roles próprias nesse ambiente).
- **RDS** (`infra/rds.tf`): PostgreSQL, não exposto publicamente — só acessível a partir do cluster.
- **ECR** (`infra/ecr.tf`): registry da imagem Docker da aplicação.
- **metrics-server** (`infra/metrics_server.tf`): instalado via provider Helm — pré-requisito para o HPA conseguir ler métricas de CPU/memória dos pods.
- **Backend do Terraform**: bucket S3 (`oficina-mecanica-tfstate-<account-id>`), criado via AWS CLI no início do pipeline para evitar o problema de "ovo e galinha" (o backend precisa existir antes do `terraform init`).

### Fluxo de deploy (CI/CD)

```
workflow_dispatch (credenciais AWS Academy como input — expiram em ~4h)
        │
        ▼
1. Configura credenciais AWS + cria/reaproveita bucket S3 do tfstate
2. terraform apply  →  VPC + EKS + node group + RDS + ECR + metrics-server
3. docker build + push da imagem para o ECR (tag = SHA do commit)
4. kubectl apply configmap/secrets  →  kubectl apply Job db-prepare (aguarda conclusão)
        →  kubectl apply web + jobs + service (LoadBalancer) + hpa
5. Autodestruição de segurança: aguarda 2h e roda o destroy automaticamente
   (ou dispara manualmente via cd_destroy.yml a qualquer momento)
```

Workflows: [`cd_deploy.yml`](.github/workflows/cd_deploy.yml) (provisiona + deploy + auto-destroy) e [`cd_destroy.yml`](.github/workflows/cd_destroy.yml) (destroy manual imediato), compartilhando a lógica de destruição via a composite action [`infra-destroy`](.github/actions/infra-destroy/action.yml).

## Execução local

Sem alterações em relação à Fase 1 — apenas Docker é necessário:

```bash
git clone git@github.com:<seu-usuario>/oficina_mecanica.git
cd oficina_mecanica
cp .env.example .env
docker compose build
docker compose run --rm web bin/rails db:prepare
docker compose up
```

A API sobe em `http://localhost:3000` (Swagger em `/api-docs`). Detalhes de setup, credenciais de teste e troubleshooting: [`docs/fase1/README.md`](docs/fase1/README.md).

## Deploy em Kubernetes

O deploy real acontece via GitHub Actions (aba **Actions → CD Deploy (EKS & K8s) → Run workflow**), informando as credenciais temporárias da sessão AWS Academy. Para rodar manualmente contra um cluster já provisionado:

```bash
aws eks update-kubeconfig --name oficina-mecanica-cluster --region us-east-1

kubectl apply -f k8s/configmap.yaml -f k8s/secrets.yaml
kubectl apply -f k8s/db-prepare-job.yaml
kubectl wait --for=condition=complete --timeout=300s job/oficina-mecanica-db-prepare

kubectl apply -f k8s/web-deployment.yaml -f k8s/jobs-deployment.yaml -f k8s/service.yaml -f k8s/hpa.yaml

kubectl get svc oficina-mecanica-web-service   # EXTERNAL-IP é a URL pública (http://, porta 80)
```

> `k8s/configmap.yaml` e `k8s/secrets.yaml` contêm placeholders (`DATABASE_HOST_PLACEHOLDER`, `DATABASE_PASSWORD_PLACEHOLDER`, `SECRET_KEY_BASE_PLACEHOLDER`, `IMAGE_PLACEHOLDER`) — o workflow de CD os substitui automaticamente com `sed` a partir dos outputs do Terraform e dos GitHub Secrets. Para aplicar manualmente, substitua-os antes.

### Testando o autoscaling (HPA)

```bash
bin/test_hpa.sh start     # gera carga real contra o Service e acompanha o HPA em tempo real
bin/test_hpa.sh status    # snapshot único do HPA/pods/CPU, sem gerar carga
bin/test_hpa.sh stop      # remove o gerador de carga manualmente
```

O script sobe um `Deployment` auxiliar (`busybox`) batendo em `/up`, mostra `kubectl get hpa`/`top pods` em loop e remove tudo automaticamente ao encerrar com `Ctrl+C`.

## Provisionamento da infraestrutura (Terraform)

```bash
cd infra/
terraform init \
  -backend-config="bucket=<nome-do-bucket-s3>" \
  -backend-config="key=oficina-mecanica/terraform.tfstate" \
  -backend-config="region=us-east-1"

terraform plan  -var="db_password=<senha-do-rds>"
terraform apply -var="db_password=<senha-do-rds>"

terraform output   # rds_address, eks_cluster_name, ecr_repository_url
```

Ao final do uso, destrua os recursos para não consumir os créditos do AWS Academy:

```bash
terraform destroy -var="db_password=<senha-do-rds>"
```

No pipeline de CI/CD, esses passos são automáticos — incluindo a limpeza de imagens do ECR e a espera pela liberação física dos Load Balancers antes do `destroy`, feita na composite action [`infra-destroy`](.github/actions/infra-destroy/action.yml).

## Documentação da API

- **Swagger UI** (ambiente local): [`http://localhost:3000/api-docs`](http://localhost:3000/api-docs)
- **Swagger UI** (ambiente implantado): `http://<EXTERNAL-IP-do-Service>/api-docs`
- Spec OpenAPI versionada: [`swagger/v1/swagger.json`](swagger/v1/swagger.json)
- Walkthrough completo via `curl` cobrindo o ciclo de vida de uma OS: [`docs/fase1/demo.md`](docs/fase1/demo.md)

## Vídeo demonstrativo

*(link do vídeo a adicionar aqui)*

Roteiro coberto (≤ 15 min): deploy da aplicação, execução do CI/CD, consumo das APIs e escalabilidade automática (HPA sob carga).

## Segurança

Mantido da Fase 1 sem alterações — bundler-audit, brakeman, Trivy, Semgrep, SonarQube e OWASP ZAP. Detalhes, exemplos de output e workflow de remediação: [`docs/fase1/security.md`](docs/fase1/security.md).

## Testes

RSpec com FactoryBot, Faker e shoulda-matchers — sem alterações na estrutura da Fase 1:

```bash
docker compose exec web bundle exec rspec
```

Detalhes da estrutura de `spec/` e comandos por camada: [`docs/fase1/README.md`](docs/fase1/README.md#testes).

## Documentação adicional

| Documento | Conteúdo |
| --- | --- |
| [`docs/fase1/README.md`](docs/fase1/README.md) | README original da Fase 1: stack, arquitetura DDD, bounded contexts, comandos úteis, troubleshooting |
| [`docs/fase1/event_storming.md`](docs/fase1/event_storming.md) | Event Storming dos 4 bounded contexts (diagramas Mermaid) |
| [`docs/fase1/demo.md`](docs/fase1/demo.md) | Walkthrough via `curl` do ciclo de vida completo de uma OS |
| [`docs/fase1/security.md`](docs/fase1/security.md) | Scanners de segurança (SAST/DAST), como rodar e remediar achados |
| [`docs/fase1/fase2-plano.md`](docs/fase1/fase2-plano.md) | Plano de execução da Fase 2 — gaps identificados e ordem de implementação |

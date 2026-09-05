# RFC-002: Escolha do Provedor de Nuvem (AWS)

| Metadado | Detalhe |
| :--- | :--- |
| **Título** | Escolha do Provedor de Nuvem e suas Implicações Arquiteturais |
| **Status** | `ACEITO` |
| **Autor(es)** | FIAP 15SOAT - Grupo 161 |
| **Data** | 04 de Setembro de 2026 |
| **Contexto** | Tech Challenge - Fases 2 e 3 (decisão tomada na Fase 2, documentada formalmente agora) |
| **Repositórios afetados** | `k8s-infra`, `db-infra`, `api`, `auth-serverless`, `deploy-orchestrator` |

---

## 1. Resumo Executivo

Esta RFC documenta formalmente a escolha da **AWS** como provedor de nuvem para o projeto Oficina Mecânica, e as restrições concretas que essa escolha impõe sobre a arquitetura (uso obrigatório da `LabRole`, ausência de IAM customizado, contas temporárias, créditos limitados). Diferente de uma escolha de mercado tradicional, a decisão aqui é **majoritariamente determinada pelo ambiente do curso** (AWS Academy) — e é isso que a torna uma decisão arquitetural relevante de se registrar: as restrições do AWS Academy explicam por que várias outras RFCs/ADRs deste projeto existem (Terraform em vez de Serverless Framework, ausência de VPC Link, sessões de deploy manuais com credenciais efêmeras).

## 2. Motivação e Contexto

O Tech Challenge exige que a aplicação seja implantada em nuvem pública, com infraestrutura como código, containers orquestrados (Kubernetes) e, na Fase 3, um componente serverless (API Gateway + Lambda). A FIAP disponibiliza aos alunos acesso ao **AWS Academy Learner Lab**: contas AWS temporárias, pré-configuradas com uma única IAM Role de uso obrigatório (`LabRole`), sem permissão para criar roles/políticas IAM próprias, e com sessões de credenciais que expiram em ~4 horas.

## 3. Alternativas Consideradas

| Alternativa | Prós | Contras | Decisão |
| :--- | :--- | :--- | :--- |
| **AWS (AWS Academy Learner Lab)** | Acesso gratuito via a instituição; suporta todos os serviços exigidos (EKS, RDS, API Gateway, Lambda, ECR, SSM); documentação e comunidade extensas. | `LabRole` única (sem IAM customizado); sessões de credenciais efêmeras (~4h); sem cartão de crédito/conta paga, então sem alguns serviços gerenciados de nicho. | **Aceito** |
| **Google Cloud Platform (GKE, Cloud SQL, Cloud Functions, API Gateway)** | Equivalentes diretos para todos os serviços usados na AWS. | Sem acesso institucional gratuito equivalente ao AWS Academy para o curso; exigiria conta paga do próprio grupo. | Rejeitado — custo/acesso |
| **Azure (AKS, Azure Database, Functions, API Management)** | Equivalentes diretos disponíveis. | Mesmo problema de acesso/custo do GCP; menor familiaridade do grupo com o ecossistema. | Rejeitado — custo/acesso |
| **On-premise / self-hosted (k3s local, Docker Compose apenas)** | Sem custo, sem limite de tempo de sessão. | Não atende ao requisito explícito do desafio de nuvem pública gerenciada; sem paridade real com um ambiente produtivo (RDS, IAM, API Gateway gerenciado). | Rejeitado — não atende ao requisito do desafio |

## 4. Decisão

Adotar a **AWS**, via **AWS Academy Learner Lab**, como único provedor de nuvem do projeto.

## 5. Consequências (o que essa escolha implica no resto do projeto)

A restrição de ambiente do AWS Academy **não é um detalhe menor** — ela é a causa raiz de várias outras decisões documentadas neste projeto:

| Restrição do AWS Academy | Onde isso aparece no projeto |
| :--- | :--- |
| Não é possível criar IAM Roles/Policies próprias — só a `LabRole` pré-existente | Todo `aws_iam_role`/`aws_lambda_function` usa `arn:aws:iam::<account>:role/LabRole` (ver `k8s-infra/infra/eks.tf`, `auth-serverless/infra/main.tf`) |
| Sessões de credenciais temporárias (~4h) | Todos os workflows de deploy (`cd_deploy.yml`) recebem `aws_access_key_id`/`aws_secret_access_key`/`aws_session_token` como **input manual** do `workflow_dispatch`, nunca como secret fixo (ver ADR 6 do log de ADRs, `docs/fase3/architecture/adr-log.md`) |
| Conta é recriada/reciclada periodicamente; sem persistência garantida entre sessões | `api/cd_deploy.yml` tem uma etapa de "Autodestruição de Segurança" (2h de janela de demonstração, depois destrói os workloads) para não consumir os créditos além do necessário |
| Sem cartão de crédito / billing próprio, então sem alguns add-ons gerenciados pagos (ex: New Relic AWS Marketplace listing direto) | Observabilidade (New Relic) é avaliada como agente/APM instalado na aplicação, não como um serviço gerenciado pago da AWS |
| Escolha do Serverless Framework para IaC foi descartada | Ver RFC-001 ADR 3 — o Serverless Framework cria roles IAM customizadas via CloudFormation, o que falha nesse ambiente; por isso o projeto usa exclusivamente Terraform com a `LabRole` |

## 6. Referências

- [RFC-001](RFC-001-authentication-authorization-serverless.md) — arquitetura serverless (API Gateway + Lambda) dentro da AWS.
- [Log de ADRs](architecture/adr-log.md) — decisões permanentes derivadas desta escolha de nuvem (padrão de comunicação, uso de HPA).
- `k8s-infra/infra/`, `db-infra/infra/`, `auth-serverless/infra/` — implementação em Terraform de cada componente AWS usado (VPC, EKS, RDS, Lambda, API Gateway, SSM Parameter Store).

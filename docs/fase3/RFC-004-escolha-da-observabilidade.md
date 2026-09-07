# RFC-004: Escolha da Ferramenta de Observabilidade

| Metadado | Detalhe |
| :--- | :--- |
| **Título** | Escolha do New Relic como Ferramenta de Observabilidade e Monitoramento |
| **Status** | `ACEITO` |
| **Autor(es)** | FIAP 15SOAT - Grupo 161 |
| **Data** | 06 de Setembro de 2026 |
| **Contexto** | Tech Challenge - Fase 3 (requisito de monitoramento/observabilidade) |
| **Repositórios afetados** | `api`, `auth-serverless`, `k8s-infra` |

---

## 1. Resumo Executivo

Esta RFC justifica formalmente a escolha do **New Relic** como ferramenta única de observabilidade do projeto Oficina Mecânica, cobrindo APM da API Rails, extensão de Lambda do `auth-serverless`, métricas de infraestrutura Kubernetes (`k8s-infra`) e dashboard/alertas como código. A decisão arquitetural permanente correspondente está registrada na [ADR 11](architecture/adr-log.md#adr-11-new-relic-como-ferramenta-de-observabilidade-e-monitoramento); esta RFC documenta a análise de alternativas e o critério que definiu o desempate.

## 2. Motivação e Contexto

O tech challenge exige que a aplicação possua monitoramento e observabilidade cobrindo latência de API, consumo de CPU/memória do Kubernetes, healthchecks, disponibilidade e falhas no processamento de OS, além de dashboards demonstráveis em vídeo. Diferente da escolha de nuvem ou banco de dados — decisões tomadas uma vez e fixas pelo resto do projeto —, a ferramenta de observabilidade precisa continuar acessível e com dados visíveis **entre sessões de trabalho não contínuas**: o ambiente AWS Academy é recriado a cada sessão (~4h, credenciais e cluster efêmeros), mas o vídeo de demonstração e a eventual reapresentação dos dashboards podem acontecer dias ou semanas depois de os dados terem sido gerados. Isso torna a política de free tier de cada ferramenta um critério de decisão tão relevante quanto suas capacidades técnicas.

## 3. Alternativas Consideradas

| Alternativa | Prós | Contras | Decisão |
| :--- | :--- | :--- | :--- |
| **New Relic** | Free tier permanente (não expira): 100 GB/mês de ingestão de dados grátis, sem cartão de crédito exigido no cadastro; cobre APM, infraestrutura K8s, logs e dashboards/alertas num único produto; provider Terraform oficial (`newrelic/newrelic`) versiona dashboard e alertas como código; extensão Lambda pré-compilada (sem alterar código da função). | Interface de query (NRQL) tem curva de aprendizado própria; UI de dashboard leva alguns minutos para refletir dados novos (latência de ingestão). | **Aceito** |
| **Datadog** | Também cobre APM, infraestrutura K8s, logs e dashboards; UI e NRQL-equivalente (Datadog Query Language) maduros; amplamente adotado no mercado. | O plano gratuito é um **trial de 14 dias** com todos os recursos habilitados — após esse período, a conta cai automaticamente para um tier "Free" bem mais restrito (retenção de métricas de 1 dia, sem APM completo, sem alertas customizados) ou exige cadastro de cartão de crédito para continuar no plano pago. Como o cronograma da Fase 3 (implementação, deploy, geração de dados de demonstração e gravação do vídeo) facilmente ultrapassa 14 dias corridos, esse prazo criaria risco real de os dashboards pararem de funcionar ou perderem histórico antes da entrega/gravação. | Rejeitado — risco de expiração do free tier durante o cronograma do projeto |
| **Prometheus + Grafana (self-hosted no próprio EKS)** | Sem custo de licença, controle total sobre retenção; ecossistema padrão para métricas Kubernetes. | Exigiria provisionar, operar e manter storage persistente (Prometheus TSDB) dentro do cluster do AWS Academy — cujo cluster inteiro é destruído e recriado a cada sessão, então o histórico de métricas seria perdido a cada `terraform destroy`; também não cobre APM de código (traces distribuídos, breakdown de latência por transação) sem componentes adicionais (Tempo/Jaeger); mais infraestrutura para o grupo manter sem ganho real sobre uma opção gerenciada. | Rejeitado — persistência de dados incompatível com o ciclo de vida efêmero do ambiente |
| **AWS CloudWatch (nativo)** | Já integrado à conta AWS, sem provedor externo; métricas de EKS e Lambda disponíveis por padrão. | Dashboards nativos são mais limitados para eventos de negócio customizados (duração de OS por etapa, falhas de use case) e para correlação de trace entre API Gateway → Lambda → Rails; exigiria combinar vários serviços (CloudWatch Logs Insights, X-Ray, Container Insights) para cobrir o mesmo escopo que uma única ferramenta de APM resolve nativamente. | Rejeitado — fragmentação de sinais entre múltiplos serviços AWS |

## 4. Decisão

Adotar o **New Relic** como ferramenta única de observabilidade, com o dashboard e os alertas provisionados como código (Terraform, provider `newrelic`) no repositório [`k8s-infra`](https://github.com/FIAP-15SOAT-GabrielHelton/k8s-infra) — mesmo consultando dados gerados por `api` e `auth-serverless`, já que dashboard/alerta observa dados já enviados, não pertence a quem os gera.

## 5. Critério Decisivo: Free Tier Permanente

O fator que desempatou entre New Relic e Datadog — ambos tecnicamente equivalentes para os requisitos deste tech challenge — foi a política de free tier:

- **New Relic**: o free tier (100 GB/mês de ingestão, 1 usuário "Full Platform" grátis) **não tem prazo de expiração** — permanece disponível indefinidamente, sem necessidade de cartão de crédito. Os dados gerados por `bin/generate_demo_traffic.sh` (ver seção de scripts no [README](../../README.md#monitoramento-e-observabilidade)) continuam acessíveis para consulta e gravação do vídeo demonstrativo a qualquer momento após a implementação, sem risco de a conta expirar no meio do cronograma.
- **Datadog**: o cadastro concede acesso total por **14 dias corridos**, após os quais a conta é automaticamente rebaixada para um tier gratuito muito mais limitado (retenção de métricas de 1 dia, sem alertas customizados, sem APM completo) — ou passa a exigir cartão de crédito para manter os recursos usados durante o desenvolvimento. Para um projeto acadêmico em que implementação, deploy, geração de tráfego de demonstração e gravação do vídeo não necessariamente acontecem no mesmo dia, esse prazo é um risco operacional desnecessário.

Essa característica pesou mais do que qualquer diferença técnica entre as duas ferramentas, já que nenhuma capacidade exigida pelo tech challenge (APM, métricas de K8s, dashboards, alertas, logs correlacionados) é exclusiva de uma ou outra.

## 6. Consequências

A conta New Relic (license key, account id, API key) é um segredo independente da AWS Academy — não expira com a sessão AWS, mas precisa ser gerenciada como GitHub Secret permanente nos 3 repositórios que a consomem (`api`, `auth-serverless`, `k8s-infra`), diferente do padrão de credenciais AWS efêmeras via `workflow_dispatch` usado no resto do projeto. Ver [ADR 11](architecture/adr-log.md#adr-11-new-relic-como-ferramenta-de-observabilidade-e-monitoramento) para as consequências arquiteturais permanentes dessa escolha.

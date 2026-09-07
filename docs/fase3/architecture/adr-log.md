# Log de ADRs — Decisões Arquiteturais Permanentes

Diferente das RFCs (que documentam uma decisão pontual, com alternativas discutidas e um contexto histórico específico), este documento reúne **Architecture Decision Records (ADRs)** — decisões arquiteturais **permanentes**, que continuam válidas independente da fase do projeto em que foram tomadas.

A numeração continua a sequência dos ADRs 1-7 já registrados na [RFC-001](../RFC-001-authentication-authorization-serverless.md) (todos escopados a autenticação/serverless/multi-repo). Os ADRs abaixo cobrem decisões permanentes de outras áreas do projeto.

---

## ADR 8: Padrão de Comunicação — REST Síncrono sobre HTTP

* **Decisão:** Toda comunicação entre cliente e sistema, e entre os componentes internos (API Gateway → Lambdas, API Gateway → API Rails), é feita via **REST síncrono sobre HTTP/JSON**. Não há mensageria assíncrona (fila de eventos, pub/sub) entre serviços — mesmo a comunicação assíncrona interna do sistema (envio de e-mail de notificação de status) é feita via **Solid Queue** (jobs de background dentro do próprio processo Rails), não via um broker de mensagens externo.
* **Justificativa:**
  - O domínio (abertura de OS → diagnóstico → orçamento → aprovação → execução → entrega) é uma máquina de estados **sequencial e request-driven**: cada transição é iniciada por uma ação explícita de um ator (cliente aprova orçamento, mecânico marca execução como concluída) que espera uma confirmação imediata (sucesso/erro) — um padrão naturalmente síncrono.
  - Introduzir um broker de mensagens (SQS, EventBridge, Kafka) adicionaria um componente de infraestrutura extra para gerenciar (deploy, IAM, monitoramento) sem resolver nenhum problema real deste domínio — não há necessidade de desacoplar produtores/consumidores em múltiplos serviços independentes, já que o sistema é um monólito modular (`api`) com uma camada serverless fina na frente (`auth-serverless`), não um conjunto de microsserviços que precisariam de comunicação assíncrona para não se acoplar diretamente.
  - Onde existe uma necessidade real de assincronia (enviar e-mail sem bloquear a resposta HTTP), o **Solid Queue** do Rails 8 já resolve isso sem infraestrutura extra — reforça a decisão da [RFC-003](../RFC-003-escolha-do-banco-e-modelo.md) de manter tudo num único banco PostgreSQL.
* **Consequências:** Se o sistema crescer para múltiplos serviços de domínio independentes (ex: um serviço de faturamento separado), essa decisão precisaria ser revisitada — REST síncrono ponto-a-ponto não escala bem para múltiplos consumidores de um mesmo evento.

## ADR 9: Uso de HPA (Horizontal Pod Autoscaler) para Escala da Aplicação

* **Decisão:** A aplicação (`Deployment web`) escala horizontalmente via **HPA do Kubernetes**, baseado em utilização de CPU (70%) e memória (80%), entre 1 e 3 réplicas — em vez de escala vertical (aumentar o tamanho da instância) ou escala manual.
* **Justificativa:**
  - O tráfego esperado de uma oficina mecânica é **variável e imprevisível** (picos em horários de atendimento, vazio fora deles) — HPA responde a isso automaticamente, sem intervenção manual.
  - Escala horizontal (mais réplicas do mesmo pod) é mais barata e simples de reverter no ambiente do AWS Academy do que escala vertical (trocar o tipo de instância do node group, que exigiria recriar o `node_group` do [`k8s-infra`](https://github.com/FIAP-15SOAT-GabrielHelton/k8s-infra)).
  - O teto de 3 réplicas é deliberadamente baixo — reflete o ambiente de demonstração/estudo (créditos limitados do AWS Academy), não uma capacidade de produção real.
  - Depende do `metrics-server` (ver [diagrama de componentes](component-diagram.md)) para funcionar — sem ele, o HPA não tem métricas de CPU/memória para decidir quando escalar.
* **Consequências:** O HPA decide escala **só por CPU/memória do processo**, não por métricas de negócio (ex: latência de resposta, fila de requisições). Com a adoção do New Relic (ADR 11), essas métricas de negócio passam a existir e ficam disponíveis no dashboard — mas o HPA continua escalando só por infraestrutura, por decisão deliberada de manter o escopo simples (ver ADR 11).

## ADR 11: New Relic como Ferramenta de Observabilidade e Monitoramento

* **Decisão:** Adotar o **New Relic** (em vez de Datadog ou outra alternativa equivalente) como ferramenta única de observabilidade do sistema, cobrindo quatro frentes: APM na API Rails (`newrelic_rpm`, repositório `api`), extensão Lambda nas duas funções serverless (repositório `auth-serverless`), integração de infraestrutura Kubernetes (`nri-kubernetes`, repositório `k8s-infra`) e dashboard/policy de alertas provisionados como código (Terraform, provider `newrelic`, repositório `k8s-infra`).
* **Justificativa:**
  - Ambas as ferramentas (New Relic e Datadog) atendem igualmente bem aos requisitos do tech challenge (APM, logs estruturados, métricas de Kubernetes, dashboards, alertas) — a escolha entre elas é indiferente para o domínio do projeto; o critério decisivo foi o free tier do New Relic não ter prazo de expiração (Datadog rebaixa a conta após 14 dias), compatível com o caráter acadêmico e não-contínuo do projeto. Análise completa das alternativas em [RFC-004](../RFC-004-escolha-da-observabilidade.md).
  - Um único fornecedor para APM (aplicação), infraestrutura (cluster) e dashboards evita a fragmentação de sinais entre ferramentas diferentes — uma requisição é rastreável do API Gateway até o banco de dados usando o mesmo `trace.id`/`request_id` em todos os pontos.
  - O provider Terraform oficial (`newrelic/newrelic`) permite versionar dashboard e alertas como código, no mesmo padrão do resto do projeto (Terraform para toda a infraestrutura) — diferente de outros recursos AWS, a conta New Relic não é destruída ao final da sessão do AWS Academy, então esse estado é persistente entre execuções.
  - A extensão Lambda do New Relic (camada pré-compilada, sem alterar o código das funções) foi preferida a instrumentação manual via SDK, mantendo o código das Lambdas focado na lógica de autenticação/autorização.
* **Consequências:** A conta New Relic (license key, account id, API key) é um segredo independente da AWS Academy — não expira com a sessão, mas precisa ser gerenciada nos 3 repositórios que a consomem (`api`, `auth-serverless`, `k8s-infra`) como GitHub Secrets permanentes, diferente do padrão de credenciais AWS efêmeras via `workflow_dispatch` usado no resto do projeto.

## ADR 10: Clean Architecture / DDD em Camadas Explícitas

* **Decisão:** O código do repositório `api` é organizado em camadas explícitas com regra de dependência única (`controllers/jobs → application → domains ← infrastructure`), com nomenclatura em português para os conceitos de domínio (`OrdemDeServico`, `CriarOrdemDeServico`) e sufixo `Record` para os modelos ActiveRecord — mantendo o domínio (`app/domains/`) livre de qualquer referência a Rails/ActiveRecord.
* **Justificativa:**
  - Isola as regras de negócio (máquina de estados da OS, cálculo de orçamento, RBAC) de detalhes de infraestrutura (ORM, HTTP, serialização) — um teste de `app/application/work_orders/create_work_order_spec.rb`, por exemplo, não precisa de banco de dados real (usa dublês/mocks dos repositórios).
  - Facilita a extração de partes do sistema para outros repositórios sem reescrever a lógica de negócio — foi essa separação que permitiu extrair a autenticação/RBAC para o `auth-serverless` (Fase 3) tocando minimamente na lógica de domínio já existente (ver RFC-001).
  - Nomenclatura em português mantém a Linguagem Ubíqua (Ubiquitous Language) alinhada com os stakeholders do domínio (equipe da oficina), reduzindo a tradução mental entre "como o negócio fala" e "como o código está escrito".
* **Consequências:** Onboarding de alguém não-lusófono no código exigiria uma camada extra de tradução de termos — trade-off aceito porque o time e os stakeholders do domínio são todos falantes de português.

## ADR 12: Organização de Logs e Traces — Correlação por `X-Request-Id`

* **Decisão:** Toda requisição que atravessa a arquitetura (API Gateway → Lambda `auth-serverless` → API Rails) é identificada por um único `X-Request-Id`, propagado explicitamente entre componentes, e usado como campo de correlação em todos os logs estruturados e nos eventos/traces do New Relic. Logs de aplicação são emitidos em **JSON de linha única** (não texto livre), nunca texto livre multi-linha.
* **Justificativa:**
  - O API Gateway do [`auth-serverless`](https://github.com/FIAP-15SOAT-GabrielHelton/auth-serverless) injeta `X-Request-Id: $context.requestId` via `request_parameters` (`overwrite:header.X-Request-Id`) em toda rota `HTTP_PROXY`, garantindo que o identificador nasça no ponto de entrada do sistema, não em cada componente individualmente — evitando IDs divergentes entre as pontas de uma mesma requisição.
  - No `auth-serverless`, os handlers Lambda (`auth_customer`, `lambda_authorizer`) extraem esse `X-Request-Id` (ou `requestContext.requestId` quando a rota não é `HTTP_PROXY`) e o incluem em todo log estruturado (`src/utils/logger.ts`) e ao repassar a chamada para o Rails (`rails_client.ts`), preservando o mesmo ID ponta a ponta.
  - No repositório `api`, a API Rails honra automaticamente o `X-Request-Id` recebido via o middleware padrão `ActionDispatch::RequestId` — não reimplementa esse comportamento. O `lograge` (`config/initializers/lograge.rb`) formata cada requisição como uma linha JSON única contendo `request_id`, mais `trace.id`/`span.id` do agente New Relic (`NewRelic::Agent::Tracer.current_trace_id/current_span_id`) — permitindo pular do log de uma requisição direto para o trace de APM correspondente na mesma ferramenta.
  - Eventos de negócio customizados (`WorkOrderStageDuration`, `UseCaseFailed`) também herdam o `trace.id` corrente do agente, então uma falha de processamento de OS pode ser correlacionada de volta à requisição HTTP e ao log JSON que a originou.
* **Consequências:** Qualquer novo componente adicionado à arquitetura (ex: um futuro serviço adicional) precisa honrar e repropagar o `X-Request-Id` recebido para não quebrar a cadeia de correlação — não há um "trace ID" gerado independentemente por cada serviço. Não há um coletor de tracing distribuído dedicado (ex: OpenTelemetry Collector); a correlação depende inteiramente do New Relic (APM + Lambda extension) reconhecer o mesmo `trace.id` em todos os pontos, então uma eventual troca de ferramenta de observabilidade ([RFC-004](../RFC-004-escolha-da-observabilidade.md)) precisaria revalidar essa cadeia de propagação.

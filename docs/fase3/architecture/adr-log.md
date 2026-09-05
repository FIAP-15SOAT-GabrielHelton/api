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
* **Consequências:** Sem um APM/observabilidade de aplicação (ver estado do monitoramento no [diagrama de componentes](component-diagram.md)), o HPA decide escala **só por CPU/memória do processo**, não por métricas de negócio (ex: latência de resposta, fila de requisições) — uma limitação a considerar quando o New Relic for adotado.

## ADR 10: Clean Architecture / DDD em Camadas Explícitas

* **Decisão:** O código do repositório `api` é organizado em camadas explícitas com regra de dependência única (`controllers/jobs → application → domains ← infrastructure`), com nomenclatura em português para os conceitos de domínio (`OrdemDeServico`, `CriarOrdemDeServico`) e sufixo `Record` para os modelos ActiveRecord — mantendo o domínio (`app/domains/`) livre de qualquer referência a Rails/ActiveRecord.
* **Justificativa:**
  - Isola as regras de negócio (máquina de estados da OS, cálculo de orçamento, RBAC) de detalhes de infraestrutura (ORM, HTTP, serialização) — um teste de `app/application/work_orders/create_work_order_spec.rb`, por exemplo, não precisa de banco de dados real (usa dublês/mocks dos repositórios).
  - Facilita a extração de partes do sistema para outros repositórios sem reescrever a lógica de negócio — foi essa separação que permitiu extrair a autenticação/RBAC para o `auth-serverless` (Fase 3) tocando minimamente na lógica de domínio já existente (ver RFC-001).
  - Nomenclatura em português mantém a Linguagem Ubíqua (Ubiquitous Language) alinhada com os stakeholders do domínio (equipe da oficina), reduzindo a tradução mental entre "como o negócio fala" e "como o código está escrito".
* **Consequências:** Onboarding de alguém não-lusófono no código exigiria uma camada extra de tradução de termos — trade-off aceito porque o time e os stakeholders do domínio são todos falantes de português.

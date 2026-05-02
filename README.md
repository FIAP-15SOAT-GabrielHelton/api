# Oficina Mecânica

Sistema de gestão de oficina mecânica desenvolvido como projeto de pós-graduação.

## Stack

- **Ruby** 3.4
- **Rails** 8.1 (modo API-only)
- **PostgreSQL** 17
- **Solid Queue** para processamento de jobs em background (sem Redis)
- **Solid Cache / Solid Cable** em produção (Postgres-backed)
- **Docker Compose** para orquestrar tudo em desenvolvimento

## Pré-requisitos

Você só precisa ter instalado na máquina:

- [Docker](https://docs.docker.com/get-docker/) (versão recente com suporte a `compose.yml`)
- [Docker Compose v2](https://docs.docker.com/compose/) (já vem no Docker Desktop)
- `git`

**Não é necessário** instalar Ruby, Rails ou PostgreSQL diretamente no host — tudo roda dentro de containers.

## Setup inicial

```bash
# 1. Clonar o repositório
git clone git@github.com:<seu-usuario>/oficina_mecanica.git
cd oficina_mecanica

# 2. Copiar as variáveis de ambiente
cp .env.example .env

# 3. Construir as imagens
docker compose build

# 4. Criar e migrar os bancos (primary + queue)
docker compose run --rm web bin/rails db:prepare

# 5. Popular o banco com dados de demonstração
#    (catálogo de serviços/peças + WOs em vários estados — ver "Demo Walkthrough")
docker compose run --rm web bin/rails db:seed

# 6. Subir a aplicação
docker compose up
```

Após o último passo, a API estará disponível em `http://localhost:3000` com
todos os dados de demonstração já carregados.

## Demo Walkthrough

O passo 5 do setup acima (`db:seed`) popula o banco com dados realistas:
clientes, veículos, catálogo de serviços e peças, e algumas Ordens de Serviço
já distribuídas em vários estados. Ao final, o terminal imprime um resumo com
credenciais, IDs de customers/vehicles e protocols das WorkOrders criadas.

As credenciais padrão são:

| Email | Senha | Role |
|---|---|---|
| `admin@oficina.local` | `oficina123` | admin |
| `mechanic@oficina.local` | `oficina123` | mechanic |

A seed é **idempotente**: rodar múltiplas vezes (`docker compose run --rm web
bin/rails db:seed`) não duplica dados nem decrementa estoque novamente. Para
resetar tudo do zero:

```bash
docker compose run --rm web bin/rails db:drop db:create db:migrate db:seed
```

### Fluxo completo via HTTP (passo a passo)

Os comandos `curl` abaixo cobrem o ciclo de vida completo de uma Ordem de Serviço:
do recebimento do cliente na recepção até a entrega do veículo finalizado. Os
IDs usados (`customer_id=2`, `vehicle_id=3`) correspondem à Maria Souza /
Toyota Corolla criados pela seed — confirme no resumo impresso ao final do
`db:seed`.

Para visualizar a API de forma interativa em vez do `curl`, abra o Swagger UI
em [`http://localhost:3000/api-docs`](http://localhost:3000/api-docs).

#### 1. Login (admin) — obtém o `access_token`

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@oficina.local","password":"oficina123"}'
```

Copie o valor de `access_token` da resposta. Os próximos passos usam esse
token no header `Authorization: Bearer <TOKEN>`.

#### 2. (Opcional) Inspecionar dados pré-carregados

```bash
# Substitua <TOKEN> pelo access_token obtido no passo 1
curl http://localhost:3000/api/v1/services           -H "Authorization: Bearer <TOKEN>"
curl http://localhost:3000/api/v1/inventory_items    -H "Authorization: Bearer <TOKEN>"
curl http://localhost:3000/api/v1/work_orders        -H "Authorization: Bearer <TOKEN>"
curl http://localhost:3000/api/v1/admin/metrics      -H "Authorization: Bearer <TOKEN>"
```

#### 3. Criar uma nova Ordem de Serviço — status `received`

A atendente recebe o cliente e abre a OS:

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

Anote o `data.id` da resposta como `<WORK_ORDER_ID>` para os próximos passos.

#### 4. Mecânico assume a OS — status `received` → `diagnosing`

```bash
curl -X PATCH http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/assign \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"mechanic_id": 2}'
```

#### 5. Adicionar serviços e peças durante o diagnóstico

```bash
# Service: Diagnóstico eletrônico (reference_id=5)
curl -X POST http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/line_items \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"item_type":"service","reference_id":5,"quantity":1}'

# Part: Velas de ignição (reference_id=8, qty=4)
curl -X POST http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/line_items \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"item_type":"part","reference_id":8,"quantity":4}'
```

> Os IDs `5` e `8` são exemplos. Confirme via `GET /api/v1/services` e
> `GET /api/v1/inventory_items` (passo 2) os IDs reais no seu banco.

#### 6. Diagnosticar — status `diagnosing` → `awaiting_approval` (cria Quote automaticamente)

```bash
curl -X PATCH http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/diagnose \
  -H "Authorization: Bearer <TOKEN>"
```

Para obter o `id` do Quote criado, consulte os detalhes da OS:

```bash
curl http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID> \
  -H "Authorization: Bearer <TOKEN>"
```

Anote o `quote.id` como `<QUOTE_ID>`.

#### 7. Enviar o orçamento ao cliente — Quote `created` → `sent`

```bash
curl -X PATCH http://localhost:3000/api/v1/quotes/<QUOTE_ID>/send_to_customer \
  -H "Authorization: Bearer <TOKEN>"
```

#### 8. Cliente aprova — Quote `approved`, WO `awaiting_approval` → `approved`, estoque é decrementado

```bash
curl -X PATCH http://localhost:3000/api/v1/quotes/<QUOTE_ID>/approve \
  -H "Authorization: Bearer <TOKEN>"
```

#### 9. Iniciar execução — status `approved` → `in_progress`

```bash
curl -X PATCH http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/execute \
  -H "Authorization: Bearer <TOKEN>"
```

#### 10. Iniciar e finalizar cada serviço (registra duração)

Para cada `line_item` cujo `item_type` é `service`, busque o `id` em
`GET /api/v1/work_orders/<WORK_ORDER_ID>` e rode:

```bash
# Inicia o serviço
curl -X PATCH http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/line_items/<LINE_ITEM_ID>/start \
  -H "Authorization: Bearer <TOKEN>"

# Finaliza o serviço
curl -X PATCH http://localhost:3000/api/v1/work_orders/<WORK_ORDER_ID>/line_items/<LINE_ITEM_ID>/finish \
  -H "Authorization: Bearer <TOKEN>"
```

Quando o último serviço é finalizado, a OS transiciona automaticamente para
`completed`.

#### 11. Consulta pública pelo `protocol` (sem autenticação)

O cliente pode acompanhar a OS sem login usando o `protocol` impresso na
criação:

```bash
curl http://localhost:3000/api/v1/tracking/<PROTOCOL>
```

#### 12. Métricas administrativas

```bash
curl http://localhost:3000/api/v1/admin/metrics \
  -H "Authorization: Bearer <TOKEN>"
```

## Verificando que está tudo funcionando

```bash
# Health check nativo do Rails
curl -i http://localhost:3000/up
```

Deve retornar `200 OK`. Nos logs, você verá tanto o serviço `web` (Rails server) quanto o `jobs` (Solid Queue worker) rodando.

## Serviços do `compose.yml`

| Serviço | Responsabilidade | Porta |
|---|---|---|
| `db`   | Banco PostgreSQL 17 | `5432` |
| `web`  | API Rails (`bin/rails server`) | `3000` |
| `jobs` | Worker do Solid Queue (`bin/jobs`) | — |

## Comandos úteis

```bash
# Subir / derrubar
docker compose up
docker compose up -d                    # em background
docker compose down                     # para tudo
docker compose down -v                  # para e APAGA o volume do Postgres

# Ver logs
docker compose logs -f web
docker compose logs -f jobs
docker compose logs -f db

# Console Rails
docker compose exec web bin/rails console

# Rodar migrations
docker compose exec web bin/rails db:migrate

# Listar rotas
docker compose exec web bin/rails routes

# Shell no container web
docker compose exec web bash

# Conectar diretamente no Postgres
docker compose exec db psql -U oficina_mecanica oficina_mecanica_development
```

## Bancos de dados

Em desenvolvimento, o Rails cria **dois** bancos:

- `oficina_mecanica_development` — banco principal (models da aplicação)
- `oficina_mecanica_development_queue` — banco usado pelo Solid Queue para persistir jobs

Ambos são criados automaticamente pelo `bin/rails db:prepare`. Em produção, o Rails 8 também cria `_cache` e `_cable` (Solid Cache e Solid Cable), mas em desenvolvimento mantemos só primary + queue para simplificar.

## Troubleshooting

**Porta 3000 ou 5432 já em uso**
Algum outro processo (outro Rails, outro Postgres local) está segurando a porta. Pare-o ou ajuste o mapeamento de portas no `compose.yml`.

**Resetar o banco do zero**
```bash
docker compose down -v       # apaga o volume do Postgres
docker compose up -d db
docker compose run --rm web bin/rails db:prepare
docker compose up
```

**Mudou o `Gemfile` e precisa reinstalar gems**
```bash
docker compose build web jobs
```
Ou, se quiser forçar a reinstalação completa:
```bash
docker compose down
docker volume rm pos_graduacao_bundle_cache
docker compose build web jobs
```

**Erro de permissão em arquivos gerados pelo container**
O container roda como `root` por padrão, então arquivos criados por ele (ex.: `bin/rails generate`) podem ficar com dono `root` no host. No macOS isso geralmente não incomoda; no Linux, ajuste com `sudo chown -R $USER:$USER .`.

## Arquitetura

O projeto segue **Domain-Driven Design** (DDD) dentro de um monolito Rails, com **separação explícita de camadas** estilo arquitetura hexagonal. A motivação é deixar o domínio isolado de detalhes de framework e infraestrutura — quem lê `app/domains/` deve ver código Ruby puro, sem nenhum vestígio de Rails.

### Bounded Contexts

O projeto tem dois tipos de contexto: **core** (o que dá valor ao negócio, definido no Event Storming) e **supporting** (subdomínios de apoio que viabilizam o core).

**Contextos core:**

| Contexto | Responsabilidade | Agregado principal |
|---|---|---|
| **Ordens de Serviço** | Ciclo de vida da OS (criação, diagnóstico, execução, finalização) | `OrdemDeServico` |
| **Orçamentos** | Criação, envio, aprovação e reprovação de orçamentos | `Orcamento` |
| **Estoque** | Reserva, baixa e cancelamento de peças | `ItemDeEstoque` |

**Contextos de suporte:**

| Contexto | Responsabilidade | Agregados |
|---|---|---|
| **Cadastros** | Gerenciar clientes (PF/PJ) e seus veículos — dados-mestre consumidos pelos contextos core | `Cliente`, `Veiculo` |

Os contextos **não se conhecem no nível de domínio**. A comunicação cross-context é feita por **chamada direta entre Application Services (use cases) com injeção de dependência**, conforme descrito por Eric Evans (Domain-Driven Design, cap. 4): a Application Layer "coordena tarefas e delega trabalho para objetos de domínio". Exemplo: ao aprovar um orçamento, o use case `AprovarOrcamento` chama diretamente `AprovarOrdemDeServico` e `BaixarQuantidade` — ambos injetados no construtor.

**Context map** (quem depende de quem):

```
          ┌───────────────┐
          │   CADASTROS   │  ◄──── FinalizarOS chama AtualizarQuilometragem
          │  (supporting) │
          └───────┬───────┘
                  │
   Dados de Cliente, Veículo e Serviço
   via repositórios injetados
                  │
     ┌────────────┼────────────┐
     ▼            ▼            ▼
┌─────────┐  ┌─────────┐  ┌─────────┐
│ ORDENS  │  │ ORÇA-   │  │ ESTOQUE │
│   DE    │──│ MENTOS  │──│(support)│
│ SERVIÇO │  │         │  │         │
└─────────┘  └─────────┘  └─────────┘
    core        core
```

Cadastros é um **supplier** no padrão Customer/Supplier: os contextos core consomem dados de Cliente/Veículo/Serviço dele via repositórios injetados.

### Camadas

```
app/
├── domains/                     # CAMADA DE DOMÍNIO — Ruby puro, sem Rails
│   ├── ordens_de_servico/
│   │   ├── ordem_de_servico.rb              # Agregado / entidade raiz
│   │   ├── repositorio_de_ordens_de_servico.rb  # Interface (módulo)
│   │   └── value_objects/                   # VOs imutáveis (StatusDaOrdem, etc)
│   ├── orcamentos/              # mesma estrutura
│   ├── estoque/                 # mesma estrutura
│   ├── cadastros/               # Cliente e Veículo (supporting subdomain)
│   └── shared/                  # Base classes e VOs cross-context (ValorMonetario…)
│
├── application/                 # CAMADA DE APLICAÇÃO — casos de uso
│   ├── ordens_de_servico/       # 1 arquivo = 1 caso de uso (ex: CriarOrdemDeServico)
│   ├── orcamentos/
│   ├── estoque/
│   ├── cadastros/
│   └── shared/                  # Base classes (CasoDeUso, Resultado)
│
├── infrastructure/              # CAMADA DE INFRAESTRUTURA — adapters
│   ├── persistence/             # ActiveRecord mora aqui, confinado
│   │   ├── ordens_de_servico/   # *_record.rb (AR) + repositório concreto
│   │   ├── orcamentos/
│   │   ├── estoque/
│   │   └── cadastros/
│   ├── read_models/             # Projeções de leitura (ex: lista de OS aprovadas)
│   └── integrations/            # Gateways para serviços externos (WhatsApp, etc)
│
├── controllers/                 # CAMADA DE INTERFACES — HTTP (convenção Rails)
│   └── api/v1/                  # Controllers finos: só parseiam input e chamam casos de uso
│
├── jobs/                        # CAMADA DE INTERFACES — async (convenção Rails)
│                                # Jobs também são só "entradas" que chamam casos de uso
│
└── models/                      # Apenas o ApplicationRecord base (convenção Rails)
                                 # Modelos de persistência vivem em infrastructure/persistence/
```

> **Por que `controllers/` e `jobs/` não estão dentro de `interfaces/`?** Conceitualmente eles *são* a camada de interfaces (HTTP e async, respectivamente). Mantemos nos caminhos convencionais do Rails apenas para não brigar com Zeitwerk, roteamento e generators. No código, trate-os como parte da camada de interfaces.

### Regra de dependência

As camadas de fora podem depender das camadas de dentro, **nunca o contrário**:

```
controllers/jobs  →  application  →  domains
                         ↓
                   infrastructure  →  domains
```

- `domains/` não importa nada do Rails, nem de `application/`, `infrastructure/`, `controllers/`.
- `application/` pode usar `domains/`, mas depende de repositórios via **interface** (definida em `domains/`), não da implementação AR.
- `infrastructure/persistence/` implementa as interfaces de repositório definidas em `domains/`.
- `controllers/` e `jobs/` orquestram: recebem input, chamam um caso de uso em `application/`, devolvem resposta. Nada de lógica de negócio.

### Convenções de nomenclatura

- **Domínio em português**: `OrdemDeServico`, `Orcamento`, `ItemDeEstoque`, `criar_ordem_de_servico`, etc. A *ubiquitous language* casa com os stakeholders.
- **Entidades de domínio** têm o nome limpo: `OrdemDeServico`.
- **Registros ActiveRecord** têm o sufixo `Record`: `OrdemDeServicoRecord`. Vivem em `infrastructure/persistence/`.
- **Repositórios** têm o prefixo `RepositorioDe...` (interface) e `RepositorioArDe...` (implementação AR).
- **Casos de uso** são verbos no infinitivo: `CriarOrdemDeServico`, `AprovarOrcamento`, `ReservarPeca`.
### Fluxo de exemplo (end-to-end)

Quando um atendente cria uma OS via API:

1. **HTTP** → `Api::V1::OrdensDeServicoController#create` recebe o request.
2. **Controller** instancia o caso de uso `CriarOrdemDeServico` com suas dependências (repositório de OS, repositório de clientes, repositório de veículos — todos injetados).
3. **Caso de uso** valida que cliente e veículo existem, cria a entidade `OrdemDeServico` (domínio), persiste via repositório.
4. **Repositório** converte a entidade para `OrdemDeServicoRecord` (AR) e grava no banco.
5. **Controller** devolve `201 Created` com o serializer.

Mais tarde, quando o mecânico diagnostica a OS:

1. **Controller** chama `DiagnosticarOrdemDeServico` (que recebeu `CriarOrcamento` como dependência injetada).
2. **Use case** muda status da OS para "AguardandoAprovacao" e persiste.
3. **Use case** chama `CriarOrcamento` diretamente — cruzando para o contexto **Orçamentos** na camada de aplicação.
4. `CriarOrcamento` copia os itens da OS com snapshot de preço e cria o agregado `Orcamento`.

O domínio permanece puro: `OrdemDeServico#diagnosticar` não sabe que orçamento existe. A orquestração cross-context vive exclusivamente na Application Layer (Evans, cap. 4).

## Swagger / Documentação da API

A documentação interativa da API é gerada automaticamente pelo [rswag](https://github.com/rswag/rswag) a partir dos request specs.

### Acessando a UI

Com a aplicação rodando, acesse:

```
http://localhost:3000/api-docs
```

O arquivo gerado fica em `swagger/v1/swagger.json` e é versionado no repositório.

### Regenerando a documentação

Sempre que um request spec for alterado, regenere o arquivo:

```bash
docker compose exec web bundle exec rake rswag:specs:swaggerize
```

### Manter em sincronia automaticamente

Dois mecanismos garantem que `swagger/v1/swagger.json` nunca fique desatualizado:

- **Pre-commit hook** (`.githooks/pre-commit`): antes de cada commit, verifica se algum arquivo em `spec/requests/` ou `spec/swagger_helper.rb` foi alterado. Se sim, regenera o JSON e inclui a atualização no mesmo commit.
- **Claude Code hook** (`.claude/settings.json`): dentro de uma sessão do Claude Code, regenera o JSON automaticamente sempre que Claude edita um request spec.

O hook de git requer uma configuração local feita pelo `bin/setup`:

```bash
git config core.hooksPath .githooks
```

### Adicionando documentação para novos endpoints

Os specs que geram o Swagger ficam em `spec/requests/api/v1/`. Siga o padrão do arquivo `customers_spec.rb` como referência: use o DSL `path`/`get`/`post`/`response` do rswag em um `RSpec.describe` com a tag `swagger_doc: 'v1/swagger.json'` e `require 'swagger_helper'`.

## Testes

Usamos **RSpec** com `factory_bot_rails`, `faker` e `shoulda-matchers`. A estrutura de `spec/` espelha `app/`:

```
spec/
├── domains/              # Testes unitários de entidades e VOs — sem Rails, extremamente rápidos
├── application/          # Testes de casos de uso com doubles para repositórios
├── infrastructure/
│   └── persistence/      # Testes de integração dos repositórios (batem no Postgres)
├── requests/             # Request specs para a API
│   └── api/v1/
├── factories/            # FactoryBot factories
└── support/              # Helpers compartilhados
```

**Rodando os testes:**
```bash
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rspec spec/domains        # só unit tests do domínio
docker compose exec web bundle exec rspec spec/requests       # só request specs
```

## Linting

Usamos **RuboCop** com `rubocop-rails-omakase` como base e `rubocop-rspec` para cops específicos de testes. Regras customizadas estão em `.rubocop.yml`.

```bash
docker compose exec web bundle exec rubocop                   # roda em tudo
docker compose exec web bundle exec rubocop -A                # auto-fix do que é seguro
docker compose exec web bundle exec rubocop app/domains       # só um diretório
```

## Segurança — Scanning de Vulnerabilidades

O projeto integra múltiplas ferramentas de segurança para cobrir diferentes camadas: dependências Ruby, código Rails, pacotes do SO e padrões de código malformados.

### Ferramentas utilizadas

| Ferramenta | O que detecta | Executado |
|---|---|---|
| **bundler-audit** | CVEs conhecidas em gems (Gemfile.lock) | Localmente + CI |
| **brakeman** | Vulnerabilidades específicas do Rails (SQL injection, XSS, etc) | Localmente + CI |
| **Trivy** | CVEs em pacotes OS, Dockerfile misconfigs, gems | CI apenas |
| **Semgrep** | Padrões de código inseguro (Ruby/Rails rules) | CI apenas |

### Executando scan localmente

Para gerar um relatório completo de segurança com os quatro scanners:

```bash
./bin/generate_security_report.sh
```

Isso irá:
1. Rodar **bundler-audit** para detectar gems com CVEs
2. Rodar **brakeman** para padrões inseguros do Rails
3. Rodar **Trivy** para vulnerabilidades no SO e Dockerfile
4. Rodar **Semgrep** para padrões de Ruby/Rails inseguros
5. Gerar relatório HTML em `tmp/security_report.html`
6. Converter para PDF em `tmp/security_report.pdf` (requer Chrome/Chromium)

O relatório é auto-contido com CSS inline, listando todas as descobertas agrupadas por ferramenta com severidade, linha do código (quando aplicável) e descrição do problema.

### CI — Segurança contínua

Na CI (GitHub Actions), a segurança roda em paralelo com testes e linting:

```yaml
scan_extra:
  - Trivy: escaneia filesystem (gems, pacotes OS, Dockerfile)
  - Semgrep: escaneia código com regras comunitárias de Ruby/Rails
  - Ambos exportam resultados para a aba "Security" do GitHub
```

**Comportamento em PRs:**
- **Trivy** — bloqueia se encontrar CVE crítico/alto
- **Semgrep** — não bloqueia (`continue-on-error: true`) enquanto construímos a baseline

Resultados aparecem em **Security → Code scanning** no repositório do GitHub, permitindo filtrar por severidade e arquivo.

### Entendendo cada ferramenta

#### bundler-audit
Compara `Gemfile.lock` contra um banco de dados de CVEs publicadas.

- **O que procura:** Versões de gems com vulnerabilidades conhecidas (SQLi, RCE, XSS, etc)
- **Exemplo de output:**
  ```
  gem: devise
  version: 4.8.0
  advisory_id: CVE-2021-12384
  title: Timing attack vulnerability in Devise password hashing
  ```
- **Remediar:** Atualizar a gem para versão patched (`bundle update devise`)

#### brakeman
Scanner estático nativo do Rails que procura por padrões inseguros no código Ruby.

- **O que procura:**
  - SQL injection (`User.find(params[:id])` sem sanitizar)
  - XSS (renderizar conteúdo do usuário sem escape)
  - Mass assignment (`attr_accessible` / `permit` incompleto)
  - Command injection (shell metacharacters em `system()`, backticks)
  - Uso de `eval()`, `instance_eval()`, etc
- **Exemplo de output:**
  ```
  Warning Type: Cross-Site Scripting
  File: app/views/orders/show.html.erb
  Line: 42
  Message: Unescaped user input in <%= @order.description %>
  ```
- **Remediar:** No Rails 8 com CSRF token automático e HTML escaping por padrão, a maioria dos alertas são falsos positivos. Se legítimo, refatorar código: usar `h()` ou `sanitize()` manualmente, ou usar strong parameters com `permit()`.

#### Trivy
Scanner de container e filesystem que detecta vulnerabilidades em camadas do Docker.

- **O que procura:**
  - **CVEs em pacotes OS** (de `Gemfile.lock`, através da imagem base Ruby)
  - **Misconfigurations no Dockerfile** (rodando como root, sem `USER`, `HEALTHCHECK` ausente, etc)
  - **Vulnerabilidades em dependências** (gems com histórico de CVEs)
- **Exemplo de output (vulnerabilidade OS):**
  ```
  CVE ID: CVE-2023-39615
  Package: openssl
  Installed: 1.1.1
  Fixed: 1.1.1w
  Severity: CRITICAL
  ```
- **Exemplo de output (misconfig):**
  ```
  ID: AVD-DKR-0001
  Title: Dockerfile should use COPY instead of ADD
  Severity: LOW
  ```
- **Remediar (vulnerabilidades):** Fazer rebuild da imagem Docker (`docker compose build`) para trazer versão atualizada da imagem base Ruby, que incluirá patches de segurança do SO.
- **Remediar (misconfigs):** Atualizar `Dockerfile` ou `Dockerfile.dev` com as recomendações.

#### Semgrep
Engine de pattern matching que executa regras comunitárias de segurança.

- **O que procura:** Usa rulesets comunitários `p/ruby` e `p/security-audit`, detectando:
  - SQL injection (mesmo em queries dinamicamente construídas)
  - Path traversal (`File.read(user_input)`)
  - Insecure randomness (`rand()` vs `SecureRandom`)
  - Weak cryptography (MD5, SHA-1 para senhas)
  - Deserialization de dados não confiáveis (`YAML.load`, `Marshal.load`)
  - Use de `system()` com input do usuário não sanitizado
- **Exemplo de output:**
  ```
  Rule ID: ruby.lang.security.deserialization.yaml-load
  File: lib/parser.rb
  Line: 15
  Severity: HIGH
  Message: Use YAML.safe_load instead of YAML.load to prevent code execution
  ```
- **Remediar:** Seguir a sugestão da mensagem. Geralmente é refatoração simples: `YAML.load(x)` → `YAML.safe_load(x)`, `eval(code)` → `Kernel.eval(code, BINDING)`, etc.

### Workflow recomendado

1. **Antes de comitar:**
   ```bash
   ./bin/generate_security_report.sh
   ```
   Revisar o relatório HTML. Se houver findings altos/críticos, ajustar código antes de fazer push.

2. **Em CI:** A segurança roda automaticamente. Trivy bloqueia se houver CVEs críticas; Semgrep apenas avisa (não bloqueia por enquanto).

3. **Em PRs:** A aba "Security" do GitHub mostra novos findings. Resolver antes de merge.

4. **Falsos positivos:** Se brakeman/Semgrep apontam código que você sabe ser seguro:
   - **brakeman:** adicionar comentário `# brakeman:ignore` na linha
   - **Semgrep:** prefixar com `# nosemgrep` ou usar `# pragma: no-security`

### Segredos e variáveis sensíveis

O projeto **não escaneia** variáveis de ambiente ou segredos no `.env`. Isso é responsabilidade de:

- **Pre-commit hooks** (`.githooks/pre-commit`): bloqueiam commit de `.env`
- **GitHub Secret scanning**: detecta tokens conhecidos em commits já feitos

Se notar que um segredo foi exposto em git:

```bash
# Remoção permanente do histórico
git-filter-repo --invert-paths --path .env
# Depois, force-push (cuidado, afeta histórico)
```

## Estrutura do projeto

- `app/` — código da aplicação (ver seção **Arquitetura** acima)
- `config/` — configurações (rotas, ambientes, database, queue)
- `db/` — migrations e schemas
- `spec/` — testes (RSpec)
- `Dockerfile.dev` — imagem usada em desenvolvimento
- `compose.yml` — orquestração dos serviços

O `Dockerfile` na raiz (sem `.dev`) é o gerado pelo Rails para produção e **não** é usado em desenvolvimento.

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

# 5. Subir a aplicação
docker compose up
```

Após o último passo, a API estará disponível em `http://localhost:3000`.

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

Foram identificados três contextos delimitados (do Event Storming):

| Contexto | Responsabilidade | Agregado principal |
|---|---|---|
| **Ordens de Serviço** | Ciclo de vida da OS (criação, diagnóstico, execução, finalização) | `OrdemDeServico` |
| **Orçamentos** | Criação, envio, aprovação e reprovação de orçamentos | `Orcamento` |
| **Estoque** | Reserva, baixa e cancelamento de peças | `ItemDeEstoque` |

Os contextos **não se conhecem diretamente**: eles se comunicam por **eventos de domínio** publicados num barramento interno. As políticas (listeners) que reagem a esses eventos vivem em `app/application/politicas/` — é o único lugar do código que "sabe sobre dois contextos ao mesmo tempo".

### Camadas

```
app/
├── domains/                     # CAMADA DE DOMÍNIO — Ruby puro, sem Rails
│   ├── ordens_de_servico/
│   │   ├── ordem_de_servico.rb              # Agregado / entidade raiz
│   │   ├── repositorio_de_ordens_de_servico.rb  # Interface (módulo)
│   │   ├── value_objects/                   # VOs imutáveis (StatusDaOrdem, etc)
│   │   └── eventos/                         # Eventos de domínio (OsCriada, OsDiagnosticada…)
│   ├── orcamentos/              # mesma estrutura
│   ├── estoque/                 # mesma estrutura
│   └── shared/                  # Base classes e VOs cross-context (ValorMonetario…)
│
├── application/                 # CAMADA DE APLICAÇÃO — casos de uso
│   ├── ordens_de_servico/       # 1 arquivo = 1 caso de uso (ex: CriarOrdemDeServico)
│   ├── orcamentos/
│   ├── estoque/
│   ├── politicas/               # Listeners cross-context (sagas/process managers)
│   └── shared/                  # Base classes (CasoDeUso, Resultado)
│
├── infrastructure/              # CAMADA DE INFRAESTRUTURA — adapters
│   ├── persistence/             # ActiveRecord mora aqui, confinado
│   │   ├── ordens_de_servico/   # *_record.rb (AR) + repositório concreto
│   │   ├── orcamentos/
│   │   └── estoque/
│   ├── barramento_de_eventos/   # Publisher/subscriber interno
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
- **Eventos de domínio** são substantivos no particípio: `OsCriada`, `OrcamentoAprovado`, `PecaReservada`.
- **Políticas** começam com `Quando...`: `QuandoOsDiagnosticadaCriaOrcamento`.

### Fluxo de exemplo (end-to-end)

Quando um atendente cria uma OS via API:

1. **HTTP** → `Api::V1::OrdensDeServicoController#create` recebe o request.
2. **Controller** instancia o caso de uso `OrdensDeServico::CriarOrdemDeServico` com suas dependências (repositório, barramento).
3. **Caso de uso** cria a entidade `OrdemDeServico` (domínio), persiste via repositório, publica o evento `OsCriada`.
4. **Repositório** converte a entidade para `OrdemDeServicoRecord` (AR) e grava no banco.
5. **Barramento** entrega `OsCriada` para qualquer listener inscrito (nenhum, por enquanto).
6. **Controller** devolve `201 Created` com o serializer.

Mais tarde, quando o mecânico diagnostica a OS:

1. `DiagnosticarOrdemDeServico` publica `OsDiagnosticada`.
2. A política `QuandoOsDiagnosticadaCriaOrcamento` (em `application/politicas/`) captura o evento.
3. A política chama `Orcamentos::CriarOrcamento` — cruzando para o contexto **Orçamentos**.
4. `Orcamentos::CriarOrcamento` cria o agregado `Orcamento` e publica `OrcamentoCriado`.

Nenhum desses passos acopla domínios diferentes. O único ponto de contato é o evento, que é *parte do domínio* (não da infraestrutura).

## Testes

Usamos **RSpec** com `factory_bot_rails`, `faker` e `shoulda-matchers`. A estrutura de `spec/` espelha `app/`:

```
spec/
├── domains/              # Testes unitários de entidades e VOs — sem Rails, extremamente rápidos
├── application/          # Testes de casos de uso com doubles para repositórios
│   └── politicas/        # Testes de integração de listeners cross-context
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

## Estrutura do projeto

- `app/` — código da aplicação (ver seção **Arquitetura** acima)
- `config/` — configurações (rotas, ambientes, database, queue)
- `db/` — migrations e schemas
- `spec/` — testes (RSpec)
- `Dockerfile.dev` — imagem usada em desenvolvimento
- `compose.yml` — orquestração dos serviços

O `Dockerfile` na raiz (sem `.dev`) é o gerado pelo Rails para produção e **não** é usado em desenvolvimento.

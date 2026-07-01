# 15SOAT - Fase 1 - Tech Challenge - Grupo 183

> Este é o README original da Fase 1. Para a visão atual do projeto (Fase 2 — Kubernetes, Terraform, CI/CD), veja o [README principal](../../README.md).

MVP do back-end de um sistema de gestão de oficina mecânica, desenvolvido como Tech Challenge de pós-graduação (FIAP). Aplica **Domain-Driven Design (DDD)** em um monolito Rails API-only, com separação explícita de camadas.

## Stack

- **Ruby** 3.4 / **Rails** 8.1 (API-only)
- **PostgreSQL** 17 — banco único para dados da aplicação e para o Solid Queue (sem Redis)
- **Solid Queue** — processamento de jobs em background
- **Docker Compose** — orquestração completa do ambiente de desenvolvimento

## Pré-requisitos

Apenas **Docker** (com suporte a `compose.yml`) e **git**. Não é necessário instalar Ruby, Rails ou PostgreSQL no host.

## Setup

```bash
git clone git@github.com:<seu-usuario>/oficina_mecanica.git
cd oficina_mecanica
cp .env.example .env
docker compose build
docker compose run --rm web bin/rails db:prepare
docker compose up
```

A API fica disponível em `http://localhost:3000`. O `db:prepare` já popula o banco com dados de demonstração (Rails 8 executa o seed automaticamente ao criar o banco), imprimindo no terminal um resumo com credenciais, IDs de clientes/veículos e protocols das WorkOrders criadas.

Para resetar tudo do zero:

```bash
docker compose down -v && docker compose run --rm web bin/rails db:prepare && docker compose up
```

## Explorando a API

Acesse o **Swagger UI** em [`http://localhost:3000/api-docs`](http://localhost:3000/api-docs) para documentação interativa de todos os endpoints.

**Credenciais padrão** (criadas pelo `db:seed`):

| Email                    | Senha        | Role     |
| ------------------------ | ------------ | -------- |
| `admin@oficina.local`    | `oficina123` | admin    |
| `mechanic@oficina.local` | `oficina123` | mechanic |

Para verificar que a aplicação está no ar: `curl -i http://localhost:3000/up` deve retornar `200 OK`.

Para um walkthrough completo via `curl` cobrindo o ciclo de vida de uma OS (abertura → diagnóstico → orçamento → aprovação → execução → finalização), veja [`demo.md`](demo.md).

## Arquitetura

Monolito Rails com separação explícita de camadas seguindo DDD. A motivação é manter o domínio isolado de detalhes de framework: quem lê `app/domains/` vê Ruby puro, sem vestígios de Rails.

### Bounded Contexts

| Contexto              | Tipo       | Responsabilidade                                                           |
| --------------------- | ---------- | -------------------------------------------------------------------------- |
| **Ordens de Serviço** | core       | Ciclo de vida da OS: criação, diagnóstico, execução e finalização          |
| **Orçamentos**        | core       | Criação, envio e aprovação de orçamentos                                   |
| **Estoque**           | supporting | Reserva e baixa de peças ao aprovar orçamento                              |
| **Cadastros**         | supporting | Clientes (PF/PJ) e veículos — dados-mestre consumidos pelos contextos core |

Os contextos não se conhecem no nível de domínio. A comunicação cross-context é feita por **chamada direta entre Application Services com injeção de dependência** na camada de aplicação (Evans, DDD cap. 4).

### Camadas

```
app/
├── domains/          # Ruby puro — entidades, value objects, interfaces de repositório
├── application/      # Casos de uso (1 arquivo = 1 use case, ex: CriarOrdemDeServico)
├── infrastructure/   # ActiveRecord, repositórios concretos, read models
├── controllers/      # HTTP — parseiam input e delegam ao caso de uso correspondente
└── jobs/             # Async — mesma responsabilidade dos controllers, convenção Rails
```

> `controllers/` e `jobs/` ficam nos caminhos convencionais do Rails por conta do Zeitwerk e do roteamento automático (_convention over configuration_), mas conceitualmente são a camada de interfaces.

**Regra de dependência:** `controllers/jobs → application → domains ← infrastructure`

**Nomenclatura em português** (`OrdemDeServico`, `CriarOrdemDeServico`, `RepositorioDeOrdens`) para casar com a Linguagem Ubíqua dos stakeholders. Registros ActiveRecord levam sufixo `Record` e vivem em `infrastructure/persistence/`.

### Por que PostgreSQL?

O Rails 8 introduziu Solid Queue e Solid Cache, que rodam sobre o próprio banco relacional — eliminando a necessidade de Redis. Com PostgreSQL já obrigatório para o domínio, manter tudo em um único banco simplifica o ambiente de desenvolvimento e reduz dependências operacionais sem abrir mão de confiabilidade.

## Segurança

Quatro ferramentas cobrindo dependências, código Rails, pacotes do SO e padrões inseguros:

| Ferramenta        | Escopo                                     |
| ----------------- | ------------------------------------------ |
| **bundler-audit** | CVEs em gems                               |
| **brakeman**      | Vulnerabilidades Rails (SQLi, XSS…)        |
| **Trivy**         | CVEs em pacotes OS e Dockerfile misconfigs |
| **Semgrep**       | Padrões inseguros Ruby/Rails               |

```bash
./bin/generate_security_report.sh   # gera relatório HTML + PDF em tmp/
```

Na CI (GitHub Actions), Trivy e Semgrep rodam em paralelo com testes e publicam resultados em **Security → Code scanning** no GitHub. Trivy bloqueia o pipeline em CVEs críticas/altas.

Para detalhes de cada ferramenta, exemplos de output e workflow de remediação, veja [`security.md`](security.md).

## Testes

RSpec com FactoryBot, Faker e shoulda-matchers. A estrutura de `spec/` espelha `app/`:

```
spec/
├── domains/          # Unitários — sem Rails, sem banco, extremamente rápidos
├── application/      # Casos de uso com doubles para repositórios
├── infrastructure/   # Integração com Postgres
└── requests/         # Request specs — também geram o swagger.json
```

```bash
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rspec spec/domains    # só unitários
docker compose exec web bundle exec rspec spec/requests   # só request specs
```

## Documentação da API (Swagger)

O `swagger/v1/swagger.json` é gerado a partir dos request specs via [rswag](https://github.com/rswag/rswag) e versionado no repositório. Para regenerar após alterar um request spec:

```bash
docker compose run --rm web bundle exec rake swagger:generate
```

## Comandos úteis

```bash
docker compose up -d                                       # sobe em background
docker compose down -v                                     # para e apaga volume Postgres
docker compose logs -f web                                 # logs da aplicação
docker compose exec web bin/rails console
docker compose exec web bin/rails routes
docker compose exec web bundle exec rubocop -A             # linting com auto-fix
```

## Troubleshooting

**Porta 3000 ou 5432 em uso:** pare o processo conflitante ou ajuste o mapeamento em `compose.yml`.

**Gems atualizadas no `Gemfile`:**

```bash
docker compose build web jobs
```

**Erro de permissão em arquivos gerados pelo container:** no Linux, ajuste com `sudo chown -R $USER:$USER .`. No macOS não costuma ocorrer.

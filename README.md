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

## Estrutura do projeto

Esqueleto padrão do Rails 8 API-only. As pastas relevantes para o dia-a-dia:

- `app/` — models, controllers, jobs, mailers
- `config/` — configurações (rotas, ambientes, database, queue)
- `db/` — migrations e schemas
- `Dockerfile.dev` — imagem usada em desenvolvimento
- `compose.yml` — orquestração dos serviços

O `Dockerfile` na raiz (sem `.dev`) é o gerado pelo Rails para produção e **não** é usado em desenvolvimento.

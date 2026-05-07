# Segurança — Scanning de Vulnerabilidades

O projeto integra quatro ferramentas cobrindo diferentes camadas: dependências Ruby, código Rails, pacotes do SO e padrões de código inseguros.

| Ferramenta        | O que detecta                                                 | Quando roda |
| ----------------- | ------------------------------------------------------------- | ----------- |
| **bundler-audit** | CVEs conhecidas em gems (`Gemfile.lock`)                      | Local + CI  |
| **brakeman**      | Vulnerabilidades Rails (SQL injection, XSS, mass assignment…) | Local + CI  |
| **Trivy**         | CVEs em pacotes OS, Dockerfile misconfigs, gems               | Local + CI  |
| **Semgrep**       | Padrões de código inseguro (Ruby/Rails rules)                 | Local + CI  |
| **SonarQube**     | Vulnerabilidades consolidadas, code smells, cobertura         | Local      |

## Executando localmente

```bash
./bin/generate_security_report.sh
```

Isso roda os quatro scanners e gera:

- `tmp/security_report.html` — relatório HTML com CSS inline
- `tmp/security_report.pdf` — versão PDF (requer Chrome/Chromium)

## Detalhes de cada ferramenta

### bundler-audit

Compara `Gemfile.lock` contra um banco de dados de CVEs publicadas.

**Exemplo de output:**

```
gem: devise
version: 4.8.0
advisory_id: CVE-2021-12384
title: Timing attack vulnerability in Devise password hashing
```

**Remediar:** atualizar a gem para a versão com patch (`bundle update devise`).

---

### brakeman

Scanner estático nativo do Rails. Detecta SQL injection, XSS, mass assignment, command injection, uso de `eval()`, etc.

**Exemplo de output:**

```
Warning Type: Cross-Site Scripting
File: app/views/orders/show.html.erb
Line: 42
Message: Unescaped user input in <%= @order.description %>
```

**Remediar:** no Rails 8 com CSRF e HTML escaping automáticos, a maioria dos alertas são falsos positivos. Se legítimo, usar `h()`, `sanitize()` ou strong parameters com `permit()`.

**Suprimir falso positivo:** adicionar `# brakeman:ignore` na linha.

---

### Trivy

Scanner de container e filesystem.

**Exemplo — vulnerabilidade OS:**

```
CVE ID: CVE-2023-39615
Package: openssl
Installed: 1.1.1 / Fixed: 1.1.1w
Severity: CRITICAL
```

**Exemplo — misconfig Dockerfile:**

```
ID: AVD-DKR-0001
Title: Dockerfile should use COPY instead of ADD
Severity: LOW
```

**Remediar vulnerabilidades:** rebuild da imagem (`docker compose build`) para trazer a versão atualizada da imagem base Ruby.  
**Remediar misconfigs:** ajustar `Dockerfile` ou `Dockerfile.dev`.

---

### Semgrep

Engine de pattern matching com rulesets comunitários `p/ruby` e `p/security-audit`. Detecta: SQL injection, path traversal, insecure randomness, weak cryptography, deserialization insegura (`YAML.load`, `Marshal.load`), `system()` com input não sanitizado.

**Exemplo de output:**

```
Rule ID: ruby.lang.security.deserialization.yaml-load
File: lib/parser.rb / Line: 15
Severity: HIGH
Message: Use YAML.safe_load instead of YAML.load to prevent code execution
```

**Remediar:** seguir a sugestão da mensagem — geralmente é uma substituição simples.  
**Suprimir falso positivo:** prefixar com `# nosemgrep`.

---

### SonarQube

Análise consolidada de segurança, qualidade de código e cobertura em um dashboard interativo. Integra-se com SimpleCov para mostrar quais linhas estão cobertas por testes.

**O que detecta:**
- Hotspots de segurança (código suspeito que precisa de review)
- Vulnerabilidades (com severidade: Blocker, Critical, Major, Minor, Info)
- Code smells (código confuso ou duplicado)
- Cobertura de testes por linha/branch
- Duplicação de código

**Executar análise localmente:**

```bash
# 1. Gerar relatório de cobertura com SimpleCov JSON
docker compose run --rm web sh -c "COVERAGE=1 bundle exec rspec"

# 2. Iniciar SonarQube (primeira execução: 60-120s)
docker compose -f compose.sonar.yml up sonarqube -d

# 3. Esperar pelo servidor ficar pronto
sleep 30

# 4. Gerar token de autenticação
TOKEN=$(curl -s -u admin:admin -X POST "http://localhost:9000/api/user_tokens/generate?name=scanner" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

# 5. Executar análise
docker run --rm --network oficina-mecanica-sonar_sonar \
  -e SONAR_HOST_URL=http://sonarqube:9000 \
  -e SONAR_TOKEN=$TOKEN \
  -v "$PWD":/usr/src \
  sonarsource/sonar-scanner-cli:latest
```

**Acessar o dashboard:**
- URL: http://localhost:9000/dashboard?id=oficina_mecanica
- Login padrão (primeira vez): admin / admin (força mudança de senha)

**Tabs principais:**
- **Overview** — métricas gerais (bugs, vulnerabilidades, code smells, cobertura)
- **Security** — vulnerabilidades por severidade, hotspots, análise de risco
- **Code** — code smells, duplicação, tamanho de métodos
- **Coverage** — linha por linha com cores (verde = coberto, vermelho = não coberto)

**Parar SonarQube:**

```bash
docker compose -f compose.sonar.yml down
```

**Rodadas subsequentes:**

Se SonarQube já está rodando:
```bash
TOKEN=$(curl -s -u admin:admin -X POST "http://localhost:9000/api/user_tokens/generate?name=scanner" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
docker run --rm --network oficina-mecanica-sonar_sonar \
  -e SONAR_HOST_URL=http://sonarqube:9000 \
  -e SONAR_TOKEN=$TOKEN \
  -v "$PWD":/usr/src \
  sonarsource/sonar-scanner-cli:latest
```

**Arquivos de configuração:**
- `sonar-project.properties` — define qual código analisar, exclusões, caminho da cobertura
- `compose.sonar.yml` — stack Docker isolado (não polui a stack da aplicação)

**Integração com SimpleCov:**
SonarQube lê `coverage/coverage.json` gerado pelo `simplecov_json_formatter` e mostra cobertura por linha. Código não coberto é destacado em vermelho no dashboard, facilitando identificar gaps de teste.

---

## CI — Segurança contínua

Na CI (GitHub Actions), Trivy e Semgrep rodam em paralelo com testes e linting, exportando resultados para **Security → Code scanning** no GitHub.

- **Trivy** — bloqueia o pipeline se encontrar CVE crítico/alto
- **Semgrep** — não bloqueia (`continue-on-error: true`) enquanto construímos a baseline

## Segredos e variáveis sensíveis

O `.env` **não é commitado**. Dois mecanismos protegem isso:

- **Pre-commit hook** (`.githooks/pre-commit`): bloqueia commit de `.env`
- **GitHub Secret scanning**: detecta tokens conhecidos em commits já feitos

Se um segredo for exposto no histórico:

```bash
git-filter-repo --invert-paths --path .env
# Depois force-push (afeta histórico compartilhado — alinhar com o time antes)
```

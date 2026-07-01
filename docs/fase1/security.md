# Segurança — Scanning de Vulnerabilidades

O projeto integra cinco ferramentas cobrindo diferentes camadas: dependências Ruby, código Rails, pacotes do SO, padrões de código inseguros e comportamento em tempo de execução.

| Ferramenta        | Tipo  | O que detecta                                                 | Quando roda |
| ----------------- | ----- | ------------------------------------------------------------- | ----------- |
| **bundler-audit** | SAST  | CVEs conhecidas em gems (`Gemfile.lock`)                      | Local + CI  |
| **brakeman**      | SAST  | Vulnerabilidades Rails (SQL injection, XSS, mass assignment…) | Local + CI  |
| **Trivy**         | SAST  | CVEs em pacotes OS, Dockerfile misconfigs, gems               | Local + CI  |
| **Semgrep**       | SAST  | Padrões de código inseguro (Ruby/Rails rules)                 | Local + CI  |
| **SonarQube**     | SAST  | Vulnerabilidades consolidadas, code smells, cobertura         | Local       |
| **OWASP ZAP**     | DAST  | Vulnerabilidades em tempo de execução via requisições reais   | Local       |

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
./bin/run_sonarqube.sh
```

A primeira execução demora 30-60s (SonarQube iniciando). Rodadas subsequentes são mais rápidas.

**Comandos disponíveis:**

```bash
./bin/run_sonarqube.sh analyze     # Rodar análise completa (padrão)
./bin/run_sonarqube.sh dashboard   # Abrir dashboard no navegador
./bin/run_sonarqube.sh stop        # Parar servidor e limpar volumes
```

**Dashboard:**
- Abres automaticamente após a análise ou via `./bin/run_sonarqube.sh dashboard`
- URL: http://localhost:9000/dashboard?id=oficina_mecanica
- Login padrão (primeira vez): admin / admin

**Tabs principais:**
- **Overview** — métricas gerais (bugs, vulnerabilidades, code smells, cobertura)
- **Security** — vulnerabilidades por severidade, hotspots, análise de risco
- **Code** — code smells, duplicação, tamanho de métodos
- **Coverage** — linha por linha com cores (verde = coberto, vermelho = não coberto)

**Arquivos de configuração:**
- `sonar-project.properties` — define qual código analisar, exclusões, caminho da cobertura
- `compose.sonar.yml` — stack Docker isolado (não polui a stack da aplicação)
- `bin/run_sonarqube.sh` — script que orquestra todo o fluxo

---

### OWASP ZAP

Scanner dinâmico (DAST — *Dynamic Application Security Testing*). Ao contrário das ferramentas acima, que leem o código sem executá-lo, o ZAP sobe como um proxy e faz requisições reais à API em execução, observando as respostas em busca de vulnerabilidades que só se manifestam em tempo de execução: headers de segurança ausentes, exposição de informações no corpo das respostas, falhas de autenticação e injeção.

O script autentica automaticamente com as credenciais do seed, obtém um token JWT e o injeta em todas as requisições, garantindo cobertura dos endpoints protegidos.

**Executar localmente (requer `docker compose up -d`):**

```bash
./bin/run_zap.sh          # executa o scan e gera o relatório
./bin/run_zap.sh report   # abre tmp/zap_report.html no navegador
```

**Exemplos de alertas detectados:**

```
Alert: X-Content-Type-Options Header Missing
Risk: Low | URL: http://localhost:3000/api/v1/orders
Solution: Ensure the application sets the header 'X-Content-Type-Options' to 'nosniff'

Alert: Application Error Disclosure
Risk: Medium | URL: http://localhost:3000/api/v1/budgets
Solution: Review error handling to avoid leaking stack traces in production
```

**Remediar:** seguir a solução sugerida no alerta — geralmente um header de resposta ou ajuste no tratamento de erros.

**Arquivos de configuração:**
- `bin/run_zap.sh` — script que orquestra o fluxo completo
- `tmp/zap_openapi.json` — spec OpenAPI gerada pelo script (não commitada)
- `tmp/zap_report.html` — relatório HTML gerado pelo ZAP (não commitado)

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

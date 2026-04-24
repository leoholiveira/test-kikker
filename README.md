# Test Kikker

API REST em **Ruby on Rails 8** com **PostgreSQL**. Este documento descreve como instalar, executar, testar, rodar o **RuboCop** e carregar os **seeds** no ambiente recomendado (**Docker**).

---

## Pré-requisitos

- **Docker** e **Docker Compose** (v2)
- No **macOS com Apple Silicon (M1/M2/M3)**, use o Docker Desktop com virtualização padrão; as imagens do projeto publicam `linux/arm64`

**Versões de referência** (veja `Dockerfile.mac` e `Gemfile`):

- Ruby **3.4.x** (imagem `ruby:3.4-slim`)
- Rails **~> 8.0**
- PostgreSQL **16** (imagem `postgres:16-alpine`)

---

## Instalação e execução com Docker (recomendado)

No diretório do projeto:

```bash
docker compose build
docker compose up
```

O `docker-compose.yml` está configurado para usar o **`Dockerfile.mac`** (linha 34) — adequado para **Mac M1 (Apple Silicon)** e builds que acompanham esse ambiente. Se precisar do **`Dockerfile`** padrão (por exemplo, Linux x86/CI ou outro fluxo), abra o `docker-compose.yml` e, na seção `web` → `build`, troque `dockerfile: Dockerfile.mac` por `dockerfile: Dockerfile` nessa **linha 34** (ou mantenha o caminho do arquivo que fizer sentido no seu `docker-compose` local).

Na **primeira subida** (ou após novas migrations), o serviço `web` roda `bin/rails db:prepare` e `bin/rails db:test:prepare` antes do servidor.

- **Aplicação:** [http://localhost:3000](http://localhost:3000)
- **PostgreSQL (host):** porta `5432` mapeada para o container `db`

**Variáveis de ambiente no Compose** (já definidas no `docker-compose.yml`):

- `DATABASE_URL` — desenvolvimento: `postgresql://postgres:postgres@db:5432/test_kikker_development`
- `DATABASE_TEST_URL` — teste: `postgresql://postgres:postgres@db:5432/test_kikker_test`

**Health check:** `GET /up` (retorna 200 se a aplicação subir sem exceção).

### Comandos úteis dentro do contêiner

Com o stack de pé:

```bash
docker compose exec web bash
```

A partir daí você pode executar `bin/rails`, `bundle exec`, etc.

---

## Instalação local (sem Docker) — opcional

Requer **Ruby** compatível com o projeto, **Bundler**, **PostgreSQL** local e o cliente de desenvolvimento do PostgreSQL (`libpq`).

1. Crie os bancos e configure as URLs, por exemplo:

   ```bash
   export DATABASE_URL="postgresql://usuario:senha@localhost:5432/test_kikker_development"
   export DATABASE_TEST_URL="postgresql://usuario:senha@localhost:5432/test_kikker_test"
   ```

2. Instale as gems:

   ```bash
   bundle install
   ```

3. Prepare o schema:

   ```bash
   RAILS_ENV=development bin/rails db:prepare
   RAILS_ENV=test bin/rails db:test:prepare
   ```

4. Sobe o servidor:

   ```bash
   bin/rails server
   ```

> **Observação:** o fluxo documentado e testado no repositório é o **Docker Compose**; ajuste usuário/senha/porta do PostgreSQL conforme a sua instalação.

---

## Testes (RSpec)

Com o banco de **teste** preparado e as variáveis `DATABASE_TEST_URL` (ou `config/database.yml`) corretas:

### No Docker

```bash
docker compose exec web bundle exec rspec
```

**Arquivo de um grupo só:**

```bash
docker compose exec web bundle exec rspec spec/requests/assignment_api_spec.rb
```

### Local

```bash
RAILS_ENV=test bundle exec rspec
```

O projeto usa **RSpec**, **FactoryBot** e **Shoulda Matchers** (veja o `Gemfile`).

---

## RuboCop

O estilo segue a stack **rubocop-rails-omakase** (veja o `Gemfile` e `.rubocop.yml`).

### No Docker

```bash
docker compose exec web bundle exec rubocop
```

**Aplicar correções automáticas** (onde o cop permitir):

```bash
docker compose exec web bundle exec rubocop -A
```

### Local

```bash
bundle exec rubocop
bundle exec rubocop -A
```

### Outras análises (opcional)

- **Brakeman** (segurança), se quiser no CI ou local: `bundle exec brakeman`

---

## Seeds (`db/seeds.rb`)

O arquivo de seed gera um **volume grande** de dados: cerca de **200.000 posts**, **100 usuários**, **~50 IPs** e aproximadamente **75%** dos posts com **avaliações (ratings)**.  
No próprio início do arquivo existe `ENV["SEED_FORCE_RESET"] = "1"`, o que força o **esvaziamento** de `ratings`, `posts` e `users` antes de semear (use com cuidado em ambientes reais).

### Dois modos de execução

| Modo | Variável | Descrição |
|------|----------|------------|
| **API (controladores)** | *(padrão, sem `SEED_BULK`)* | Cada criação passa pelos **controllers** (stack HTTP em processo ou `curl` opcional). Atende a regras de “usar a API” em avaliações. **Demora muito** com 200k registros. |
| **Bulk (performance)** | `SEED_BULK=1` | Usa `insert_all` no PostgreSQL em lotes. **Não** passa pelos controllers. Muito mais rápido, adequado a carga de volume. |

**Tamanho do lote (apenas no modo bulk):** `SEED_INSERT_BATCH` (padrão `2500` no código, se definido com valor inválido cai no mínimo `500`).

**Semente aleatória (reprodutibilidade aproximada):** `SEED_RANDOM_SEED`.

### Com Docker

Com os serviços ativos, **na API por controlador** (lento para o volume completo):

```bash
docker compose exec web env SEED_FORCE_RESET=1 bin/rails db:seed
```

**Não** defina `SEED_BULK` (ou deixe `SEED_BULK` diferente de `1`) para manter o modo que usa os **controllers**.

**Modo bulk (rápido):**

```bash
docker compose exec web env SEED_BULK=1 SEED_FORCE_RESET=1 bin/rails db:seed
```

**Exemplo ajustando o lote:**

```bash
docker compose exec web env SEED_BULK=1 SEED_INSERT_BATCH=5000 SEED_FORCE_RESET=1 bin/rails db:seed
```

### `curl` em vez de integração in-process (opcional)

Com o Puma acessível (por exemplo o próprio contêiner `web` com a app na porta 3000):

```bash
docker compose exec web env \
  SEED_USE_CURL=1 \
  SEED_API_BASE="http://127.0.0.1:3000" \
  SEED_FORCE_RESET=1 \
  bin/rails db:seed
```

(Em geral, o modo padrão sem `SEED_USE_CURL` usa o cliente de integração do Rails, sem abrir o `curl` por registro.)

### O que observar

- O seed exige, na prática, tabelas **vazias** de `User` / `Post` / `Rating` **ou** o fluxo de reset (conforme o bloco `SEED_FORCE_RESET` no `db/seeds.rb` e a linha que define essa variável no topo do arquivo).
- O modo **API** gera centenas de milhares de requisições; para desenvolvimento diário, prefira `SEED_BULK=1` se o objetivo for só encher a base.
- Ajuste o topo do `db/seeds.rb` (por exemplo a linha que fixa `SEED_FORCE_RESET`) se quiser `bin/rails db:seed` vazio em projetos pessoais, sem carga de massa.

---

## Estrutura relevante

- `app/controllers/` — endpoints da API (`posts`, `ratings`, `users`)
- `config/routes.rb` — rotas, incluindo `GET /posts/top` e `GET /posts/ips_by_authors`
- `db/seeds.rb` — seed de volume e clientes de API
- `spec/` — RSpec (requests, models, etc.)

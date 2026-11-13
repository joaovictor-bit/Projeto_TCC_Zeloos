# Backend da Pulseira Localizadora

## Visão geral
Este backend foi desenvolvido em Node.js + Express para apoiar o sistema de pulseira localizadora infantil com autenticação JWT, CRUD de crianças, pulseiras, locais seguros, alertas e configurações.

## Estrutura
- src/app.js
- src/config/db.js
- src/config/env.js
- src/controllers/
- src/middlewares/authMiddleware.js
- src/repositories/
- src/routes/
- src/utils/geo.js
- src/validators/
- database/schema.sql
- database/seed.sql

## Instalação
1. Abra o terminal na pasta backend.
2. Copie o arquivo .env.example para .env.
3. Ajuste os valores de acesso ao MySQL.
4. Execute:

```bash
npm install
```

## Configuração do MySQL
1. Instale o MySQL localmente.
2. Crie um usuário e banco conforme o arquivo .env.
3. Execute o script SQL:

```bash
mysql -u seu_usuario -p < database/schema.sql
```

Opcionalmente, carregue dados de demonstração:

```bash
mysql -u seu_usuario -p < database/seed.sql
```

O driver `mysql2` não oferece suporte ao plugin de autenticação `auth_gssapi_client`. Se a API retornar `AUTH_SWITCH_PLUGIN_ERROR`, configure uma conta exclusiva para o aplicativo com um plugin compatível, como `caching_sha2_password` no MySQL 8, e atualize `DB_USER` e `DB_PASSWORD` no `.env`:

```sql
CREATE USER 'pulseira_app'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'troque-por-uma-senha-forte';
GRANT SELECT, INSERT, UPDATE, DELETE ON pulseira_localizadora.* TO 'pulseira_app'@'localhost';
```

Execute o `schema.sql` com uma conta administrativa antes de iniciar a API. Se o MySQL estiver em outro computador, restrinja o host da conta ao endereço de origem do backend em vez de usar `localhost`.

## Iniciar a API
```bash
npm run dev
```

No PowerShell do Windows, use o executável `.cmd` para evitar o bloqueio do
script `npm.ps1` pela política de execução:

```powershell
npm.cmd run dev
```

O endpoint `GET /api/health` verifica também a conexão com o banco; responde `503` quando o banco não está acessível.

## Endpoints principais
- POST /api/auth/register
- POST /api/auth/login
- GET /api/auth/me
- GET /api/criancas
- POST /api/criancas
- GET /api/criancas/:id
- PUT /api/criancas/:id
- DELETE /api/criancas/:id
- GET /api/pulseiras
- POST /api/pulseiras
- GET /api/pulseiras/:id/localizacao-atual
- GET /api/pulseiras/:id/historico
- POST /api/pulseiras/receber-localizacao
- GET /api/alertas
- PATCH /api/alertas/:id/visualizar
- PATCH /api/alertas/:id/resolver

## Localização da pulseira
O app atualiza a tela do mapa a cada 15 segundos e mostra a última localização recebida pela API. O dispositivo deve enviar posições reais para `POST /api/pulseiras/receber-localizacao`, usando o identificador cadastrado:

```json
{
  "identificador": "BRACELET-001",
  "latitude": -23.55052,
  "longitude": -46.63331,
  "bateria_percentual": 82
}
```

Sem um dispositivo enviando coordenadas, o mapa informa que ainda não recebeu localização; ele não simula movimento.
O mapa usa tiles do OpenStreetMap durante o desenvolvimento. Para uso em produção, configure um provedor de tiles que atenda aos termos e limites de uso do serviço escolhido.

## Documentação da API (Swagger)
Com a API rodando, acesse:

- Interface interativa: http://localhost:3005/api-docs
- Especificação OpenAPI (JSON): http://localhost:3005/api-docs.json

A especificação fica em `src/docs/swagger.js`. Para testar rotas protegidas pela interface, chame `POST /api/auth/login`, copie o `token` da resposta, clique em **Authorize** e cole apenas o token. Ao criar ou alterar uma rota, documente-a também em `src/docs/swagger.js` — o teste `tests/swagger.test.js` falha se alguma rota da API não estiver documentada.

## Autenticação
O token deve ser enviado no header:

```http
Authorization: Bearer <token>
```

## Modo de demonstração
O endpoint de recepção de geolocalização foi organizado para aceitar dados simulados com o campo `origem` e pode ser usado em ambiente de prova sem hardware real.

## Testes
```bash
npm test
```

No PowerShell, use `npm.cmd test`. Os testes não precisam do MySQL: o banco e os repositórios são substituídos por mocks do Jest.

- `tests/unit/`: testes unitários de utilitários (`geo`), middleware de autenticação, validadores, controllers e repositório de pulseiras.
- `tests/auth.test.js` e `tests/pulseira.test.js`: testes das rotas HTTP com `supertest`.
- `tests/swagger.test.js`: garante que o Swagger está disponível e que todas as rotas estão documentadas.

Para gerar o relatório de cobertura:

```bash
npx jest --coverage
```

## Importante
O backend não deve expor segredos em produção, e não deve misturar dados reais com dados simulados sem marcação explícita.

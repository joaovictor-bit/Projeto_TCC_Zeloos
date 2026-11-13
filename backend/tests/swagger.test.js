const request = require('supertest');
const app = require('../src/app');
const swaggerSpec = require('../src/docs/swagger');

jest.mock('../src/config/db', () => ({ execute: jest.fn() }));

function listarRotasExpress() {
  const rotas = [];
  app._router.stack.forEach((layer) => {
    if (layer.route) {
      Object.keys(layer.route.methods).forEach((method) => rotas.push({ method, path: layer.route.path }));
      return;
    }
    if (layer.name !== 'router' || !layer.regexp) return;
    const prefixo = layer.regexp.source
      .replace('^\\', '')
      .replace('\\/?(?=\\/|$)', '')
      .replace(/\\\//g, '/');
    layer.handle.stack.forEach((sub) => {
      if (!sub.route) return;
      Object.keys(sub.route.methods).forEach((method) => {
        rotas.push({ method, path: `${prefixo}${sub.route.path}`.replace(/\/$/, '') });
      });
    });
  });
  return rotas.filter((r) => r.path.startsWith('/api/'));
}

const toOpenApiPath = (path) => path.replace(/:(\w+)/g, '{$1}');

describe('Swagger / OpenAPI', () => {
  test('GET /api-docs.json retorna a especificação OpenAPI', async () => {
    const response = await request(app).get('/api-docs.json');

    expect(response.status).toBe(200);
    expect(response.body.openapi).toMatch(/^3\./);
    expect(response.body.info.title).toBeDefined();
  });

  test('GET /api-docs/ serve a interface do Swagger UI', async () => {
    const response = await request(app).get('/api-docs/');

    expect(response.status).toBe(200);
    expect(response.text).toContain('swagger-ui');
  });

  test('todas as rotas da API estão documentadas', () => {
    const naoDocumentadas = listarRotasExpress()
      .filter(({ path }) => path !== '/api/pulseiras/health')
      .filter(({ method, path }) => !swaggerSpec.paths[toOpenApiPath(path)]?.[method])
      .map(({ method, path }) => `${method.toUpperCase()} ${path}`);

    expect(naoDocumentadas).toEqual([]);
  });

  test('todas as referências $ref apontam para schemas existentes', () => {
    const refs = JSON.stringify(swaggerSpec).match(/#\/components\/schemas\/\w+/g) || [];
    const inexistentes = [...new Set(refs)]
      .map((ref) => ref.split('/').pop())
      .filter((nome) => !swaggerSpec.components.schemas[nome]);

    expect(inexistentes).toEqual([]);
  });
});

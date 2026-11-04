const request = require('supertest');
const app = require('../src/app');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const userRepository = require('../src/repositories/userRepository');
const db = require('../src/config/db');

jest.mock('jsonwebtoken', () => ({
  sign: jest.fn(() => 'fake-jwt-token'),
  verify: jest.fn(() => ({ id: 1, email: 'responsavel@demo.com', nome: 'Responsável Demo' })),
}));

jest.mock('bcryptjs', () => ({
  hash: jest.fn(async () => 'hashed-password'),
  compare: jest.fn(async () => true),
}));

jest.mock('../src/repositories/userRepository', () => ({
  findByEmail: jest.fn(),
  createUser: jest.fn(),
  findById: jest.fn(),
}));

jest.mock('../src/config/db', () => ({
  execute: jest.fn(),
}));

describe('Backend auth flow', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('GET /api/health should verify database connectivity', async () => {
    db.execute.mockResolvedValue([[{ 1: 1 }], []]);

    const response = await request(app).get('/api/health');

    expect(response.status).toBe(200);
    expect(response.body.database).toBe('ok');
    expect(response.headers['cache-control']).toBe('no-store');
  });

  test('CORS should allow local Flutter web development ports', async () => {
    db.execute.mockResolvedValue([[{ 1: 1 }], []]);

    const response = await request(app)
      .get('/api/health')
      .set('Origin', 'http://localhost:8080');

    expect(response.headers['access-control-allow-origin']).toBe('http://localhost:8080');
  });

  test('CORS should not allow unconfigured external origins', async () => {
    db.execute.mockResolvedValue([[{ 1: 1 }], []]);

    const response = await request(app)
      .get('/api/health')
      .set('Origin', 'https://untrusted.example');

    expect(response.headers['access-control-allow-origin']).toBeUndefined();
  });

  test('GET /api/health should report unavailable database', async () => {
    db.execute.mockRejectedValue({ code: 'AUTH_SWITCH_PLUGIN_ERROR' });

    const response = await request(app).get('/api/health');

    expect(response.status).toBe(503);
    expect(response.body.database).toBe('unavailable');
    expect(response.body.error).toBe('AUTH_SWITCH_PLUGIN_ERROR');
  });

  test('POST /api/auth/register should create user and return token', async () => {
    userRepository.findByEmail.mockResolvedValue(null);
    userRepository.createUser.mockResolvedValue({ id: 1, nome: 'Responsável Demo', email: 'responsavel@demo.com' });

    const response = await request(app)
      .post('/api/auth/register')
      .send({ nome: 'Responsável Demo', email: 'responsavel@demo.com', senha: '123456' });

    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
    expect(response.body.token).toBe('fake-jwt-token');
    expect(userRepository.createUser).toHaveBeenCalled();
  });

  test('POST /api/auth/login should authenticate existing user', async () => {
    userRepository.findByEmail.mockResolvedValue({
      id: 1,
      nome: 'Responsável Demo',
      email: 'responsavel@demo.com',
      senha_hash: 'hashed-password',
      telefone: null,
      ativo: 1,
    });

    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'responsavel@demo.com', senha: '123456' });

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(bcrypt.compare).toHaveBeenCalledWith('123456', 'hashed-password');
  });

  test('GET /api/auth/me should require valid token', async () => {
    userRepository.findById.mockResolvedValue({
      id: 1,
      nome: 'Responsável Demo',
      email: 'responsavel@demo.com',
      ativo: 1,
    });

    const response = await request(app)
      .get('/api/auth/me')
      .set('Authorization', 'Bearer fake-jwt-token');

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(jwt.verify).toHaveBeenCalled();
  });
});

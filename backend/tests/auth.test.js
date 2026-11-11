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
  updateProfile: jest.fn(),
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

  test('POST /api/auth/register should save optional phone', async () => {
    userRepository.findByEmail.mockResolvedValue(null);
    userRepository.createUser.mockResolvedValue({ id: 1, nome: 'Responsável Demo', email: 'responsavel@demo.com', telefone: '(11) 98765-4321' });

    const response = await request(app)
      .post('/api/auth/register')
      .send({ nome: 'Responsável Demo', email: 'responsavel@demo.com', senha: '123456', telefone: '(11) 98765-4321' });

    expect(response.status).toBe(201);
    expect(userRepository.createUser).toHaveBeenCalledWith(expect.objectContaining({ telefone: '(11) 98765-4321' }));
  });

  test('POST /api/auth/register should store null when phone is empty', async () => {
    userRepository.findByEmail.mockResolvedValue(null);
    userRepository.createUser.mockResolvedValue({ id: 1, nome: 'Responsável Demo', email: 'responsavel@demo.com' });

    const response = await request(app)
      .post('/api/auth/register')
      .send({ nome: 'Responsável Demo', email: 'responsavel@demo.com', senha: '123456', telefone: '' });

    expect(response.status).toBe(201);
    expect(userRepository.createUser).toHaveBeenCalledWith(expect.objectContaining({ telefone: null }));
  });

  test('POST /api/auth/register should reject invalid phone', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({ nome: 'Responsável Demo', email: 'responsavel@demo.com', senha: '123456', telefone: '123' });

    expect(response.status).toBe(400);
    expect(response.body.errors[0].field).toBe('telefone');
    expect(userRepository.createUser).not.toHaveBeenCalled();
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

  test('PUT /api/auth/me should update name and phone of logged user', async () => {
    userRepository.updateProfile.mockResolvedValue({
      id: 1,
      nome: 'Novo Nome',
      email: 'responsavel@demo.com',
      telefone: '(11) 98765-4321',
      ativo: 1,
    });

    const response = await request(app)
      .put('/api/auth/me')
      .set('Authorization', 'Bearer fake-jwt-token')
      .send({ nome: 'Novo Nome', telefone: '(11) 98765-4321' });

    expect(response.status).toBe(200);
    expect(response.body.user.nome).toBe('Novo Nome');
    expect(userRepository.updateProfile).toHaveBeenCalledWith(1, { nome: 'Novo Nome', telefone: '(11) 98765-4321' });
  });

  test('PUT /api/auth/me should clear phone when empty', async () => {
    userRepository.updateProfile.mockResolvedValue({ id: 1, nome: 'Novo Nome', email: 'responsavel@demo.com', telefone: null });

    const response = await request(app)
      .put('/api/auth/me')
      .set('Authorization', 'Bearer fake-jwt-token')
      .send({ nome: 'Novo Nome', telefone: '' });

    expect(response.status).toBe(200);
    expect(userRepository.updateProfile).toHaveBeenCalledWith(1, { nome: 'Novo Nome', telefone: null });
  });

  test('PUT /api/auth/me should reject invalid data', async () => {
    const response = await request(app)
      .put('/api/auth/me')
      .set('Authorization', 'Bearer fake-jwt-token')
      .send({ nome: 'A', telefone: '12' });

    expect(response.status).toBe(400);
    expect(response.body.errors.map((e) => e.field)).toEqual(['nome', 'telefone']);
    expect(userRepository.updateProfile).not.toHaveBeenCalled();
  });

  test('PUT /api/auth/me should require token', async () => {
    const response = await request(app).put('/api/auth/me').send({ nome: 'Novo Nome' });

    expect(response.status).toBe(401);
  });
});

const jwt = require('jsonwebtoken');
const authMiddleware = require('../../src/middlewares/authMiddleware');
const { JWT_SECRET } = require('../../src/config/env');
const { mockRequest, mockResponse } = require('./helpers');

describe('middlewares/authMiddleware', () => {
  test('retorna 401 quando não há header Authorization', () => {
    const req = mockRequest({ user: undefined });
    const res = mockResponse();
    const next = jest.fn();

    authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: false }));
    expect(next).not.toHaveBeenCalled();
  });

  test('retorna 401 quando o header não usa o esquema Bearer', () => {
    const req = mockRequest({ headers: { authorization: 'Basic abc123' }, user: undefined });
    const res = mockResponse();
    const next = jest.fn();

    authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  test('retorna 401 para token inválido', () => {
    const req = mockRequest({ headers: { authorization: 'Bearer token-invalido' }, user: undefined });
    const res = mockResponse();
    const next = jest.fn();

    authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ message: 'Token expirado ou inválido.' }));
    expect(next).not.toHaveBeenCalled();
  });

  test('retorna 401 para token assinado com outro segredo', () => {
    const token = jwt.sign({ id: 1 }, 'outro-segredo');
    const req = mockRequest({ headers: { authorization: `Bearer ${token}` }, user: undefined });
    const res = mockResponse();
    const next = jest.fn();

    authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  test('retorna 401 para token expirado', () => {
    const token = jwt.sign({ id: 1, exp: Math.floor(Date.now() / 1000) - 60 }, JWT_SECRET);
    const req = mockRequest({ headers: { authorization: `Bearer ${token}` }, user: undefined });
    const res = mockResponse();
    const next = jest.fn();

    authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  test('chama next e preenche req.user para token válido', () => {
    const token = jwt.sign({ id: 7, email: 'teste@demo.com', nome: 'Teste' }, JWT_SECRET, { expiresIn: '1h' });
    const req = mockRequest({ headers: { authorization: `Bearer ${token}` }, user: undefined });
    const res = mockResponse();
    const next = jest.fn();

    authMiddleware(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(res.status).not.toHaveBeenCalled();
    expect(req.user).toEqual(expect.objectContaining({ id: 7, email: 'teste@demo.com', nome: 'Teste' }));
  });
});

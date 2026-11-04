const request = require('supertest');
const app = require('../src/app');
const pulseiraRepository = require('../src/repositories/pulseiraRepository');
const criancaRepository = require('../src/repositories/criancaRepository');

jest.mock('jsonwebtoken', () => ({
  sign: jest.fn(() => 'fake-jwt-token'),
  verify: jest.fn(() => ({ id: 1, email: 'responsavel@demo.com', nome: 'Responsável Demo' })),
}));

jest.mock('../src/repositories/pulseiraRepository', () => ({
  listByUser: jest.fn(),
  findById: jest.fn(),
  findByIdForUser: jest.fn(),
  findByIdentificador: jest.fn(),
  create: jest.fn(),
  updateById: jest.fn(),
  removeById: jest.fn(),
  getUltimaLocalizacao: jest.fn(),
  getHistorico: jest.fn(),
  registrarLocalizacao: jest.fn(),
}));

jest.mock('../src/repositories/criancaRepository', () => ({
  findById: jest.fn(),
  belongsToUser: jest.fn(),
}));

jest.mock('../src/repositories/alertaRepository', () => ({
  alreadyExists: jest.fn(),
  create: jest.fn(),
}));

jest.mock('../src/repositories/localSeguroRepository', () => ({
  listByCrianca: jest.fn(),
}));

describe('Pulseira API ownership', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('POST /api/pulseiras requires the selected child to belong to the user', async () => {
    criancaRepository.findById.mockResolvedValue({ id: 9, nome: 'Outra criança' });
    criancaRepository.belongsToUser.mockResolvedValue(false);

    const response = await request(app)
      .post('/api/pulseiras')
      .set('Authorization', 'Bearer valid-token')
      .send({
        crianca_id: 9,
        identificador: 'WATCH-009',
        nome_dispositivo: 'Pulseira de teste',
      });

    expect(response.status).toBe(403);
    expect(pulseiraRepository.create).not.toHaveBeenCalled();
  });

  test('GET /api/pulseiras/:id/localizacao-atual does not expose another user device', async () => {
    pulseiraRepository.findByIdForUser.mockResolvedValue(null);

    const response = await request(app)
      .get('/api/pulseiras/42/localizacao-atual')
      .set('Authorization', 'Bearer valid-token');

    expect(response.status).toBe(404);
    expect(pulseiraRepository.getUltimaLocalizacao).not.toHaveBeenCalled();
  });

  test('PUT /api/pulseiras/:id rejects fields outside the editable device data', async () => {
    const response = await request(app)
      .put('/api/pulseiras/42')
      .set('Authorization', 'Bearer valid-token')
      .send({ ativo: false });

    expect(response.status).toBe(400);
    expect(pulseiraRepository.updateById).not.toHaveBeenCalled();
  });
});

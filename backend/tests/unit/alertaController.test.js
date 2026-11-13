jest.mock('../../src/repositories/alertaRepository');
jest.mock('../../src/config/db', () => ({ execute: jest.fn() }));

const alertaRepository = require('../../src/repositories/alertaRepository');
const controller = require('../../src/controllers/alertaController');
const { mockRequest, mockResponse } = require('./helpers');

describe('controllers/alertaController', () => {
  beforeEach(() => jest.clearAllMocks());

  test('listarAlertas retorna os alertas do usuário', async () => {
    alertaRepository.listForUser.mockResolvedValue([{ id: 1 }]);
    const res = mockResponse();

    await controller.listarAlertas(mockRequest({ user: { id: 4 } }), res, jest.fn());

    expect(alertaRepository.listForUser).toHaveBeenCalledWith(4);
    expect(res.json).toHaveBeenCalledWith({ success: true, data: [{ id: 1 }] });
  });

  test('obterAlerta retorna 404 quando não existe', async () => {
    alertaRepository.findById.mockResolvedValue(null);
    const res = mockResponse();

    await controller.obterAlerta(mockRequest({ params: { id: '8' } }), res, jest.fn());

    expect(alertaRepository.findById).toHaveBeenCalledWith(8);
    expect(res.status).toHaveBeenCalledWith(404);
  });

  test('obterAlerta retorna o alerta', async () => {
    alertaRepository.findById.mockResolvedValue({ id: 8 });
    const res = mockResponse();

    await controller.obterAlerta(mockRequest({ params: { id: '8' } }), res, jest.fn());

    expect(res.json).toHaveBeenCalledWith({ success: true, data: { id: 8 } });
  });

  describe.each([
    ['visualizarAlerta', 'markAsVisualizado', 'Alerta marcado como visualizado.'],
    ['resolverAlerta', 'markAsResolvido', 'Alerta resolvido.'],
  ])('%s', (acao, metodoRepo, mensagem) => {
    test('atualiza o alerta do usuário', async () => {
      alertaRepository[metodoRepo].mockResolvedValue(true);
      const res = mockResponse();

      await controller[acao](mockRequest({ params: { id: '8' }, user: { id: 4 } }), res, jest.fn());

      expect(alertaRepository[metodoRepo]).toHaveBeenCalledWith(8, 4);
      expect(res.json).toHaveBeenCalledWith({ success: true, message: mensagem });
    });

    test('retorna 404 quando o alerta não pertence ao usuário', async () => {
      alertaRepository[metodoRepo].mockResolvedValue(false);
      const res = mockResponse();

      await controller[acao](mockRequest({ params: { id: '8' } }), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(404);
    });
  });
});

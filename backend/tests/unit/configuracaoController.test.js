jest.mock('../../src/repositories/configuracaoAlertaRepository');
jest.mock('../../src/config/db', () => ({ execute: jest.fn() }));

const configuracaoRepository = require('../../src/repositories/configuracaoAlertaRepository');
const controller = require('../../src/controllers/configuracaoController');
const { mockRequest, mockResponse } = require('./helpers');

describe('controllers/configuracaoController', () => {
  beforeEach(() => jest.clearAllMocks());

  test('obterConfiguracao busca pela criança e usuário', async () => {
    const config = { alerta_saida_local: 1 };
    configuracaoRepository.getByCrianca.mockResolvedValue(config);
    const res = mockResponse();

    await controller.obterConfiguracao(mockRequest({ params: { criancaId: '5' }, user: { id: 2 } }), res, jest.fn());

    expect(configuracaoRepository.getByCrianca).toHaveBeenCalledWith(5, 2);
    expect(res.json).toHaveBeenCalledWith({ success: true, data: config });
  });

  test('obterConfiguracao retorna null quando não há configuração', async () => {
    configuracaoRepository.getByCrianca.mockResolvedValue(undefined);
    const res = mockResponse();

    await controller.obterConfiguracao(mockRequest({ params: { criancaId: '5' } }), res, jest.fn());

    expect(res.json).toHaveBeenCalledWith({ success: true, data: null });
  });

  test('atualizarConfiguracao usa criança da URL e usuário do token (não do corpo)', async () => {
    configuracaoRepository.createOrUpdate.mockImplementation(async (payload) => payload);
    const res = mockResponse();

    await controller.atualizarConfiguracao(mockRequest({
      params: { criancaId: '5' },
      user: { id: 2 },
      body: { alerta_bateria_baixa: 0, crianca_id: 99, usuario_id: 99 },
    }), res, jest.fn());

    expect(configuracaoRepository.createOrUpdate).toHaveBeenCalledWith({ alerta_bateria_baixa: 0, crianca_id: 5, usuario_id: 2 });
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });
});

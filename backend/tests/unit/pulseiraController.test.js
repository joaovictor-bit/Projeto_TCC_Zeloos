jest.mock('../../src/repositories/pulseiraRepository');
jest.mock('../../src/repositories/criancaRepository');
jest.mock('../../src/repositories/alertaRepository');
jest.mock('../../src/repositories/localSeguroRepository');
jest.mock('../../src/config/db', () => ({ execute: jest.fn() }));

const pulseiraRepository = require('../../src/repositories/pulseiraRepository');
const criancaRepository = require('../../src/repositories/criancaRepository');
const alertaRepository = require('../../src/repositories/alertaRepository');
const localSeguroRepository = require('../../src/repositories/localSeguroRepository');
const controller = require('../../src/controllers/pulseiraController');
const { mockRequest, mockResponse } = require('./helpers');

const escola = { id: 3, nome: 'Escola', latitude: -23.55052, longitude: -46.63331, raio_metros: 100 };
const pontoNaEscola = { latitude: -23.55052, longitude: -46.63331 };
const pontoLonge = { latitude: -23.56, longitude: -46.64 };
const pulseira = { id: 10, crianca_id: 5, identificador: 'BRACELET-001' };

describe('controllers/pulseiraController', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('listarPulseiras', () => {
    test('retorna as pulseiras do usuário logado', async () => {
      pulseiraRepository.listByUser.mockResolvedValue([pulseira]);
      const res = mockResponse();

      await controller.listarPulseiras(mockRequest({ user: { id: 2 } }), res, jest.fn());

      expect(pulseiraRepository.listByUser).toHaveBeenCalledWith(2);
      expect(res.json).toHaveBeenCalledWith({ success: true, data: [pulseira] });
    });

    test('encaminha erros para o next', async () => {
      const erro = new Error('falha no banco');
      pulseiraRepository.listByUser.mockRejectedValue(erro);
      const next = jest.fn();

      await controller.listarPulseiras(mockRequest(), mockResponse(), next);

      expect(next).toHaveBeenCalledWith(erro);
    });
  });

  describe('criarPulseira', () => {
    const body = { crianca_id: 5, identificador: 'BRACELET-001', nome_dispositivo: 'Pulseira', modelo: 'ZL-01' };

    test('retorna 404 se a criança não existe', async () => {
      criancaRepository.findById.mockResolvedValue(null);
      const res = mockResponse();

      await controller.criarPulseira(mockRequest({ body }), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(404);
      expect(pulseiraRepository.create).not.toHaveBeenCalled();
    });

    test('retorna 403 se a criança não pertence ao usuário', async () => {
      criancaRepository.findById.mockResolvedValue({ id: 5 });
      criancaRepository.belongsToUser.mockResolvedValue(false);
      const res = mockResponse();

      await controller.criarPulseira(mockRequest({ body }), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(403);
      expect(pulseiraRepository.create).not.toHaveBeenCalled();
    });

    test('cria a pulseira e retorna 201', async () => {
      criancaRepository.findById.mockResolvedValue({ id: 5 });
      criancaRepository.belongsToUser.mockResolvedValue(true);
      pulseiraRepository.create.mockResolvedValue({ id: 10, ...body });
      const res = mockResponse();

      await controller.criarPulseira(mockRequest({ body: { ...body, ativo: false } }), res, jest.fn());

      expect(pulseiraRepository.create).toHaveBeenCalledWith(body);
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith({ success: true, data: { id: 10, ...body } });
    });
  });

  describe('obterPulseira', () => {
    test('retorna 404 quando a pulseira não é do usuário', async () => {
      pulseiraRepository.findByIdForUser.mockResolvedValue(null);
      const res = mockResponse();

      await controller.obterPulseira(mockRequest({ params: { id: '10' } }), res, jest.fn());

      expect(pulseiraRepository.findByIdForUser).toHaveBeenCalledWith(10, 1);
      expect(res.status).toHaveBeenCalledWith(404);
    });

    test('retorna a pulseira encontrada', async () => {
      pulseiraRepository.findByIdForUser.mockResolvedValue(pulseira);
      const res = mockResponse();

      await controller.obterPulseira(mockRequest({ params: { id: '10' } }), res, jest.fn());

      expect(res.json).toHaveBeenCalledWith({ success: true, data: pulseira });
    });
  });

  describe('atualizarPulseira', () => {
    test('rejeita campos não permitidos', async () => {
      const res = mockResponse();

      await controller.atualizarPulseira(mockRequest({ params: { id: '10' }, body: { bateria_percentual: 100 } }), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ message: 'Campo não permitido: bateria_percentual.' }));
      expect(pulseiraRepository.updateById).not.toHaveBeenCalled();
    });

    test('rejeita corpo vazio', async () => {
      const res = mockResponse();

      await controller.atualizarPulseira(mockRequest({ params: { id: '10' }, body: {} }), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(400);
      expect(pulseiraRepository.updateById).not.toHaveBeenCalled();
    });

    test('retorna 403 ao mover para criança de outro usuário', async () => {
      criancaRepository.belongsToUser.mockResolvedValue(false);
      const res = mockResponse();

      await controller.atualizarPulseira(mockRequest({ params: { id: '10' }, body: { crianca_id: 99 } }), res, jest.fn());

      expect(criancaRepository.belongsToUser).toHaveBeenCalledWith(99, 1);
      expect(res.status).toHaveBeenCalledWith(403);
    });

    test('retorna 404 se a pulseira não pertence ao usuário', async () => {
      pulseiraRepository.findByIdForUser.mockResolvedValue(null);
      const res = mockResponse();

      await controller.atualizarPulseira(mockRequest({ params: { id: '10' }, body: { modelo: 'X' } }), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(404);
      expect(pulseiraRepository.updateById).not.toHaveBeenCalled();
    });

    test('atualiza a pulseira', async () => {
      pulseiraRepository.findByIdForUser.mockResolvedValue(pulseira);
      pulseiraRepository.updateById.mockResolvedValue({ ...pulseira, modelo: 'X' });
      const res = mockResponse();

      await controller.atualizarPulseira(mockRequest({ params: { id: '10' }, body: { modelo: 'X' } }), res, jest.fn());

      expect(pulseiraRepository.updateById).toHaveBeenCalledWith(10, { modelo: 'X' });
      expect(res.json).toHaveBeenCalledWith({ success: true, data: { ...pulseira, modelo: 'X' } });
    });
  });

  describe('excluirPulseira', () => {
    test('retorna 404 se a pulseira não é do usuário', async () => {
      pulseiraRepository.findByIdForUser.mockResolvedValue(null);
      const res = mockResponse();

      await controller.excluirPulseira(mockRequest({ params: { id: '10' } }), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(404);
      expect(pulseiraRepository.removeById).not.toHaveBeenCalled();
    });

    test('remove a pulseira', async () => {
      pulseiraRepository.findByIdForUser.mockResolvedValue(pulseira);
      pulseiraRepository.removeById.mockResolvedValue(true);
      const res = mockResponse();

      await controller.excluirPulseira(mockRequest({ params: { id: '10' } }), res, jest.fn());

      expect(pulseiraRepository.removeById).toHaveBeenCalledWith(10);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
    });
  });

  describe('localizacaoAtual', () => {
    test('informa o local seguro em que a criança está', async () => {
      pulseiraRepository.findByIdForUser.mockResolvedValue(pulseira);
      pulseiraRepository.getUltimaLocalizacao.mockResolvedValue({ id: 1, ...pontoNaEscola });
      localSeguroRepository.listByCrianca.mockResolvedValue([escola]);
      const res = mockResponse();

      await controller.localizacaoAtual(mockRequest({ params: { id: '10' } }), res, jest.fn());

      expect(localSeguroRepository.listByCrianca).toHaveBeenCalledWith(5);
      expect(res.json.mock.calls[0][0].data.dentro).toEqual(escola);
    });

    test('retorna dentro = null quando fora dos locais seguros', async () => {
      pulseiraRepository.findByIdForUser.mockResolvedValue(pulseira);
      pulseiraRepository.getUltimaLocalizacao.mockResolvedValue({ id: 1, ...pontoLonge });
      localSeguroRepository.listByCrianca.mockResolvedValue([escola]);
      const res = mockResponse();

      await controller.localizacaoAtual(mockRequest({ params: { id: '10' } }), res, jest.fn());

      expect(res.json.mock.calls[0][0].data.dentro).toBeNull();
    });

    test('retorna localizacao = null quando não há registros', async () => {
      pulseiraRepository.findByIdForUser.mockResolvedValue(pulseira);
      pulseiraRepository.getUltimaLocalizacao.mockResolvedValue(null);
      localSeguroRepository.listByCrianca.mockResolvedValue([escola]);
      const res = mockResponse();

      await controller.localizacaoAtual(mockRequest({ params: { id: '10' } }), res, jest.fn());

      expect(res.json.mock.calls[0][0].data).toEqual(expect.objectContaining({ localizacao: null, dentro: null }));
    });
  });

  describe('historicoPulseira', () => {
    test('usa limit=20 e offset=0 por padrão', async () => {
      pulseiraRepository.findByIdForUser.mockResolvedValue(pulseira);
      pulseiraRepository.getHistorico.mockResolvedValue([]);
      const res = mockResponse();

      await controller.historicoPulseira(mockRequest({ params: { id: '10' } }), res, jest.fn());

      expect(pulseiraRepository.getHistorico).toHaveBeenCalledWith(10, 20, 0);
      expect(res.json).toHaveBeenCalledWith({ success: true, data: [], pagination: { limit: 20, offset: 0 } });
    });

    test('respeita limit e offset informados', async () => {
      pulseiraRepository.findByIdForUser.mockResolvedValue(pulseira);
      pulseiraRepository.getHistorico.mockResolvedValue([]);

      await controller.historicoPulseira(mockRequest({ params: { id: '10' }, query: { limit: '5', offset: '10' } }), mockResponse(), jest.fn());

      expect(pulseiraRepository.getHistorico).toHaveBeenCalledWith(10, 5, 10);
    });
  });

  describe('receberLocalizacao', () => {
    const novaLocalizacao = (ponto) => ({ identificador: 'BRACELET-001', bateria_percentual: 80, ...ponto });

    beforeEach(() => {
      pulseiraRepository.findByIdentificador.mockResolvedValue(pulseira);
      pulseiraRepository.registrarLocalizacao.mockImplementation(async (data) => ({ id: 2, ...data }));
      pulseiraRepository.updateById.mockResolvedValue(pulseira);
      localSeguroRepository.listByCrianca.mockResolvedValue([escola]);
      alertaRepository.alreadyExists.mockResolvedValue(false);
    });

    test('retorna 404 para identificador desconhecido', async () => {
      pulseiraRepository.findByIdentificador.mockResolvedValue(null);
      const res = mockResponse();

      await controller.receberLocalizacao(mockRequest({ body: novaLocalizacao(pontoNaEscola) }), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(404);
      expect(pulseiraRepository.registrarLocalizacao).not.toHaveBeenCalled();
    });

    test.each([
      [91, 0],
      [-91, 0],
      [0, 181],
      [0, -181],
    ])('rejeita coordenadas inválidas (lat %d, lon %d)', async (latitude, longitude) => {
      const res = mockResponse();

      await controller.receberLocalizacao(mockRequest({ body: novaLocalizacao({ latitude, longitude }) }), res, jest.fn());

      expect(res.status).toHaveBeenCalledWith(400);
      expect(pulseiraRepository.registrarLocalizacao).not.toHaveBeenCalled();
    });

    test('registra a localização e atualiza o status da pulseira', async () => {
      pulseiraRepository.getUltimaLocalizacao.mockResolvedValue(null);
      const res = mockResponse();

      await controller.receberLocalizacao(mockRequest({ body: novaLocalizacao(pontoNaEscola) }), res, jest.fn());

      expect(pulseiraRepository.registrarLocalizacao).toHaveBeenCalledWith(expect.objectContaining({
        pulseira_id: 10, ...pontoNaEscola, bateria_percentual: 80, origem: 'dispositivo',
      }));
      expect(pulseiraRepository.updateById).toHaveBeenCalledWith(10, expect.objectContaining({
        bateria_percentual: 80, status_conexao: 'conectada', ultima_comunicacao_em: expect.any(Date),
      }));
      expect(res.status).toHaveBeenCalledWith(201);
      expect(alertaRepository.create).not.toHaveBeenCalled();
    });

    test('gera alerta de entrada ao entrar em local seguro', async () => {
      pulseiraRepository.getUltimaLocalizacao.mockResolvedValue({ id: 1, ...pontoLonge });
      const res = mockResponse();

      await controller.receberLocalizacao(mockRequest({ body: novaLocalizacao(pontoNaEscola) }), res, jest.fn());

      expect(alertaRepository.create).toHaveBeenCalledTimes(1);
      expect(alertaRepository.create).toHaveBeenCalledWith(expect.objectContaining({
        tipo: 'entrada_local', crianca_id: 5, pulseira_id: 10, local_seguro_id: 3, mensagem: 'A criança entrou em Escola.',
      }));
      expect(res.json.mock.calls[0][0].data.entrouEmLocal).toEqual(escola);
    });

    test('gera alerta de saída ao sair de local seguro', async () => {
      pulseiraRepository.getUltimaLocalizacao.mockResolvedValue({ id: 1, ...pontoNaEscola });
      const res = mockResponse();

      await controller.receberLocalizacao(mockRequest({ body: novaLocalizacao(pontoLonge) }), res, jest.fn());

      expect(alertaRepository.create).toHaveBeenCalledWith(expect.objectContaining({ tipo: 'saida_local', local_seguro_id: 3 }));
      expect(res.json.mock.calls[0][0].data.saiuDeLocal).toEqual(escola);
    });

    test('não duplica alerta já existente', async () => {
      pulseiraRepository.getUltimaLocalizacao.mockResolvedValue({ id: 1, ...pontoLonge });
      alertaRepository.alreadyExists.mockResolvedValue(true);

      await controller.receberLocalizacao(mockRequest({ body: novaLocalizacao(pontoNaEscola) }), mockResponse(), jest.fn());

      expect(alertaRepository.create).not.toHaveBeenCalled();
    });

    test('não gera alerta quando continua no mesmo local', async () => {
      pulseiraRepository.getUltimaLocalizacao.mockResolvedValue({ id: 1, ...pontoNaEscola });

      await controller.receberLocalizacao(mockRequest({ body: novaLocalizacao(pontoNaEscola) }), mockResponse(), jest.fn());

      expect(alertaRepository.create).not.toHaveBeenCalled();
    });
  });
});

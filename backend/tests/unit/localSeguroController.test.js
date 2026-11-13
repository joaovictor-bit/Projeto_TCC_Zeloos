jest.mock('../../src/repositories/localSeguroRepository');
jest.mock('../../src/repositories/criancaRepository');
jest.mock('../../src/config/db', () => ({ execute: jest.fn() }));

const localSeguroRepository = require('../../src/repositories/localSeguroRepository');
const criancaRepository = require('../../src/repositories/criancaRepository');
const controller = require('../../src/controllers/localSeguroController');
const { mockRequest, mockResponse } = require('./helpers');

const local = { id: 3, crianca_id: 5, nome: 'Escola', latitude: -23.5, longitude: -46.6, raio_metros: 100 };

describe('controllers/localSeguroController', () => {
  beforeEach(() => jest.clearAllMocks());

  test('listarLocaisSeguros usa o :id da criança da rota', async () => {
    localSeguroRepository.listByCrianca.mockResolvedValue([local]);
    const res = mockResponse();

    await controller.listarLocaisSeguros(mockRequest({ params: { id: '5' } }), res, jest.fn());

    expect(localSeguroRepository.listByCrianca).toHaveBeenCalledWith(5);
    expect(res.json).toHaveBeenCalledWith({ success: true, data: [local] });
  });

  test('criarLocalSeguro retorna 404 quando a criança não existe', async () => {
    criancaRepository.findById.mockResolvedValue(null);
    const res = mockResponse();

    await controller.criarLocalSeguro(mockRequest({ params: { id: '5' }, body: local }), res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(404);
    expect(localSeguroRepository.create).not.toHaveBeenCalled();
  });

  test('criarLocalSeguro cria o local para a criança da rota', async () => {
    criancaRepository.findById.mockResolvedValue({ id: 5 });
    localSeguroRepository.create.mockResolvedValue(local);
    const res = mockResponse();
    const body = { nome: 'Escola', latitude: -23.5, longitude: -46.6, raio_metros: 100 };

    await controller.criarLocalSeguro(mockRequest({ params: { id: '5' }, body }), res, jest.fn());

    expect(criancaRepository.findById).toHaveBeenCalledWith(5);
    expect(localSeguroRepository.create).toHaveBeenCalledWith({ crianca_id: 5, ...body });
    expect(res.status).toHaveBeenCalledWith(201);
  });

  test('atualizarLocalSeguro ignora o campo id do corpo', async () => {
    localSeguroRepository.updateById.mockResolvedValue(local);
    const res = mockResponse();

    await controller.atualizarLocalSeguro(mockRequest({ params: { id: '3' }, body: { id: 1, raio_metros: 200 } }), res, jest.fn());

    expect(localSeguroRepository.updateById).toHaveBeenCalledWith(3, { raio_metros: 200 });
  });

  test('atualizarLocalSeguro retorna 404 quando não existe', async () => {
    localSeguroRepository.updateById.mockResolvedValue(null);
    const res = mockResponse();

    await controller.atualizarLocalSeguro(mockRequest({ params: { id: '3' }, body: { raio_metros: 200 } }), res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test('excluirLocalSeguro remove o local', async () => {
    localSeguroRepository.removeById.mockResolvedValue(true);
    const res = mockResponse();

    await controller.excluirLocalSeguro(mockRequest({ params: { id: '3' } }), res, jest.fn());

    expect(localSeguroRepository.removeById).toHaveBeenCalledWith(3);
    expect(res.json).toHaveBeenCalledWith({ success: true, message: 'Local seguro removido.' });
  });
});

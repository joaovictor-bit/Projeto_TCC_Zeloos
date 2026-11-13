jest.mock('../../src/repositories/criancaRepository');
jest.mock('../../src/config/db', () => ({ execute: jest.fn() }));

const criancaRepository = require('../../src/repositories/criancaRepository');
const controller = require('../../src/controllers/criancaController');
const { mockRequest, mockResponse } = require('./helpers');

const crianca = { id: 5, nome: 'Ana', data_nascimento: '2018-05-10', foto_url: null };

describe('controllers/criancaController', () => {
  beforeEach(() => jest.clearAllMocks());

  test('listarCriancas retorna as crianças do usuário', async () => {
    criancaRepository.listByUser.mockResolvedValue([crianca]);
    const res = mockResponse();

    await controller.listarCriancas(mockRequest({ user: { id: 3 } }), res, jest.fn());

    expect(criancaRepository.listByUser).toHaveBeenCalledWith(3);
    expect(res.json).toHaveBeenCalledWith({ success: true, data: [crianca] });
  });

  test('criarCrianca cria e vincula ao usuário logado', async () => {
    criancaRepository.create.mockResolvedValue(crianca);
    const res = mockResponse();
    const body = { nome: 'Ana', data_nascimento: '2018-05-10', foto_url: null };

    await controller.criarCrianca(mockRequest({ body, user: { id: 3 } }), res, jest.fn());

    expect(criancaRepository.create).toHaveBeenCalledWith(body);
    expect(criancaRepository.linkResponsavel).toHaveBeenCalledWith({ usuario_id: 3, crianca_id: 5 });
    expect(res.status).toHaveBeenCalledWith(201);
  });

  test('obterCrianca retorna 404 quando não existe', async () => {
    criancaRepository.findById.mockResolvedValue(null);
    const res = mockResponse();

    await controller.obterCrianca(mockRequest({ params: { id: '5' } }), res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(404);
    expect(criancaRepository.listResponsaveis).not.toHaveBeenCalled();
  });

  test('obterCrianca inclui os responsáveis', async () => {
    const responsaveis = [{ usuario_id: 1, nome: 'Responsável' }];
    criancaRepository.findById.mockResolvedValue(crianca);
    criancaRepository.listResponsaveis.mockResolvedValue(responsaveis);
    const res = mockResponse();

    await controller.obterCrianca(mockRequest({ params: { id: '5' } }), res, jest.fn());

    expect(criancaRepository.findById).toHaveBeenCalledWith(5);
    expect(res.json).toHaveBeenCalledWith({ success: true, data: { ...crianca, responsaveis } });
  });

  test('atualizarCrianca ignora o campo id do corpo', async () => {
    criancaRepository.updateById.mockResolvedValue({ ...crianca, nome: 'Ana Clara' });
    const res = mockResponse();

    await controller.atualizarCrianca(mockRequest({ params: { id: '5' }, body: { id: 99, nome: 'Ana Clara' } }), res, jest.fn());

    expect(criancaRepository.updateById).toHaveBeenCalledWith(5, { nome: 'Ana Clara' });
    expect(res.json).toHaveBeenCalledWith({ success: true, data: { ...crianca, nome: 'Ana Clara' } });
  });

  test('atualizarCrianca retorna 404 quando não existe', async () => {
    criancaRepository.updateById.mockResolvedValue(null);
    const res = mockResponse();

    await controller.atualizarCrianca(mockRequest({ params: { id: '5' }, body: { nome: 'X' } }), res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test.each([
    [true, undefined],
    [false, 404],
  ])('excluirCrianca (removido=%s) → status %s', async (removido, status) => {
    criancaRepository.removeById.mockResolvedValue(removido);
    const res = mockResponse();

    await controller.excluirCrianca(mockRequest({ params: { id: '5' } }), res, jest.fn());

    if (status) expect(res.status).toHaveBeenCalledWith(status);
    else expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
  });

  test('adicionarResponsavel vincula usuário à criança', async () => {
    criancaRepository.linkResponsavel.mockResolvedValue({ id: 1 });
    const res = mockResponse();
    const body = { usuario_id: 2, tipo_relacao: 'mae', permissao: 'admin' };

    await controller.adicionarResponsavel(mockRequest({ params: { id: '5' }, body }), res, jest.fn());

    expect(criancaRepository.linkResponsavel).toHaveBeenCalledWith({ ...body, crianca_id: 5 });
    expect(res.status).toHaveBeenCalledWith(201);
  });

  test('removerResponsavel retorna 404 quando o vínculo não existe', async () => {
    criancaRepository.removeResponsavel.mockResolvedValue(false);
    const res = mockResponse();

    await controller.removerResponsavel(mockRequest({ params: { id: '5', usuarioId: '2' } }), res, jest.fn());

    expect(criancaRepository.removeResponsavel).toHaveBeenCalledWith(5, 2);
    expect(res.status).toHaveBeenCalledWith(404);
  });

  test('encaminha erros do repositório para o next', async () => {
    const erro = new Error('falha');
    criancaRepository.listResponsaveis.mockRejectedValue(erro);
    const next = jest.fn();

    await controller.listarResponsaveis(mockRequest({ params: { id: '5' } }), mockResponse(), next);

    expect(next).toHaveBeenCalledWith(erro);
  });
});

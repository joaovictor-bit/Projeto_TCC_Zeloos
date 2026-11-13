jest.mock('../../src/config/db', () => ({ execute: jest.fn() }));

const db = require('../../src/config/db');
const repository = require('../../src/repositories/pulseiraRepository');

describe('repositories/pulseiraRepository', () => {
  beforeEach(() => jest.clearAllMocks());

  test('findById retorna o primeiro registro ou null', async () => {
    db.execute.mockResolvedValueOnce([[{ id: 1 }]]).mockResolvedValueOnce([[]]);

    await expect(repository.findById(1)).resolves.toEqual({ id: 1 });
    await expect(repository.findById(2)).resolves.toBeNull();
    expect(db.execute).toHaveBeenCalledWith(expect.stringContaining('WHERE id = ?'), [1]);
  });

  test('findByIdForUser filtra pelo usuário responsável', async () => {
    db.execute.mockResolvedValue([[]]);

    await repository.findByIdForUser(10, 3);

    expect(db.execute).toHaveBeenCalledWith(expect.stringContaining('rc.usuario_id = ?'), [10, 3]);
  });

  test('create usa valores padrão e retorna o id inserido', async () => {
    db.execute.mockResolvedValue([{ insertId: 42 }]);

    const pulseira = await repository.create({ crianca_id: 5, identificador: 'BRACELET-001' });

    expect(db.execute).toHaveBeenCalledWith(expect.stringContaining('INSERT INTO pulseiras'), [5, 'BRACELET-001', null, null, 'ativa', 'desconectada']);
    expect(pulseira).toEqual({
      id: 42, crianca_id: 5, identificador: 'BRACELET-001', nome_dispositivo: null, modelo: null, status: 'ativa', status_conexao: 'desconectada',
    });
  });

  test('updateById monta o UPDATE apenas com campos permitidos', async () => {
    db.execute
      .mockResolvedValueOnce([{ affectedRows: 1 }])
      .mockResolvedValueOnce([[{ id: 10, modelo: 'X' }]]);

    const resultado = await repository.updateById(10, { modelo: 'X', nome_dispositivo: undefined, ativo: 0 });

    expect(db.execute.mock.calls[0][0]).toMatch(/UPDATE pulseiras SET modelo = \?, atualizado_em = NOW\(\) WHERE id = \?/);
    expect(db.execute.mock.calls[0][1]).toEqual(['X', 10]);
    expect(resultado).toEqual({ id: 10, modelo: 'X' });
  });

  test('updateById retorna null sem consultar o banco se não houver campos válidos', async () => {
    await expect(repository.updateById(10, { ativo: 0 })).resolves.toBeNull();
    expect(db.execute).not.toHaveBeenCalled();
  });

  test('updateById retorna null quando nenhuma linha é afetada', async () => {
    db.execute.mockResolvedValueOnce([{ affectedRows: 0 }]);

    await expect(repository.updateById(10, { modelo: 'X' })).resolves.toBeNull();
    expect(db.execute).toHaveBeenCalledTimes(1);
  });

  test('removeById faz exclusão lógica (ativo = 0)', async () => {
    db.execute.mockResolvedValue([{ affectedRows: 1 }]);

    await expect(repository.removeById(10)).resolves.toBe(true);
    expect(db.execute).toHaveBeenCalledWith(expect.stringContaining('SET ativo = 0'), [10]);
  });

  test('getHistorico converte limit/offset para número', async () => {
    db.execute.mockResolvedValue([[]]);

    await repository.getHistorico(10, '5', '15');

    expect(db.execute).toHaveBeenCalledWith(expect.stringContaining('LIMIT ? OFFSET ?'), [10, 5, 15]);
  });

  test('registrarLocalizacao usa origem "dispositivo" por padrão', async () => {
    db.execute.mockResolvedValue([{ insertId: 7 }]);

    const localizacao = await repository.registrarLocalizacao({ pulseira_id: 10, latitude: -23.5, longitude: -46.6 });

    expect(db.execute.mock.calls[0][1]).toEqual([10, -23.5, -46.6, null, null, 'dispositivo']);
    expect(localizacao).toEqual(expect.objectContaining({ id: 7, origem: 'dispositivo' }));
  });
});

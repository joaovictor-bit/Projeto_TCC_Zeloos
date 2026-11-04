const db = require('../config/db');

async function listByUser(usuarioId) {
  const [rows] = await db.execute(
    `SELECT p.*
     FROM pulseiras p
     INNER JOIN criancas c ON c.id = p.crianca_id
     INNER JOIN responsaveis_criancas rc ON rc.crianca_id = c.id
     WHERE rc.usuario_id = ? AND p.ativo = 1
     ORDER BY p.criado_em DESC`,
    [usuarioId]
  );
  return rows;
}

async function findById(id) {
  const [rows] = await db.execute('SELECT * FROM pulseiras WHERE id = ? LIMIT 1', [id]);
  return rows[0] || null;
}

async function findByIdForUser(id, usuarioId) {
  const [rows] = await db.execute(
    `SELECT p.*
     FROM pulseiras p
     INNER JOIN criancas c ON c.id = p.crianca_id
     INNER JOIN responsaveis_criancas rc ON rc.crianca_id = c.id
     WHERE p.id = ? AND rc.usuario_id = ? AND p.ativo = 1
     LIMIT 1`,
    [id, usuarioId]
  );
  return rows[0] || null;
}

async function findByIdentificador(identificador) {
  const [rows] = await db.execute('SELECT * FROM pulseiras WHERE identificador = ? LIMIT 1', [identificador]);
  return rows[0] || null;
}

async function create({
  crianca_id,
  identificador,
  nome_dispositivo = null,
  modelo = null,
  status = 'ativa',
  status_conexao = 'desconectada',
}) {
  const [result] = await db.execute(
    `INSERT INTO pulseiras (crianca_id, identificador, nome_dispositivo, modelo, status, status_conexao, ultima_comunicacao_em, bateria_percentual, ativo, criado_em, atualizado_em)
     VALUES (?, ?, ?, ?, ?, ?, NULL, NULL, true, NOW(), NOW())`,
    [crianca_id, identificador, nome_dispositivo, modelo, status, status_conexao]
  );

  return { id: result.insertId, crianca_id, identificador, nome_dispositivo, modelo, status, status_conexao };
}

async function updateById(id, payload) {
  const fields = [];
  const values = [];
  const allowedFields = new Set([
    'crianca_id',
    'identificador',
    'nome_dispositivo',
    'modelo',
    'status',
  ]);

  Object.entries(payload).forEach(([key, value]) => {
    if (allowedFields.has(key) && value !== undefined) {
      fields.push(`${key} = ?`);
      values.push(value);
    }
  });

  if (!fields.length) return null;

  values.push(id);

  const [result] = await db.execute(
    `UPDATE pulseiras SET ${fields.join(', ')}, atualizado_em = NOW() WHERE id = ?`,
    values
  );

  return result.affectedRows ? await findById(id) : null;
}

async function removeById(id) {
  const [result] = await db.execute('UPDATE pulseiras SET ativo = 0, atualizado_em = NOW() WHERE id = ?', [id]);
  return result.affectedRows > 0;
}

async function getUltimaLocalizacao(pulseiraId) {
  const [rows] = await db.execute(
    'SELECT * FROM localizacoes WHERE pulseira_id = ? ORDER BY registrada_em DESC LIMIT 1',
    [pulseiraId]
  );
  return rows[0] || null;
}

async function getHistorico(pulseiraId, limit = 20, offset = 0) {
  const [rows] = await db.execute(
    'SELECT * FROM localizacoes WHERE pulseira_id = ? ORDER BY registrada_em DESC LIMIT ? OFFSET ?',
    [pulseiraId, Number(limit), Number(offset)]
  );
  return rows;
}

async function registrarLocalizacao({
  pulseira_id,
  latitude,
  longitude,
  precisao_metros = null,
  bateria_percentual = null,
  origem = 'dispositivo',
}) {
  const [result] = await db.execute(
    `INSERT INTO localizacoes (pulseira_id, latitude, longitude, precisao_metros, bateria_percentual, origem, registrada_em, recebida_em)
     VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())`,
    [pulseira_id, latitude, longitude, precisao_metros, bateria_percentual, origem]
  );

  return { id: result.insertId, pulseira_id, latitude, longitude, precisao_metros, bateria_percentual, origem };
}

module.exports = {
  listByUser,
  findById,
  findByIdForUser,
  findByIdentificador,
  create,
  updateById,
  removeById,
  getUltimaLocalizacao,
  getHistorico,
  registrarLocalizacao,
};

const db = require('../config/db');

async function listByCrianca(criancaId) {
  const [rows] = await db.execute(
    'SELECT * FROM locais_seguros WHERE crianca_id = ? AND ativo = 1 ORDER BY nome ASC',
    [criancaId]
  );
  return rows;
}

async function findById(id) {
  const [rows] = await db.execute('SELECT * FROM locais_seguros WHERE id = ? LIMIT 1', [id]);
  return rows[0] || null;
}

async function create({ crianca_id, nome, latitude, longitude, raio_metros }) {
  const [result] = await db.execute(
    'INSERT INTO locais_seguros (crianca_id, nome, latitude, longitude, raio_metros, ativo, criado_em, atualizado_em) VALUES (?, ?, ?, ?, ?, true, NOW(), NOW())',
    [crianca_id, nome, latitude, longitude, raio_metros]
  );

  return { id: result.insertId, crianca_id, nome, latitude, longitude, raio_metros };
}

async function updateById(id, payload) {
  const fields = [];
  const values = [];

  Object.entries(payload).forEach(([key, value]) => {
    if (value !== undefined) {
      fields.push(`${key} = ?`);
      values.push(value);
    }
  });

  if (!fields.length) return null;

  values.push(id);

  const [result] = await db.execute(
    `UPDATE locais_seguros SET ${fields.join(', ')}, atualizado_em = NOW() WHERE id = ?`,
    values
  );

  return result.affectedRows ? await findById(id) : null;
}

async function removeById(id) {
  const [result] = await db.execute('UPDATE locais_seguros SET ativo = 0, atualizado_em = NOW() WHERE id = ?', [id]);
  return result.affectedRows > 0;
}

module.exports = { listByCrianca, findById, create, updateById, removeById };

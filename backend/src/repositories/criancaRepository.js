const db = require('../config/db');

async function listByUser(usuarioId) {
  const [rows] = await db.execute(
    `SELECT c.*
     FROM criancas c
     INNER JOIN responsaveis_criancas rc ON rc.crianca_id = c.id
     WHERE rc.usuario_id = ? AND c.ativo = 1
     ORDER BY c.criado_em DESC`,
    [usuarioId]
  );
  return rows;
}

async function findById(id) {
  const [rows] = await db.execute('SELECT * FROM criancas WHERE id = ? LIMIT 1', [id]);
  return rows[0] || null;
}

async function belongsToUser(criancaId, usuarioId) {
  const [rows] = await db.execute(
    'SELECT 1 FROM responsaveis_criancas WHERE crianca_id = ? AND usuario_id = ? LIMIT 1',
    [criancaId, usuarioId]
  );
  return rows.length > 0;
}

async function create({ nome, data_nascimento = null, foto_url = null }) {
  const [result] = await db.execute(
    'INSERT INTO criancas (nome, data_nascimento, foto_url, ativo, criado_em, atualizado_em) VALUES (?, ?, ?, true, NOW(), NOW())',
    [nome, data_nascimento, foto_url]
  );
  return { id: result.insertId, nome, data_nascimento, foto_url };
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
    `UPDATE criancas SET ${fields.join(', ')}, atualizado_em = NOW() WHERE id = ?`,
    values
  );

  return result.affectedRows ? await findById(id) : null;
}

async function removeById(id) {
  const [result] = await db.execute('UPDATE criancas SET ativo = 0, atualizado_em = NOW() WHERE id = ?', [id]);
  return result.affectedRows > 0;
}

async function linkResponsavel({ usuario_id, crianca_id, tipo_relacao = 'responsavel', permissao = 'admin' }) {
  const [result] = await db.execute(
    'INSERT INTO responsaveis_criancas (usuario_id, crianca_id, tipo_relacao, permissao, criado_em) VALUES (?, ?, ?, ?, NOW())',
    [usuario_id, crianca_id, tipo_relacao, permissao]
  );
  return { id: result.insertId, usuario_id, crianca_id, tipo_relacao, permissao };
}

async function listResponsaveis(criancaId) {
  const [rows] = await db.execute(
    `SELECT rc.id, rc.usuario_id, rc.permissao, u.nome, u.email
     FROM responsaveis_criancas rc
     INNER JOIN usuarios u ON u.id = rc.usuario_id
     WHERE rc.crianca_id = ?`,
    [criancaId]
  );
  return rows;
}

async function removeResponsavel(criancaId, usuarioId) {
  const [result] = await db.execute(
    'DELETE FROM responsaveis_criancas WHERE crianca_id = ? AND usuario_id = ?',
    [criancaId, usuarioId]
  );
  return result.affectedRows > 0;
}

module.exports = {
  listByUser,
  findById,
  belongsToUser,
  create,
  updateById,
  removeById,
  linkResponsavel,
  listResponsaveis,
  removeResponsavel,
};

const db = require('../config/db');

async function listForUser(usuarioId) {
  const [rows] = await db.execute(
    `SELECT a.*
     FROM alertas a
     INNER JOIN criancas c ON c.id = a.crianca_id
     INNER JOIN responsaveis_criancas rc ON rc.crianca_id = c.id
     WHERE rc.usuario_id = ?
     ORDER BY a.ocorrido_em DESC`,
    [usuarioId]
  );
  return rows;
}

async function create({ crianca_id, pulseira_id = null, local_seguro_id = null, tipo, titulo, mensagem, status = 'novo', ocorrido_em = new Date() }) {
  const [result] = await db.execute(
    `INSERT INTO alertas (crianca_id, pulseira_id, local_seguro_id, tipo, titulo, mensagem, status, ocorrido_em, criado_em, visualizado_em)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NULL)`,
    [crianca_id, pulseira_id, local_seguro_id, tipo, titulo, mensagem, status, new Date(ocorrido_em).toISOString().slice(0, 19).replace('T', ' ')]
  );

  return { id: result.insertId, crianca_id, pulseira_id, local_seguro_id, tipo, titulo, mensagem, status };
}

async function findById(id) {
  const [rows] = await db.execute('SELECT * FROM alertas WHERE id = ? LIMIT 1', [id]);
  return rows[0] || null;
}

async function markAsVisualizado(id, usuarioId) {
  const [result] = await db.execute(
    'UPDATE alertas SET status = ?, visualizado_em = NOW() WHERE id = ? AND crianca_id IN (SELECT crianca_id FROM responsaveis_criancas WHERE usuario_id = ?)',
    ['visualizado', id, usuarioId]
  );
  return result.affectedRows > 0;
}

async function markAsResolvido(id, usuarioId) {
  const [result] = await db.execute(
    'UPDATE alertas SET status = ? WHERE id = ? AND crianca_id IN (SELECT crianca_id FROM responsaveis_criancas WHERE usuario_id = ?)',
    ['resolvido', id, usuarioId]
  );
  return result.affectedRows > 0;
}

async function alreadyExists({ crianca_id, tipo, local_seguro_id = null, pulseira_id = null, status = 'novo' }) {
  const [rows] = await db.execute(
    `SELECT * FROM alertas
      WHERE crianca_id = ? AND tipo = ? AND COALESCE(local_seguro_id, -1) = COALESCE(?, -1)
      AND COALESCE(pulseira_id, -1) = COALESCE(?, -1)
      AND status IN ('novo','visualizado')
      ORDER BY ocorrido_em DESC LIMIT 1`,
    [crianca_id, tipo, local_seguro_id, pulseira_id]
  );
  return rows[0] || null;
}

module.exports = { listForUser, create, findById, markAsVisualizado, markAsResolvido, alreadyExists };

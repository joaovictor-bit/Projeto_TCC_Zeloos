const db = require('../config/db');

async function getByCrianca(criancaId, usuarioId) {
  const [rows] = await db.execute(
    `SELECT * FROM configuracoes_alertas
     WHERE crianca_id = ? AND usuario_id = ? LIMIT 1`,
    [criancaId, usuarioId]
  );
  return rows[0] || null;
}

async function createOrUpdate({ crianca_id, usuario_id, alerta_saida_local = true, alerta_entrada_local = true, alerta_desconexao = true, alerta_bateria_baixa = true, limite_bateria_percentual = 20 }) {
  const existing = await getByCrianca(crianca_id, usuario_id);

  if (existing) {
    const [result] = await db.execute(
      `UPDATE configuracoes_alertas SET alerta_saida_local = ?, alerta_entrada_local = ?, alerta_desconexao = ?, alerta_bateria_baixa = ?, limite_bateria_percentual = ?, atualizado_em = NOW()
       WHERE id = ?`,
      [alerta_saida_local, alerta_entrada_local, alerta_desconexao, alerta_bateria_baixa, limite_bateria_percentual, existing.id]
    );
    return result.affectedRows ? await getByCrianca(crianca_id, usuario_id) : existing;
  }

  const [result] = await db.execute(
    `INSERT INTO configuracoes_alertas (crianca_id, usuario_id, alerta_saida_local, alerta_entrada_local, alerta_desconexao, alerta_bateria_baixa, limite_bateria_percentual, criado_em, atualizado_em)
     VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
    [crianca_id, usuario_id, alerta_saida_local, alerta_entrada_local, alerta_desconexao, alerta_bateria_baixa, limite_bateria_percentual]
  );

  return { id: result.insertId, crianca_id, usuario_id, alerta_saida_local, alerta_entrada_local, alerta_desconexao, alerta_bateria_baixa, limite_bateria_percentual };
}

module.exports = { getByCrianca, createOrUpdate };

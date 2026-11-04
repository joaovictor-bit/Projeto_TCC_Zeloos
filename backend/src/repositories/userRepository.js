const db = require('../config/db');

async function findByEmail(email) {
  const [rows] = await db.execute('SELECT * FROM usuarios WHERE email = ? LIMIT 1', [email]);
  return rows[0] || null;
}

async function createUser({ nome, email, senhaHash, telefone = null }) {
  const [result] = await db.execute(
    'INSERT INTO usuarios (nome, email, senha_hash, telefone, ativo, criado_em, atualizado_em) VALUES (?, ?, ?, ?, true, NOW(), NOW())',
    [nome, email, senhaHash, telefone]
  );

  return { id: result.insertId, nome, email, telefone };
}

async function findById(id) {
  const [rows] = await db.execute('SELECT id, nome, email, telefone, ativo, criado_em, atualizado_em FROM usuarios WHERE id = ? LIMIT 1', [id]);
  return rows[0] || null;
}

module.exports = { findByEmail, createUser, findById };

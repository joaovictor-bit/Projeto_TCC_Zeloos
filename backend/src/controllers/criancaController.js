const criancaRepository = require('../repositories/criancaRepository');

async function listarCriancas(req, res, next) {
  try {
    const criancas = await criancaRepository.listByUser(req.user.id);
    return res.json({ success: true, data: criancas });
  } catch (error) {
    next(error);
  }
}

async function criarCrianca(req, res, next) {
  try {
    const { nome, data_nascimento, foto_url } = req.body;
    const crianca = await criancaRepository.create({ nome, data_nascimento, foto_url });
    await criancaRepository.linkResponsavel({ usuario_id: req.user.id, crianca_id: crianca.id });
    return res.status(201).json({ success: true, data: crianca });
  } catch (error) {
    next(error);
  }
}

async function obterCrianca(req, res, next) {
  try {
    const criancaId = Number(req.params.id);
    const crianca = await criancaRepository.findById(criancaId);
    if (!crianca) return res.status(404).json({ success: false, message: 'Criança não encontrada.' });

    const responsaveis = await criancaRepository.listResponsaveis(criancaId);
    return res.json({ success: true, data: { ...crianca, responsaveis } });
  } catch (error) {
    next(error);
  }
}

async function atualizarCrianca(req, res, next) {
  try {
    const criancaId = Number(req.params.id);
    const payload = { ...req.body };
    delete payload.id;
    const crianca = await criancaRepository.updateById(criancaId, payload);
    if (!crianca) return res.status(404).json({ success: false, message: 'Criança não encontrada.' });
    return res.json({ success: true, data: crianca });
  } catch (error) {
    next(error);
  }
}

async function excluirCrianca(req, res, next) {
  try {
    const criancaId = Number(req.params.id);
    const deleted = await criancaRepository.removeById(criancaId);
    if (!deleted) return res.status(404).json({ success: false, message: 'Criança não encontrada.' });
    return res.json({ success: true, message: 'Criança removida com sucesso.' });
  } catch (error) {
    next(error);
  }
}

async function listarResponsaveis(req, res, next) {
  try {
    const criancaId = Number(req.params.id);
    const responsaveis = await criancaRepository.listResponsaveis(criancaId);
    return res.json({ success: true, data: responsaveis });
  } catch (error) {
    next(error);
  }
}

async function adicionarResponsavel(req, res, next) {
  try {
    const criancaId = Number(req.params.id);
    const { usuario_id, tipo_relacao, permissao } = req.body;
    const result = await criancaRepository.linkResponsavel({ usuario_id, crianca_id: criancaId, tipo_relacao, permissao });
    return res.status(201).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
}

async function removerResponsavel(req, res, next) {
  try {
    const criancaId = Number(req.params.id);
    const usuarioId = Number(req.params.usuarioId);
    const removed = await criancaRepository.removeResponsavel(criancaId, usuarioId);
    if (!removed) return res.status(404).json({ success: false, message: 'Vínculo não encontrado.' });
    return res.json({ success: true, message: 'Vínculo removido.' });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  listarCriancas,
  criarCrianca,
  obterCrianca,
  atualizarCrianca,
  excluirCrianca,
  listarResponsaveis,
  adicionarResponsavel,
  removerResponsavel,
};

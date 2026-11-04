const configuracaoRepository = require('../repositories/configuracaoAlertaRepository');

async function obterConfiguracao(req, res, next) {
  try {
    const criancaId = Number(req.params.criancaId);
    const config = await configuracaoRepository.getByCrianca(criancaId, req.user.id);
    return res.json({ success: true, data: config || null });
  } catch (error) {
    next(error);
  }
}

async function atualizarConfiguracao(req, res, next) {
  try {
    const criancaId = Number(req.params.criancaId);
    const payload = { ...req.body, crianca_id: criancaId, usuario_id: req.user.id };
    const config = await configuracaoRepository.createOrUpdate(payload);
    return res.json({ success: true, data: config });
  } catch (error) {
    next(error);
  }
}

module.exports = { obterConfiguracao, atualizarConfiguracao };

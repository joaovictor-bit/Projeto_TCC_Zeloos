const alertaRepository = require('../repositories/alertaRepository');

async function listarAlertas(req, res, next) {
  try {
    const alertas = await alertaRepository.listForUser(req.user.id);
    return res.json({ success: true, data: alertas });
  } catch (error) {
    next(error);
  }
}

async function obterAlerta(req, res, next) {
  try {
    const alertaId = Number(req.params.id);
    const alerta = await alertaRepository.findById(alertaId);
    if (!alerta) return res.status(404).json({ success: false, message: 'Alerta não encontrado.' });
    return res.json({ success: true, data: alerta });
  } catch (error) {
    next(error);
  }
}

async function visualizarAlerta(req, res, next) {
  try {
    const alertaId = Number(req.params.id);
    const updated = await alertaRepository.markAsVisualizado(alertaId, req.user.id);
    if (!updated) return res.status(404).json({ success: false, message: 'Alerta não encontrado para este usuário.' });
    return res.json({ success: true, message: 'Alerta marcado como visualizado.' });
  } catch (error) {
    next(error);
  }
}

async function resolverAlerta(req, res, next) {
  try {
    const alertaId = Number(req.params.id);
    const updated = await alertaRepository.markAsResolvido(alertaId, req.user.id);
    if (!updated) return res.status(404).json({ success: false, message: 'Alerta não encontrado para este usuário.' });
    return res.json({ success: true, message: 'Alerta resolvido.' });
  } catch (error) {
    next(error);
  }
}

module.exports = { listarAlertas, obterAlerta, visualizarAlerta, resolverAlerta };

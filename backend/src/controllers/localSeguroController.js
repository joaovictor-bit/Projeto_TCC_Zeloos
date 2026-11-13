const localSeguroRepository = require('../repositories/localSeguroRepository');
const criancaRepository = require('../repositories/criancaRepository');

async function listarLocaisSeguros(req, res, next) {
  try {
    const criancaId = Number(req.params.id);
    const locais = await localSeguroRepository.listByCrianca(criancaId);
    return res.json({ success: true, data: locais });
  } catch (error) {
    next(error);
  }
}

async function criarLocalSeguro(req, res, next) {
  try {
    const criancaId = Number(req.params.id);
    const crianca = await criancaRepository.findById(criancaId);
    if (!crianca) return res.status(404).json({ success: false, message: 'Criança não encontrada.' });

    const { nome, latitude, longitude, raio_metros } = req.body;
    const local = await localSeguroRepository.create({ crianca_id: criancaId, nome, latitude, longitude, raio_metros });
    return res.status(201).json({ success: true, data: local });
  } catch (error) {
    next(error);
  }
}

async function atualizarLocalSeguro(req, res, next) {
  try {
    const localId = Number(req.params.id);
    const payload = { ...req.body };
    delete payload.id;
    const local = await localSeguroRepository.updateById(localId, payload);
    if (!local) return res.status(404).json({ success: false, message: 'Local seguro não encontrado.' });
    return res.json({ success: true, data: local });
  } catch (error) {
    next(error);
  }
}

async function excluirLocalSeguro(req, res, next) {
  try {
    const localId = Number(req.params.id);
    const deleted = await localSeguroRepository.removeById(localId);
    if (!deleted) return res.status(404).json({ success: false, message: 'Local seguro não encontrado.' });
    return res.json({ success: true, message: 'Local seguro removido.' });
  } catch (error) {
    next(error);
  }
}

module.exports = { listarLocaisSeguros, criarLocalSeguro, atualizarLocalSeguro, excluirLocalSeguro };

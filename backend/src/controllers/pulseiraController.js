const pulseiraRepository = require('../repositories/pulseiraRepository');
const criancaRepository = require('../repositories/criancaRepository');
const alertaRepository = require('../repositories/alertaRepository');
const { pointInCircle } = require('../utils/geo');
const localSeguroRepository = require('../repositories/localSeguroRepository');

async function listarPulseiras(req, res, next) {
  try {
    const pulseiras = await pulseiraRepository.listByUser(req.user.id);
    return res.json({ success: true, data: pulseiras });
  } catch (error) {
    next(error);
  }
}

async function criarPulseira(req, res, next) {
  try {
    const { crianca_id, identificador, nome_dispositivo, modelo } = req.body;
    const crianca = await criancaRepository.findById(crianca_id);

    if (!crianca) {
      return res.status(404).json({ success: false, message: 'Criança não encontrada.' });
    }
    if (!(await criancaRepository.belongsToUser(crianca_id, req.user.id))) {
      return res.status(403).json({ success: false, message: 'Você não tem acesso a esta criança.' });
    }

    const pulseira = await pulseiraRepository.create({ crianca_id, identificador, nome_dispositivo, modelo });
    return res.status(201).json({ success: true, data: pulseira });
  } catch (error) {
    next(error);
  }
}

async function obterPulseira(req, res, next) {
  try {
    const pulseiraId = Number(req.params.id);
    const pulseira = await pulseiraRepository.findByIdForUser(pulseiraId, req.user.id);
    if (!pulseira) return res.status(404).json({ success: false, message: 'Pulseira não encontrada.' });
    return res.json({ success: true, data: pulseira });
  } catch (error) {
    next(error);
  }
}

async function atualizarPulseira(req, res, next) {
  try {
    const pulseiraId = Number(req.params.id);
    const allowedFields = ['crianca_id', 'identificador', 'nome_dispositivo', 'modelo', 'status'];
    const unsupportedField = Object.keys(req.body).find((field) => !allowedFields.includes(field));
    if (unsupportedField) {
      return res.status(400).json({ success: false, message: `Campo não permitido: ${unsupportedField}.` });
    }
    if (!Object.keys(req.body).length) {
      return res.status(400).json({ success: false, message: 'Informe ao menos um campo para atualizar.' });
    }
    if (req.body.crianca_id !== undefined
      && !(await criancaRepository.belongsToUser(req.body.crianca_id, req.user.id))) {
      return res.status(403).json({ success: false, message: 'Você não tem acesso a esta criança.' });
    }
    const payload = { ...req.body };
    delete payload.id;
    const existing = await pulseiraRepository.findByIdForUser(pulseiraId, req.user.id);
    if (!existing) return res.status(404).json({ success: false, message: 'Pulseira não encontrada.' });
    const pulseira = await pulseiraRepository.updateById(pulseiraId, payload);
    if (!pulseira) return res.status(404).json({ success: false, message: 'Pulseira não encontrada.' });
    return res.json({ success: true, data: pulseira });
  } catch (error) {
    next(error);
  }
}

async function excluirPulseira(req, res, next) {
  try {
    const pulseiraId = Number(req.params.id);
    const existing = await pulseiraRepository.findByIdForUser(pulseiraId, req.user.id);
    if (!existing) return res.status(404).json({ success: false, message: 'Pulseira não encontrada.' });
    const deleted = await pulseiraRepository.removeById(pulseiraId);
    if (!deleted) return res.status(404).json({ success: false, message: 'Pulseira não encontrada.' });
    return res.json({ success: true, message: 'Pulseira removida com sucesso.' });
  } catch (error) {
    next(error);
  }
}

async function localizacaoAtual(req, res, next) {
  try {
    const pulseiraId = Number(req.params.id);
    const pulseira = await pulseiraRepository.findByIdForUser(pulseiraId, req.user.id);
    if (!pulseira) return res.status(404).json({ success: false, message: 'Pulseira não encontrada.' });

    const localizacao = await pulseiraRepository.getUltimaLocalizacao(pulseiraId);
    const locaisSeguros = await localSeguroRepository.listByCrianca(pulseira.crianca_id);

    let dentro = null;
    if (localizacao) {
      for (const local of locaisSeguros) {
        const isInside = pointInCircle(localizacao.latitude, localizacao.longitude, local.latitude, local.longitude, local.raio_metros);
        if (isInside) {
          dentro = local;
          break;
        }
      }
    }

    return res.json({ success: true, data: { pulseira, localizacao, dentro, locaisSeguros } });
  } catch (error) {
    next(error);
  }
}

async function historicoPulseira(req, res, next) {
  try {
    const pulseiraId = Number(req.params.id);
    const pulseira = await pulseiraRepository.findByIdForUser(pulseiraId, req.user.id);
    if (!pulseira) return res.status(404).json({ success: false, message: 'Pulseira não encontrada.' });
    const limit = Number(req.query.limit || 20);
    const offset = Number(req.query.offset || 0);
    const items = await pulseiraRepository.getHistorico(pulseiraId, limit, offset);
    return res.json({ success: true, data: items, pagination: { limit, offset } });
  } catch (error) {
    next(error);
  }
}

async function receberLocalizacao(req, res, next) {
  try {
    const { identificador, latitude, longitude, precisao_metros, bateria_percentual, origem = 'dispositivo' } = req.body;

    const pulseira = await pulseiraRepository.findByIdentificador(identificador);
    if (!pulseira) {
      return res.status(404).json({ success: false, message: 'Pulseira não encontrada.' });
    }

    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return res.status(400).json({ success: false, message: 'Coordenadas fora do limite válido.' });
    }

    const localizacao = await pulseiraRepository.registrarLocalizacao({
      pulseira_id: pulseira.id,
      latitude,
      longitude,
      precisao_metros,
      bateria_percentual,
      origem,
    });

    await pulseiraRepository.updateById(pulseira.id, {
      ultima_comunicacao_em: new Date(),
      bateria_percentual,
      status_conexao: 'conectada',
    });

    const locaisSeguros = await localSeguroRepository.listByCrianca(pulseira.crianca_id);
    const ultimaLocalizacaoAnterior = await pulseiraRepository.getUltimaLocalizacao(pulseira.id);

    let entrouEmLocal = null;
    let saiuDeLocal = null;

    if (ultimaLocalizacaoAnterior && ultimaLocalizacaoAnterior.id !== localizacao.id) {
      for (const local of locaisSeguros) {
        const anteriorDentro = pointInCircle(ultimaLocalizacaoAnterior.latitude, ultimaLocalizacaoAnterior.longitude, local.latitude, local.longitude, local.raio_metros);
        const atualDentro = pointInCircle(latitude, longitude, local.latitude, local.longitude, local.raio_metros);

        if (!anteriorDentro && atualDentro) {
          entrouEmLocal = local;
        }

        if (anteriorDentro && !atualDentro) {
          saiuDeLocal = local;
        }
      }
    }

    if (entrouEmLocal) {
      const existente = await alertaRepository.alreadyExists({ crianca_id: pulseira.crianca_id, tipo: 'entrada_local', local_seguro_id: entrouEmLocal.id, pulseira_id: pulseira.id });
      if (!existente) {
        await alertaRepository.create({
          crianca_id: pulseira.crianca_id,
          pulseira_id: pulseira.id,
          local_seguro_id: entrouEmLocal.id,
          tipo: 'entrada_local',
          titulo: 'Entrada em local seguro',
          mensagem: `A criança entrou em ${entrouEmLocal.nome}.`,
          ocorrido_em: new Date(),
        });
      }
    }

    if (saiuDeLocal) {
      const existente = await alertaRepository.alreadyExists({ crianca_id: pulseira.crianca_id, tipo: 'saida_local', local_seguro_id: saiuDeLocal.id, pulseira_id: pulseira.id });
      if (!existente) {
        await alertaRepository.create({
          crianca_id: pulseira.crianca_id,
          pulseira_id: pulseira.id,
          local_seguro_id: saiuDeLocal.id,
          tipo: 'saida_local',
          titulo: 'Saída de local seguro',
          mensagem: `A criança saiu de ${saiuDeLocal.nome}.`,
          ocorrido_em: new Date(),
        });
      }
    }

    return res.status(201).json({ success: true, data: { localizacao, pulseira, entrouEmLocal, saiuDeLocal } });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  listarPulseiras,
  criarPulseira,
  obterPulseira,
  atualizarPulseira,
  excluirPulseira,
  localizacaoAtual,
  historicoPulseira,
  receberLocalizacao,
};

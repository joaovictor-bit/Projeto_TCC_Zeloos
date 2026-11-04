const express = require('express');
const authMiddleware = require('../middlewares/authMiddleware');
const pulseiraController = require('../controllers/pulseiraController');

const router = express.Router();

router.get('/health', pulseiraController.localizacaoAtual);

router.post('/receber-localizacao', pulseiraController.receberLocalizacao);

router.use(authMiddleware);

router.get('/', pulseiraController.listarPulseiras);
router.post('/', pulseiraController.criarPulseira);
router.get('/:id', pulseiraController.obterPulseira);
router.put('/:id', pulseiraController.atualizarPulseira);
router.delete('/:id', pulseiraController.excluirPulseira);
router.get('/:id/localizacao-atual', pulseiraController.localizacaoAtual);
router.get('/:id/historico', pulseiraController.historicoPulseira);

module.exports = router;

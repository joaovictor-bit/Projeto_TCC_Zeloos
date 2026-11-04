const express = require('express');
const authMiddleware = require('../middlewares/authMiddleware');
const configuracaoController = require('../controllers/configuracaoController');

const router = express.Router();

router.use(authMiddleware);

router.get('/:criancaId', configuracaoController.obterConfiguracao);
router.put('/:criancaId', configuracaoController.atualizarConfiguracao);

module.exports = router;

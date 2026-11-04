const express = require('express');
const authMiddleware = require('../middlewares/authMiddleware');
const criancaController = require('../controllers/criancaController');
const localSeguroController = require('../controllers/localSeguroController');

const router = express.Router();

router.use(authMiddleware);

router.get('/', criancaController.listarCriancas);
router.post('/', criancaController.criarCrianca);
router.get('/:id', criancaController.obterCrianca);
router.put('/:id', criancaController.atualizarCrianca);
router.delete('/:id', criancaController.excluirCrianca);

router.get('/:id/responsaveis', criancaController.listarResponsaveis);
router.post('/:id/responsaveis', criancaController.adicionarResponsavel);
router.delete('/:id/responsaveis/:usuarioId', criancaController.removerResponsavel);

router.get('/:id/locais-seguros', localSeguroController.listarLocaisSeguros);
router.post('/:id/locais-seguros', localSeguroController.criarLocalSeguro);

module.exports = router;

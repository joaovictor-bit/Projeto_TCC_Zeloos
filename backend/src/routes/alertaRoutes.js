const express = require('express');
const authMiddleware = require('../middlewares/authMiddleware');
const alertaController = require('../controllers/alertaController');

const router = express.Router();

router.use(authMiddleware);

router.get('/', alertaController.listarAlertas);
router.get('/:id', alertaController.obterAlerta);
router.patch('/:id/visualizar', alertaController.visualizarAlerta);
router.patch('/:id/resolver', alertaController.resolverAlerta);

module.exports = router;

const express = require('express');
const authMiddleware = require('../middlewares/authMiddleware');
const localSeguroController = require('../controllers/localSeguroController');

const router = express.Router();

router.use(authMiddleware);

router.put('/:id', localSeguroController.atualizarLocalSeguro);
router.delete('/:id', localSeguroController.excluirLocalSeguro);

module.exports = router;

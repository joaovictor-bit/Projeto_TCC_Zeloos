const { body } = require('express-validator');

const registerValidation = [
  body('nome').trim().isLength({ min: 2 }).withMessage('Nome deve ter pelo menos 2 caracteres.'),
  body('email').isEmail().withMessage('E-mail inválido.'),
  body('senha').isLength({ min: 6 }).withMessage('Senha deve ter pelo menos 6 caracteres.'),
];

const loginValidation = [
  body('email').isEmail().withMessage('E-mail inválido.'),
  body('senha').notEmpty().withMessage('Senha obrigatória.'),
];

module.exports = { registerValidation, loginValidation };

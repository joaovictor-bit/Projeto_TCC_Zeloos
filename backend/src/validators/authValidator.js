const { body } = require('express-validator');

const nomeRule = () => body('nome').trim().isLength({ min: 2 }).withMessage('Nome deve ter pelo menos 2 caracteres.');

const telefoneRule = () => body('telefone')
  .optional({ values: 'falsy' })
  .trim()
  .matches(/^[0-9()+\-\s]+$/)
  .custom((value) => /^\d{10,13}$/.test(value.replace(/\D/g, '')))
  .withMessage('Telefone inválido. Informe DDD e número.');

const registerValidation = [
  nomeRule(),
  body('email').isEmail().withMessage('E-mail inválido.'),
  body('senha').isLength({ min: 6 }).withMessage('Senha deve ter pelo menos 6 caracteres.'),
  telefoneRule(),
];

const updateProfileValidation = [nomeRule(), telefoneRule()];

const loginValidation = [
  body('email').isEmail().withMessage('E-mail inválido.'),
  body('senha').notEmpty().withMessage('Senha obrigatória.'),
];

module.exports = { registerValidation, loginValidation, updateProfileValidation };

const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../config/env');
const { registerValidation, loginValidation, updateProfileValidation } = require('../validators/authValidator');
const handleValidation = require('../validators/validationResult');
const userRepository = require('../repositories/userRepository');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

router.post('/register', registerValidation, handleValidation, async (req, res, next) => {
  try {
    const { nome, email, senha, telefone } = req.body;

    const existingUser = await userRepository.findByEmail(email);
    if (existingUser) {
      return res.status(409).json({ success: false, message: 'E-mail já cadastrado.' });
    }

    const senhaHash = await bcrypt.hash(senha, 10);
    const user = await userRepository.createUser({ nome, email, senhaHash, telefone: telefone || null });

    const token = jwt.sign({ id: user.id, email: user.email, nome: user.nome }, JWT_SECRET, { expiresIn: '7d' });

    return res.status(201).json({ success: true, token, user: { ...user, ativo: true } });
  } catch (error) {
    next(error);
  }
});

router.post('/login', loginValidation, handleValidation, async (req, res, next) => {
  try {
    const { email, senha } = req.body;
    const user = await userRepository.findByEmail(email);

    if (!user || !user.senha_hash) {
      return res.status(401).json({ success: false, message: 'Credenciais inválidas.' });
    }

    const senhaValida = await bcrypt.compare(senha, user.senha_hash);
    if (!senhaValida) {
      return res.status(401).json({ success: false, message: 'Credenciais inválidas.' });
    }

    const token = jwt.sign({ id: user.id, email: user.email, nome: user.nome }, JWT_SECRET, { expiresIn: '7d' });

    return res.json({
      success: true,
      token,
      user: {
        id: user.id,
        nome: user.nome,
        email: user.email,
        telefone: user.telefone,
        ativo: !!user.ativo,
      },
    });
  } catch (error) {
    next(error);
  }
});

router.get('/me', authMiddleware, async (req, res, next) => {
  try {
    const user = await userRepository.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'Usuário não encontrado.' });
    }

    return res.json({ success: true, user });
  } catch (error) {
    next(error);
  }
});

router.put('/me', authMiddleware, updateProfileValidation, handleValidation, async (req, res, next) => {
  try {
    const { nome, telefone } = req.body;
    const user = await userRepository.updateProfile(req.user.id, { nome, telefone: telefone || null });
    if (!user) {
      return res.status(404).json({ success: false, message: 'Usuário não encontrado.' });
    }

    return res.json({ success: true, user });
  } catch (error) {
    next(error);
  }
});

module.exports = router;

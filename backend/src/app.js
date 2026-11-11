const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { CORS_ORIGIN } = require('./config/env');
const db = require('./config/db');

const app = express();

app.use(helmet());
app.use(express.json({ limit: '1mb' }));
app.use('/api', (req, res, next) => {
  res.set('Cache-Control', 'no-store');
  next();
});
app.use(cors({
  origin: (origin, callback) => {
    const configuredOrigins = CORS_ORIGIN.split(',').map((value) => value.trim());
    const localDevelopmentOrigin = process.env.NODE_ENV !== 'production'
      && /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin || '');

    callback(null, !origin || configuredOrigins.includes('*') || configuredOrigins.includes(origin) || localDevelopmentOrigin);
  },
  credentials: true,
}));
app.use(morgan('dev'));

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Muitas tentativas. Tente novamente mais tarde.' },
});

app.use('/api/auth', authLimiter);

app.get('/api/health', async (req, res) => {
  try {
    await db.execute('SELECT 1');
    return res.json({ status: 'ok', service: 'pulseira-localizadora-api', database: 'ok' });
  } catch (error) {
    console.error('Database health check failed:', error.code || error.name);
    return res.status(503).json({
      status: 'error',
      service: 'pulseira-localizadora-api',
      database: 'unavailable',
      error: error.code || 'DATABASE_UNAVAILABLE',
    });
  }
});

app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/criancas', require('./routes/criancaRoutes'));
app.use('/api/pulseiras', require('./routes/pulseiraRoutes'));
app.use('/api/locais-seguros', require('./routes/localSeguroRoutes'));
app.use('/api/alertas', require('./routes/alertaRoutes'));
app.use('/api/configuracoes', require('./routes/configuracaoRoutes'));

app.use((err, req, res, next) => {
  console.error(err);
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Erro interno no servidor';
  res.status(statusCode).json({
    success: false,
    message,
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack }),
  });
});

module.exports = app;
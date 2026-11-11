require('dotenv').config();

module.exports = {
  PORT: process.env.PORT || 3005,
  DB_HOST: process.env.DB_HOST || 'localhost',
  DB_PORT: Number(process.env.DB_PORT || 3306),
  DB_USER: process.env.DB_USER || 'root',
  DB_PASSWORD: process.env.DB_PASSWORD || 'senai2026',
  DB_NAME: process.env.DB_NAME || 'pulseira_localizadora',
  JWT_SECRET: process.env.JWT_SECRET || 'tcc-secret-default-change-me',
  CORS_ORIGIN: process.env.CORS_ORIGIN || '*',
  DEMO_MODE: process.env.DEMO_MODE === 'true',
};

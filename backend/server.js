require('dotenv').config();

const app = require('./src/app');
const { PORT } = require('./src/config/env');

app.listen(PORT, () => {
  console.log(`API rodando na porta ${PORT}`);
});

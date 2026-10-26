import express from 'express';

import type { Banco } from './db.js';
import { rotaDesconhecida, tratarErros } from './erros.js';
import { rotasRegistros } from './routes/registros.js';
import { rotasTalhoes } from './routes/talhoes.js';

// Monta a aplicação Express. O banco é recebido por parâmetro para que os
// testes usem um Postgres em memória e o servidor use o real.
export function criarApp(banco: Banco) {
  const app = express();

  app.disable('x-powered-by');
  app.use(express.json({ limit: '100kb' }));

  // Usado pelo aplicativo para saber se o servidor está acessível.
  app.get('/health', (_req, res) => {
    res.json({ status: 'ok' });
  });

  app.use('/talhoes', rotasTalhoes(banco));
  app.use('/registros', rotasRegistros(banco));

  app.use(rotaDesconhecida);
  app.use(tratarErros);
  return app;
}

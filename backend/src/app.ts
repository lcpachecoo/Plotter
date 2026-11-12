import express from 'express';

import { ServicoClima } from './clima.js';
import type { Banco } from './db.js';
import { rotaDesconhecida, tratarErros } from './erros.js';
import { rotasClima } from './routes/clima.js';
import { rotasRegistros } from './routes/registros.js';
import { rotasTalhoes } from './routes/talhoes.js';

export interface OpcoesApp {
  // Serviço de previsão do tempo (Etapa 6). Os testes passam um serviço com
  // um `fetch` falso; sem ele, a rota /clima responde que não está configurada.
  clima?: ServicoClima;
}

// Monta a aplicação Express. O banco é recebido por parâmetro para que os
// testes usem um Postgres em memória e o servidor use o real.
export function criarApp(banco: Banco, opcoes: OpcoesApp = {}) {
  const app = express();

  app.disable('x-powered-by');
  app.use(express.json({ limit: '100kb' }));

  // Usado pelo aplicativo para saber se o servidor está acessível.
  app.get('/health', (_req, res) => {
    res.json({ status: 'ok' });
  });

  app.use('/talhoes', rotasTalhoes(banco));
  app.use('/registros', rotasRegistros(banco));
  app.use('/clima', rotasClima(opcoes.clima ?? new ServicoClima()));

  app.use(rotaDesconhecida);
  app.use(tratarErros);
  return app;
}

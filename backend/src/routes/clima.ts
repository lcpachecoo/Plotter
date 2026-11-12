import { Router } from 'express';

import type { ServicoClima } from '../clima.js';

// /clima — previsão do tempo da fazenda, obtida do serviço externo
// OpenWeatherMap (ver ../clima.ts). Falhas do serviço externo chegam ao
// middleware `tratarErros` como HttpError 502, 503 ou 504.
export function rotasClima(clima: ServicoClima): Router {
  const rotas = Router();

  rotas.get('/previsao', async (_req, res) => {
    res.json(await clima.previsao());
  });

  return rotas;
}

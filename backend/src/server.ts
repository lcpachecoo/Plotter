import 'dotenv/config';

import { criarApp } from './app.js';
import { configClimaDoAmbiente, ServicoClima } from './clima.js';
import { criarEsquema, criarPool } from './db.js';

// Ponto de entrada: lê a configuração do .env, garante as tabelas e sobe a
// API. HOST 0.0.0.0 permite o acesso pelo emulador e por celulares na rede.
const PORTA = Number(process.env.PORT ?? 3000);
const HOST = process.env.HOST ?? '0.0.0.0';
const DATABASE_URL = process.env.DATABASE_URL;

if (!DATABASE_URL) {
  console.error('Defina DATABASE_URL no arquivo .env (veja .env.example).');
  process.exit(1);
}

const pool = criarPool(DATABASE_URL);

try {
  await criarEsquema(pool);
} catch (erro) {
  console.error('Não foi possível conectar ao PostgreSQL:', (erro as Error).message);
  process.exit(1);
}

// Previsão do tempo (Etapa 6): sem a chave, o resto da API funciona e a rota
// /clima/previsao responde 503 explicando que não está configurada.
const clima = new ServicoClima(configClimaDoAmbiente());
if (!clima.configurado) {
  console.warn(
    'Previsão do tempo desativada: defina OPENWEATHER_API_KEY, FAZENDA_LAT e ' +
      'FAZENDA_LON no arquivo .env (veja .env.example).',
  );
}

criarApp(pool, { clima }).listen(PORTA, HOST, () => {
  console.log(`API do Plotter em http://localhost:${PORTA}`);
});

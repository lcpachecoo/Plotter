import 'dotenv/config';

import { criarEsquema, criarPool } from './db.js';
import { inserirRegistro, inserirTalhao, listarTalhoes } from './repositorio.js';
import type { RegistroEntrada, TalhaoEntrada } from './validacao.js';

// Carga de exemplo (`npm run seed`): os mesmos talhões e registros que o
// aplicativo gravava no SQLite na Etapa 4 (lib/data/mock_data.dart), para
// que a demonstração não comece com o banco vazio. Só roda com o banco vazio.

const TALHOES: TalhaoEntrada[] = [
  { nome: 'Talhão 01 - Pivô Norte', cultura: 'Soja', areaHa: 42.5, estagio: 'Floração (R2)', pivo: 'Pivô Norte', status: 'pendente' },
  { nome: 'Talhão 02 - Baixada', cultura: 'Milho', areaHa: 30.0, estagio: 'Vegetativo (V8)', pivo: '', status: 'feito' },
  { nome: 'Talhão 03 - Pivô Sul', cultura: 'Soja', areaHa: 55.2, estagio: 'Enchimento de grãos (R5)', pivo: 'Pivô Sul', status: 'agendado' },
  { nome: 'Talhão 04 - Fundo de Vale', cultura: 'Algodão', areaHa: 21.8, estagio: 'Formação de capulho', pivo: '', status: 'pendente' },
];

// [posição do talhão, insumo, tipo, dias a partir de hoje, quantidade, responsável]
const REGISTROS: [number, string, RegistroEntrada['tipo'], number, string, string][] = [
  [1, 'Ureia 45%', 'fertilizante', -3, '180 kg/ha', 'João Operador'],
  [2, 'Inseticida Lambda', 'defensivo', -9, '0.3 L/ha', 'Maria Gerente'],
  [0, 'Fungicida Triazol', 'defensivo', -11, '0.5 L/ha', 'João Operador'],
  [3, 'Regulador Mepiquat', 'defensivo', -17, '0.6 L/ha', 'Maria Gerente'],
  [0, 'Inseticida', 'defensivo', 2, '0.4 L/ha', ''],
  [1, 'Herbicida', 'defensivo', 10, '2 L/ha', ''],
  [2, 'Fungicida', 'defensivo', 4, '0.5 L/ha', ''],
  [3, 'Desfolhante', 'outro', 15, '1.5 L/ha', ''],
];

function diaRelativo(deslocamento: number): string {
  const data = new Date();
  data.setDate(data.getDate() + deslocamento);
  const mes = String(data.getMonth() + 1).padStart(2, '0');
  const dia = String(data.getDate()).padStart(2, '0');
  return `${data.getFullYear()}-${mes}-${dia}`;
}

const url = process.env.DATABASE_URL;
if (!url) {
  console.error('Defina DATABASE_URL no arquivo .env (veja .env.example).');
  process.exit(1);
}

const pool = criarPool(url);
await criarEsquema(pool);

if ((await listarTalhoes(pool)).length > 0) {
  console.log('O banco já possui talhões; nada foi inserido.');
} else {
  const ids: number[] = [];
  for (const talhao of TALHOES) ids.push((await inserirTalhao(pool, talhao)).id);
  for (const [pos, insumo, tipo, dias, quantidade, responsavel] of REGISTROS) {
    await inserirRegistro(pool, {
      talhaoId: ids[pos], insumo, tipo, data: diaRelativo(dias), quantidade, responsavel, observacoes: '',
    });
  }
  console.log(`Inseridos ${TALHOES.length} talhões e ${REGISTROS.length} registros.`);
}

await pool.end();

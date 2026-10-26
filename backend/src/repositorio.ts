import type { Banco } from './db.js';
import type { RegistroEntrada, TalhaoEntrada } from './validacao.js';

// Acesso ao banco. Só este arquivo contém SQL: as rotas chamam as funções
// abaixo e recebem objetos já no formato da API (camelCase).
//
// Todos os valores vindos do cliente entram como parâmetros ($1, $2...),
// nunca concatenados ao SQL, o que impede injeção de SQL.

export interface Talhao extends TalhaoEntrada {
  id: number;
}

export interface Registro extends RegistroEntrada {
  id: number;
}

type Linha = Record<string, unknown>;

const paraTalhao = (l: Linha): Talhao => ({
  id: l.id as number,
  nome: l.nome as string,
  cultura: l.cultura as string,
  areaHa: Number(l.area_ha),
  estagio: l.estagio as string,
  pivo: l.pivo as string,
  status: l.status as Talhao['status'],
});

const paraRegistro = (l: Linha): Registro => ({
  id: l.id as number,
  talhaoId: l.talhao_id as number,
  insumo: l.insumo as string,
  tipo: l.tipo as Registro['tipo'],
  data: dataIso(l.data),
  quantidade: l.quantidade as string,
  responsavel: l.responsavel as string,
  observacoes: l.observacoes as string,
});

// O driver `pg` devolve DATE como texto (ver db.ts); o banco em memória dos
// testes devolve um Date em UTC. As duas formas viram "aaaa-mm-dd".
function dataIso(valor: unknown): string {
  return valor instanceof Date ? valor.toISOString().slice(0, 10) : String(valor).slice(0, 10);
}

// ---------------------------------------------------------------------------
// Talhões
// ---------------------------------------------------------------------------

export async function listarTalhoes(banco: Banco): Promise<Talhao[]> {
  const { rows } = await banco.query('SELECT * FROM talhoes ORDER BY id');
  return rows.map(paraTalhao);
}

export async function buscarTalhao(banco: Banco, id: number): Promise<Talhao | null> {
  const { rows } = await banco.query('SELECT * FROM talhoes WHERE id = $1', [id]);
  return rows.length ? paraTalhao(rows[0]) : null;
}

export async function inserirTalhao(banco: Banco, t: TalhaoEntrada): Promise<Talhao> {
  const { rows } = await banco.query(
    `INSERT INTO talhoes (nome, cultura, area_ha, estagio, pivo, status)
     VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
    [t.nome, t.cultura, t.areaHa, t.estagio, t.pivo, t.status],
  );
  return paraTalhao(rows[0]);
}

// Devolve `null` se o talhão não existir.
export async function atualizarTalhao(banco: Banco, id: number, t: TalhaoEntrada): Promise<Talhao | null> {
  const { rows } = await banco.query(
    `UPDATE talhoes
        SET nome = $1, cultura = $2, area_ha = $3, estagio = $4, pivo = $5, status = $6
      WHERE id = $7 RETURNING *`,
    [t.nome, t.cultura, t.areaHa, t.estagio, t.pivo, t.status, id],
  );
  return rows.length ? paraTalhao(rows[0]) : null;
}

// Remove o talhão e, pelo ON DELETE CASCADE, os registros dele. Devolve
// quantos registros foram removidos junto, ou `null` se o talhão não existir.
export async function removerTalhao(banco: Banco, id: number): Promise<number | null> {
  const contagem = await banco.query(
    'SELECT COUNT(*)::int AS total FROM registros WHERE talhao_id = $1',
    [id],
  );
  const { rowCount } = await banco.query('DELETE FROM talhoes WHERE id = $1', [id]);
  return rowCount ? (contagem.rows[0].total as number) : null;
}

// ---------------------------------------------------------------------------
// Registros
// ---------------------------------------------------------------------------

// Do mais recente para o mais antigo, como o histórico do aplicativo.
export async function listarRegistros(banco: Banco, talhaoId?: number): Promise<Registro[]> {
  const { rows } = talhaoId === undefined
    ? await banco.query('SELECT * FROM registros ORDER BY data DESC, id DESC')
    : await banco.query(
        'SELECT * FROM registros WHERE talhao_id = $1 ORDER BY data DESC, id DESC',
        [talhaoId],
      );
  return rows.map(paraRegistro);
}

export async function buscarRegistro(banco: Banco, id: number): Promise<Registro | null> {
  const { rows } = await banco.query('SELECT * FROM registros WHERE id = $1', [id]);
  return rows.length ? paraRegistro(rows[0]) : null;
}

export async function inserirRegistro(banco: Banco, r: RegistroEntrada): Promise<Registro> {
  const { rows } = await banco.query(
    `INSERT INTO registros (talhao_id, insumo, tipo, data, quantidade, responsavel, observacoes)
     VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
    [r.talhaoId, r.insumo, r.tipo, r.data, r.quantidade, r.responsavel, r.observacoes],
  );
  return paraRegistro(rows[0]);
}

export async function atualizarRegistro(banco: Banco, id: number, r: RegistroEntrada): Promise<Registro | null> {
  const { rows } = await banco.query(
    `UPDATE registros
        SET talhao_id = $1, insumo = $2, tipo = $3, data = $4,
            quantidade = $5, responsavel = $6, observacoes = $7
      WHERE id = $8 RETURNING *`,
    [r.talhaoId, r.insumo, r.tipo, r.data, r.quantidade, r.responsavel, r.observacoes, id],
  );
  return rows.length ? paraRegistro(rows[0]) : null;
}

export async function removerRegistro(banco: Banco, id: number): Promise<boolean> {
  const { rowCount } = await banco.query('DELETE FROM registros WHERE id = $1', [id]);
  return (rowCount ?? 0) > 0;
}

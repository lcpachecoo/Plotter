import { newDb } from 'pg-mem';
import request from 'supertest';
import { beforeEach, describe, expect, it } from 'vitest';

import { criarApp } from '../src/app.js';
import { criarEsquema } from '../src/db.js';

// Testes da API com um PostgreSQL em memória (pg-mem): cada teste começa
// com o banco vazio e não depende de servidor nem de Docker.

let app: ReturnType<typeof criarApp>;

beforeEach(async () => {
  const { Pool } = newDb().adapters.createPg();
  const pool = new Pool();
  await criarEsquema(pool);
  app = criarApp(pool);
});

const talhaoValido = {
  nome: 'Talhão 01 - Pivô Norte',
  cultura: 'Soja',
  areaHa: 42.5,
  estagio: 'Floração (R2)',
  pivo: 'Pivô Norte',
  status: 'pendente',
};

const registroValido = (talhaoId: number) => ({
  talhaoId,
  insumo: 'Fungicida Triazol',
  tipo: 'defensivo',
  data: '2026-10-20',
  quantidade: '0.5 L/ha',
  responsavel: 'João Operador',
  observacoes: '',
});

async function criarTalhao() {
  const res = await request(app).post('/talhoes').send(talhaoValido).expect(201);
  return res.body.id as number;
}

describe('GET /health', () => {
  it('informa que o servidor está no ar', async () => {
    await request(app).get('/health').expect(200, { status: 'ok' });
  });
});

describe('fluxo completo de talhão', () => {
  it('cria, lista, consulta, altera e exclui', async () => {
    const id = await criarTalhao();

    const lista = await request(app).get('/talhoes').expect(200);
    expect(lista.body).toHaveLength(1);
    expect(lista.body[0]).toMatchObject({ id, ...talhaoValido });

    await request(app)
      .put(`/talhoes/${id}`)
      .send({ ...talhaoValido, status: 'feito', areaHa: 40 })
      .expect(200);
    const alterado = await request(app).get(`/talhoes/${id}`).expect(200);
    expect(alterado.body).toMatchObject({ status: 'feito', areaHa: 40 });

    await request(app).delete(`/talhoes/${id}`).expect(200, { registrosRemovidos: 0 });
    await request(app).get(`/talhoes/${id}`).expect(404);
  });

  it('remove os textos com espaços nas pontas', async () => {
    const res = await request(app)
      .post('/talhoes')
      .send({ ...talhaoValido, nome: '  Talhão 05  ' })
      .expect(201);
    expect(res.body.nome).toBe('Talhão 05');
  });
});

describe('fluxo completo de registro', () => {
  it('cria, lista, altera e exclui um registro do talhão', async () => {
    const talhaoId = await criarTalhao();

    const criado = await request(app).post('/registros').send(registroValido(talhaoId)).expect(201);
    expect(criado.body).toMatchObject(registroValido(talhaoId));
    const id = criado.body.id as number;

    const doTalhao = await request(app).get(`/registros?talhaoId=${talhaoId}`).expect(200);
    expect(doTalhao.body.map((r: { id: number }) => r.id)).toEqual([id]);

    const alterado = await request(app)
      .put(`/registros/${id}`)
      .send({ ...registroValido(talhaoId), data: '2026-12-01' })
      .expect(200);
    expect(alterado.body.data).toBe('2026-12-01');

    await request(app).delete(`/registros/${id}`).expect(204);
    await request(app).get(`/registros/${id}`).expect(404);
  });

  it('lista do mais recente para o mais antigo', async () => {
    const talhaoId = await criarTalhao();
    for (const data of ['2026-01-10', '2026-03-05', '2026-02-01']) {
      await request(app).post('/registros').send({ ...registroValido(talhaoId), data }).expect(201);
    }
    const res = await request(app).get('/registros').expect(200);
    expect(res.body.map((r: { data: string }) => r.data)).toEqual(['2026-03-05', '2026-02-01', '2026-01-10']);
  });

  it('exclui os registros junto com o talhão', async () => {
    const talhaoId = await criarTalhao();
    await request(app).post('/registros').send(registroValido(talhaoId)).expect(201);
    await request(app).post('/registros').send(registroValido(talhaoId)).expect(201);

    await request(app).delete(`/talhoes/${talhaoId}`).expect(200, { registrosRemovidos: 2 });
    const res = await request(app).get('/registros').expect(200);
    expect(res.body).toEqual([]);
  });
});

describe('entradas inválidas', () => {
  it('rejeita talhão sem campos obrigatórios, informando cada campo', async () => {
    const res = await request(app)
      .post('/talhoes')
      .send({ nome: '   ', areaHa: -3, status: 'qualquer' })
      .expect(400);
    expect(Object.keys(res.body.campos).sort()).toEqual(['areaHa', 'cultura', 'nome', 'status']);
  });

  it('rejeita área enviada como texto', async () => {
    const res = await request(app).post('/talhoes').send({ ...talhaoValido, areaHa: '42' }).expect(400);
    expect(res.body.campos).toHaveProperty('areaHa');
  });

  it('rejeita data inexistente e tipo desconhecido', async () => {
    const talhaoId = await criarTalhao();
    const res = await request(app)
      .post('/registros')
      .send({ ...registroValido(talhaoId), data: '2026-02-30', tipo: 'semente' })
      .expect(400);
    expect(Object.keys(res.body.campos).sort()).toEqual(['data', 'tipo']);
  });

  it('rejeita registro de talhão inexistente', async () => {
    const res = await request(app).post('/registros').send(registroValido(999)).expect(400);
    expect(res.body.campos.talhaoId).toBe('O talhão informado não existe.');
  });

  it('rejeita JSON malformado', async () => {
    await request(app)
      .post('/talhoes')
      .set('Content-Type', 'application/json')
      .send('{"nome": ')
      .expect(400);
  });

  it('rejeita id inválido na URL', async () => {
    await request(app).get('/talhoes/abc').expect(400);
  });

  it('devolve 404 para item e rota inexistentes', async () => {
    await request(app).put('/talhoes/999').send(talhaoValido).expect(404);
    await request(app).delete('/registros/999').expect(404);
    await request(app).get('/nada').expect(404);
  });
});

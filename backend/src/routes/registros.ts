import { Router } from 'express';

import type { Banco } from '../db.js';
import { HttpError, naoEncontrado } from '../erros.js';
import * as repo from '../repositorio.js';
import { type RegistroEntrada, validarId, validarRegistro } from '../validacao.js';

// /registros — CRUD dos registros de aplicação.
// GET /registros?talhaoId=3 filtra os registros de um talhão.
export function rotasRegistros(banco: Banco): Router {
  const rotas = Router();

  rotas.get('/', async (req, res) => {
    const filtro = req.query.talhaoId;
    const talhaoId = typeof filtro === 'string' ? validarId(filtro) : undefined;
    res.json(await repo.listarRegistros(banco, talhaoId));
  });

  rotas.get('/:id', async (req, res) => {
    const registro = await repo.buscarRegistro(banco, validarId(req.params.id));
    if (!registro) throw naoEncontrado('Registro');
    res.json(registro);
  });

  rotas.post('/', async (req, res) => {
    const dados = await validarComTalhao(banco, req.body);
    const registro = await repo.inserirRegistro(banco, dados);
    res.status(201).location(`/registros/${registro.id}`).json(registro);
  });

  rotas.put('/:id', async (req, res) => {
    const id = validarId(req.params.id);
    const dados = await validarComTalhao(banco, req.body);
    const registro = await repo.atualizarRegistro(banco, id, dados);
    if (!registro) throw naoEncontrado('Registro');
    res.json(registro);
  });

  rotas.delete('/:id', async (req, res) => {
    const removido = await repo.removerRegistro(banco, validarId(req.params.id));
    if (!removido) throw naoEncontrado('Registro');
    res.status(204).end();
  });

  return rotas;
}

// Além do formato dos campos, o talhão informado precisa existir. A
// verificação é feita antes do INSERT para devolver uma mensagem clara em vez
// de um erro de chave estrangeira do banco.
async function validarComTalhao(banco: Banco, corpo: unknown): Promise<RegistroEntrada> {
  const dados = validarRegistro(corpo);
  if (!(await repo.buscarTalhao(banco, dados.talhaoId))) {
    throw new HttpError(400, 'Dados inválidos. Revise os campos informados.', {
      talhaoId: 'O talhão informado não existe.',
    });
  }
  return dados;
}

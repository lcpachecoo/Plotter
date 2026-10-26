import { Router } from 'express';

import type { Banco } from '../db.js';
import { naoEncontrado } from '../erros.js';
import * as repo from '../repositorio.js';
import { validarId, validarTalhao } from '../validacao.js';

// /talhoes — CRUD de talhões.
//
// Erros lançados aqui (validação, 404) são repassados pelo Express 5 ao
// middleware `tratarErros`, que monta a resposta.
export function rotasTalhoes(banco: Banco): Router {
  const rotas = Router();

  rotas.get('/', async (_req, res) => {
    res.json(await repo.listarTalhoes(banco));
  });

  rotas.get('/:id', async (req, res) => {
    const talhao = await repo.buscarTalhao(banco, validarId(req.params.id));
    if (!talhao) throw naoEncontrado('Talhão');
    res.json(talhao);
  });

  rotas.post('/', async (req, res) => {
    const talhao = await repo.inserirTalhao(banco, validarTalhao(req.body));
    res.status(201).location(`/talhoes/${talhao.id}`).json(talhao);
  });

  rotas.put('/:id', async (req, res) => {
    const id = validarId(req.params.id);
    const talhao = await repo.atualizarTalhao(banco, id, validarTalhao(req.body));
    if (!talhao) throw naoEncontrado('Talhão');
    res.json(talhao);
  });

  rotas.delete('/:id', async (req, res) => {
    const registrosRemovidos = await repo.removerTalhao(banco, validarId(req.params.id));
    if (registrosRemovidos === null) throw naoEncontrado('Talhão');
    res.json({ registrosRemovidos });
  });

  return rotas;
}

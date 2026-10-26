import type { ErrorRequestHandler, RequestHandler } from 'express';

// Erro com status HTTP conhecido. As rotas lançam este erro e o
// middleware `tratarErros` o converte na resposta JSON padrão:
//
//   { "erro": "mensagem legível", "campos": { "nome": "motivo" } }
//
// `campos` só aparece nos erros de validação (400).
export class HttpError extends Error {
  constructor(
    readonly status: number,
    mensagem: string,
    readonly campos?: Record<string, string>,
  ) {
    super(mensagem);
  }
}

export const naoEncontrado = (recurso: string) =>
  new HttpError(404, `${recurso} não encontrado.`);

// Rota inexistente.
export const rotaDesconhecida: RequestHandler = (req, _res, next) => {
  next(new HttpError(404, `Rota ${req.method} ${req.path} não existe.`));
};

export const tratarErros: ErrorRequestHandler = (erro, _req, res, _next) => {
  if (erro instanceof HttpError) {
    res.status(erro.status).json({ erro: erro.message, campos: erro.campos });
    return;
  }

  // Corpo da requisição que não é um JSON válido (lançado pelo express.json).
  if (erro?.type === 'entity.parse.failed') {
    res.status(400).json({ erro: 'O corpo da requisição não é um JSON válido.' });
    return;
  }

  // Qualquer outra falha (ex.: banco fora do ar): o detalhe fica no log do
  // servidor e o cliente recebe só uma mensagem genérica.
  console.error(erro);
  res.status(500).json({ erro: 'Erro interno no servidor. Tente novamente.' });
};

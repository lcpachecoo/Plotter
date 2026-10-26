import { HttpError } from './erros.js';

// Validação dos dados recebidos pela API.
//
// O aplicativo já valida os formulários, mas o servidor não pode confiar
// no cliente: toda entrada é conferida aqui antes de chegar ao banco.

export const STATUS_TALHAO = ['feito', 'pendente', 'agendado'] as const;
export const TIPOS_INSUMO = ['defensivo', 'fertilizante', 'outro'] as const;

const TAMANHO_MAXIMO = 120;
const TAMANHO_MAXIMO_OBSERVACOES = 1000;

export interface TalhaoEntrada {
  nome: string;
  cultura: string;
  areaHa: number;
  estagio: string;
  pivo: string;
  status: (typeof STATUS_TALHAO)[number];
}

export interface RegistroEntrada {
  talhaoId: number;
  insumo: string;
  tipo: (typeof TIPOS_INSUMO)[number];
  data: string;
  quantidade: string;
  responsavel: string;
  observacoes: string;
}

// Acumula os problemas de cada campo para devolver todos de uma vez, e não
// só o primeiro.
class Validador {
  readonly erros: Record<string, string> = {};

  constructor(private readonly corpo: Record<string, unknown>) {}

  texto(campo: string, rotulo: string, opcoes: { obrigatorio: boolean; maximo?: number }): string {
    const valor = this.corpo[campo];
    const maximo = opcoes.maximo ?? TAMANHO_MAXIMO;

    if (valor === undefined || valor === null) {
      if (opcoes.obrigatorio) this.erros[campo] = `Informe ${rotulo}.`;
      return '';
    }
    if (typeof valor !== 'string') {
      this.erros[campo] = `${capitalizar(rotulo)} deve ser um texto.`;
      return '';
    }
    const limpo = valor.trim();
    if (opcoes.obrigatorio && limpo.length === 0) {
      this.erros[campo] = `Informe ${rotulo}.`;
    } else if (limpo.length > maximo) {
      this.erros[campo] = `${capitalizar(rotulo)} deve ter no máximo ${maximo} caracteres.`;
    }
    return limpo;
  }

  opcao<T extends string>(campo: string, rotulo: string, validas: readonly T[]): T {
    const valor = this.corpo[campo];
    if (typeof valor !== 'string' || !validas.includes(valor as T)) {
      this.erros[campo] = `${capitalizar(rotulo)} inválido. Use: ${validas.join(', ')}.`;
    }
    return valor as T;
  }

  numeroPositivo(campo: string, rotulo: string): number {
    const valor = this.corpo[campo];
    if (typeof valor !== 'number' || !Number.isFinite(valor) || valor <= 0) {
      this.erros[campo] = `${capitalizar(rotulo)} deve ser um número maior que zero.`;
    }
    return valor as number;
  }

  idInteiro(campo: string, rotulo: string): number {
    const valor = this.corpo[campo];
    if (typeof valor !== 'number' || !Number.isInteger(valor) || valor <= 0) {
      this.erros[campo] = `Informe ${rotulo}.`;
    }
    return valor as number;
  }

  // Data no formato aaaa-mm-dd que exista no calendário (rejeita 2026-02-30).
  data(campo: string, rotulo: string): string {
    const valor = this.corpo[campo];
    if (typeof valor !== 'string' || !dataIsoValida(valor)) {
      this.erros[campo] = `${capitalizar(rotulo)} inválida. Use o formato aaaa-mm-dd.`;
    }
    return valor as string;
  }

  // Lança 400 com a lista de campos inválidos, se houver algum.
  concluir(): void {
    if (Object.keys(this.erros).length > 0) {
      throw new HttpError(400, 'Dados inválidos. Revise os campos informados.', this.erros);
    }
  }
}

export function validarTalhao(corpo: unknown): TalhaoEntrada {
  const v = new Validador(objeto(corpo));
  const talhao: TalhaoEntrada = {
    nome: v.texto('nome', 'o nome do talhão', { obrigatorio: true }),
    cultura: v.texto('cultura', 'a cultura plantada', { obrigatorio: true }),
    areaHa: v.numeroPositivo('areaHa', 'a área'),
    estagio: v.texto('estagio', 'o estágio', { obrigatorio: false }),
    pivo: v.texto('pivo', 'o pivô', { obrigatorio: false }),
    status: v.opcao('status', 'o status', STATUS_TALHAO),
  };
  v.concluir();
  return talhao;
}

export function validarRegistro(corpo: unknown): RegistroEntrada {
  const v = new Validador(objeto(corpo));
  const registro: RegistroEntrada = {
    talhaoId: v.idInteiro('talhaoId', 'o talhão da aplicação'),
    insumo: v.texto('insumo', 'o produto aplicado', { obrigatorio: true }),
    tipo: v.opcao('tipo', 'o tipo de insumo', TIPOS_INSUMO),
    data: v.data('data', 'a data da aplicação'),
    quantidade: v.texto('quantidade', 'a quantidade aplicada', { obrigatorio: true }),
    responsavel: v.texto('responsavel', 'o responsável', { obrigatorio: false }),
    observacoes: v.texto('observacoes', 'as observações', {
      obrigatorio: false,
      maximo: TAMANHO_MAXIMO_OBSERVACOES,
    }),
  };
  v.concluir();
  return registro;
}

// Converte o `:id` da URL em número, rejeitando valores como "abc" ou "1.5".
export function validarId(texto: string): number {
  const id = Number(texto);
  if (!Number.isInteger(id) || id <= 0) {
    throw new HttpError(400, 'Identificador inválido na URL.');
  }
  return id;
}

function objeto(corpo: unknown): Record<string, unknown> {
  if (typeof corpo !== 'object' || corpo === null || Array.isArray(corpo)) {
    throw new HttpError(400, 'Envie os dados como um objeto JSON.');
  }
  return corpo as Record<string, unknown>;
}

function dataIsoValida(texto: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(texto)) return false;
  const [ano, mes, dia] = texto.split('-').map(Number);
  const data = new Date(Date.UTC(ano, mes - 1, dia));
  return data.getUTCFullYear() === ano && data.getUTCMonth() === mes - 1 && data.getUTCDate() === dia;
}

function capitalizar(texto: string): string {
  const semArtigo = texto.replace(/^(o|a|os|as) /, '');
  return semArtigo.charAt(0).toUpperCase() + semArtigo.slice(1);
}

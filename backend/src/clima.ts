import { HttpError } from './erros.js';

// Integração com o serviço externo de previsão do tempo (OpenWeatherMap).
//
// O aplicativo não fala direto com o OpenWeatherMap: ele chama
// GET /clima/previsao nesta API, que consulta o serviço externo com a chave
// guardada no .env do servidor e devolve só o que o app precisa, já com a
// avaliação das condições para pulverização. Assim a chave não fica no app
// nem no repositório.
//
// Endpoint usado: "5 day / 3 hour forecast" (plano gratuito)
//   GET https://api.openweathermap.org/data/2.5/forecast
//       ?lat=..&lon=..&units=metric&lang=pt_br&appid=<chave>

export const URL_PADRAO_OPENWEATHER = 'https://api.openweathermap.org/data/2.5';

// Menor que os 8 s que o app espera pela API, para que o app receba a
// mensagem de "serviço demorou" em vez de um tempo esgotado genérico.
const TEMPO_LIMITE_PADRAO_MS = 6000;

// O OpenWeatherMap atualiza a previsão a cada 3 horas; 30 minutos de cache
// evitam gastar a cota gratuita com consultas repetidas.
const VALIDADE_CACHE_PADRAO_MS = 30 * 60 * 1000;

const DIAS_PREVISTOS = 5;

// Condições consideradas adequadas para pulverizar em cada intervalo de 3
// horas (recomendações usuais de tecnologia de aplicação).
export const LIMITES_PULVERIZACAO = {
  ventoMaxKmh: 10, // acima disso, risco de deriva do produto
  temperaturaMaxC: 30, // acima disso, o produto evapora antes de agir
  umidadeMinPct: 50, // abaixo disso, evaporação e deriva
  probChuvaMaxPct: 50, // chuva logo após a aplicação lava o produto
  chuvaMaxMm: 0.5, // chuva prevista no intervalo
  horaInicio: 6, // só o período diurno é avaliado (06h às 18h)
  horaFim: 18,
} as const;

export interface ConfigClima {
  apiKey?: string;
  latitude?: number;
  longitude?: number;
  baseUrl?: string;
  tempoLimiteMs?: number;
  validadeCacheMs?: number;
}

// --- Formato devolvido ao aplicativo ----------------------------------------

export interface Pulverizacao {
  adequada: boolean;
  motivo: string;
  // Início (hora local, "HH:MM") de cada intervalo de 3 h favorável.
  horarios: string[];
}

export interface PrevisaoDia {
  data: string; // aaaa-mm-dd, no fuso da fazenda
  descricao: string;
  icone: string; // código do ícone do OpenWeatherMap (ex.: "10d")
  tempMin: number; // °C
  tempMax: number; // °C
  umidade: number; // %, média do dia
  ventoKmh: number; // maior velocidade média prevista no dia
  probChuva: number; // %, maior probabilidade prevista no dia
  chuvaMm: number; // total previsto no dia
  pulverizacao: Pulverizacao;
}

export interface Previsao {
  fonte: 'OpenWeatherMap';
  local: string;
  latitude: number;
  longitude: number;
  atualizadoEm: string; // ISO 8601
  dias: PrevisaoDia[];
}

// --- Formato recebido do OpenWeatherMap (apenas os campos usados) -----------

interface PeriodoOpenWeather {
  dt: number; // instante do início do intervalo, em segundos (UTC)
  main: { temp: number; temp_min: number; temp_max: number; humidity: number };
  weather: { description: string; icon: string }[];
  wind: { speed: number }; // m/s com units=metric
  pop?: number; // probabilidade de chuva, de 0 a 1
  rain?: { '3h'?: number }; // mm no intervalo
}

interface RespostaOpenWeather {
  list: unknown[];
  city?: { name?: string; timezone?: number }; // timezone: deslocamento em s
}

// ----------------------------------------------------------------------------

export function configClimaDoAmbiente(env: NodeJS.ProcessEnv = process.env): ConfigClima {
  return {
    apiKey: env.OPENWEATHER_API_KEY?.trim() || undefined,
    latitude: numero(env.FAZENDA_LAT),
    longitude: numero(env.FAZENDA_LON),
    baseUrl: env.OPENWEATHER_URL?.trim() || undefined,
  };
}

export class ServicoClima {
  private cache?: { previsao: Previsao; expiraEm: number };
  private emAndamento?: Promise<Previsao>;

  constructor(
    private readonly config: ConfigClima = {},
    private readonly buscar: typeof fetch = (url, init) => fetch(url, init),
    private readonly agora: () => number = () => Date.now(),
  ) {}

  // Chave e coordenadas válidas definidas no .env.
  get configurado(): boolean {
    const { apiKey, latitude, longitude } = this.config;
    return (
      !!apiKey &&
      latitude !== undefined && Number.isFinite(latitude) && Math.abs(latitude) <= 90 &&
      longitude !== undefined && Number.isFinite(longitude) && Math.abs(longitude) <= 180
    );
  }

  async previsao(): Promise<Previsao> {
    if (!this.configurado) {
      throw new HttpError(503, 'A previsão do tempo ainda não foi configurada no servidor.');
    }
    if (this.cache && this.agora() < this.cache.expiraEm) return this.cache.previsao;

    // Pedidos simultâneos (ex.: duas telas abertas) aproveitam a mesma
    // consulta ao serviço externo.
    this.emAndamento ??= this.consultar().finally(() => {
      this.emAndamento = undefined;
    });
    return this.emAndamento;
  }

  private async consultar(): Promise<Previsao> {
    const { apiKey, latitude, longitude } = this.config as Required<ConfigClima>;
    const base = (this.config.baseUrl ?? URL_PADRAO_OPENWEATHER).replace(/\/+$/, '');
    const url = new URL(`${base}/forecast`);
    url.search = new URLSearchParams({
      lat: String(latitude),
      lon: String(longitude),
      units: 'metric', // °C e m/s
      lang: 'pt_br', // descrições em português
      appid: apiKey,
    }).toString();

    let dados: unknown;
    try {
      const resposta = await this.buscar(url, {
        headers: { Accept: 'application/json' },
        signal: AbortSignal.timeout(this.config.tempoLimiteMs ?? TEMPO_LIMITE_PADRAO_MS),
      });
      if (!resposta.ok) throw erroDoServico(resposta.status);
      dados = await resposta.json();
    } catch (erro) {
      throw traduzirFalha(erro);
    }

    const previsao = resumirPrevisao(dados, latitude, longitude, new Date(this.agora()));
    this.cache = {
      previsao,
      expiraEm: this.agora() + (this.config.validadeCacheMs ?? VALIDADE_CACHE_PADRAO_MS),
    };
    return previsao;
  }
}

// Resposta de erro do OpenWeatherMap. O detalhe fica só no log do servidor
// (sem a URL, que contém a chave); o app recebe uma mensagem compreensível.
function erroDoServico(status: number): HttpError {
  if (status === 401) {
    console.error(
      'OpenWeatherMap recusou a chave (401). Confira OPENWEATHER_API_KEY no .env; ' +
        'chaves recém-criadas podem levar até 2 horas para serem ativadas.',
    );
  } else {
    console.error(`OpenWeatherMap respondeu com status ${status}.`);
  }
  if (status === 429) {
    return new HttpError(
      503,
      'O limite de consultas à previsão do tempo foi atingido. Tente novamente mais tarde.',
    );
  }
  return new HttpError(502, 'O serviço de previsão do tempo está indisponível no momento.');
}

function traduzirFalha(erro: unknown): HttpError {
  if (erro instanceof HttpError) return erro;
  const nome = (erro as { name?: string } | null)?.name;
  if (nome === 'TimeoutError' || nome === 'AbortError') {
    console.error('OpenWeatherMap não respondeu dentro do tempo limite.');
    return new HttpError(504, 'O serviço de previsão do tempo demorou para responder. Tente novamente.');
  }
  if (erro instanceof SyntaxError) {
    console.error('OpenWeatherMap enviou uma resposta que não é JSON.');
    return new HttpError(502, 'O serviço de previsão do tempo enviou dados inválidos.');
  }
  console.error('Falha de rede ao consultar o OpenWeatherMap:', (erro as Error)?.message);
  return new HttpError(502, 'Não foi possível consultar o serviço de previsão do tempo.');
}

// Converte a resposta do OpenWeatherMap (40 intervalos de 3 horas) em um
// resumo por dia, no fuso horário da fazenda.
export function resumirPrevisao(
  dados: unknown,
  latitude: number,
  longitude: number,
  agora: Date,
): Previsao {
  const resposta = dados as RespostaOpenWeather | null;
  if (typeof resposta !== 'object' || resposta === null || !Array.isArray(resposta.list)) {
    console.error('OpenWeatherMap enviou uma resposta sem a lista de previsões.');
    throw new HttpError(502, 'O serviço de previsão do tempo enviou dados inválidos.');
  }

  const fuso = typeof resposta.city?.timezone === 'number' ? resposta.city.timezone : 0;
  const porDia = new Map<string, PeriodoLocal[]>();
  for (const item of resposta.list) {
    if (!periodoValido(item)) continue;
    const local = new Date((item.dt + fuso) * 1000);
    const data = local.toISOString().slice(0, 10);
    const periodo = { ...item, hora: local.getUTCHours(), minuto: local.getUTCMinutes() };
    porDia.set(data, [...(porDia.get(data) ?? []), periodo]);
  }

  const dias = [...porDia.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .slice(0, DIAS_PREVISTOS)
    .map(([data, periodos]) => resumirDia(data, periodos));

  return {
    fonte: 'OpenWeatherMap',
    local: resposta.city?.name?.trim() || 'Fazenda',
    latitude,
    longitude,
    atualizadoEm: agora.toISOString(),
    dias,
  };
}

type PeriodoLocal = PeriodoOpenWeather & { hora: number; minuto: number };
type Restricao = 'chuva' | 'vento' | 'calor' | 'arSeco';

const MOTIVOS: Record<Restricao, string> = {
  chuva: 'Chuva prevista durante o dia: o produto pode ser lavado.',
  vento: `Vento acima de ${LIMITES_PULVERIZACAO.ventoMaxKmh} km/h: risco de deriva do produto.`,
  calor: `Temperatura acima de ${LIMITES_PULVERIZACAO.temperaturaMaxC} °C: o produto evapora antes de agir.`,
  arSeco: `Umidade do ar abaixo de ${LIMITES_PULVERIZACAO.umidadeMinPct}%: risco de evaporação e deriva.`,
};
// Em caso de empate, a restrição mais grave é a informada.
const PRIORIDADE: Restricao[] = ['chuva', 'vento', 'calor', 'arSeco'];

function resumirDia(data: string, periodos: PeriodoLocal[]): PrevisaoDia {
  // Descrição e ícone do intervalo mais próximo do meio-dia.
  const referencia = periodos.reduce((melhor, p) =>
    Math.abs(p.hora - 12) < Math.abs(melhor.hora - 12) ? p : melhor,
  );
  const descricao = referencia.weather[0]?.description ?? '';

  return {
    data,
    descricao: descricao.charAt(0).toUpperCase() + descricao.slice(1),
    icone: referencia.weather[0]?.icon ?? '',
    tempMin: arredondar(Math.min(...periodos.map((p) => p.main.temp_min))),
    tempMax: arredondar(Math.max(...periodos.map((p) => p.main.temp_max))),
    umidade: Math.round(media(periodos.map((p) => p.main.humidity))),
    ventoKmh: arredondar(Math.max(...periodos.map(ventoKmh))),
    probChuva: Math.round(Math.max(...periodos.map((p) => (p.pop ?? 0) * 100))),
    chuvaMm: arredondar(periodos.reduce((soma, p) => soma + chuvaMm(p), 0)),
    pulverizacao: avaliarPulverizacao(periodos),
  };
}

function avaliarPulverizacao(periodos: PeriodoLocal[]): Pulverizacao {
  const { horaInicio, horaFim } = LIMITES_PULVERIZACAO;
  const diurnos = periodos.filter((p) => p.hora >= horaInicio && p.hora < horaFim);
  if (diurnos.length === 0) {
    return {
      adequada: false,
      motivo: 'Não há previsão para o período diurno deste dia.',
      horarios: [],
    };
  }

  const avaliados = diurnos.map((p) => ({ periodo: p, restricoes: restricoes(p) }));
  const favoraveis = avaliados.filter((a) => a.restricoes.length === 0).map((a) => a.periodo);

  if (favoraveis.length > 0) {
    const janelas = agruparJanelas(favoraveis);
    return {
      adequada: true,
      motivo: `${janelas.length > 1 ? 'Janelas favoráveis' : 'Janela favorável'}: ${juntar(janelas)}.`,
      horarios: favoraveis.map((p) => horario(p.hora, p.minuto)),
    };
  }

  // Nenhum horário bom: informa a restrição que aparece em mais intervalos.
  const contagem = new Map<Restricao, number>();
  for (const { restricoes: lista } of avaliados) {
    for (const r of lista) contagem.set(r, (contagem.get(r) ?? 0) + 1);
  }
  const principal = PRIORIDADE.reduce((melhor, r) =>
    (contagem.get(r) ?? 0) > (contagem.get(melhor) ?? 0) ? r : melhor,
  );
  return { adequada: false, motivo: MOTIVOS[principal], horarios: [] };
}

function restricoes(p: PeriodoOpenWeather): Restricao[] {
  const limites = LIMITES_PULVERIZACAO;
  const lista: Restricao[] = [];
  if (chuvaMm(p) >= limites.chuvaMaxMm || (p.pop ?? 0) * 100 >= limites.probChuvaMaxPct) {
    lista.push('chuva');
  }
  if (ventoKmh(p) > limites.ventoMaxKmh) lista.push('vento');
  if (p.main.temp > limites.temperaturaMaxC) lista.push('calor');
  if (p.main.humidity < limites.umidadeMinPct) lista.push('arSeco');
  return lista;
}

// Intervalos favoráveis consecutivos viram uma janela só: 06h, 09h → "06h–12h".
function agruparJanelas(periodos: PeriodoLocal[]): string[] {
  const TRES_HORAS = 3 * 60 * 60;
  const janelas: { inicio: PeriodoLocal; fim: PeriodoLocal }[] = [];
  for (const p of periodos) {
    const ultima = janelas.at(-1);
    if (ultima && p.dt - ultima.fim.dt === TRES_HORAS) ultima.fim = p;
    else janelas.push({ inicio: p, fim: p });
  }
  return janelas.map(({ inicio, fim }) => {
    const fimHora = (fim.hora + 3) % 24;
    return `${hora(inicio.hora, inicio.minuto)}–${hora(fimHora, fim.minuto)}`;
  });
}

function periodoValido(item: unknown): item is PeriodoOpenWeather {
  const p = item as PeriodoOpenWeather | null;
  return (
    typeof p === 'object' && p !== null &&
    typeof p.dt === 'number' &&
    typeof p.main?.temp === 'number' &&
    typeof p.main.temp_min === 'number' &&
    typeof p.main.temp_max === 'number' &&
    typeof p.main.humidity === 'number' &&
    typeof p.wind?.speed === 'number' &&
    Array.isArray(p.weather)
  );
}

const ventoKmh = (p: PeriodoOpenWeather) => p.wind.speed * 3.6;
const chuvaMm = (p: PeriodoOpenWeather) => p.rain?.['3h'] ?? 0;
const media = (valores: number[]) => valores.reduce((a, b) => a + b, 0) / valores.length;
const arredondar = (valor: number) => Math.round(valor * 10) / 10;
const doisDigitos = (n: number) => String(n).padStart(2, '0');
const horario = (h: number, m: number) => `${doisDigitos(h)}:${doisDigitos(m)}`;
const hora = (h: number, m: number) => (m === 0 ? `${doisDigitos(h)}h` : horario(h, m));
const juntar = (itens: string[]) =>
  itens.length <= 1 ? itens.join('') : `${itens.slice(0, -1).join(', ')} e ${itens.at(-1)}`;

function numero(texto: string | undefined): number | undefined {
  if (texto === undefined || texto.trim() === '') return undefined;
  return Number(texto);
}

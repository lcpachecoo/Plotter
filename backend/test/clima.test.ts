import request from 'supertest';
import { afterEach, describe, expect, it, vi } from 'vitest';

import { criarApp } from '../src/app.js';
import { ServicoClima, type ConfigClima } from '../src/clima.js';
import type { Banco } from '../src/db.js';

// Testes da integração com o OpenWeatherMap (Etapa 6). O serviço externo é
// substituído por um `fetch` falso, então os testes não usam a internet nem
// uma chave verdadeira.

const CHAVE = 'chave-de-teste-123';
const FUSO = -3 * 60 * 60; // UTC-3, enviado pelo OpenWeatherMap em city.timezone
const config: ConfigClima = { apiKey: CHAVE, latitude: -17.79, longitude: -50.92 };

// As rotas de clima não usam o banco.
const bancoNaoUsado = {
  query: () => Promise.reject(new Error('banco não deveria ser usado')),
} as unknown as Banco;

// Intervalo de 3 h no formato do OpenWeatherMap, a partir da hora local.
function periodo(
  horaLocal: string,
  { temp = 24, umidade = 70, ventoMs = 2, pop = 0, chuva = 0, icone = '01d', descricao = 'céu limpo' } = {},
) {
  return {
    dt: Date.parse(`${horaLocal}:00Z`) / 1000 - FUSO,
    main: { temp, temp_min: temp - 1, temp_max: temp + 1, humidity: umidade },
    weather: [{ id: 800, main: 'Clear', description: descricao, icon: icone }],
    wind: { speed: ventoMs, deg: 90 },
    pop,
    ...(chuva > 0 ? { rain: { '3h': chuva } } : {}),
  };
}

const respostaOpenWeather = {
  cod: '200',
  cnt: 11,
  list: [
    // 13/11: bom de manhã, quente ao meio-dia e chuva à tarde.
    periodo('2026-11-13T03:00', { pop: 0.8, chuva: 1.2 }),
    periodo('2026-11-13T06:00', { temp: 21 }),
    periodo('2026-11-13T09:00', { temp: 26 }),
    periodo('2026-11-13T12:00', { temp: 32, umidade: 45 }),
    periodo('2026-11-13T15:00', { pop: 0.9, chuva: 2.5, icone: '10d', descricao: 'chuva leve' }),
    // 14/11: vento forte o dia todo (4 m/s = 14,4 km/h).
    periodo('2026-11-14T06:00', { ventoMs: 4 }),
    periodo('2026-11-14T09:00', { ventoMs: 4 }),
    periodo('2026-11-14T12:00', { ventoMs: 4.5 }),
    periodo('2026-11-14T15:00', { ventoMs: 4 }),
    // 15/11: só há previsão para a madrugada.
    periodo('2026-11-15T00:00'),
    { dt: 'inválido' }, // intervalos malformados são ignorados
  ],
  city: { id: 3451138, name: 'Rio Verde', country: 'BR', timezone: FUSO },
};

function respostaJson(corpo: unknown, status = 200) {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function criar(
  buscar: (url: URL) => Promise<Response>,
  opcoes: { config?: ConfigClima; agora?: () => number } = {},
) {
  const fetchFalso = vi.fn(buscar as unknown as typeof fetch);
  const clima = new ServicoClima(opcoes.config ?? config, fetchFalso, opcoes.agora);
  return { app: criarApp(bancoNaoUsado, { clima }), fetchFalso };
}

afterEach(() => {
  vi.restoreAllMocks();
});

describe('GET /clima/previsao', () => {
  it('consulta o OpenWeatherMap e devolve a previsão resumida por dia', async () => {
    const { app, fetchFalso } = criar(async () => respostaJson(respostaOpenWeather), {
      agora: () => Date.parse('2026-11-13T05:00:00Z'),
    });

    const res = await request(app).get('/clima/previsao').expect(200);

    // Requisição enviada ao serviço externo.
    const url = fetchFalso.mock.calls[0][0] as URL;
    expect(url.origin + url.pathname).toBe('https://api.openweathermap.org/data/2.5/forecast');
    expect(Object.fromEntries(url.searchParams)).toEqual({
      lat: '-17.79',
      lon: '-50.92',
      units: 'metric',
      lang: 'pt_br',
      appid: CHAVE,
    });

    // Resposta enviada ao aplicativo.
    expect(res.body).toMatchObject({
      fonte: 'OpenWeatherMap',
      local: 'Rio Verde',
      latitude: -17.79,
      longitude: -50.92,
      atualizadoEm: '2026-11-13T05:00:00.000Z',
    });
    expect(res.body.dias.map((d: { data: string }) => d.data)).toEqual([
      '2026-11-13',
      '2026-11-14',
      '2026-11-15',
    ]);

    const [dia13, dia14, dia15] = res.body.dias;
    expect(dia13).toEqual({
      data: '2026-11-13',
      descricao: 'Céu limpo',
      icone: '01d',
      tempMin: 20,
      tempMax: 33,
      umidade: 65,
      ventoKmh: 7.2,
      probChuva: 90,
      chuvaMm: 3.7,
      pulverizacao: {
        adequada: true,
        motivo: 'Janela favorável: 06h–12h.',
        horarios: ['06:00', '09:00'],
      },
    });
    expect(dia14.ventoKmh).toBe(16.2);
    expect(dia14.pulverizacao).toEqual({
      adequada: false,
      motivo: 'Vento acima de 10 km/h: risco de deriva do produto.',
      horarios: [],
    });
    expect(dia15.pulverizacao.adequada).toBe(false);
    expect(dia15.pulverizacao.motivo).toContain('período diurno');
  });

  it('informa chuva como motivo quando chove o dia todo', async () => {
    const chuvoso = {
      list: ['06', '09', '12', '15'].map((h) =>
        periodo(`2026-11-20T${h}:00`, { pop: 1, chuva: 4, icone: '10d', descricao: 'chuva moderada' }),
      ),
      city: { name: 'Rio Verde', timezone: FUSO },
    };
    const { app } = criar(async () => respostaJson(chuvoso));

    const res = await request(app).get('/clima/previsao').expect(200);
    expect(res.body.dias[0]).toMatchObject({
      descricao: 'Chuva moderada',
      chuvaMm: 16,
      probChuva: 100,
      pulverizacao: { adequada: false, motivo: 'Chuva prevista durante o dia: o produto pode ser lavado.' },
    });
  });

  it('guarda a previsão por 30 minutos antes de consultar de novo', async () => {
    let agora = Date.parse('2026-11-13T05:00:00Z');
    const { app, fetchFalso } = criar(async () => respostaJson(respostaOpenWeather), {
      agora: () => agora,
    });

    await request(app).get('/clima/previsao').expect(200);
    agora += 29 * 60 * 1000;
    await request(app).get('/clima/previsao').expect(200);
    expect(fetchFalso).toHaveBeenCalledTimes(1);

    agora += 2 * 60 * 1000;
    await request(app).get('/clima/previsao').expect(200);
    expect(fetchFalso).toHaveBeenCalledTimes(2);
  });

  it('devolve lista vazia quando o serviço não tem previsão (ausência de dados)', async () => {
    const { app } = criar(async () => respostaJson({ cod: '200', cnt: 0, list: [], city: {} }));

    const res = await request(app).get('/clima/previsao').expect(200);
    expect(res.body.dias).toEqual([]);
    expect(res.body.local).toBe('Fazenda');
  });
});

describe('falhas do serviço externo', () => {
  it('sem chave configurada responde 503 e não chama o serviço', async () => {
    const { app, fetchFalso } = criar(async () => respostaJson(respostaOpenWeather), {
      config: { latitude: -17.79, longitude: -50.92 },
    });

    const res = await request(app).get('/clima/previsao').expect(503);
    expect(res.body.erro).toBe('A previsão do tempo ainda não foi configurada no servidor.');
    expect(fetchFalso).not.toHaveBeenCalled();
  });

  it('coordenadas inválidas também contam como não configurado', async () => {
    const { app } = criar(async () => respostaJson(respostaOpenWeather), {
      config: { apiKey: CHAVE, latitude: Number.NaN, longitude: -50.92 },
    });
    await request(app).get('/clima/previsao').expect(503);
  });

  it('chave recusada (401) vira 502 sem expor a chave', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    const { app } = criar(async () => respostaJson({ cod: 401, message: 'Invalid API key.' }, 401));

    const res = await request(app).get('/clima/previsao').expect(502);
    expect(res.body.erro).toBe('O serviço de previsão do tempo está indisponível no momento.');
    expect(JSON.stringify(res.body)).not.toContain(CHAVE);
  });

  it('limite de consultas (429) vira 503', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    const { app } = criar(async () => respostaJson({ cod: 429 }, 429));

    const res = await request(app).get('/clima/previsao').expect(503);
    expect(res.body.erro).toContain('limite de consultas');
  });

  it('tempo esgotado vira 504', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    const { app } = criar(async () => {
      throw new DOMException('The operation was aborted due to timeout', 'TimeoutError');
    });

    const res = await request(app).get('/clima/previsao').expect(504);
    expect(res.body.erro).toContain('demorou para responder');
  });

  it('falha de rede vira 502', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    const { app } = criar(async () => {
      throw new TypeError('fetch failed');
    });

    const res = await request(app).get('/clima/previsao').expect(502);
    expect(res.body.erro).toBe('Não foi possível consultar o serviço de previsão do tempo.');
  });

  it('resposta que não é JSON ou sem a lista vira 502', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    const { app: textoPuro } = criar(async () => new Response('<html>erro</html>', { status: 200 }));
    await request(textoPuro).get('/clima/previsao').expect(502);

    const { app: semLista } = criar(async () => respostaJson({ cod: '200' }));
    const res = await request(semLista).get('/clima/previsao').expect(502);
    expect(res.body.erro).toBe('O serviço de previsão do tempo enviou dados inválidos.');
  });

  it('não guarda falhas em cache: a próxima consulta tenta de novo', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    let falhar = true;
    const { app, fetchFalso } = criar(async () =>
      falhar ? respostaJson({}, 500) : respostaJson(respostaOpenWeather),
    );

    await request(app).get('/clima/previsao').expect(502);
    falhar = false;
    await request(app).get('/clima/previsao').expect(200);
    expect(fetchFalso).toHaveBeenCalledTimes(2);
  });
});

import pg from 'pg';

// Conexão com o PostgreSQL e criação das tabelas.
//
// A mesma API funciona com o Postgres local (docker-compose.yml) e com o
// Postgres hospedado no Supabase: muda apenas a DATABASE_URL.

// Por padrão o driver converte colunas DATE em objetos Date no fuso do
// servidor, o que pode deslocar o dia. A data trafega como texto aaaa-mm-dd.
const TIPO_DATE = 1082;
pg.types.setTypeParser(TIPO_DATE, (valor) => valor);

// Pool mínimo usado pelos repositórios. Tanto o `pg.Pool` real quanto o
// banco em memória dos testes (pg-mem) atendem a esta interface.
export type Banco = Pick<pg.Pool, 'query'>;

export function criarPool(databaseUrl: string): pg.Pool {
  // O Supabase exige conexão criptografada; o Postgres local, não.
  const ssl = databaseUrl.includes('supabase.co') || databaseUrl.includes('supabase.com')
    ? { rejectUnauthorized: false }
    : undefined;
  return new pg.Pool({ connectionString: databaseUrl, ssl });
}

// Mesmas tabelas do SQLite do aplicativo (Etapa 4), agora no servidor.
// As restrições CHECK repetem no banco as regras de validação da API.
export const ESQUEMA = `
  CREATE TABLE IF NOT EXISTS talhoes (
    id      SERIAL PRIMARY KEY,
    nome    TEXT             NOT NULL,
    cultura TEXT             NOT NULL,
    area_ha DOUBLE PRECISION NOT NULL CHECK (area_ha > 0),
    estagio TEXT             NOT NULL DEFAULT '',
    pivo    TEXT             NOT NULL DEFAULT '',
    status  TEXT             NOT NULL
            CHECK (status IN ('feito', 'pendente', 'agendado'))
  );

  CREATE TABLE IF NOT EXISTS registros (
    id          SERIAL PRIMARY KEY,
    talhao_id   INTEGER NOT NULL REFERENCES talhoes (id) ON DELETE CASCADE,
    insumo      TEXT    NOT NULL,
    tipo        TEXT    NOT NULL
                CHECK (tipo IN ('defensivo', 'fertilizante', 'outro')),
    data        DATE    NOT NULL,
    quantidade  TEXT    NOT NULL,
    responsavel TEXT    NOT NULL DEFAULT '',
    observacoes TEXT    NOT NULL DEFAULT ''
  );

  CREATE INDEX IF NOT EXISTS idx_registros_talhao ON registros (talhao_id);
`;

// Cria as tabelas que ainda não existem. Pode ser executado a cada
// inicialização do servidor sem apagar dados.
export async function criarEsquema(banco: Banco): Promise<void> {
  await banco.query(ESQUEMA);
}

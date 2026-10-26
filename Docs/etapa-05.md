# Etapa 05 — Primeira Versão Funcional com Backend

**Disciplina:** Tecnologia e Construção de Software 2
**Autor:** Lucas Carvalho Pacheco
**Projeto:** Plotter — gestão de lavoura por talhões

## 1. Objetivo da Etapa

Integrar o que foi construído nas Etapas 2 a 4 (interface, navegação, feedback, acessibilidade e persistência local) com um **backend próprio**, separando as responsabilidades:

| Camada | Responsabilidade |
|---|---|
| **App Flutter** (`lib/`) | Interface, navegação, validação dos formulários para orientar o usuário, feedback das operações e cópia local dos dados (SQLite) para consulta sem internet. |
| **API Node.js** (`backend/`) | Fonte oficial dos dados: regras de validação definitivas, gravação no PostgreSQL e integridade entre talhões e registros. |

A tecnologia é a definida na proposta (`Docs/proposta.md`, seção 9) e no README: **Node.js + Express + TypeScript** com **PostgreSQL**. O banco pode ser o PostgreSQL local (Docker) ou o do **Supabase**; a API é a mesma e muda apenas a `DATABASE_URL`.

## 2. Fluxo Completo de Negócio Implementado

O fluxo principal é o **ciclo de vida de um talhão e das suas aplicações de insumo**: **criar → visualizar → alterar → excluir**, com todas as gravações passando pelo servidor.

```text
App (tela)                       PlotterCrud              PlotterApi            API (Express)         PostgreSQL
────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Novo talhão  ── salvar ──►  inserirTalhao ──►  POST /talhoes ──►  valida ──► INSERT ... RETURNING
                                │                                  201 + talhão com id ◄──┘
                                └─ grava cópia no SQLite com o id do servidor ─► recarrega listas ─► telas atualizam
Detalhe      ── novo registro ─► inserirRegistro ─► POST /registros (confere se o talhão existe)
Detalhe      ── editar ──────► atualizarTalhao ─► PUT /talhoes/:id
Detalhe      ── excluir ─────► removerTalhao ───► DELETE /talhoes/:id (ON DELETE CASCADE apaga os registros)
Dashboard    ── puxar p/ baixo ► sincronizar ───► GET /talhoes + GET /registros ─► substitui a cópia local
```

Regra central: **nenhuma alteração é dada como concluída antes de o servidor confirmar.** Se a API recusar os dados ou não responder, a cópia local não muda, o formulário continua aberto com o que foi digitado e o usuário recebe uma mensagem dizendo o que aconteceu.

## 3. Passo a Passo para Executar o Fluxo

Com a API e o app rodando (seção 8):

1. **Entrar:** na tela de login (e-mail e senha de demonstração já vêm preenchidos), toque em "Entrar". O Dashboard mostra os 4 talhões que vieram do servidor (carga do `npm run seed`).
2. **Criar o talhão:** toque em **"Novo talhão"**, preencha *Nome* (ex.: "Talhão 05 - Pivô Leste"), *Cultura* (ex.: "Trigo") e *Área* (ex.: 12.5) e toque em **Salvar**. O app volta ao Dashboard com a mensagem *"Talhão cadastrado com sucesso."* e o talhão aparece na lista.
3. **Visualizar:** toque no cartão do novo talhão. O detalhe mostra cultura, área, estágio e "Nenhuma aplicação registrada".
4. **Registrar uma aplicação:** no detalhe, toque em **"Novo registro"**, informe o produto (ex.: "Fungicida"), a dose (ex.: "0.5 L/ha") e escolha uma **data futura**. Ao salvar, o registro aparece em "Próxima aplicação" e na aba "Agendadas" do Histórico.
5. **Alterar:** no detalhe, toque em **"Editar talhão"**, mude a situação para "Em dia" e salve (*"Talhão atualizado com sucesso."*). No Histórico, toque no registro, altere a dose e salve.
6. **Conferir no servidor:** em outro aparelho/emulador, ou em `http://localhost:3000/talhoes` no navegador do computador, o talhão aparece com os dados alterados.
7. **Excluir:** no detalhe, toque em **"Excluir talhão"**. O diálogo informa quantos registros serão apagados junto. Confirme: o app volta ao Dashboard com *"Talhão "…" excluído."*, e os registros dele somem do Histórico.
8. **Sem conexão:** pare a API (`Ctrl+C` no terminal dela) e tente salvar um talhão. Aparece *"Sem conexão com o servidor. Verifique a internet e tente novamente."*, o formulário continua preenchido, e o Dashboard passa a exibir a faixa *"Sem conexão com o servidor. Exibindo os dados salvos no aparelho…"* com o botão **"Tentar de novo"**. Suba a API novamente e toque nele: a faixa some.

## 4. Funcionalidades Integradas Nesta Etapa

| Funcionalidade (etapa de origem) | Como ficou integrada ao backend |
|---|---|
| CRUD de talhões (Etapa 4) | Cada criação, edição e exclusão é feita na API; o SQLite recebe a cópia depois da confirmação, com o **mesmo id** gerado pelo PostgreSQL. |
| CRUD de registros de aplicação (Etapa 4) | Idem, em `/registros`. A API rejeita registros de talhões inexistentes. |
| Exclusão em cascata (Etapa 4) | Feita pelo `ON DELETE CASCADE` do PostgreSQL; a API devolve quantos registros foram removidos. |
| Persistência local (Etapa 4) | O SQLite virou a **cópia local** dos dados do servidor: o app abre mostrando os últimos dados recebidos, mesmo sem internet. |
| Puxar para atualizar no Dashboard (Etapa 3) | Antes relia o banco local; agora busca os dados no servidor (`sincronizar`). |
| Tela de Ajustes/Sincronização (Etapa 2) | O status "Conectado" e o horário eram fixos e a sincronização era simulada com um atraso. Agora o cartão mostra a situação real (conectado, conectando, sem conexão) e "Sincronizar agora" baixa os dados da API. |
| Carga inicial (Etapa 4) | Saiu do aplicativo e foi para o servidor (`npm run seed`), com os mesmos talhões e registros. |
| Feedback padronizado `AppFeedback` (Etapa 3) | Reutilizado para todas as respostas da API: sucesso, erro de validação, item inexistente, servidor fora do ar. |

## 5. Tratamento de Entradas Inválidas

A validação acontece em **três níveis**, do mais próximo do usuário ao mais próximo dos dados:

1. **Formulários do app** (já existentes desde a Etapa 3): campos obrigatórios destacados, área numérica maior que zero, data escolhida pelo seletor. Impedem o envio e orientam o usuário antes de qualquer requisição.
2. **API** (`backend/src/validacao.ts`): o servidor não confia no cliente e confere tudo de novo, devolvendo **400** com o motivo de cada campo:

   | Entrada | Regra |
   |---|---|
   | `nome`, `cultura`, `insumo`, `quantidade` | Texto obrigatório, sem considerar espaços nas pontas; máximo de 120 caracteres. |
   | `estagio`, `pivo`, `responsavel` | Texto opcional; máximo de 120 caracteres. `observacoes`: até 1000. |
   | `areaHa` | Número maior que zero (o texto `"42"` é recusado). |
   | `status` | Somente `feito`, `pendente` ou `agendado`. |
   | `tipo` | Somente `defensivo`, `fertilizante` ou `outro`. |
   | `data` | Formato `aaaa-mm-dd` e data existente no calendário (`2026-02-30` é recusada). |
   | `talhaoId` | Inteiro positivo de um talhão que **existe**. |
   | `:id` na URL | Inteiro positivo (`/talhoes/abc` → 400). |
   | Corpo da requisição | Precisa ser um objeto JSON válido; JSON malformado → 400. Limite de 100 kB. |

   Exemplo de resposta:

   ```json
   {
     "erro": "Dados inválidos. Revise os campos informados.",
     "campos": {
       "insumo": "Informe o produto aplicado.",
       "data": "Data da aplicação inválida. Use o formato aaaa-mm-dd."
     }
   }
   ```

3. **Banco PostgreSQL** (`backend/src/db.ts`): `NOT NULL`, `CHECK (area_ha > 0)`, `CHECK` nos valores de `status` e `tipo`, e chave estrangeira. São a última barreira, caso alguma regra passe pelas camadas anteriores.

Outras situações tratadas:

| Situação | Resposta da API | O que o usuário vê |
|---|---|---|
| Item já excluído por outro aparelho | 404 | *"Este item não existe mais no servidor. Atualize a lista."* |
| Rota inexistente | 404 com `{erro}` | — |
| Falha inesperada (ex.: banco fora do ar) | 500 genérico; o detalhe fica só no log do servidor | *"O servidor encontrou um erro. Tente novamente em instantes."* |
| Servidor desligado / sem rede | — | *"Sem conexão com o servidor. Verifique a internet e tente novamente."* |
| Servidor sem resposta em 8 s | — | *"O servidor demorou para responder…"* |
| Resposta que não é JSON | — | *"O servidor enviou uma resposta inválida."* |

Na API, todos os valores entram no SQL como parâmetros (`$1`, `$2`…), nunca concatenados, o que impede injeção de SQL.

## 6. Mecanismos de Feedback Utilizados

| Mecanismo | Onde | Exemplo |
|---|---|---|
| **SnackBar de sucesso** (verde, ícone ✓) | Após salvar ou excluir | *"Talhão cadastrado com sucesso."*, *"Registro excluído."*, *"Dados sincronizados com o servidor."* |
| **SnackBar de erro** (vermelho) com a mensagem da API | Formulários, exclusões, sincronização | *"Informe a cultura plantada."* (vinda do servidor), *"Sem conexão com o servidor…"* |
| **Indicador de carregamento no botão** | "Salvar" dos formulários | O botão fica desabilitado e mostra progresso enquanto a API responde, evitando envio duplicado. |
| **Indicador de "puxar para atualizar"** | Dashboard | Fica girando durante a sincronização e termina com *"Lista de talhões atualizada."* |
| **Faixa "Sem conexão com o servidor"** | Dashboard | Aparece quando a API não responde, explica que os dados exibidos são os salvos no aparelho e oferece **"Tentar de novo"**. |
| **Cartão de status da conexão** | Ajustes | Conectado (verde, com horário da última sincronização) · Conectando… (azul) · Sem conexão (laranja). Cor, ícone e texto mudam juntos. |
| **Diálogo de confirmação** | Exclusões, descartar formulário, sair | Informa o que será perdido (ex.: quantos registros serão apagados com o talhão). |
| **Anúncio para leitor de tela** | Todas as mensagens acima | `AppFeedback` anuncia o mesmo texto exibido (Etapa 3). |

## 7. Principais Decisões Técnicas

1. **Backend próprio em Node.js + Express + TypeScript**, conforme a proposta. Mantém a validação e as regras no servidor, com código próprio que pode ser explicado e alterado, em vez de deixar a lógica no app (como aconteceria com um BaaS acessado direto pelo cliente).
2. **Driver `pg` com SQL escrito à mão, sem ORM.** O esquema é pequeno (duas tabelas) e espelha o SQLite da Etapa 4. Todo o SQL fica em um único arquivo (`repositorio.ts`), sempre com parâmetros.
3. **PostgreSQL local via Docker ou Supabase sem mudar código.** `db.ts` ativa SSL automaticamente quando a URL é do Supabase. As tabelas são criadas na inicialização (`CREATE TABLE IF NOT EXISTS`), sem passo manual.
4. **Datas trafegam como texto `aaaa-mm-dd`.** O driver `pg` foi configurado para não converter `DATE` em `Date` do JavaScript, o que poderia deslocar o dia por causa do fuso horário.
5. **Servidor como fonte oficial, SQLite como cópia local.** O app grava primeiro na API e só depois na cópia local, usando o id devolvido pelo servidor, o que evita conflito de ids entre aparelhos. A sincronização substitui a cópia local inteira dentro de uma transação.
6. **Sem servidor, o app continua utilizável para consulta.** A abertura não espera a API: as telas aparecem com a cópia local e a sincronização inicial acontece em segundo plano. Gravações sem conexão são **recusadas com aviso**, e não enfileiradas (ver limitações).
7. **As telas não mudaram de contrato.** Continuam chamando o mesmo `PlotterCrud` da Etapa 4; a integração ficou concentrada em `PlotterCrud` e no novo `PlotterApi`. Sem `PlotterApi` o `PlotterCrud` funciona só com o SQLite, o que manteve válidos os testes da Etapa 4.
8. **Erros traduzidos em um só lugar.** `PlotterApi` converte cada falha (sem rede, tempo esgotado, 400, 404, 500) em uma `ApiException` com mensagem pronta; as telas apenas a exibem via `mensagemDeErro`.
9. **Endereço da API definido na compilação** (`--dart-define=API_URL=...`), com padrão `http://10.0.2.2:3000`, o endereço pelo qual o emulador Android acessa o computador.
10. **Testes sem infraestrutura externa.** A API é testada com `pg-mem` (PostgreSQL em memória) e `supertest`; o app, com um servidor falso (`MockClient`) que reproduz as rotas e respostas da API.

### Endpoints da API

| Método | Rota | Resposta |
|---|---|---|
| GET | `/health` | `200 {"status":"ok"}` |
| GET | `/talhoes` | `200` lista de talhões |
| GET | `/talhoes/:id` | `200` talhão · `404` |
| POST | `/talhoes` | `201` talhão criado (com `id`) · `400` |
| PUT | `/talhoes/:id` | `200` talhão atualizado · `400` · `404` |
| DELETE | `/talhoes/:id` | `200 {"registrosRemovidos": n}` · `404` |
| GET | `/registros[?talhaoId=n]` | `200` lista, da data mais recente para a mais antiga |
| GET | `/registros/:id` | `200` registro · `404` |
| POST | `/registros` | `201` registro criado · `400` |
| PUT | `/registros/:id` | `200` registro atualizado · `400` · `404` |
| DELETE | `/registros/:id` | `204` · `404` |

Formato JSON (camelCase): talhão `{id, nome, cultura, areaHa, estagio, pivo, status}`; registro `{id, talhaoId, insumo, tipo, data, quantidade, responsavel, observacoes}`.

### Bibliotecas adicionadas

| Pacote | Onde | Uso |
|---|---|---|
| `express` | backend | Rotas REST e tratamento de erros. |
| `pg` | backend | Conexão com o PostgreSQL. |
| `dotenv` | backend | Lê a configuração do arquivo `.env`. |
| `typescript`, `tsx` | backend (dev) | Compilação e execução em modo de desenvolvimento. |
| `vitest`, `supertest`, `pg-mem` | backend (dev) | Testes da API com banco em memória. |
| `http` | app | Requisições à API (e `MockClient` nos testes). |

## 8. Instruções para Execução e Teste

### 8.1 Backend

Pré-requisitos: Node.js 20 ou superior e Docker (ou um projeto no Supabase).

```bash
cd backend
npm install
cp .env.example .env        # para usar o Supabase, troque a DATABASE_URL
docker compose up -d        # sobe o PostgreSQL local (pule se usar o Supabase)
npm run seed                # carga de exemplo (só grava se o banco estiver vazio)
npm run dev                 # API em http://localhost:3000
```

Conferência rápida: abrir `http://localhost:3000/health` no navegador deve mostrar `{"status":"ok"}`.

### 8.2 App

```bash
flutter pub get
flutter run                                         # emulador Android: usa http://10.0.2.2:3000
flutter run --dart-define=API_URL=http://192.168.0.10:3000   # aparelho físico na mesma rede (IP do computador)
```

No simulador iOS, use `--dart-define=API_URL=http://localhost:3000`.

### 8.3 Testes automatizados

```bash
# Backend: 13 testes
cd backend
npm test          # vitest + supertest + pg-mem (não precisa de Docker)
npm run typecheck

# App: 25 testes
flutter analyze
flutter test
```

| Arquivo | O que cobre |
|---|---|
| `backend/test/api.test.ts` (13) | `/health`; fluxo completo de talhão e de registro (criar, listar, consultar, alterar, excluir); ordenação por data; exclusão em cascata; campos obrigatórios, tipos errados, data inexistente, enum inválido, talhão inexistente, JSON malformado, id inválido e 404. |
| `test/plotter_api_test.dart` (7) | Sincronização substituindo a cópia local; fluxo criar → alterar → excluir passando pelo servidor, com o id do servidor na cópia local; servidor fora do ar (cópia local intacta, status offline e reconexão); erro de validação por campo; 404; tempo esgotado; erro 500 sem detalhes técnicos. |
| `test/plotter_crud_test.dart` (6) e `test/widget_test.dart` (12) | Testes das Etapas 3 e 4 (navegação, acessibilidade, CRUD local), mantidos sem alteração e passando. |

### 8.4 Verificação feita de ponta a ponta

Com o PostgreSQL no Docker e a API rodando, o `PlotterCrud` do app foi exercitado contra o servidor real: a sincronização trouxe os 4 talhões e 8 registros da carga; a criação de talhão e registro, a edição do registro (dose de 2 para 3 t/ha) e a exclusão em cascata foram confirmadas no banco; um talhão sem cultura foi recusado com *"Informe a cultura plantada."*; e, apontando para uma porta sem servidor, o resultado foi *"Sem conexão com o servidor…"* com status offline.

## 9. Arquivos Criados ou Alterados na Etapa 5

| Arquivo | Situação | Papel |
|---|---|---|
| `backend/src/server.ts` | novo | Ponto de entrada: lê o `.env`, cria as tabelas e sobe a API. |
| `backend/src/app.ts` | novo | Monta o Express (JSON, rotas, erros). Recebe o banco por parâmetro para os testes. |
| `backend/src/db.ts` | novo | Conexão (local/Supabase), esquema das tabelas e tratamento de `DATE`. |
| `backend/src/repositorio.ts` | novo | Todo o SQL da aplicação. |
| `backend/src/validacao.ts` | novo | Regras de validação de talhões, registros e ids. |
| `backend/src/erros.ts` | novo | `HttpError` e o middleware que padroniza as respostas de erro. |
| `backend/src/routes/talhoes.ts`, `registros.ts` | novos | Rotas REST. |
| `backend/src/seed.ts` | novo | Carga de exemplo no servidor. |
| `backend/test/api.test.ts` | novo | Testes da API. |
| `backend/docker-compose.yml`, `.env.example` | novos | PostgreSQL local e modelo de configuração. |
| `lib/data/plotter_api.dart` | novo | Cliente HTTP da API e `ApiException`. |
| `test/plotter_api_test.dart` | novo | Testes da integração app ↔ API. |
| `lib/data/plotter_crud.dart` | alterado | Grava na API antes do SQLite; `sincronizar()`; `StatusServidor`. |
| `lib/models/talhao.dart`, `registro.dart` | alterados | `toJson`/`fromJson` no formato da API. |
| `lib/main.dart` | alterado | Cria o `PlotterApi`, desliga a carga local e sincroniza em segundo plano. |
| `lib/screens/dashboard_screen.dart` | alterado | Puxar para atualizar sincroniza com o servidor; faixa de "sem conexão". |
| `lib/screens/configuracoes_screen.dart` | alterado | Status real da conexão e sincronização real. |
| `lib/screens/cadastro_talhao_screen.dart`, `novo_registro_screen.dart`, `talhao_detail_screen.dart`, `lib/widgets/registro_tile.dart` | alterados | Exibem a mensagem de erro da API; textos não falam mais em "apagar do aparelho". |
| `lib/screens/ajuda_screen.dart` | alterado | Texto de ajuda sobre onde os dados ficam salvos. |
| `android/app/src/main/AndroidManifest.xml` | alterado | Permissão `INTERNET` e liberação de `http` para a API de desenvolvimento. |
| `pubspec.yaml` | alterado | Pacote `http`. |

## 10. Limitações Conhecidas

- **Gravação offline não é enfileirada.** Sem conexão, o app mostra os dados já baixados, mas criar, editar ou excluir exige servidor acessível. A fila de sincronização prevista na proposta fica para uma etapa futura.
- **Sem autenticação.** O login continua validando apenas o formulário, e a API não exige token; qualquer cliente que alcance o servidor pode ler e gravar. Por isso a API deve ser exposta somente em rede local nesta etapa.
- **HTTP sem TLS em desenvolvimento.** O `AndroidManifest` libera `http` para a API local; em produção a API deve ser servida por HTTPS e essa liberação removida.
- **Último a gravar vence.** Se dois aparelhos editarem o mesmo talhão, prevalece a última gravação; não há detecção de conflito.
- A API de previsão do tempo (OpenWeatherMap) prevista na proposta ainda não foi integrada.
- As limitações da Etapa 4 continuam: preferências de Ajustes e notificações lidas não são persistidas, e a situação do talhão é escolhida manualmente.

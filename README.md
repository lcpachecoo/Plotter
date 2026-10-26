# Plotter

Aplicativo mobile para gestão de lavoura por talhões, criado para centralizar e organizar as atividades diárias de fazendas agrícolas.

## Sobre o Projeto

Produtores rurais frequentemente controlam suas atividades de campo - aplicações de defensivos, fertilizantes - em anotações de papel, o que gera perda de dados e falta de rastreabilidade.

O **Plotter** resolve esse problema centralizando, em um único aplicativo, o controle de cada talhão ou pivô: o que já foi aplicado, o que está pendente e o que está agendado para os próximos dias.

## Problema que a Aplicação Resolve

Substitui o controle manual em papel/cadernos pelo registro digital das aplicações de insumos em cada talhão, evitando perda de dados e dando visibilidade imediata do que já foi feito, do que está pendente e do que está agendado.

## Público-Alvo

Produtores agrícolas, gerentes de fazenda e operadores de campo responsáveis pelo manejo diário de lavouras.

## Funcionalidades Implementadas (Etapas 2 a 5)

Na Etapa 2 foi construída a camada visual da aplicação; na Etapa 3 ela ganhou o fluxo de navegação completo, ergonomia das ações e acessibilidade; na Etapa 4 os dados passaram a ser gravados em um banco SQLite no próprio aparelho; na Etapa 5 o app passou a usar um backend próprio (API REST + PostgreSQL):

- Login de acesso, com validação por campo, estado de carregamento e mostrar/ocultar senha
- Dashboard com painel de status (em dia / pendente), filtro por situação e lista de talhões
- Detalhes do talhão (cultura, estágio, última e próxima aplicação) com ações conectadas
- Cadastro, edição e exclusão de talhão (formulário com aviso de alterações não salvas)
- Lançamento, edição e exclusão de registros de aplicação (formulário com data validada; data futura = aplicação agendada)
- Histórico de aplicações em duas abas: realizadas e agendadas
- Relatórios/indicadores consolidados da fazenda
- Notificações de aplicações pendentes e agendadas
- Ajuda e acessibilidade: mapa de navegação dentro do próprio aplicativo
- Configurações, preferências e status real da conexão com o servidor, com sincronização manual
- Navegação adaptável: barra inferior no celular, menu lateral em tablets e menu lateral estendido em telas largas

### Backend e integração (Etapa 5)

- API REST em **Node.js + Express + TypeScript** (pasta `backend/`), com PostgreSQL local (Docker) ou no Supabase
- Fluxo completo **criar → visualizar → alterar → excluir** de talhões e registros passando pelo servidor: o app só confirma a operação depois da resposta da API
- Validação no servidor (campos obrigatórios, tipos, datas existentes, valores permitidos, talhão existente), com mensagem por campo exibida no app
- O SQLite do aparelho virou a cópia local dos dados do servidor: sem internet, o app continua exibindo os últimos dados recebidos e avisa que está sem conexão
- "Puxar para atualizar" no Dashboard e "Sincronizar agora" em Ajustes baixam os dados do servidor
- Mensagens claras para servidor fora do ar, tempo esgotado, item já excluído e erro interno
- Fluxo, endpoints, tratamento de erros, decisões técnicas e roteiro de teste em [`Docs/etapa-05.md`](Docs/etapa-05.md)

### Persistência local (Etapa 4)

- Banco **SQLite** (`sqflite`) com as tabelas `talhoes` e `registros`, ligadas por chave estrangeira com exclusão em cascata
- Todas as operações (criar, recuperar, atualizar e remover) centralizadas em `lib/data/plotter_crud.dart`; as telas não executam SQL
- Os dados são carregados antes da primeira tela e continuam disponíveis após fechar e reabrir o aplicativo
- Na primeira execução o banco recebe uma carga de exemplo (`lib/data/mock_data.dart`), que não se repete
- A última e a próxima aplicação de cada talhão são calculadas a partir dos registros gravados
- Detalhes, estrutura das tabelas e roteiro de verificação em [`Docs/etapa-04.md`](Docs/etapa-04.md)

### Navegação, UX e acessibilidade (Etapa 3)

- Rotas nomeadas centralizadas em `lib/routes/app_routes.dart`, com tratamento de rota desconhecida
- Retorno consistente: seta na barra superior, botão voltar do aparelho, confirmação antes de descartar formulários e antes de fechar o app
- Feedback visual padronizado em `lib/utils/app_feedback.dart`: mensagens de sucesso/erro/aviso, carregamento, diálogos de confirmação e estados vazios
- Lei de Fitts: alvos de toque de no mínimo 48 dp, ação principal em botão flutuante e navegação na borda inferior
- Contraste mínimo de 4,5:1 em todos os textos, situação indicada por cor + ícone + texto e suporte ao tamanho de fonte do sistema
- Suporte a leitores de tela: rótulos descritivos, cabeçalhos navegáveis, anúncio de trocas de aba e filtros, e interface localizada em português

## Limitações Conhecidas

- Sem conexão com o servidor o app permite apenas consultar: criar, editar e excluir exigem a API acessível (ainda não há fila de sincronização offline).
- O login não realiza autenticação real (validação apenas de formulário) e a API não exige token; por isso ela deve ser exposta apenas em rede local.
- A API de desenvolvimento usa HTTP sem TLS; em produção deve ser servida por HTTPS.
- Se dois aparelhos editarem o mesmo item, prevalece a última gravação (sem detecção de conflito).
- A previsão do tempo (OpenWeatherMap) prevista na proposta ainda não foi integrada.
- As preferências de Ajustes e o estado "lida" das notificações ainda não são persistidos.
- A situação do talhão (em dia / pendente / agendado) é escolhida manualmente, não calculada a partir dos registros.
- As notificações não são disparadas pelo sistema operacional; a tela de notificações apresenta os avisos derivados dos dados fictícios.

## Funcionalidades Principais (planejadas)

- Gerenciamento de talhões/pivôs
- Histórico de aplicações de insumos
- Notificações push proativas de aplicações agendadas
- Painel de status (feito vs. pendente) por talhão
- Sincronização offline, para uso em campo sem internet

## Telas da Aplicação

1. **Login** — tela inicial, autenticação do usuário
2. **Dashboard (Talhões)** — visão geral dos talhões ativos, com filtro por situação
3. **Histórico e Agenda** — abas de aplicações realizadas e agendadas
4. **Relatórios/Indicadores** — visão consolidada da fazenda para o gerente
5. **Ajustes** — conta, preferências e status de sincronização
6. **Detalhes do Talhão** — cultura, estágio e manejo do talhão selecionado
7. **Cadastro/Edição de Talhão** — criação e edição de talhões
8. **Novo Registro** — formulário para lançar uma nova aplicação
9. **Notificações** — avisos de aplicações pendentes e agendadas
10. **Ajuda e acessibilidade** — como navegar e quais recursos estão disponíveis

## Fluxo de Navegação

```text
Login
 └── Início (casca de navegação com 4 seções)
      ├── Talhões ──► Detalhes do Talhão ──► Novo Registro
      │      │                      └──────► Editar Talhão
      │      ├──────► Novo Talhão
      │      ├──────► Notificações ──► Detalhes do Talhão
      │      └──────► menu "..." ──► Ajuda · Ajustes · Sair
      ├── Histórico (abas: Realizadas | Agendadas) ──► Novo Registro · Detalhes do Talhão
      ├── Relatórios ──► Detalhes do Talhão
      └── Ajustes ──► Notificações · Ajuda · Sair da conta
```

As quatro seções principais ficam sempre acessíveis pela barra inferior (celular) ou pelo menu lateral (tablet e telas largas); as demais telas são empilhadas sobre elas e fechadas pela seta "Voltar" ou pelo botão voltar do aparelho.

Detalhes completos em [`Docs/proposta.md`](Docs/proposta.md), [`Docs/etapa-02.md`](Docs/etapa-02.md), [`Docs/etapa-03.md`](Docs/etapa-03.md), [`Docs/etapa-04.md`](Docs/etapa-04.md) e [`Docs/etapa-05.md`](Docs/etapa-05.md).

## Tecnologias

| Camada | Tecnologia |
|---|---|
| Mobile | Flutter |
| Backend | Node.js + Express + TypeScript — implementado na Etapa 5 (`backend/`) |
| Banco do servidor | PostgreSQL — local via Docker ou no Supabase |
| Banco local (offline) | SQLite (`sqflite`) — Etapa 4; cópia local dos dados do servidor desde a Etapa 5 |
| Comunicação app ↔ API | REST/JSON com o pacote `http` |
| API externa (planejada) | OpenWeatherMap (previsão do tempo) |

## Instruções para Execução

Pré-requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install), um emulador Android/iOS (ou dispositivo físico), [Node.js](https://nodejs.org/) 20+ e [Docker](https://www.docker.com/) (ou um projeto no Supabase).

**1. Backend** (em um terminal):

```bash
cd backend
npm install
cp .env.example .env        # para usar o Supabase, troque a DATABASE_URL
docker compose up -d        # PostgreSQL local
npm run seed                # carga de exemplo
npm run dev                 # API em http://localhost:3000
```

**2. App** (em outro terminal, na raiz do projeto):

```bash
flutter pub get
flutter run                                                        # emulador Android → http://10.0.2.2:3000
flutter run --dart-define=API_URL=http://<IP-do-computador>:3000   # aparelho físico na mesma rede
```

Para verificar dispositivos disponíveis: `flutter devices`.

Verificações automatizadas:

```bash
flutter analyze             # análise estática
flutter test                # navegação, acessibilidade, persistência local e integração com a API
cd backend && npm test      # rotas, validação e erros da API (PostgreSQL em memória, sem Docker)
```

O roteiro de teste manual da navegação está em [`Docs/etapa-03.md`](Docs/etapa-03.md#8-instruções-para-execução-e-teste-da-navegação), o da persistência (incluindo fechar e reabrir o app) em [`Docs/etapa-04.md`](Docs/etapa-04.md#8-verificação-da-persistência-após-encerrar-e-reabrir-o-app) e o do fluxo completo com o backend em [`Docs/etapa-05.md`](Docs/etapa-05.md#3-passo-a-passo-para-executar-o-fluxo).

## Estrutura do Projeto

```text
Plotter/
├── Docs/
│   ├── proposta.md        <-- Proposta técnica/comercial (Etapa 1)
│   ├── etapa-02.md        <-- Documentação da Etapa 2
│   ├── etapa-03.md        <-- Documentação da Etapa 3
│   ├── etapa-04.md        <-- Documentação da Etapa 4
│   └── etapa-05.md        <-- Documentação da Etapa 5
├── README.md               <-- Este arquivo
├── backend/                 <-- API REST (Node.js + Express + TypeScript)
│   ├── src/                  <-- Servidor, rotas, validação e acesso ao PostgreSQL
│   ├── test/                  <-- Testes da API
│   └── docker-compose.yml      <-- PostgreSQL local
├── android/, ios/           <-- Projetos nativos gerados pelo Flutter
├── lib/                     <-- Código-fonte do app
│   ├── main.dart            <-- Ponto de entrada da aplicação
│   ├── theme/                <-- Tema visual, contraste e breakpoints responsivos
│   ├── routes/                <-- Rotas nomeadas e mapa de navegação
│   ├── utils/                  <-- Feedback visual, anúncios e diálogos
│   ├── models/                  <-- Modelos de dados (Talhao, Registro)
│   ├── data/                     <-- Cliente da API, banco SQLite e operações de CRUD
│   ├── widgets/                   <-- Componentes visuais reaproveitáveis
│   └── screens/                    <-- As telas da aplicação
└── test/                    <-- Testes automatizados (widgets, persistência e integração com a API)
```

## Documentação

Consulte a proposta técnica/comercial completa em [`Docs/proposta.md`](Docs/proposta.md), a documentação da Etapa 2 em [`Docs/etapa-02.md`](Docs/etapa-02.md), a da Etapa 3 (navegação, UX e acessibilidade) em [`Docs/etapa-03.md`](Docs/etapa-03.md) a da Etapa 4 (persistência local) em [`Docs/etapa-04.md`](Docs/etapa-04.md) e a da Etapa 5 (backend e fluxo completo) em [`Docs/etapa-05.md`](Docs/etapa-05.md).

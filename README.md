# Plotter

Aplicativo mobile para gestão de lavoura por talhões, criado para centralizar e organizar as atividades diárias de fazendas agrícolas.

## Sobre o Projeto

Produtores rurais frequentemente controlam suas atividades de campo - aplicações de defensivos, fertilizantes - em anotações de papel, o que gera perda de dados e falta de rastreabilidade.

O **Plotter** resolve esse problema centralizando, em um único aplicativo, o controle de cada talhão ou pivô: o que já foi aplicado, o que está pendente e o que está agendado para os próximos dias.

## Problema que a Aplicação Resolve

Substitui o controle manual em papel/cadernos pelo registro digital das aplicações de insumos em cada talhão, evitando perda de dados e dando visibilidade imediata do que já foi feito, do que está pendente e do que está agendado.

## Público-Alvo

Produtores agrícolas, gerentes de fazenda e operadores de campo responsáveis pelo manejo diário de lavouras.

## Funcionalidades Implementadas (Etapas 2 e 3)

Na Etapa 2 foi construída a camada visual da aplicação; na Etapa 3 ela ganhou o fluxo de navegação completo, ergonomia das ações e acessibilidade. Os dados continuam fictícios (mock), sem persistência local nem comunicação com servidor:

- Login de acesso, com validação por campo, estado de carregamento e mostrar/ocultar senha
- Dashboard com painel de status (em dia / pendente), filtro por situação e lista de talhões
- Detalhes do talhão (cultura, estágio, última e próxima aplicação) com ações conectadas
- Cadastro/edição de talhão (formulário com aviso de alterações não salvas)
- Lançamento de novo registro de aplicação (formulário com data validada)
- Histórico de aplicações em duas abas: realizadas e agendadas
- Relatórios/indicadores consolidados da fazenda
- Notificações de aplicações pendentes e agendadas
- Ajuda e acessibilidade: mapa de navegação dentro do próprio aplicativo
- Configurações, preferências e status de sincronização
- Navegação adaptável: barra inferior no celular, menu lateral em tablets e menu lateral estendido em telas largas

### Navegação, UX e acessibilidade (Etapa 3)

- Rotas nomeadas centralizadas em `lib/routes/app_routes.dart`, com tratamento de rota desconhecida
- Retorno consistente: seta na barra superior, botão voltar do aparelho, confirmação antes de descartar formulários e antes de fechar o app
- Feedback visual padronizado em `lib/utils/app_feedback.dart`: mensagens de sucesso/erro/aviso, carregamento, diálogos de confirmação e estados vazios
- Lei de Fitts: alvos de toque de no mínimo 48 dp, ação principal em botão flutuante e navegação na borda inferior
- Contraste mínimo de 4,5:1 em todos os textos, situação indicada por cor + ícone + texto e suporte ao tamanho de fonte do sistema
- Suporte a leitores de tela: rótulos descritivos, cabeçalhos navegáveis, anúncio de trocas de aba e filtros, e interface localizada em português

## Limitações Conhecidas

- Não há persistência local (SQLite) nem comunicação com backend/API externa ainda; todos os dados exibidos são fictícios (mock).
- Login, cadastro e sincronização não realizam autenticação/envio real: a validação é apenas de formulário.
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

Detalhes completos em [`Docs/proposta.md`](Docs/proposta.md), [`Docs/etapa-02.md`](Docs/etapa-02.md) e [`Docs/etapa-03.md`](Docs/etapa-03.md).

## Tecnologias

| Camada | Tecnologia |
|---|---|
| Mobile | Flutter |
| Backend | Node.js + Express + TypeScript |
| Banco local (offline) | SQLite |
| Banco em nuvem | PostgreSQL (Supabase) |
| API externa | OpenWeatherMap (previsão do tempo) |

## Instruções para Execução

Pré-requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado e um emulador Android/iOS configurado (ou dispositivo físico conectado).

```bash
flutter pub get
flutter run
```

Para verificar dispositivos disponíveis: `flutter devices`.

Verificações automatizadas:

```bash
flutter analyze   # análise estática
flutter test      # testes de fluxo de navegação e de acessibilidade
```

O roteiro de teste manual da navegação está em [`Docs/etapa-03.md`](Docs/etapa-03.md#8-instruções-para-execução-e-teste-da-navegação).

## Estrutura do Projeto

```text
Plotter/
├── Docs/
│   ├── proposta.md        <-- Proposta técnica/comercial (Etapa 1)
│   ├── etapa-02.md        <-- Documentação da Etapa 2
│   └── etapa-03.md        <-- Documentação da Etapa 3
├── README.md               <-- Este arquivo
├── android/, ios/           <-- Projetos nativos gerados pelo Flutter
├── lib/                     <-- Código-fonte do app
│   ├── main.dart            <-- Ponto de entrada da aplicação
│   ├── theme/                <-- Tema visual, contraste e breakpoints responsivos
│   ├── routes/                <-- Rotas nomeadas e mapa de navegação
│   ├── utils/                  <-- Feedback visual, anúncios e diálogos
│   ├── models/                  <-- Modelos de dados (Talhao, Registro)
│   ├── data/                     <-- Dados fictícios (mock) usados nesta etapa
│   ├── widgets/                   <-- Componentes visuais reaproveitáveis
│   └── screens/                    <-- As telas da aplicação
└── test/                    <-- Testes automatizados (widget tests)
```

## Documentação

Consulte a proposta técnica/comercial completa em [`Docs/proposta.md`](Docs/proposta.md), a documentação da Etapa 2 em [`Docs/etapa-02.md`](Docs/etapa-02.md) e a da Etapa 3 (navegação, UX e acessibilidade) em [`Docs/etapa-03.md`](Docs/etapa-03.md).

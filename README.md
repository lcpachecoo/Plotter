# Plotter

Aplicativo mobile para gestão de lavoura por talhões, criado para centralizar e organizar as atividades diárias de fazendas agrícolas.

## Sobre o Projeto

Produtores rurais frequentemente controlam suas atividades de campo - aplicações de defensivos, fertilizantes - em anotações de papel, o que gera perda de dados e falta de rastreabilidade.

O **Plotter** resolve esse problema centralizando, em um único aplicativo, o controle de cada talhão ou pivô: o que já foi aplicado, o que está pendente e o que está agendado para os próximos dias.

## Problema que a Aplicação Resolve

Substitui o controle manual em papel/cadernos pelo registro digital das aplicações de insumos em cada talhão, evitando perda de dados e dando visibilidade imediata do que já foi feito, do que está pendente e do que está agendado.

## Público-Alvo

Produtores agrícolas, gerentes de fazenda e operadores de campo responsáveis pelo manejo diário de lavouras.

## Funcionalidades Implementadas (Etapa 2)

Nesta etapa foi implementada a camada visual e de navegação da aplicação, com dados fictícios (mock), sem persistência local nem comunicação com servidor:

- Login de acesso (tela inicial)
- Dashboard com painel de status (em dia / pendente) e lista de talhões
- Detalhes do talhão (cultura, estágio, última e próxima aplicação)
- Cadastro/edição de talhão (formulário)
- Lançamento de novo registro de aplicação (formulário)
- Histórico de aplicações (linha do tempo)
- Relatórios/indicadores consolidados da fazenda
- Configurações e status de sincronização
- Navegação adaptável: barra inferior em telas de celular e menu lateral (rail) em tablets

## Limitações Conhecidas

- Não há persistência local (SQLite) nem comunicação com backend/API externa ainda; todos os dados exibidos são fictícios (mock).
- Login, cadastro e sincronização não realizam validação/autenticação real.
- Notificações push ainda não foram implementadas (apenas o ícone/entrada de UI existe).

## Funcionalidades Principais (planejadas)

- Gerenciamento de talhões/pivôs
- Histórico de aplicações de insumos
- Notificações push proativas de aplicações agendadas
- Painel de status (feito vs. pendente) por talhão
- Sincronização offline, para uso em campo sem internet

## Telas da Aplicação

1. **Login/Perfil** — autenticação e controle de permissões por papel do usuário
2. **Dashboard (Home)** — visão geral dos talhões ativos
3. **Detalhes do Talhão** — cultura, estágio e último manejo
4. **Cadastro/Edição de Talhão** — criação e edição de talhões
5. **Histórico e Agenda** — linha do tempo e próximas aplicações
6. **Novo Registro** — formulário para lançar uma nova aplicação
7. **Relatórios/Indicadores** — visão consolidada da fazenda para o gerente
8. **Configurações/Sincronização** — status offline/online e sincronização manual

## Fluxo de Navegação

O fluxo principal segue Login/Perfil → Dashboard → Detalhes do Talhão → Novo Registro. A partir do Dashboard também é possível acessar diretamente Cadastro/Edição de Talhão, Histórico e Agenda, Relatórios/Indicadores e Configurações/Sincronização.

Detalhes completos em [`Docs/proposta.md`](Docs/proposta.md) e [`Docs/etapa-02.md`](Docs/etapa-02.md).

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

Para verificar dispositivos disponíveis: `flutter devices`. Para rodar os testes automatizados: `flutter test`.

## Estrutura do Projeto

```text
Plotter/
├── Docs/
│   ├── proposta.md        <-- Proposta técnica/comercial (Etapa 1)
│   └── etapa-02.md        <-- Documentação da Etapa 2
├── README.md               <-- Este arquivo
├── android/, ios/           <-- Projetos nativos gerados pelo Flutter
├── lib/                     <-- Código-fonte do app
│   ├── main.dart            <-- Ponto de entrada da aplicação
│   ├── theme/                <-- Tema visual e breakpoints responsivos
│   ├── models/                <-- Modelos de dados (Talhao, Registro)
│   ├── data/                   <-- Dados fictícios (mock) usados nesta etapa
│   ├── widgets/                 <-- Componentes visuais reaproveitáveis
│   └── screens/                  <-- As telas da aplicação
└── test/                    <-- Testes automatizados (widget tests)
```

## Documentação

Consulte a proposta técnica/comercial completa em [`Docs/proposta.md`](Docs/proposta.md) e a documentação desta etapa em [`Docs/etapa-02.md`](Docs/etapa-02.md).

# Plotter

Aplicativo mobile para gestão de lavoura por talhões, criado para centralizar e organizar as atividades diárias de fazendas agrícolas.

## Sobre o Projeto

Produtores rurais frequentemente controlam suas atividades de campo - aplicações de defensivos, fertilizantes - em anotações de papel, o que gera perda de dados e falta de rastreabilidade.

O **Plotter** resolve esse problema centralizando, em um único aplicativo, o controle de cada talhão ou pivô: o que já foi aplicado, o que está pendente e o que está agendado para os próximos dias.

## Público-Alvo

Produtores agrícolas, gerentes de fazenda e operadores de campo responsáveis pelo manejo diário de lavouras.

## Funcionalidades Principais

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

O fluxo principal segue Login/Perfil → Dashboard → Detalhes do Talhão → Histórico e Agenda → Novo Registro. A partir do Dashboard também é possível acessar diretamente Cadastro/Edição de Talhão, Relatórios/Indicadores e Configurações/Sincronização.

Detalhes completos em [`docs/proposta.md`](docs/proposta.md).

## Tecnologias

| Camada | Tecnologia |
|---|---|
| Mobile | Flutter |
| Backend | Node.js + Express + TypeScript |
| Banco local (offline) | SQLite |
| Banco em nuvem | PostgreSQL (Supabase) |
| API externa | OpenWeatherMap (previsão do tempo) |

## Estrutura do Projeto

```text
Plotter/
├── docs/
│   └── proposta.md      <-- Proposta técnica/comercial completa
├── README.md            <-- Este arquivo
├── src/                 <-- Código-fonte do app
│   ├── assets/          <-- Imagens e ícones do sistema
│   ├── components/      <-- Componentes visuais reaproveitáveis
│   ├── screens/         <-- As 8 telas da aplicação
│   └── services/        <-- Camada de serviços e conexões de API
```

## Documentação

Consulte a proposta técnica/comercial completa em [`docs/proposta.md`](docs/proposta.md).


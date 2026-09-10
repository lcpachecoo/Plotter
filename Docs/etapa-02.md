# Etapa 02 — Implementação do Protótipo de Interface

**Disciplina:** Tecnologia e Construção de Software 2
**Autor:** Lucas Carvalho Pacheco
**Projeto:** Plotter — gestão de lavoura por talhões

## 1. Objetivo da Etapa

Transformar a proposta aprovada na Etapa 1 na primeira versão visual e navegável do aplicativo Plotter, em Flutter, sem persistência de dados nem comunicação com servidor — apenas a camada visual e estrutural, com dados fictícios (mock).

## 2. Telas Implementadas

| # | Tela | Arquivo | Descrição |
|---|---|---|---|
| 1 | Login/Perfil (tela inicial) | `lib/screens/login_screen.dart` | Autenticação do usuário; ponto de entrada da aplicação. |
| 2 | Dashboard (Home) | `lib/screens/dashboard_screen.dart` | Visão geral dos talhões ativos, com painel de status (em dia/pendente) e lista/grade de talhões. |
| 3 | Detalhes do Talhão | `lib/screens/talhao_detail_screen.dart` | Cultura, estágio atual, última e próxima aplicação do talhão selecionado. |
| 4 | Cadastro/Edição de Talhão | `lib/screens/cadastro_talhao_screen.dart` | Formulário para criar ou editar um talhão (nome, cultura, área, pivô). |
| 5 | Histórico e Agenda | `lib/screens/historico_screen.dart` | Linha do tempo das aplicações já realizadas em todos os talhões. |
| 6 | Novo Registro | `lib/screens/novo_registro_screen.dart` | Formulário para lançar uma nova aplicação de insumo em um talhão. |
| 7 | Relatórios/Indicadores | `lib/screens/relatorios_screen.dart` | Indicadores consolidados da fazenda (área total, talhões em dia/pendentes/agendados). |
| 8 | Configurações/Sincronização | `lib/screens/configuracoes_screen.dart` | Status offline/online, sincronização manual e preferências. |
| — | Casca de navegação | `lib/screens/home_shell.dart` | Não é uma tela em si; organiza as quatro telas de topo (Dashboard, Histórico, Relatórios, Configurações) em uma navegação compartilhada. |

Isso atende ao requisito de uma tela inicial (Login) mais pelo menos três telas adicionais — foram implementadas sete telas adicionais.

## 3. Principais Componentes Utilizados

A interface usa componentes padrão do Material 3 (Flutter), organizados em widgets próprios para manter consistência visual:

- **AppBar / NavigationBar / NavigationRail** — cabeçalho e navegação principal, trocando de barra inferior para menu lateral conforme o tamanho da tela.
- **Card / InkWell** — base dos cards de talhão, indicadores e itens de histórico.
- **Form / TextFormField / DropdownButtonFormField / showDatePicker** — construção dos formulários de login, cadastro de talhão e novo registro, com validação de campos obrigatórios.
- **GridView / ListView** — listagem responsiva dos talhões e dos registros de histórico.
- **FloatingActionButton.extended** — ações de destaque ("Novo talhão", "Registro").
- **SnackBar** — feedback de conclusão ao salvar formulários (sem persistência real nesta etapa).

## 4. Componentes Reutilizáveis (`lib/widgets/`)

| Componente | Onde é usado | Responsabilidade |
|---|---|---|
| `StatusBadge` | `TalhaoCard`, `TalhaoDetailScreen` | Selo colorido (verde/laranja/azul) indicando se o talhão está em dia, pendente ou agendado. |
| `TalhaoCard` | `DashboardScreen` | Resumo de um talhão em formato de card, com navegação para o detalhe. |
| `AppTextField` | Login, Cadastro de Talhão, Novo Registro | Campo de texto padronizado (rótulo, ícone, validação). |
| `PrimaryButton` | Login, Detalhes do Talhão, Cadastro de Talhão, Novo Registro | Botão de ação principal, com variante `outlined`. |
| `SectionHeader` | Dashboard, Histórico, Relatórios | Título de seção com ação opcional à direita. |
| `StatTile` | Dashboard, Relatórios | Cartão de indicador numérico (ex.: "Talhões pendentes"). |

Esses componentes concentram estilo e comportamento em um único lugar, evitando duplicação de código entre as oito telas.

## 5. Elementos de Entrada de Dados

- **Login:** campos de e-mail e senha (`AppTextField`), com validação de preenchimento obrigatório.
- **Cadastro/Edição de Talhão:** nome do talhão, cultura, área em hectares (teclado numérico) e pivô associado (opcional).
- **Novo Registro:** seletor de tipo de insumo (`DropdownButtonFormField`), nome do insumo, quantidade/dose, data da aplicação (`showDatePicker`) e observações (campo multilinha, opcional).
- **Configurações:** `SwitchListTile` para preferências de notificações push e modo de economia de dados.

Todos os formulários usam `Form` + `GlobalKey<FormState>` para validar os campos obrigatórios antes de simular o salvamento (exibido via `SnackBar`, já que não há persistência nesta etapa).

## 6. Estratégias de Adaptação a Diferentes Tamanhos de Tela

- **Breakpoints centralizados** em `lib/theme/app_theme.dart` (`AppBreakpoints`), usados em todas as telas para decidir o layout: `tablet` (≥700px) e `desktop` (≥1100px).
- **Navegação adaptável** (`home_shell.dart`): em telas estreitas (celular) usa `NavigationBar` inferior; em telas largas (tablet/desktop) usa `NavigationRail` lateral, aproveitando melhor o espaço horizontal.
- **Grades responsivas**: o Dashboard e a tela de Relatórios usam `LayoutBuilder`/`GridView` para alternar entre 1, 2 ou 3 colunas conforme a largura disponível.
- **Formulários e telas de detalhe**: usam `ConstrainedBox` para limitar a largura máxima do conteúdo em telas largas, evitando campos de formulário esticados e mantendo a leitura confortável.
- **Painel de status do Dashboard**: empilha os indicadores verticalmente em celulares e os exibe lado a lado em telas largas.

## 7. Instruções para Execução

Pré-requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado e um emulador Android/iOS configurado (ou dispositivo físico conectado via USB/depuração).

```bash
flutter pub get
flutter run
```

Para listar os dispositivos disponíveis: `flutter devices`.
Para rodar os testes automatizados (smoke test de login e navegação): `flutter test`.

## 8. Principais Decisões de Interface

- **Login como tela inicial** do fluxo, replicando a proposta da Etapa 1, mesmo sem autenticação real — o botão "Entrar" apenas valida o preenchimento dos campos e navega ao Dashboard.
- **Casca de navegação única (`HomeShell`)** para as quatro telas de topo (Dashboard, Histórico, Relatórios, Configurações), evitando duplicar a lógica de navegação adaptável em cada tela.
- **Paleta de cores em tons de verde/terra** (`AppTheme`), remetendo ao contexto agrícola do aplicativo, com cores de status (verde/laranja/azul) reaproveitadas em badges e indicadores.
- **Dados fictícios centralizados** em `lib/data/mock_data.dart`, isolando o mock do restante do app para facilitar a futura substituição por chamadas reais de API/banco local, sem alterar as telas.
- **Formulários sempre com validação local**, mesmo sem persistência, para já estabelecer o padrão de UX que será mantido quando a gravação real dos dados for implementada.
- **Remoção dos alvos de desktop/web** gerados automaticamente pelo `flutter create` (Windows, Linux, macOS, Web), mantendo apenas `android/` e `ios/`, já que o Plotter é uma aplicação mobile.

## 9. Evidências

Capturas de tela podem ser adicionadas neste diretório (`Docs/`) como evidência visual complementar, sem substituir o código-fonte da aplicação.

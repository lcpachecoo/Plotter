# Etapa 04 — Persistência Local de Dados

**Disciplina:** Tecnologia e Construção de Software 2
**Autor:** Lucas Carvalho Pacheco
**Projeto:** Plotter — gestão de lavoura por talhões

## 1. Objetivo da Etapa

Substituir os dados fictícios usados até a Etapa 3 por armazenamento persistente no próprio aparelho. Talhões e registros de aplicação passam a ser criados, lidos, atualizados e removidos em um banco local, e continuam disponíveis depois que o aplicativo é fechado e reaberto.

A navegação, o feedback visual e as medidas de acessibilidade da Etapa 3 foram preservados.

## 2. Mecanismo de Persistência Utilizado

**SQLite**, acessado pelo pacote [`sqflite`](https://pub.dev/packages/sqflite).

| Pacote | Uso |
|---|---|
| `sqflite` | Driver do SQLite para Flutter (Android e iOS). |
| `path` | Monta o caminho do arquivo do banco (`plotter.db`) na pasta de dados do app. |
| `sqflite_common_ffi` (apenas testes) | Executa o mesmo SQLite nos testes automatizados (`flutter test`), que rodam fora de um aparelho. |

O arquivo `plotter.db` fica na pasta de dados privada do aplicativo (`getDatabasesPath()`). Ele não é apagado ao fechar o app nem ao reiniciar o aparelho; só some ao desinstalar o app ou limpar os dados dele.

## 3. Justificativa da Escolha

1. **Coerência com a proposta.** A Etapa 1 (`Docs/proposta.md`, seção de armazenamento) já previa SQLite como banco local. Manter a escolha evita uma mudança de escopo não planejada.
2. **Os dados são relacionais.** Um talhão tem vários registros de aplicação. Com SQLite isso vira uma chave estrangeira (`registros.talhao_id`) com `ON DELETE CASCADE`: excluir um talhão apaga os registros dele sem deixar dados órfãos.
3. **Consultas e ordenação.** Filtrar os registros por talhão, ordenar por data e separar aplicações realizadas de agendadas são operações naturais em SQL.
4. **Preparação para a nuvem.** O backend previsto usa PostgreSQL (Supabase). Ter um modelo relacional no aparelho facilita a sincronização planejada para etapas futuras.
5. **Uso offline.** O banco fica no aparelho e não depende de conexão, requisito central para o trabalho no campo.

Alternativas consideradas:

| Alternativa | Por que não foi usada |
|---|---|
| `shared_preferences` | Guarda apenas pares chave/valor simples; não é adequado para listas que precisam ser criadas, editadas e removidas item a item, nem para relações entre entidades. |
| Hive / Isar | Bancos NoSQL: exigiriam reimplementar à mão a relação talhão → registros e a remoção em cascata, e fugiriam do que foi definido na proposta. |
| Drift | Também usa SQLite, mas exige geração de código (`build_runner`), aumentando a complexidade sem ganho real para o tamanho atual do projeto. |

## 4. Estrutura dos Dados Armazenados

O esquema é criado em `lib/data/database_helper.dart` (versão 1 do banco). As chaves estrangeiras são ativadas com `PRAGMA foreign_keys = ON` ao abrir a conexão, pois o SQLite as deixa desligadas por padrão.

### Tabela `talhoes`

| Coluna | Tipo | Restrição | Descrição |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Identificador gerado pelo banco. |
| `nome` | TEXT | NOT NULL | Nome do talhão (ex.: "Talhão 01 - Pivô Norte"). |
| `cultura` | TEXT | NOT NULL | Cultura plantada. |
| `area_ha` | REAL | NOT NULL | Área em hectares. |
| `estagio` | TEXT | NOT NULL, padrão `''` | Estágio atual da cultura (opcional). |
| `pivo` | TEXT | NOT NULL, padrão `''` | Pivô associado (opcional). |
| `status` | TEXT | NOT NULL | Situação: `feito`, `pendente` ou `agendado` (nome do enum `TalhaoStatus`). |

### Tabela `registros`

| Coluna | Tipo | Restrição | Descrição |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Identificador gerado pelo banco. |
| `talhao_id` | INTEGER | NOT NULL, FK → `talhoes(id)` ON DELETE CASCADE | Talhão onde a aplicação foi (ou será) feita. |
| `insumo` | TEXT | NOT NULL | Produto aplicado. |
| `tipo` | TEXT | NOT NULL | `defensivo`, `fertilizante` ou `outro` (enum `TipoInsumo`). |
| `data` | TEXT | NOT NULL | Data no formato ISO `aaaa-mm-dd`, que o SQLite ordena corretamente. |
| `quantidade` | TEXT | NOT NULL | Dose com unidade (ex.: "0.5 L/ha"). |
| `responsavel` | TEXT | NOT NULL, padrão `''` | Quem fez a aplicação (opcional). |
| `observacoes` | TEXT | NOT NULL, padrão `''` | Observações livres (opcional). |

Índice: `idx_registros_talhao` em `registros(talhao_id)`, usado ao listar os registros de um talhão.

### Regras derivadas dos dados

- **Realizada x agendada:** um registro com data até hoje é uma aplicação **realizada**; com data futura, uma aplicação **agendada**. Não existe uma coluna separada para isso, então a informação nunca fica inconsistente.
- **Última e próxima aplicação** do talhão não são gravadas: são calculadas a partir dos registros (`PlotterCrud.ultimaAplicacao` / `proximaAplicacao`). Até a Etapa 3 eram textos fixos dentro do talhão, que ficavam desatualizados ao lançar um registro.

### Mudanças nos modelos (`lib/models/`)

| Modelo | Antes (Etapa 3) | Agora (Etapa 4) |
|---|---|---|
| `Talhao` | `id` texto fixo; `ultimaAplicacao` e `proximaAplicacao` como texto | `id` inteiro gerado pelo banco; novo campo `pivo`; `toMap` / `fromMap` / `copyWith` |
| `Registro` | Ligado ao talhão pelo **nome** (`talhaoNome`); data como texto | Ligado pelo **id** (`talhaoId`, chave estrangeira); `data` como `DateTime`; novo campo `observacoes`; `toMap` / `fromMap` / `copyWith` |

A ligação pelo id corrige um problema do modelo anterior: ao renomear um talhão, o histórico dele deixaria de ser encontrado.

### Carga inicial

Na primeira vez que o banco é criado (`onCreate`), `DatabaseHelper` grava em uma única transação os talhões e registros de `lib/data/mock_data.dart`, para o app não abrir vazio. As datas são relativas ao dia da instalação, garantindo exemplos tanto de aplicações realizadas quanto de agendadas. A carga **não se repete** ao reabrir o app: a partir daí, tudo o que aparece vem do banco.

## 5. Operações de Persistência Implementadas

Todas as operações ficam em `lib/data/plotter_crud.dart` (classe `PlotterCrud`). As telas nunca executam SQL diretamente.

| Operação | Talhões | Registros | Onde é disparada na interface |
|---|---|---|---|
| **Criar / armazenar** | `inserirTalhao` (`INSERT`) | `inserirRegistro` (`INSERT`) | Botões "Cadastrar talhão" e "Salvar registro". |
| **Recuperar** | `carregar` (`SELECT … ORDER BY id`), `buscarTalhao` | `carregar` (`SELECT … ORDER BY data DESC`), `registrosDoTalhao`, `realizadas`, `agendadas` | Na abertura do app (`main.dart`), depois de cada gravação e no "puxar para atualizar" do Dashboard. |
| **Atualizar** | `atualizarTalhao` (`UPDATE … WHERE id = ?`) | `atualizarRegistro` (`UPDATE … WHERE id = ?`) | "Salvar alterações" na edição do talhão e na edição do registro. |
| **Remover** | `removerTalhao` (`DELETE`, com cascata para os registros) | `removerRegistro` (`DELETE`) | Botão "Excluir talhão" no detalhe; opção "Excluir registro" no menu de cada registro. Ambos pedem confirmação. |

Como os dados chegam às telas:

1. `main.dart` abre o banco (`PlotterCrud.abrir`) **antes** de exibir a primeira tela, então os dados de execuções anteriores já estão carregados quando o app aparece.
2. O `PlotterCrud` é disponibilizado para todas as rotas por `PlotterCrudScope`, um `InheritedNotifier` posicionado acima do `MaterialApp`.
3. Depois de cada gravação, o `PlotterCrud` relê as tabelas e chama `notifyListeners()`. Todas as telas que leem os dados com `PlotterCrudScope.of(context)` são reconstruídas sozinhas: a interface mostra sempre o que está gravado.

Tratamento de erros: toda gravação e exclusão nas telas fica dentro de `try/catch`. Em caso de falha, o formulário continua aberto com os dados digitados e é exibida uma mensagem de erro (`AppFeedback.erro`), por exemplo "Não foi possível salvar o talhão no aparelho. Tente novamente.".

## 6. Telas que Utilizam os Dados Persistidos

| Tela | Arquivo | Uso dos dados |
|---|---|---|
| Dashboard (Talhões) | `lib/screens/dashboard_screen.dart` | Lista os talhões gravados, conta em dia/pendentes, mostra a próxima aplicação de cada um e recarrega o banco no "puxar para atualizar". Estado vazio quando não há talhões. |
| Detalhes do Talhão | `lib/screens/talhao_detail_screen.dart` | Lê o talhão pelo id a cada reconstrução (reflete edições na hora), calcula a última e a próxima aplicação, lista os registros do talhão e permite **excluir** o talhão. |
| Cadastro/Edição de Talhão | `lib/screens/cadastro_talhao_screen.dart` | **Cria** e **atualiza** talhões. Ganhou o campo "Estágio atual", e o "Pivô associado", que antes era descartado, agora é gravado. |
| Novo/Editar Registro | `lib/screens/novo_registro_screen.dart` | **Cria** e **atualiza** registros. Quando aberto pelo Histórico, pede o talhão em uma lista dos talhões gravados. Ganhou o campo "Responsável", e as "Observações" passaram a ser gravadas. |
| Histórico e Agenda | `lib/screens/historico_screen.dart` | Aba "Realizadas" = registros com data até hoje; aba "Agendadas" = registros com data futura. Tocar no item abre a edição; o menu do item permite ver o talhão ou **excluir** o registro. |
| Relatórios | `lib/screens/relatorios_screen.dart` | Indicadores calculados com os dados gravados (área total, situação dos talhões, número de aplicações registradas e agendadas). |
| Notificações | `lib/screens/notificacoes_screen.dart` | Avisos gerados a partir dos talhões pendentes/agendados gravados, com a próxima aplicação de cada um. |

Componente novo: `lib/widgets/registro_tile.dart` (`RegistroTile`), o item de registro reutilizado no Histórico e no detalhe do talhão. Ele concentra as ações de editar, ver o talhão e excluir.

## 7. Instruções para Execução e Teste

### 7.1 Executar

Pré-requisitos: Flutter SDK e um emulador ou aparelho **Android ou iOS** (o `sqflite` usa o SQLite nativo dessas plataformas).

```bash
flutter pub get
flutter run
```

### 7.2 Testes automatizados

```bash
flutter analyze   # análise estática (sem avisos)
flutter test      # 18 testes
```

| Arquivo | O que cobre |
|---|---|
| `test/plotter_crud_test.dart` (6 testes) | Carga inicial; criar/ler/atualizar/remover talhão; criar/atualizar/remover registro e a separação realizadas × agendadas; remoção em cascata; **persistência após fechar e reabrir o banco**; a carga inicial não se repete. Usa um arquivo SQLite real em pasta temporária. |
| `test/widget_test.dart` (12 testes) | Os 9 testes da Etapa 3 (navegação e acessibilidade), agora sobre um banco em memória, mais 3 novos: edição de talhão refletida no detalhe, exclusão de talhão com confirmação e exclusão de registro pelo Histórico. O teste de cadastro também confere que o talhão foi gravado e aparece na lista. |

### 7.3 Roteiro de teste manual das operações

1. **Recuperar:** abra o app e entre. O Dashboard mostra os 4 talhões da carga inicial, e o Histórico mostra aplicações realizadas e agendadas.
2. **Criar talhão:** toque em "Novo talhão", preencha nome, cultura e área e salve. O talhão aparece na lista com a confirmação.
3. **Criar registro:** no Histórico, toque em "Registro", escolha o talhão, preencha os campos e escolha uma data **futura**. O registro aparece na aba "Agendadas" e como "Próxima aplicação" no cartão do talhão.
4. **Atualizar:** abra um talhão, toque em "Editar talhão", troque a cultura e salve. O detalhe já mostra a nova cultura. No Histórico, toque em um registro, mude a dose e salve.
5. **Remover registro:** no Histórico, abra o menu "⋮" de um registro, escolha "Excluir registro" e confirme.
6. **Remover talhão:** no detalhe de um talhão, toque em "Excluir talhão". O diálogo informa quantos registros serão apagados junto. Confirme: o app volta à lista com a mensagem de confirmação, e os registros daquele talhão somem do Histórico.

## 8. Verificação da Persistência após Encerrar e Reabrir o App

Procedimento usado:

1. Com o app aberto, criar um talhão "Talhão Teste" e um registro para ele; editar um talhão existente; excluir um registro.
2. **Encerrar o app de verdade**: abrir a lista de apps recentes do Android e deslizar o Plotter para fechá-lo (ou, em modo de desenvolvimento, parar com `q` no terminal do `flutter run`). Só voltar para a tela inicial não basta, porque o processo continua vivo.
3. Opcionalmente, reiniciar o aparelho/emulador.
4. Abrir o Plotter novamente e entrar.
5. Conferir que:
   - "Talhão Teste" e o registro dele continuam lá;
   - a edição feita continua aplicada;
   - o registro excluído não voltou;
   - a carga inicial **não** foi gravada de novo (não há talhões duplicados).

A mesma verificação existe de forma automatizada no teste *"os dados continuam disponíveis após fechar e reabrir o banco"* (`test/plotter_crud_test.dart`): ele grava dados, fecha a conexão e abre um `PlotterCrud` novo sobre o mesmo arquivo, conferindo que tudo foi recuperado.

Para voltar ao estado inicial (refazer a carga de exemplo), basta limpar os dados do app em *Configurações → Apps → Plotter → Armazenamento → Limpar dados*, ou desinstalá-lo.

## 9. Arquivos Criados ou Alterados na Etapa 4

| Arquivo | Situação | Papel |
|---|---|---|
| `lib/data/database_helper.dart` | novo | Abre o `plotter.db`, cria as tabelas, ativa as chaves estrangeiras e grava a carga inicial. |
| `lib/data/plotter_crud.dart` | novo | Operações de CRUD (`PlotterCrud`) e `PlotterCrudScope`, que disponibiliza os dados para as telas. |
| `lib/widgets/registro_tile.dart` | novo | Item de registro com as ações de editar, ver o talhão e excluir. |
| `test/plotter_crud_test.dart` | novo | Testes da camada de persistência, incluindo fechar e reabrir o banco. |
| `lib/data/mock_data.dart` | alterado | Deixou de ser lido pelas telas; virou a carga inicial do banco. |
| `lib/models/talhao.dart`, `registro.dart` | alterados | Ids do banco, chave estrangeira, data como `DateTime`, novos campos e conversão para o banco. |
| `lib/main.dart` | alterado | Abre o banco antes do `runApp` e envolve o app no `PlotterCrudScope`. |
| `lib/routes/app_routes.dart` | alterado | Nova rota `/registro/editar`; detalhe do talhão recebe o id; `abrirTalhao` exibe a confirmação de exclusão na tela de origem. |
| `lib/screens/*.dart` | alterados | Leitura e gravação pelo `PlotterCrud`, edição e exclusão de itens, e estados vazios. |
| `lib/widgets/talhao_card.dart` | alterado | Recebe a próxima aplicação calculada a partir dos registros. |
| `test/widget_test.dart` | alterado | Banco em memória por teste e novos testes de CRUD pela interface. |
| `pubspec.yaml` | alterado | Inclusão de `sqflite`, `path` e `sqflite_common_ffi`. |

## 10. Limitações Conhecidas

- As preferências da tela de Ajustes (notificações, economia de dados) e o estado "lida" das notificações ainda não são persistidos; valem só enquanto o app está aberto.
- A situação do talhão (em dia / pendente / agendado) continua sendo escolhida manualmente no formulário, e não calculada a partir dos registros.
- O login continua sem autenticação real e a sincronização com o servidor continua simulada; os dados ficam apenas no aparelho.
- O `sqflite` atende Android e iOS. Para executar em desktop ou web seria necessário outro driver (ex.: `sqflite_common_ffi`).

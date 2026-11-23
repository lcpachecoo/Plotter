# Etapa 07 — Gerenciamento de Estado Global e Recursos do Dispositivo

**Disciplina:** Tecnologia e Construção de Software 2
**Autor:** Lucas Carvalho Pacheco
**Projeto:** Plotter — gestão de lavoura por talhões

## 1. Objetivo da Etapa

Tratar como **estado global** as informações que várias partes do app precisam ver ao mesmo tempo e integrar um **recurso nativo do dispositivo** com função real no fluxo do produtor.

Antes desta etapa havia dois problemas no app:

- **Estado preso a uma tela.** As notificações lidas ficavam em uma variável da tela de Notificações e sumiam ao fechá-la. O sino do Dashboard não sabia o que tinha sido lido e continuava mostrando o mesmo número depois de "Marcar todas como lidas". As preferências de Ajustes eram variáveis locais (`setState`) que se perdiam ao reabrir o app.
- **Nenhum recurso nativo.** O interruptor "Notificações push" de Ajustes era só visual, e a proposta já listava como funcionalidade planejada as *"notificações proativas de aplicações agendadas"*.

Resultado:

- **Estado global de preferências** (`Preferencias`), gravado no aparelho e compartilhado por Ajustes, Notificações, Dashboard, menu lateral e pelo serviço de lembretes.
- **Lembretes de aplicações** com as **notificações locais** do Android/iOS. No dia de cada aplicação agendada, às 7h, o sistema mostra um aviso, mesmo com o app fechado e sem internet. Tocar no aviso abre o talhão.

## 2. Mecanismo de Gerenciamento de Estado

O app usa o mecanismo do próprio Flutter, **`ChangeNotifier` + `InheritedNotifier`**, sem biblioteca externa:

| Peça | Papel |
|---|---|
| `ChangeNotifier` | Guarda o estado e chama `notifyListeners()` quando ele muda. |
| `InheritedNotifier` (os `...Scope`) | Fica acima do `MaterialApp` e entrega o objeto a qualquer tela da árvore, inclusive às rotas empilhadas. |
| `Scope.of(context)` | Lê o estado **e** registra a tela como dependente. Ela é reconstruída a cada mudança. Usado no `build`. |
| `Scope.read(context)` | Só lê, sem criar dependência. Usado em callbacks (botões, gravações). |
| `addListener` | Usado por quem não é tela. O serviço de lembretes escuta os dados e as preferências. |

```text
main.dart
└── PlotterCrudScope      → PlotterCrud   (talhões, registros, status do servidor — Etapas 4 a 6)
    └── PreferenciasScope → Preferencias  (NOVO: lembretes ligados, economia de dados, avisos lidos)
        └── LembretesScope → Lembretes    (NOVO: situação das notificações do sistema)
            └── MaterialApp → todas as rotas
```

**Por que esse mecanismo, e não `provider`/Riverpod/BLoC:** o `PlotterCrud`, criado nas Etapas 4 e 5, já usava esse padrão. Manter um padrão único deixa o código coerente e evita reescrever todas as telas. É o mesmo mecanismo em que o `provider` se apoia por dentro, não acrescenta dependência e é simples de explicar e de testar: os testes criam os objetos e os passam ao `PlotterApp`.

## 3. Estados Tratados Globalmente

| Estado | Onde fica | Quem lê | Quem altera | Gravado no aparelho? |
|---|---|---|---|---|
| Talhões, registros, status do servidor, cache da previsão | `PlotterCrud` (`lib/data/plotter_crud.dart`) | Todas as telas de dados | Formulários, sincronização | Sim (SQLite, Etapa 4) |
| **Avisos lidos** | `Preferencias` (`lib/state/preferencias.dart`) | Notificações, sino do Dashboard, sino do menu lateral | Notificações (tocar no aviso, "Marcar todas como lidas") | **Sim** (`shared_preferences`) |
| **Lembretes ligados** | `Preferencias` | Ajustes, `Lembretes` | Ajustes, faixa da tela de Notificações | **Sim** |
| **Economia de dados** | `Preferencias` | Ajustes | Ajustes | **Sim** |
| **Situação dos lembretes** (verificando, desativados, ativos, sem permissão, falha, indisponível) e quantidade agendada | `Lembretes` (`lib/state/lembretes.dart`) | Ajustes, faixa da tela de Notificações | O próprio serviço, conforme dados, preferências e permissão | Não: é recalculada ao abrir o app, consultando o sistema |
| **Talhão pedido por um lembrete tocado** | `Lembretes.talhaoSolicitado` | Casca de navegação (`HomeShell`) | Toque na notificação | Não |

Os **avisos** em si não são gravados. São derivados dos talhões a cada leitura (`PlotterCrud.avisos`), e só a chave dos que foram lidos é guardada. A chave inclui a situação do talhão e a próxima aplicação (`lib/models/aviso.dart`). Se o talhão muda de situação ou ganha outra data, o aviso volta a aparecer como não lido.

## 4. Por Que Esses Estados São Globais

- **Avisos lidos:** a mesma informação aparece em **três lugares** (lista de Notificações, sino do Dashboard e sino do menu lateral em tablets). Enquanto ficava dentro da tela de Notificações, os sinos mostravam um número errado, e a leitura se perdia ao sair da tela. Com o estado global, ler um aviso atualiza os três ao mesmo tempo.
- **Preferências de Ajustes:** precisam **durar mais que a tela** e mais que a execução do app. Ninguém espera religar os lembretes toda vez que abre o Plotter.
- **Lembretes ligados:** é lido **fora da árvore de widgets**, pelo serviço `Lembretes`, que precisa reagir mesmo que a tela de Ajustes nunca seja aberta. Por exemplo, ao abrir o app, para reagendar.
- **Situação dos lembretes:** é exibida em **duas telas** (Ajustes e Notificações) e muda por motivos que nenhuma delas controla: o usuário pode bloquear as notificações nas configurações do sistema e voltar ao app.
- **Talhão pedido por um lembrete:** o toque acontece fora do app, às vezes com o app fechado. O pedido precisa esperar até a casca de navegação existir, ou seja, depois do login.

Continuam **locais**, de propósito, os estados que só interessam a uma tela: filtro do Dashboard, aba ativa, campos de formulário, "salvando…" e o travamento do interruptor durante o pedido de permissão.

## 5. Recurso Nativo Utilizado

| Item | Valor |
|---|---|
| Recurso | **Notificações locais agendadas** do sistema operacional |
| Biblioteca | [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) 23.0.4 (+ [`timezone`](https://pub.dev/packages/timezone) para a data do agendamento) |
| Android | `AlarmManager` (agendamento inexato) + `NotificationManager`, canal **"Lembretes de aplicações"** |
| iOS | `UNUserNotificationCenter` |
| Onde fica no código | `lib/services/notificacoes_locais.dart`: única classe que conversa com o plugin. O resto do app usa a interface `CanalNotificacoes` (`lib/state/lembretes.dart`). |

**O que faz:** cada registro com data futura (aplicação agendada) vira um lembrete às **7h do dia da aplicação**, com o título *"Aplicação agendada para hoje"* e o texto *"Herbicida em Talhão 02 - Baixada · 2 L/ha"*. Tocar no lembrete abre o **detalhe do talhão**.

## 6. Justificativa da Escolha

1. **Resolve um problema real do produtor:** a aplicação agendada no escritório precisa ser lembrada no dia, no campo. Sem o lembrete, o produtor depende de abrir o app, que é a mesma falha do caderno de papel que o Plotter quer substituir.
2. **Já estava prevista:** a proposta lista "notificações push proativas de aplicações agendadas" entre as funcionalidades principais. O README listava como limitação que as notificações não eram disparadas pelo sistema.
3. **Funciona offline:** o agendamento fica no aparelho, e o sistema entrega o aviso sem internet e com o app fechado. Isso combina com a decisão das Etapas 4 e 5 de que o app precisa funcionar em campo.
4. **Integração real com o app:** os lembretes são tirados dos dados (`PlotterCrud.agendadas`) e se atualizam sozinhos a cada cadastro, edição, exclusão ou sincronização. Eles obedecem ao estado global de preferências e levam de volta ao talhão.
5. **Sem servidor de push:** notificações *push* exigiriam Firebase/APNs e credenciais. As locais atendem ao caso de uso, que é avisar sobre algo que o próprio aparelho já sabe, sem nova infraestrutura.

Alternativas consideradas: **localização (GPS)**, para registrar onde a aplicação foi feita ou ter previsão do tempo por talhão, exigiria mudar o backend e o banco. **Câmera**, para foto do rótulo como comprovante, exigiria envio de arquivos ao servidor. **Compartilhamento** tem a ligação mais fraca com o fluxo principal. Ficam para etapas futuras.

## 7. Permissões Necessárias

### Android (`android/app/src/main/AndroidManifest.xml`)

| Permissão | Para quê | Como é obtida |
|---|---|---|
| `POST_NOTIFICATIONS` | Mostrar notificações | **Android 13+:** pedida em tempo de execução, **só quando o usuário liga os lembretes** em Ajustes (ou na faixa da tela de Notificações). Android 12 ou anterior: concedida na instalação. |
| `RECEIVE_BOOT_COMPLETED` | Reagendar os lembretes depois de reiniciar o aparelho (o sistema apaga os alarmes ao desligar) | Concedida na instalação |
| `INTERNET` | Já existia (Etapa 5) | Concedida na instalação |

**Não** é usada `SCHEDULE_EXACT_ALARM` nem `USE_EXACT_ALARM`. Os lembretes usam `AndroidScheduleMode.inexactAllowWhileIdle`, porque um aviso "por volta das 7h" não precisa de precisão ao segundo. A partir do Android 14, a permissão de alarme exato vem negada por padrão e é reservada a despertadores e agendas.

Também foram declarados os receptores do plugin, `ScheduledNotificationReceiver` e `ScheduledNotificationBootReceiver`. O `build.gradle.kts` passou a usar `compileSdk = 37` e *core library desugaring*, ambos exigidos pelo plugin.

### iOS

| Permissão | Como é obtida |
|---|---|
| Autorização de notificações (alerta, som, selo) | Pedida pelo sistema quando o usuário liga os lembretes. Ao abrir o app nada é pedido (`DarwinInitializationSettings` com os três pedidos em `false`). |

O `AppDelegate.swift` registra o app como `UNUserNotificationCenterDelegate`, conforme a documentação do plugin, para receber o toque no lembrete.

## 8. Fluxo de Utilização do Recurso

```text
Ajustes ▸ "Lembretes de aplicações" (ou "Ativar lembretes" na tela de Notificações)
  │
  ▼
Lembretes.ativar()
  │ aparelho sem suporte? ─────────────────────────► "indisponível" + mensagem; app segue normal
  │ permissão já concedida? senão ► diálogo do sistema
  │      negou ───────────────────────────────────► interruptor volta a desligado + mensagem
  │                                                   com o botão "Configurações"
  ▼ concedeu
Preferencias.definirLembretes(true)   (gravado no aparelho; avisa as telas)
  │
  ▼
Lembretes.atualizar()  ◄── também roda quando: PlotterCrud muda (cadastro/edição/
  │                        exclusão/sincronização) · Preferencias muda · app volta
  │                        do segundo plano · app abre
  │ preferência desligada? → cancela todos → "desativados"
  │ permissão retirada no sistema? → cancela todos → "sem permissão" (a escolha é mantida)
  │ monta a agenda: 1 lembrete por aplicação agendada, às 7h, só futuros, até 50
  │ igual à última enviada? → não faz nada
  ▼
CanalNotificacoes.cancelarTodos() + agendar(...)  →  NotificacoesLocais → plugin → sistema
  │ erro do sistema? ───────────────────────────────► "falha" + "Tentar de novo"
  ▼
"Ativos · 4 lembretes agendados para as 7h"

            … no dia da aplicação, 7h, mesmo com o app fechado …

Sistema mostra: "Aplicação agendada para hoje — Herbicida em Talhão 02 - Baixada · 2 L/ha"
  │ toque
  ▼
Lembretes.talhaoSolicitado = id do talhão
  │ (app estava fechado? o pedido espera o login)
  ▼
HomeShell abre o Detalhe do Talhão  (talhão excluído nesse meio tempo? mensagem explicativa)
```

## 9. Tratamento de Falhas e Indisponibilidade

| Situação | Como é detectada | O que o usuário vê | O que o app faz |
|---|---|---|---|
| **Aparelho/plataforma sem notificações** (web, desktop, plugin ausente) | `inicializar` lança `MissingPluginException` ou não é Android/iOS | Ajustes: *"Indisponível neste aparelho"*, interruptor desabilitado. A faixa das Notificações não aparece. | Não escuta dados nem agenda. **Todo o resto do app funciona.** |
| **Usuário nega a permissão** | `pedirPermissao()` devolve `false` | SnackBar *"Sem permissão, o Plotter não consegue enviar lembretes…"* com o botão **Configurações** | Não liga a preferência e não agenda nada. |
| **Permissão negada de vez** (o Android não mostra mais o diálogo) | Igual ao caso anterior: o sistema devolve `false` sem perguntar | Mesma mensagem; o botão **Configurações** abre a tela de notificações do Plotter no sistema | Se não for possível abrir as configurações, explica o caminho: *Configurações > Apps > Plotter > Notificações*. |
| **Permissão retirada depois**, nas configurações do sistema | `permissaoConcedida()` a cada abertura do app e a cada volta do segundo plano | Ajustes: *"Bloqueados: as notificações do Plotter estão desligadas no aparelho"* + **Permitir notificações**. Notificações: faixa laranja com **Abrir configurações**. | Cancela os lembretes e **mantém a escolha do usuário**. Ao liberar e voltar ao app, os lembretes voltam sozinhos. |
| **Sistema recusa o agendamento** (`PlatformException`) | Erro em `agendar`/`cancelarTodos` | Ajustes: *"Não foi possível agendar os lembretes"* + **Tentar agendar de novo**. Notificações: faixa vermelha com **Tentar de novo**. | Tenta de novo na próxima alteração, ao voltar ao app ou pelo botão. |
| **Lembrete de um talhão já excluído** | O talhão não existe mais na cópia local | *"O talhão deste lembrete não existe mais. Ele pode ter sido excluído."* | Não abre nenhuma tela. (A exclusão também já remove o lembrete na próxima atualização.) |
| **Falha ao ler o lembrete que abriu o app** | Erro em `getNotificationAppLaunchDetails` | Nada | Registra no log; os lembretes continuam funcionando. |
| **Armazenamento de preferências indisponível** | Erro em `SharedPreferences.getInstance()` ou ao gravar | Nada | Segue com os valores padrão em memória. As escolhas valem até fechar o app. |
| **Aplicação no passado ou além do limite** | Data/hora já passou, ou mais de 50 lembretes | — | Não agenda. Só os 50 mais próximos ficam no sistema (o Android aceita até 500 alarmes por app). |

## 10. Instruções para Execução e Teste

### 10.1 Executar

Sem configuração nova. O backend continua igual ao da Etapa 6.

```bash
cd backend && npm run dev                # API, como nas etapas anteriores
# em outro terminal, na raiz do projeto
flutter pub get
flutter run                              # emulador/aparelho Android 13+ de preferência (para ver o pedido de permissão)
```

### 10.2 Roteiro de teste manual

1. **Estado global, avisos lidos:** entre no app. O sino do Dashboard mostra o número de avisos não lidos (com a carga de exemplo, **3**). Abra o sino, toque em **Marcar todas como lidas** e volte: o sino fica **sem número**. Feche o app pelo gerenciador de tarefas e abra de novo: continua sem número.
2. **Aviso que volta:** edite um talhão "Em dia" para "Pendente". O sino passa a mostrar **1**, porque a situação mudou.
3. **Ligar os lembretes:** em **Ajustes > Preferências > Lembretes de aplicações**, ligue o interruptor. No Android 13+ aparece o diálogo do sistema; toque em **Permitir**. A mensagem confirma, e o subtítulo passa a *"Ativos · N lembretes agendados para as 7h"*, em que N é o número de aplicações em **Histórico > Agendadas**. Se não houver nenhuma (a carga de exemplo usa datas relativas ao dia em que o `npm run seed` foi executado), lance antes um registro com data futura.
4. **Ver um lembrete chegar:** nas configurações do emulador, em **Sistema > Data e hora**, desligue a data automática e coloque a data de uma aplicação agendada (veja a aba **Histórico > Agendadas**) às **7:01**. Em instantes aparece *"Aplicação agendada para hoje"*. Toque nele: o Plotter abre no **detalhe do talhão** (depois do login, se o app estava fechado). Volte a data para automática ao terminar.
   Para conferir sem mudar a data: `adb shell dumpsys alarm | grep -A3 com.plotter.plotter` lista os alarmes agendados.
5. **Atualização automática:** com os lembretes ativos, lance um registro para amanhã. Em Ajustes, o número de lembretes aumenta. Exclua o registro e o número volta.
6. **Permissão negada:** desinstale e reinstale o app, ligue os lembretes e toque em **Não permitir**. O interruptor volta a desligado, e a mensagem tem o botão **Configurações**, que abre a tela de notificações do Plotter.
7. **Permissão retirada depois:** com os lembretes ativos, desligue as notificações do Plotter nas configurações do sistema e volte ao app. Ajustes mostra *"Bloqueados…"* e a tela de Notificações mostra a faixa laranja. Libere de novo e volte: os lembretes reaparecem como ativos, sem tocar em nada.
8. **Desligar:** desligue o interruptor. Mensagem *"Lembretes desativados…"*; `dumpsys alarm` não lista mais alarmes do app.

### 10.3 Evidências em execução

Os prints deste roteiro, feitos em um celular Android 17 real por depuração USB, estão em [`Docs/prints/`](prints/README.md). Eles incluem o pedido de permissão do sistema, os lembretes ativos, o sino zerado depois da leitura, as notificações bloqueadas e o servidor fora do ar. O alarme criado no Android ao ativar os lembretes está em [`Docs/prints/alarme-agendado.txt`](prints/alarme-agendado.txt).

### 10.4 Testes automatizados

```bash
flutter analyze
flutter test        # 60 testes (37 das Etapas 3 a 6 + 23 da Etapa 7)
```

| Arquivo | O que cobre |
|---|---|
| `test/lembretes_test.dart` (11) | Começa desativado sem pedir permissão; ativar agenda **um lembrete por aplicação agendada às 7h**, com talhão e insumo no texto; **permissão negada**; desativar cancela; novo registro e exclusão **reagendam sozinhos**; horário já passado não agenda; **permissão retirada → sem permissão → volta sozinho**; **aparelho sem suporte → indisponível**; **falha ao agendar → "Tentar de novo"**; não reagenda à toa; toque em lembrete e app aberto por lembrete. |
| `test/preferencias_test.dart` (5) | Valores padrão; **gravação e leitura ao reabrir** (`shared_preferences` simulado); contador de não lidos, "marcar todos" e descarte de chaves antigas; aviso volta a não lido quando a situação ou a data muda; telas são avisadas só quando algo muda. |
| `test/widget_test.dart` (+7) | Ler as notificações **zera o sino do Dashboard** e continua valendo ao reabrir a tela; ligar os lembretes em Ajustes pede permissão e agenda; permissão negada mantém desligado e o botão abre as configurações; faixa de bloqueio na tela de Notificações; **tocar em um lembrete abre o talhão**; app aberto por um lembrete mostra o talhão logo após o login; aparelho sem notificações desabilita o interruptor. |
| `test/canal_notificacoes_falso.dart` | Não é teste: é a versão falsa do recurso nativo usada pelos testes acima. |

O recurso nativo não roda no `flutter test`, que não tem aparelho. Por isso os testes trocam `NotificacoesLocais` por `CanalNotificacoesFalso`, pela interface `CanalNotificacoes`. A configuração nativa do Android (manifest, desugaring, SDK 37) foi verificada com `flutter build apk --debug`.

## 11. Principais Decisões Técnicas

1. **`ChangeNotifier` + `InheritedNotifier`** em vez de uma biblioteca de estado (seção 2): mesmo padrão do `PlotterCrud`, sem dependência nova.
2. **Um objeto por assunto** (`PlotterCrud`, `Preferencias`, `Lembretes`) em vez de um único objeto global. Cada tela depende só do que usa, e uma mudança de preferência não reconstrói as telas que só leem talhões.
3. **`shared_preferences` para as preferências**, e não uma tabela no SQLite: são poucos valores chave/valor, sem relação com talhões e registros, e o SQLite é a cópia dos dados do servidor, apagada a cada sincronização.
4. **Avisos derivados, só a leitura é gravada**, com uma chave que inclui a situação. Assim não existe uma segunda lista de avisos para desatualizar, e um aviso novo sobre o mesmo talhão volta a chamar atenção.
5. **Permissão pedida no contexto**, quando o usuário liga os lembretes, e não ao abrir o app, como recomenda a documentação do Android. Os lembretes começam desligados.
6. **Interface `CanalNotificacoes`** separando o plugin da regra: toda a lógica (quando agendar, o que fazer em cada falha) fica em `Lembretes` e é testável sem aparelho.
7. **Agendamento inexato**, sem a permissão de alarme exato (seção 7).
8. **Horário em UTC no agendamento:** a data das 7h é calculada no fuso do aparelho e convertida para o mesmo instante em UTC. Isso dispensa carregar a base completa de fusos horários só para agendar avisos de data única.
9. **Reagendar comparando a agenda:** a cada mudança a agenda é montada de novo e só é enviada ao sistema se for diferente da anterior. Pedidos simultâneos são reunidos em uma rodada, então dados e preferências mudando juntos não agendam em dobro.
10. **Toque no lembrete via `ValueNotifier`** (`talhaoSolicitado`), consumido pela casca de navegação: funciona com o app aberto e com o app fechado (o pedido espera o login), sem depender de uma `navigatorKey` global.
11. **Recurso iniciado depois da primeira tela** (`lembretes.iniciar()` sem `await` no `main`): preparar as notificações não atrasa a abertura do app.

### Bibliotecas adicionadas

| Biblioteca | Versão | Uso |
|---|---|---|
| `flutter_local_notifications` | ^23.0.4 | Agendar, cancelar e receber o toque das notificações; pedir e consultar a permissão; abrir as configurações de notificação do app |
| `timezone` | ^0.11.2 | Tipo `TZDateTime` exigido pelo agendamento |
| `shared_preferences` | ^2.5.6 | Gravar as preferências e os avisos lidos no aparelho |

## 12. Arquivos Criados ou Alterados na Etapa 7

| Arquivo | Situação | Papel |
|---|---|---|
| `lib/state/preferencias.dart` | novo | Estado global `Preferencias` (`ChangeNotifier`) + `PreferenciasScope`; gravação com `shared_preferences`. |
| `lib/state/lembretes.dart` | novo | `Lembretes` (`ChangeNotifier`) + `LembretesScope`; interface `CanalNotificacoes`; situações e regra de agendamento. |
| `lib/services/notificacoes_locais.dart` | novo | `NotificacoesLocais`: único ponto de contato com o recurso nativo. |
| `lib/models/aviso.dart` | novo | Modelo `Aviso` e sua chave de leitura. |
| `lib/widgets/aviso_lembretes.dart` | novo | Faixa da tela de Notificações e mensagens de ativação/falha compartilhadas com Ajustes. |
| `lib/main.dart` | alterado | Cria `Preferencias` e `Lembretes` e os coloca acima do `MaterialApp`. |
| `lib/data/plotter_crud.dart` | alterado | `avisos`, derivados dos talhões. |
| `lib/screens/notificacoes_screen.dart` | alterado | "Lido" passou do `setState` para o estado global; faixa de lembretes. |
| `lib/screens/dashboard_screen.dart` | alterado | Sino conta os avisos **não lidos**. |
| `lib/screens/home_shell.dart` | alterado | Sino com contador no menu lateral; abre o talhão do lembrete tocado. |
| `lib/screens/configuracoes_screen.dart` | alterado | Interruptores ligados ao estado global; situação dos lembretes, "Permitir notificações" e "Tentar de novo". |
| `lib/screens/ajuda_screen.dart` | alterado | Item de ajuda sobre os lembretes. |
| `android/app/src/main/AndroidManifest.xml` | alterado | Permissões `POST_NOTIFICATIONS` e `RECEIVE_BOOT_COMPLETED`; receptores do plugin. |
| `android/app/build.gradle.kts` | alterado | `compileSdk = 37` e *core library desugaring*. |
| `ios/Runner/AppDelegate.swift` | alterado | Delegado do `UNUserNotificationCenter`. |
| `pubspec.yaml` / `pubspec.lock` | alterado | Três bibliotecas novas. |
| `test/lembretes_test.dart`, `test/preferencias_test.dart`, `test/canal_notificacoes_falso.dart` | novos | Testes da etapa e canal falso. |
| `test/widget_test.dart` | alterado | Passa o estado global ao `PlotterApp`; 7 testes novos. |
| `README.md` | alterado | Funcionalidades, tecnologias, estrutura e limitações da Etapa 7. |

## 13. Limitações Conhecidas

- **Só aplicações agendadas geram lembrete.** Talhões "pendentes" sem data aparecem na tela de Notificações, mas não viram aviso do sistema.
- **Horário fixo (7h)**, ainda sem opção em Ajustes. A entrega é aproximada e pode atrasar alguns minutos em modo de economia de bateria.
- **Lembretes valem para os dados deste aparelho.** Uma aplicação agendada em outro aparelho só ganha lembrete aqui depois da sincronização (ao abrir o app, puxar para atualizar ou "Sincronizar agora").
- **"Forçar parada" apaga os alarmes:** quando o app é forçado a parar nas configurações do Android, o sistema cancela os alarmes dele. Os lembretes são refeitos na próxima vez que o app é aberto ou volta ao primeiro plano.
- **"Avisos lidos" são do aparelho**, não da conta: outro aparelho mostra os mesmos avisos como não lidos.
- **Economia de dados** agora é gravada e compartilhada, mas **ainda não altera a sincronização**: detectar Wi-Fi exige outro recurso nativo, previsto para uma etapa futura.
- **iOS não foi executado** (o desenvolvimento é em Windows). A configuração segue a documentação do plugin, mas só o Android foi compilado e testado.
- As limitações das etapas anteriores continuam: sem autenticação real, HTTP sem TLS em desenvolvimento e gravações offline não enfileiradas.

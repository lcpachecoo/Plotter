import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:plotter/data/plotter_crud.dart';
import 'package:plotter/main.dart';
import 'package:plotter/screens/cadastro_talhao_screen.dart';
import 'package:plotter/screens/notificacoes_screen.dart';
import 'package:plotter/screens/talhao_detail_screen.dart';
import 'package:plotter/state/lembretes.dart';
import 'package:plotter/state/preferencias.dart';
import 'package:plotter/widgets/registro_tile.dart';
import 'package:plotter/widgets/talhao_card.dart';

import 'canal_notificacoes_falso.dart';

/// Banco usado em cada teste: SQLite em memória, recriado do zero (com a
/// carga inicial) antes de cada caso para que um teste não afete o outro.
late PlotterCrud _crud;

/// Estado global da Etapa 7, também recriado a cada teste.
late Preferencias _preferencias;
late CanalNotificacoesFalso _canal;
late Lembretes _lembretes;

PlotterApp _app() => PlotterApp(
      crud: _crud,
      preferencias: _preferencias,
      lembretes: _lembretes,
    );

/// Ajusta a janela de teste para o tamanho de um celular, garantindo que o
/// mecanismo de navegação avaliado seja a barra inferior (em telas largas a
/// aplicação usa o menu lateral).
void _usarTelaDeCelular(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Percorre o fluxo de entrada até o Dashboard.
Future<void> _entrar(WidgetTester tester) async {
  await tester.pumpWidget(_app());
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    // Sem isolate: as operações do banco terminam dentro do relógio
    // simulado do `testWidgets`, sem precisar de `runAsync`.
    _crud = await PlotterCrud.abrir(
      factory: databaseFactoryFfiNoIsolate,
      caminho: inMemoryDatabasePath,
    );
    _preferencias = Preferencias.emMemoria();
    _canal = CanalNotificacoesFalso();
    _lembretes = Lembretes(
      canal: _canal,
      crud: _crud,
      preferencias: _preferencias,
    );
  });

  tearDown(() => _crud.fechar());

  testWidgets('Tela de login é exibida ao abrir o app', (tester) async {
    _usarTelaDeCelular(tester);
    await tester.pumpWidget(_app());

    expect(find.text('Plotter'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('Login navega até o Dashboard', (tester) async {
    _usarTelaDeCelular(tester);
    await _entrar(tester);

    expect(find.text('Meus Talhões'), findsOneWidget);
  });

  testWidgets('Barra inferior troca a seção exibida', (tester) async {
    _usarTelaDeCelular(tester);
    await _entrar(tester);

    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();

    final barra = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(barra.selectedIndex, 1);
  });

  testWidgets('Dashboard abre o detalhe do talhão e volta', (tester) async {
    _usarTelaDeCelular(tester);
    await _entrar(tester);

    await tester.tap(find.byType(TalhaoCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(TalhaoDetailScreen), findsOneWidget);

    // O rótulo do botão "voltar" vem traduzido pelo Material em pt-BR.
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(TalhaoDetailScreen), findsNothing);
    expect(find.text('Meus Talhões'), findsOneWidget);
  });

  testWidgets('Sino da barra superior abre as notificações', (tester) async {
    _usarTelaDeCelular(tester);
    await _entrar(tester);

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(NotificacoesScreen), findsOneWidget);
  });

  testWidgets('Cadastro de talhão retorna ao Dashboard com confirmação',
      (tester) async {
    _usarTelaDeCelular(tester);
    await _entrar(tester);

    await tester.tap(find.text('Novo talhão'));
    await tester.pumpAndSettle();
    expect(find.byType(CadastroTalhaoScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Talhão 09');
    await tester.enterText(find.byType(TextFormField).at(1), 'Soja');
    await tester.enterText(find.byType(TextFormField).at(2), '12.5');
    await tester.tap(find.text('Cadastrar talhão'));
    await tester.pumpAndSettle();

    expect(find.byType(CadastroTalhaoScreen), findsNothing);
    expect(find.text('Talhão cadastrado com sucesso.'), findsOneWidget);

    // O talhão foi gravado no banco e já aparece na lista do Dashboard.
    expect(_crud.talhoes.map((t) => t.nome), contains('Talhão 09'));
    expect(find.byType(TalhaoCard), findsNWidgets(_crud.talhoes.length));
    expect(find.text('Talhão 09'), findsOneWidget);
  });

  testWidgets('Edição de talhão atualiza o detalhe com o dado gravado',
      (tester) async {
    _usarTelaDeCelular(tester);
    await _entrar(tester);

    await tester.tap(find.byType(TalhaoCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar talhão'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'Feijão');
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    expect(find.byType(TalhaoDetailScreen), findsOneWidget);
    expect(find.text('Feijão'), findsOneWidget);
    expect(_crud.talhoes.first.cultura, 'Feijão');
  });

  testWidgets('Exclusão de talhão pede confirmação e remove do banco',
      (tester) async {
    _usarTelaDeCelular(tester);
    await _entrar(tester);
    final nome = _crud.talhoes.first.nome;

    await tester.tap(find.byType(TalhaoCard).first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Excluir talhão'), 300);
    await tester.tap(find.text('Excluir talhão'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir talhão?'), findsOneWidget);

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.byType(TalhaoDetailScreen), findsNothing);
    expect(find.text('Talhão "$nome" excluído.'), findsOneWidget);
    expect(_crud.talhoes.map((t) => t.nome), isNot(contains(nome)));
  });

  testWidgets('Histórico lista os registros gravados e permite excluir',
      (tester) async {
    _usarTelaDeCelular(tester);
    await _entrar(tester);
    final antes = _crud.registros.length;

    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();
    expect(find.byType(RegistroTile), findsWidgets);

    await tester.tap(find.descendant(
      of: find.byType(RegistroTile).first,
      matching: find.byIcon(Icons.more_vert),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Registro excluído.'), findsOneWidget);
    expect(_crud.registros.length, antes - 1);
  });

  testWidgets('Formulário pede confirmação antes de descartar alterações',
      (tester) async {
    _usarTelaDeCelular(tester);
    await _entrar(tester);

    await tester.tap(find.text('Novo talhão'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Talhão 10');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('Descartar alterações?'), findsOneWidget);

    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();
    expect(find.byType(CadastroTalhaoScreen), findsOneWidget);
  });

  group('Acessibilidade', () {
    testWidgets('Tela de login atende às diretrizes do Material', (tester) async {
      _usarTelaDeCelular(tester);
      await tester.pumpWidget(_app());

      // Tamanho mínimo dos alvos de toque, rótulos em elementos tocáveis e
      // contraste mínimo entre texto e fundo.
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('Dashboard atende às diretrizes de toque e rotulagem',
        (tester) async {
      _usarTelaDeCelular(tester);
      await _entrar(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });

  group('Estado global e lembretes (Etapa 7)', () {
    Future<void> abrirAjustes(WidgetTester tester) async {
      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('Lembretes de aplicações'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('ler as notificações zera o sino do Dashboard e continua valendo',
        (tester) async {
      _usarTelaDeCelular(tester);
      await _entrar(tester);

      final total = _crud.avisos.length;
      expect(total, greaterThan(0));
      expect(find.byTooltip('Notificações ($total não lidas)'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Marcar todas como lidas'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      // A tela de Notificações foi fechada, mas o estado é global: o
      // Dashboard já mostra o sino sem contador.
      expect(find.byTooltip('Notificações'), findsOneWidget);
      expect(_preferencias.naoLidos(_crud.avisos), 0);

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma notificação não lida'), findsOneWidget);
    });

    testWidgets('ligar os lembretes em Ajustes pede permissão e agenda',
        (tester) async {
      _usarTelaDeCelular(tester);
      await _lembretes.iniciar();
      await _entrar(tester);
      await abrirAjustes(tester);

      expect(find.text('Aviso no aparelho às 7h do dia de cada aplicação agendada'),
          findsOneWidget);

      await tester.tap(find.text('Lembretes de aplicações'));
      await tester.pumpAndSettle();

      expect(_canal.pedidosDePermissao, 1);
      expect(_canal.agendados, hasLength(_crud.agendadas.length));
      expect(_preferencias.lembretesAtivos, isTrue);
      expect(find.text('Ativos · 4 lembretes agendados para as 7h'), findsOneWidget);
      expect(find.textContaining('Lembretes ativados'), findsOneWidget);
    });

    testWidgets('permissão negada mantém desligado e oferece as configurações',
        (tester) async {
      _usarTelaDeCelular(tester);
      _canal.concedeAoPedir = false;
      await _lembretes.iniciar();
      await _entrar(tester);
      await abrirAjustes(tester);

      await tester.tap(find.text('Lembretes de aplicações'));
      await tester.pumpAndSettle();

      expect(_canal.agendados, isEmpty);
      expect(_preferencias.lembretesAtivos, isFalse);
      final interruptor = tester.widget<SwitchListTile>(find.ancestor(
        of: find.text('Lembretes de aplicações'),
        matching: find.byType(SwitchListTile),
      ));
      expect(interruptor.value, isFalse);
      expect(find.textContaining('Sem permissão'), findsOneWidget);

      await tester.tap(find.text('Configurações'));
      await tester.pumpAndSettle();
      expect(_canal.aberturasDasConfiguracoes, 1);
    });

    testWidgets('notificações bloqueadas no aparelho: aviso nas Notificações',
        (tester) async {
      _usarTelaDeCelular(tester);
      await _preferencias.definirLembretes(true); // escolhido antes...
      _canal.permissao = false; // ...e bloqueado depois, no sistema
      await _lembretes.iniciar();
      await _entrar(tester);

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.textContaining('estão bloqueadas no aparelho'), findsOneWidget);
      await tester.tap(find.text('Abrir configurações'));
      await tester.pumpAndSettle();
      expect(_canal.aberturasDasConfiguracoes, 1);
    });

    testWidgets('tocar em um lembrete abre o detalhe do talhão', (tester) async {
      _usarTelaDeCelular(tester);
      await _lembretes.iniciar();
      await _entrar(tester);

      _canal.tocar(_crud.agendadas.first.talhaoId);
      await tester.pumpAndSettle();

      expect(find.byType(TalhaoDetailScreen), findsOneWidget);
    });

    testWidgets('app aberto por um lembrete mostra o talhão logo após o login',
        (tester) async {
      _usarTelaDeCelular(tester);
      _canal.talhaoInicial = _crud.talhoes.first.id;
      await _lembretes.iniciar();

      await tester.pumpWidget(_app());
      expect(find.byType(TalhaoDetailScreen), findsNothing);

      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.byType(TalhaoDetailScreen), findsOneWidget);
    });

    testWidgets('aparelho sem notificações: interruptor desabilitado', (tester) async {
      _usarTelaDeCelular(tester);
      _canal.disponivel = false;
      await _lembretes.iniciar();
      await _entrar(tester);
      await abrirAjustes(tester);

      expect(find.text('Indisponível neste aparelho'), findsOneWidget);
      final interruptor = tester.widget<SwitchListTile>(find.ancestor(
        of: find.text('Lembretes de aplicações'),
        matching: find.byType(SwitchListTile),
      ));
      expect(interruptor.onChanged, isNull);
    });
  });
}

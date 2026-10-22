import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:plotter/data/plotter_crud.dart';
import 'package:plotter/main.dart';
import 'package:plotter/screens/cadastro_talhao_screen.dart';
import 'package:plotter/screens/notificacoes_screen.dart';
import 'package:plotter/screens/talhao_detail_screen.dart';
import 'package:plotter/widgets/registro_tile.dart';
import 'package:plotter/widgets/talhao_card.dart';

/// Banco usado em cada teste: SQLite em memória, recriado do zero (com a
/// carga inicial) antes de cada caso para que um teste não afete o outro.
late PlotterCrud _crud;

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
  await tester.pumpWidget(PlotterApp(crud: _crud));
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
  });

  tearDown(() => _crud.fechar());

  testWidgets('Tela de login é exibida ao abrir o app', (tester) async {
    _usarTelaDeCelular(tester);
    await tester.pumpWidget(PlotterApp(crud: _crud));

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
      await tester.pumpWidget(PlotterApp(crud: _crud));

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
}

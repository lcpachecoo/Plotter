import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plotter/main.dart';
import 'package:plotter/screens/cadastro_talhao_screen.dart';
import 'package:plotter/screens/notificacoes_screen.dart';
import 'package:plotter/screens/talhao_detail_screen.dart';
import 'package:plotter/widgets/talhao_card.dart';

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
  await tester.pumpWidget(const PlotterApp());
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Tela de login é exibida ao abrir o app', (tester) async {
    _usarTelaDeCelular(tester);
    await tester.pumpWidget(const PlotterApp());

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
      await tester.pumpWidget(const PlotterApp());

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

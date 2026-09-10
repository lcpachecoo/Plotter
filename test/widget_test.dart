import 'package:flutter_test/flutter_test.dart';

import 'package:plotter/main.dart';

void main() {
  testWidgets('Tela de login é exibida ao abrir o app', (WidgetTester tester) async {
    await tester.pumpWidget(const PlotterApp());

    expect(find.text('Plotter'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('Login navega até o Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const PlotterApp());

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Meus Talhões'), findsOneWidget);
  });
}

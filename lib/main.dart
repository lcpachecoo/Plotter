import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PlotterApp());
}

class PlotterApp extends StatelessWidget {
  const PlotterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plotter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,

      // Toda a navegação é feita por rotas nomeadas, declaradas em um único
      // arquivo (lib/routes/app_routes.dart).
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      onUnknownRoute: AppRoutes.onUnknownRoute,

      // Localização em português: rótulos padrão do Material (inclusive o
      // "Voltar" lido pelos leitores de tela e o seletor de datas) passam a
      // ser anunciados no idioma do usuário.
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          // A aplicação respeita o tamanho de fonte definido no sistema
          // (recurso essencial de acessibilidade), limitado a 1,8× para que
          // nenhuma tela quebre em ampliações extremas.
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.8,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/plotter_crud.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // O banco precisa ser aberto antes da primeira tela: assim os dados
  // gravados em execuções anteriores já estão carregados quando o app abre.
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final crud = await PlotterCrud.abrir();
    runApp(PlotterApp(crud: crud));
  } catch (_) {
    // Sem o banco o aplicativo não tem o que mostrar: em vez de fechar sem
    // explicação, exibe uma mensagem compreensível.
    runApp(const _FalhaAoAbrirDados());
  }
}

class PlotterApp extends StatelessWidget {
  final PlotterCrud crud;

  const PlotterApp({super.key, required this.crud});

  @override
  Widget build(BuildContext context) {
    // O escopo fica acima do MaterialApp para que todas as rotas, inclusive
    // as empilhadas, enxerguem os mesmos dados.
    return PlotterCrudScope(
      crud: crud,
      child: _app(),
    );
  }

  Widget _app() {
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

class _FalhaAoAbrirDados extends StatelessWidget {
  const _FalhaAoAbrirDados();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plotter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Não foi possível abrir os dados salvos no aparelho. '
                'Feche o Plotter e abra-o novamente. Se o problema continuar, '
                'verifique se há espaço livre no armazenamento.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

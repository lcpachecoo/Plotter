import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/plotter_api.dart';
import 'data/plotter_crud.dart';
import 'routes/app_routes.dart';
import 'services/notificacoes_locais.dart';
import 'state/lembretes.dart';
import 'state/preferencias.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // O banco precisa ser aberto antes da primeira tela: assim os dados
  // gravados em execuções anteriores já estão carregados quando o app abre.
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Etapa 5: os dados vêm do backend. A carga de exemplo agora fica no
    // servidor (`npm run seed`), por isso o banco local nasce vazio.
    final crud = await PlotterCrud.abrir(
      api: PlotterApi(),
      popularDadosIniciais: false,
    );

    // Etapa 7: estado global das preferências (gravado no aparelho) e
    // lembretes de aplicações pelas notificações do sistema.
    final preferencias = await Preferencias.carregar();
    final lembretes = Lembretes(
      canal: NotificacoesLocais(),
      crud: crud,
      preferencias: preferencias,
    );

    runApp(PlotterApp(
      crud: crud,
      preferencias: preferencias,
      lembretes: lembretes,
    ));

    // O recurso nativo é preparado depois que a primeira tela já apareceu.
    // Se o aparelho não oferecer notificações, os lembretes ficam
    // "indisponíveis" e o resto do app funciona normalmente.
    lembretes.iniciar();

    // A sincronização inicial não segura a abertura do app: enquanto ela
    // acontece (ou se o servidor estiver fora do ar) as telas mostram a
    // cópia local, e o Dashboard avisa quando não há conexão.
    crud.sincronizar().catchError((Object _) {});
  } catch (_) {
    // Sem o banco o aplicativo não tem o que mostrar: em vez de fechar sem
    // explicação, exibe uma mensagem compreensível.
    runApp(const _FalhaAoAbrirDados());
  }
}

class PlotterApp extends StatelessWidget {
  final PlotterCrud crud;
  final Preferencias preferencias;
  final Lembretes lembretes;

  const PlotterApp({
    super.key,
    required this.crud,
    required this.preferencias,
    required this.lembretes,
  });

  @override
  Widget build(BuildContext context) {
    // Estado global: os escopos ficam acima do MaterialApp, então todas as
    // rotas, inclusive as empilhadas, enxergam os mesmos objetos. Cada tela
    // que lê um deles com `of` é reconstruída quando ele muda.
    //   * PlotterCrudScope   → talhões, registros e status do servidor
    //   * PreferenciasScope  → lembretes ligados, economia de dados e avisos lidos
    //   * LembretesScope     → situação das notificações do sistema
    return PlotterCrudScope(
      crud: crud,
      child: PreferenciasScope(
        preferencias: preferencias,
        child: LembretesScope(
          lembretes: lembretes,
          child: _app(),
        ),
      ),
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

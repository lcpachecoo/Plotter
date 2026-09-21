import 'package:flutter/material.dart';

import '../models/talhao.dart';
import '../screens/ajuda_screen.dart';
import '../screens/cadastro_talhao_screen.dart';
import '../screens/home_shell.dart';
import '../screens/login_screen.dart';
import '../screens/notificacoes_screen.dart';
import '../screens/novo_registro_screen.dart';
import '../screens/talhao_detail_screen.dart';

/// Mapa central de rotas nomeadas da aplicação.
///
/// Toda a navegação passa por aqui: as telas não instanciam umas às outras
/// diretamente, o que mantém o fluxo em um único lugar, dá um nome legível a
/// cada rota (usado também pelos leitores de tela ao anunciar a mudança de
/// tela) e permite validar os argumentos recebidos.
class AppRoutes {
  AppRoutes._();

  static const String login = '/';
  static const String home = '/home';
  static const String talhaoDetalhe = '/talhao/detalhe';
  static const String talhaoFormulario = '/talhao/formulario';
  static const String novoRegistro = '/registro/novo';
  static const String notificacoes = '/notificacoes';
  static const String ajuda = '/ajuda';

  /// Título legível de cada rota, anunciado por leitores de tela quando a
  /// tela entra em foco e exibido na barra superior.
  static const Map<String, String> titulos = {
    login: 'Entrar no Plotter',
    home: 'Início',
    talhaoDetalhe: 'Detalhes do talhão',
    talhaoFormulario: 'Cadastro de talhão',
    novoRegistro: 'Novo registro de aplicação',
    notificacoes: 'Notificações',
    ajuda: 'Ajuda e acessibilidade',
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case login:
        return _rota(const LoginScreen(), settings);

      case home:
        return _rota(
          HomeShell(abaInicial: args is HomeTab ? args : HomeTab.dashboard),
          settings,
        );

      case talhaoDetalhe:
        if (args is! Talhao) return null;
        return _rota(TalhaoDetailScreen(talhao: args), settings);

      case talhaoFormulario:
        // Sem argumento a tela funciona como cadastro; com um [Talhao],
        // como edição do talhão informado.
        return _rota(
          CadastroTalhaoScreen(talhao: args is Talhao ? args : null),
          settings,
        );

      case novoRegistro:
        return _rota(
          NovoRegistroScreen(talhao: args is Talhao ? args : null),
          settings,
        );

      case notificacoes:
        return _rota(const NotificacoesScreen(), settings);

      case ajuda:
        return _rota(const AjudaScreen(), settings);
    }

    return null;
  }

  /// Rota exibida quando um nome desconhecido é solicitado: em vez de uma
  /// tela preta, o usuário recebe uma mensagem compreensível e um caminho
  /// de volta ao início.
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return _rota(_RotaNaoEncontradaScreen(rota: settings.name), settings);
  }

  static MaterialPageRoute<dynamic> _rota(Widget tela, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(builder: (_) => tela, settings: settings);
  }
}

class _RotaNaoEncontradaScreen extends StatelessWidget {
  final String? rota;

  const _RotaNaoEncontradaScreen({this.rota});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tela não encontrada')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'Não foi possível abrir esta tela${rota == null ? '' : ' ($rota)'}.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.home, (r) => false),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import 'configuracoes_screen.dart';
import 'dashboard_screen.dart';
import 'historico_screen.dart';
import 'relatorios_screen.dart';

/// As quatro seções de topo da aplicação, acessíveis a qualquer momento
/// pelo mecanismo de navegação principal.
enum HomeTab {
  dashboard(
    label: 'Talhões',
    icone: Icons.dashboard_outlined,
    iconeSelecionado: Icons.dashboard,
    descricao: 'Visão geral dos talhões da fazenda',
  ),
  historico(
    label: 'Histórico',
    icone: Icons.history_outlined,
    iconeSelecionado: Icons.history,
    descricao: 'Aplicações realizadas e agendadas',
  ),
  relatorios(
    label: 'Relatórios',
    icone: Icons.bar_chart_outlined,
    iconeSelecionado: Icons.bar_chart,
    descricao: 'Indicadores consolidados da fazenda',
  ),
  configuracoes(
    label: 'Ajustes',
    icone: Icons.settings_outlined,
    iconeSelecionado: Icons.settings,
    descricao: 'Conta, sincronização e preferências',
  );

  const HomeTab({
    required this.label,
    required this.icone,
    required this.iconeSelecionado,
    required this.descricao,
  });

  final String label;
  final IconData icone;
  final IconData iconeSelecionado;
  final String descricao;
}

/// Permite que qualquer tela interna troque a aba ativa da casca de
/// navegação (por exemplo, o atalho "ver histórico" do Dashboard) sem
/// empilhar uma nova rota.
class HomeShellScope extends InheritedWidget {
  final HomeTab abaAtual;
  final void Function(HomeTab aba) irPara;

  const HomeShellScope({
    super.key,
    required this.abaAtual,
    required this.irPara,
    required super.child,
  });

  static HomeShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeShellScope>();

  @override
  bool updateShouldNotify(HomeShellScope oldWidget) =>
      oldWidget.abaAtual != abaAtual;
}

/// Casca de navegação principal, compartilhada pelas quatro telas de topo.
///
/// O mecanismo de navegação se adapta à largura disponível:
/// * celular: barra inferior (`NavigationBar`), na zona de alcance do polegar;
/// * tablet: menu lateral compacto (`NavigationRail`);
/// * telas largas: o mesmo menu lateral estendido, com rótulos sempre visíveis.
///
/// Em todos os casos a aba ativa é destacada e o estado de cada tela é
/// preservado por um `IndexedStack`, de modo que voltar a uma aba não perde
/// a rolagem nem os filtros aplicados.
class HomeShell extends StatefulWidget {
  final HomeTab abaInicial;

  const HomeShell({super.key, this.abaInicial = HomeTab.dashboard});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late HomeTab _aba = widget.abaInicial;

  static const _telas = [
    DashboardScreen(),
    HistoricoScreen(),
    RelatoriosScreen(),
    ConfiguracoesScreen(),
  ];

  void _irPara(HomeTab aba) {
    if (aba == _aba) return;
    setState(() => _aba = aba);
    // A troca de aba é uma mudança puramente visual; o anúncio garante que
    // quem usa leitor de tela perceba onde está.
    AppFeedback.anunciar(context, '${aba.label}. ${aba.descricao}');
  }

  void _onSelecionarIndice(int indice) => _irPara(HomeTab.values[indice]);

  /// Botão físico/gestual "voltar": primeiro retorna à aba inicial; já no
  /// Dashboard, pede confirmação antes de fechar o aplicativo, evitando a
  /// saída acidental durante um trabalho em campo.
  Future<void> _aoVoltar(bool didPop, Object? resultado) async {
    if (didPop) return;

    if (_aba != HomeTab.dashboard) {
      _irPara(HomeTab.dashboard);
      return;
    }

    final sair = await AppFeedback.confirmar(
      context,
      titulo: 'Fechar o Plotter?',
      mensagem: 'Você voltará para a tela inicial do aparelho.',
      confirmarLabel: 'Fechar',
      cancelarLabel: 'Continuar no app',
    );

    if (sair) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final usaMenuLateral = largura >= AppBreakpoints.tablet;
    final menuEstendido = largura >= AppBreakpoints.desktop;

    // Cada seção recebe o próprio ScaffoldMessenger: assim as mensagens de
    // uma tela aparecem ancoradas ao Scaffold dela — acima do botão
    // flutuante, sem encobri-lo — e somem junto com a seção ao trocar de aba.
    final conteudo = IndexedStack(
      index: _aba.index,
      children: [
        for (final tela in _telas) ScaffoldMessenger(child: tela),
      ],
    );

    return HomeShellScope(
      abaAtual: _aba,
      irPara: _irPara,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: _aoVoltar,
        child: usaMenuLateral
            ? Scaffold(
                body: Row(
                  children: [
                    _MenuLateral(
                      aba: _aba,
                      estendido: menuEstendido,
                      onSelecionar: _onSelecionarIndice,
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: conteudo),
                  ],
                ),
              )
            : Scaffold(
                body: conteudo,
                bottomNavigationBar: _BarraInferior(
                  aba: _aba,
                  onSelecionar: _onSelecionarIndice,
                ),
              ),
      ),
    );
  }
}

/// Barra de navegação inferior usada em telas estreitas. Fica na borda
/// inferior — área de mais fácil alcance com o polegar — e cada destino
/// ocupa toda a altura de 72 dp, formando um alvo grande (Lei de Fitts).
class _BarraInferior extends StatelessWidget {
  final HomeTab aba;
  final ValueChanged<int> onSelecionar;

  const _BarraInferior({required this.aba, required this.onSelecionar});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: aba.index,
      onDestinationSelected: onSelecionar,
      destinations: [
        for (final destino in HomeTab.values)
          NavigationDestination(
            icon: Icon(destino.icone),
            selectedIcon: Icon(destino.iconeSelecionado),
            label: destino.label,
            // Lido pelo leitor de tela junto do rótulo, explicando o que o
            // destino contém antes de o usuário abri-lo.
            tooltip: destino.descricao,
          ),
      ],
    );
  }
}

/// Menu lateral usado em tablets e telas largas. Em telas muito largas ele
/// aparece estendido (ícone + rótulo lado a lado) e traz os atalhos de
/// notificações e ajuda no rodapé.
class _MenuLateral extends StatelessWidget {
  final HomeTab aba;
  final bool estendido;
  final ValueChanged<int> onSelecionar;

  const _MenuLateral({
    required this.aba,
    required this.estendido,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: aba.index,
      onDestinationSelected: onSelecionar,
      extended: estendido,
      labelType: estendido ? null : NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.grass_rounded, color: AppTheme.primaryGreen, size: 32),
            if (estendido) ...[
              const SizedBox(width: 12),
              Text('Plotter', style: Theme.of(context).textTheme.titleLarge),
            ],
          ],
        ),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Notificações',
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.notificacoes),
                  icon: const Icon(Icons.notifications_outlined),
                ),
                IconButton(
                  tooltip: 'Ajuda e acessibilidade',
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.ajuda),
                  icon: const Icon(Icons.help_outline),
                ),
              ],
            ),
          ),
        ),
      ),
      destinations: [
        for (final destino in HomeTab.values)
          NavigationRailDestination(
            icon: Icon(destino.icone),
            selectedIcon: Icon(destino.iconeSelecionado),
            label: Text(destino.label),
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'configuracoes_screen.dart';
import 'dashboard_screen.dart';
import 'historico_screen.dart';
import 'relatorios_screen.dart';

/// Casca de navegação principal, compartilhada pelas quatro telas de topo
/// (Dashboard, Histórico, Relatórios e Configurações).
///
/// Adapta-se ao tamanho da tela: em telas estreitas usa uma barra de
/// navegação inferior; em telas largas (tablet/desktop) usa um menu lateral
/// (NavigationRail), aproveitando melhor o espaço horizontal.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    HistoricoScreen(),
    RelatoriosScreen(),
    ConfiguracoesScreen(),
  ];

  static const _destinations = [
    (icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Dashboard'),
    (icon: Icons.history_outlined, selectedIcon: Icons.history, label: 'Histórico'),
    (icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: 'Relatórios'),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Config.'),
  ];

  void _onSelect(int value) => setState(() => _index = value);

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _onSelect,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Icon(Icons.grass_rounded, color: AppTheme.primaryGreen, size: 32),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: IndexedStack(index: _index, children: _screens)),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onSelect,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

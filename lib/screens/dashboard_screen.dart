import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/talhao.dart';
import '../theme/app_theme.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';
import '../widgets/talhao_card.dart';
import 'cadastro_talhao_screen.dart';
import 'talhao_detail_screen.dart';

/// Tela Dashboard (Home): visão geral dos talhões ativos da fazenda.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final talhoes = MockData.talhoes;
    final pendentes = talhoes.where((t) => t.status == TalhaoStatus.pendente).length;
    final emDia = talhoes.where((t) => t.status == TalhaoStatus.feito).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Talhões'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificações',
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard_fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CadastroTalhaoScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo talhão'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= AppBreakpoints.tablet;
          final crossAxisCount = isWide
              ? (constraints.maxWidth >= AppBreakpoints.desktop ? 3 : 2)
              : 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Painel de status (feito vs. pendente) responsivo: empilha em
                // telas estreitas e fica lado a lado em telas largas.
                isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              label: 'Talhões em dia',
                              value: '$emDia',
                              icon: Icons.check_circle_outline,
                              color: AppTheme.doneGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatTile(
                              label: 'Talhões pendentes',
                              value: '$pendentes',
                              icon: Icons.warning_amber_rounded,
                              color: AppTheme.pendingOrange,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          StatTile(
                            label: 'Talhões em dia',
                            value: '$emDia',
                            icon: Icons.check_circle_outline,
                            color: AppTheme.doneGreen,
                          ),
                          const SizedBox(height: 12),
                          StatTile(
                            label: 'Talhões pendentes',
                            value: '$pendentes',
                            icon: Icons.warning_amber_rounded,
                            color: AppTheme.pendingOrange,
                          ),
                        ],
                      ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Talhões ativos'),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: talhoes.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: 172,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final talhao = talhoes[index];
                    return TalhaoCard(
                      talhao: talhao,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TalhaoDetailScreen(talhao: talhao),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/talhao.dart';
import '../theme/app_theme.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';

/// Tela de Relatórios/Indicadores: visão consolidada da fazenda, voltada
/// ao gerente, com médias e indicadores gerais de manejo.
class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final talhoes = MockData.talhoes;
    final areaTotal = talhoes.fold<double>(0, (sum, t) => sum + t.areaHa);
    final emDia = talhoes.where((t) => t.status == TalhaoStatus.feito).length;
    final pendentes = talhoes.where((t) => t.status == TalhaoStatus.pendente).length;
    final agendados = talhoes.where((t) => t.status == TalhaoStatus.agendado).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= AppBreakpoints.tablet;
          final crossAxisCount = isWide ? 2 : 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Indicadores gerais'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 3.2 : 3.6,
                  children: [
                    StatTile(
                      label: 'Área total monitorada',
                      value: '${areaTotal.toStringAsFixed(1)} ha',
                      icon: Icons.map_outlined,
                      color: AppTheme.earthBrown,
                    ),
                    StatTile(
                      label: 'Talhões cadastrados',
                      value: '${talhoes.length}',
                      icon: Icons.grid_view_outlined,
                      color: AppTheme.primaryGreen,
                    ),
                    StatTile(
                      label: 'Em dia',
                      value: '$emDia',
                      icon: Icons.check_circle_outline,
                      color: AppTheme.doneGreen,
                    ),
                    StatTile(
                      label: 'Pendentes',
                      value: '$pendentes',
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.pendingOrange,
                    ),
                    StatTile(
                      label: 'Agendados',
                      value: '$agendados',
                      icon: Icons.schedule,
                      color: AppTheme.scheduledBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Status por talhão'),
                const SizedBox(height: 12),
                ...talhoes.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(t.nome, overflow: TextOverflow.ellipsis),
                            ),
                            Text(
                              t.status.label,
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

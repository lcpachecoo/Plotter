import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/talhao.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';
import '../widgets/status_badge.dart';
import 'home_shell.dart';

/// Tela de Relatórios/Indicadores: visão consolidada da fazenda, voltada
/// ao gerente, com médias e indicadores gerais de manejo.
///
/// Cada linha de "status por talhão" é um atalho para o detalhe do talhão,
/// mantendo a navegação conectada entre as seções.
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
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(
            tooltip: 'Ajuda e acessibilidade',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.ajuda),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= AppBreakpoints.tablet;
          final crossAxisCount = isWide ? 2 : 1;
          final escala = MediaQuery.textScalerOf(context).scale(16) / 16;

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
                  // A altura do cartão cresce junto com a fonte do sistema.
                  mainAxisExtent: 92 * escala,
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
                const SizedBox(height: 28),
                const SectionHeader(title: 'Distribuição das situações'),
                const SizedBox(height: 12),
                _Barra(
                  rotulo: 'Em dia',
                  quantidade: emDia,
                  total: talhoes.length,
                  cor: AppTheme.doneGreen,
                ),
                const SizedBox(height: 12),
                _Barra(
                  rotulo: 'Pendentes',
                  quantidade: pendentes,
                  total: talhoes.length,
                  cor: AppTheme.pendingOrange,
                ),
                const SizedBox(height: 12),
                _Barra(
                  rotulo: 'Agendados',
                  quantidade: agendados,
                  total: talhoes.length,
                  cor: AppTheme.scheduledBlue,
                ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Status por talhão',
                  actionLabel: 'Ver talhões',
                  actionIcon: Icons.dashboard_outlined,
                  onAction: () =>
                      HomeShellScope.maybeOf(context)?.irPara(HomeTab.dashboard),
                ),
                const SizedBox(height: 12),
                ...talhoes.map(
                  (talhao) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        title: Text(talhao.nome, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${talhao.cultura} · ${talhao.areaHa.toStringAsFixed(1)} ha',
                        ),
                        trailing: StatusBadge(status: talhao.status),
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.talhaoDetalhe,
                          arguments: talhao,
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

/// Barra de proporção com rótulo e valor sempre visíveis em texto: o
/// gráfico complementa a informação, mas nunca é a única forma de lê-la.
class _Barra extends StatelessWidget {
  final String rotulo;
  final int quantidade;
  final int total;
  final Color cor;

  const _Barra({
    required this.rotulo,
    required this.quantidade,
    required this.total,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final proporcao = total == 0 ? 0.0 : quantidade / total;
    final percentual = (proporcao * 100).round();

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(rotulo, style: Theme.of(context).textTheme.bodyMedium),
              ),
              Text(
                '$quantidade de $total ($percentual%)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: proporcao,
              minHeight: 12,
              backgroundColor: AppTheme.outline.withValues(alpha: 0.5),
              color: cor,
              // O valor já é descrito no texto acima; o indicador em si
              // não precisa ser lido outra vez.
              semanticsLabel: rotulo,
              semanticsValue: '$percentual por cento',
            ),
          ),
        ],
      ),
    );
  }
}

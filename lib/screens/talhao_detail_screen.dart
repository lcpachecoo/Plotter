import 'package:flutter/material.dart';

import '../models/talhao.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_badge.dart';
import 'novo_registro_screen.dart';

/// Tela de detalhes do talhão: cultura, estágio e último manejo realizado.
class TalhaoDetailScreen extends StatelessWidget {
  final Talhao talhao;

  const TalhaoDetailScreen({super.key, required this.talhao});

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);

    return Scaffold(
      appBar: AppBar(title: Text(talhao.nome)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 700 : double.infinity),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          talhao.cultura,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      StatusBadge(status: talhao.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${talhao.areaHa.toStringAsFixed(1)} hectares',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  _InfoCard(
                    icon: Icons.eco_outlined,
                    title: 'Estágio atual',
                    value: talhao.estagio,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.history,
                    title: 'Última aplicação',
                    value: talhao.ultimaAplicacao,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.event_available,
                    title: 'Próxima aplicação',
                    value: talhao.proximaAplicacao,
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: isWide ? 240 : double.infinity,
                        child: PrimaryButton(
                          label: 'Novo registro',
                          icon: Icons.add_task,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NovoRegistroScreen(talhao: talhao),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 240 : double.infinity,
                        child: PrimaryButton(
                          label: 'Editar talhão',
                          icon: Icons.edit_outlined,
                          outlined: true,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

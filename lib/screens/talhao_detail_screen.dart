import 'package:flutter/material.dart';

import '../models/talhao.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_badge.dart';

/// Tela de detalhes do talhão: cultura, estágio e último manejo realizado.
///
/// É uma tela secundária, sempre empilhada sobre uma das seções principais.
/// O retorno acontece pela seta da barra superior, pelo gesto/botão "voltar"
/// do aparelho ou automaticamente ao concluir uma das ações desta tela.
class TalhaoDetailScreen extends StatelessWidget {
  final Talhao talhao;

  const TalhaoDetailScreen({super.key, required this.talhao});

  Future<void> _novoRegistro(BuildContext context) async {
    final salvou = await Navigator.of(context)
        .pushNamed<Object?>(AppRoutes.novoRegistro, arguments: talhao);

    if (!context.mounted || salvou != true) return;
    AppFeedback.sucesso(context, 'Registro salvo para ${talhao.nome}.');
  }

  Future<void> _editar(BuildContext context) async {
    final salvou = await Navigator.of(context)
        .pushNamed<Object?>(AppRoutes.talhaoFormulario, arguments: talhao);

    if (!context.mounted || salvou != true) return;
    AppFeedback.sucesso(context, 'Talhão atualizado com sucesso.');
  }

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(talhao.nome),
        actions: [
          IconButton(
            tooltip: 'Editar talhão',
            onPressed: () => _editar(context),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 700 : double.infinity),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            talhao.cultura,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge(status: talhao.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${talhao.areaHa.toStringAsFixed(1)} hectares',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
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
                  // Ações do talhão: a principal (lançar aplicação) vem
                  // primeiro e em destaque; a secundária, contornada.
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: isWide ? 260 : double.infinity,
                        child: PrimaryButton(
                          label: 'Novo registro',
                          icon: Icons.add_task,
                          dica: 'Lança uma aplicação neste talhão',
                          onPressed: () => _novoRegistro(context),
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 260 : double.infinity,
                        child: PrimaryButton(
                          label: 'Editar talhão',
                          icon: Icons.edit_outlined,
                          outlined: true,
                          dica: 'Altera cultura, área ou pivô associado',
                          onPressed: () => _editar(context),
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
    // Rótulo e valor são lidos juntos ("Estágio atual: Floração"), em vez de
    // duas frases desconexas.
    return MergeSemantics(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(icon, color: AppTheme.primaryGreen, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/talhao.dart';
import '../theme/app_theme.dart';

/// Selo colorido reutilizado em cards, listas e telas de detalhe para
/// indicar rapidamente a situação de um talhão.
///
/// A situação nunca é comunicada só pela cor: o selo combina cor, ícone e
/// texto, atendendo a quem não distingue cores (daltonismo) e a quem usa
/// leitor de tela.
class StatusBadge extends StatelessWidget {
  final TalhaoStatus status;

  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case TalhaoStatus.feito:
        return AppTheme.doneGreen;
      case TalhaoStatus.pendente:
        return AppTheme.pendingOrange;
      case TalhaoStatus.agendado:
        return AppTheme.scheduledBlue;
    }
  }

  IconData get _icon {
    switch (status) {
      case TalhaoStatus.feito:
        return Icons.check_circle;
      case TalhaoStatus.pendente:
        return Icons.warning_rounded;
      case TalhaoStatus.agendado:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Situação: ${status.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 16, color: _color),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

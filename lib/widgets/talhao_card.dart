import 'package:flutter/material.dart';

import '../models/talhao.dart';
import 'status_badge.dart';

/// Card reutilizado no Dashboard e em outras listagens para resumir um
/// talhão. Recebe um [onTap] para permitir navegação até o detalhe.
class TalhaoCard extends StatelessWidget {
  final Talhao talhao;
  final VoidCallback? onTap;

  const TalhaoCard({super.key, required this.talhao, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      talhao.nome,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(status: talhao.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${talhao.cultura} · ${talhao.areaHa.toStringAsFixed(1)} ha',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                talhao.estagio,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.black45),
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.event_available, size: 16, color: Colors.black45),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Próxima: ${talhao.proximaAplicacao}',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

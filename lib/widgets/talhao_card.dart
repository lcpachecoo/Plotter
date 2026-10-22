import 'package:flutter/material.dart';

import '../models/talhao.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// Card reutilizado no Dashboard e em outras listagens para resumir um
/// talhão. Recebe um [onTap] para permitir navegação até o detalhe e o
/// resumo da [proximaAplicacao], calculado a partir dos registros gravados.
///
/// O cartão inteiro é a área clicável — e não apenas um pequeno botão
/// "abrir" —, o que torna o alvo muito maior (Lei de Fitts). Para leitores
/// de tela ele é anunciado como um único botão, com todas as informações
/// resumidas em uma frase.
class TalhaoCard extends StatelessWidget {
  final Talhao talhao;
  final String proximaAplicacao;
  final VoidCallback? onTap;

  const TalhaoCard({
    super.key,
    required this.talhao,
    required this.proximaAplicacao,
    this.onTap,
  });

  String get _descricaoAcessivel =>
      '${talhao.nome}. Cultura ${talhao.cultura}, '
      '${talhao.areaHa.toStringAsFixed(1)} hectares. '
      '${talhao.estagio.isEmpty ? '' : 'Estágio ${talhao.estagio}. '}'
      'Situação: ${talhao.status.label}. '
      'Próxima aplicação: $proximaAplicacao.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: onTap != null,
      label: _descricaoAcessivel,
      hint: onTap == null ? null : 'Abre os detalhes do talhão',
      onTap: onTap,
      excludeSemantics: true,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          // Realces de foco (teclado) e de toque usam a cor da marca, de
          // modo que o estado do componente fique sempre visível.
          focusColor: AppTheme.primaryGreen.withValues(alpha: 0.16),
          hoverColor: AppTheme.primaryGreen.withValues(alpha: 0.06),
          splashColor: AppTheme.lightGreen.withValues(alpha: 0.25),
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
                    const SizedBox(width: 8),
                    StatusBadge(status: talhao.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${talhao.cultura} · ${talhao.areaHa.toStringAsFixed(1)} ha',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  talhao.estagio.isEmpty ? 'Estágio não informado' : talhao.estagio,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.event_available,
                        size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Próxima: $proximaAplicacao',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

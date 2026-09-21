import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Cartão de indicador numérico reutilizado no Dashboard e em
/// Relatórios/Indicadores.
///
/// Quando recebe [onTap] vira um atalho de navegação (por exemplo, "talhões
/// pendentes" abre a lista já filtrada) e passa a ser anunciado como botão,
/// com o valor e o rótulo lidos em uma única frase.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  /// Marcação visual de "filtro ativo" quando o indicador é usado como
  /// atalho selecionável.
  final bool selecionado;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.selecionado = false,
  });

  @override
  Widget build(BuildContext context) {
    final conteudo = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            foregroundColor: color,
            child: Icon(icon, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              selecionado ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: selecionado ? color : AppTheme.textSecondary,
            ),
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      selected: onTap == null ? null : selecionado,
      label: '$label: $value',
      hint: onTap == null
          ? null
          : (selecionado ? 'Filtro ativo. Toque para remover' : 'Toque para filtrar'),
      onTap: onTap,
      excludeSemantics: true,
      child: Card(
        // O contorno verde indica, sem depender só da cor de fundo, qual
        // indicador está sendo usado como filtro.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: selecionado
              ? BorderSide(color: color, width: 2)
              : BorderSide.none,
        ),
        child: onTap == null
            ? conteudo
            : InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                focusColor: AppTheme.primaryGreen.withValues(alpha: 0.16),
                child: conteudo,
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Cabeçalho de seção reutilizado em várias telas para títulos com uma
/// ação opcional à direita (ex.: "ver tudo").
///
/// O título é marcado como cabeçalho (`header: true`), o que permite pular
/// de seção em seção com os gestos de navegação por cabeçalhos do TalkBack
/// e do VoiceOver.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton.icon(
            onPressed: onAction,
            icon: actionIcon == null ? null : Icon(actionIcon, size: 20),
            label: Text(actionLabel!),
          ),
      ],
    );
  }
}

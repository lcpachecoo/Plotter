import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/app_theme.dart';

/// Tipos de retorno visual dados ao usuário depois de uma ação.
enum FeedbackTipo { sucesso, erro, informacao }

/// Central de feedback da aplicação.
///
/// Toda confirmação, erro ou aviso passa por aqui para que a linguagem
/// visual seja a mesma em todas as telas (cor, ícone, duração) e para que a
/// mesma mensagem seja anunciada por leitores de tela — feedback visual e
/// feedback sonoro/tátil andam juntos.
class AppFeedback {
  AppFeedback._();

  static void sucesso(BuildContext context, String mensagem, {String? acaoLabel, VoidCallback? onAcao}) =>
      _mostrar(context, mensagem, FeedbackTipo.sucesso, acaoLabel, onAcao);

  static void erro(BuildContext context, String mensagem, {String? acaoLabel, VoidCallback? onAcao}) =>
      _mostrar(context, mensagem, FeedbackTipo.erro, acaoLabel, onAcao);

  static void informacao(BuildContext context, String mensagem, {String? acaoLabel, VoidCallback? onAcao}) =>
      _mostrar(context, mensagem, FeedbackTipo.informacao, acaoLabel, onAcao);

  /// Anuncia um texto diretamente ao leitor de tela, sem exibir nada.
  /// Usado em mudanças que são apenas visuais (troca de aba, filtro
  /// aplicado), que de outra forma passariam despercebidas.
  static void anunciar(BuildContext context, String mensagem) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      mensagem,
      TextDirection.ltr,
    );
  }

  static void _mostrar(
    BuildContext context,
    String mensagem,
    FeedbackTipo tipo,
    String? acaoLabel,
    VoidCallback? onAcao,
  ) {
    final (IconData icone, Color fundo, String prefixo) = switch (tipo) {
      FeedbackTipo.sucesso => (Icons.check_circle_outline, AppTheme.darkGreen, 'Sucesso'),
      FeedbackTipo.erro => (Icons.error_outline, AppTheme.dangerRed, 'Erro'),
      FeedbackTipo.informacao => (Icons.info_outline, const Color(0xFF26312A), 'Aviso'),
    };

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: fundo,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            // O ícone é decorativo: a mensagem de texto ao lado já carrega
            // todo o significado, então ele fica fora da árvore semântica.
            ExcludeSemantics(child: Icon(icone, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Text(mensagem)),
          ],
        ),
        action: acaoLabel == null
            ? null
            : SnackBarAction(
                label: acaoLabel,
                textColor: Colors.white,
                onPressed: onAcao ?? () {},
              ),
      ),
    );

    anunciar(context, '$prefixo. $mensagem');
  }

  /// Diálogo de confirmação usado antes de ações que o usuário não
  /// conseguiria desfazer (sair da conta, descartar um formulário).
  ///
  /// O botão de confirmação fica à direita e o de cancelamento à esquerda,
  /// e o foco inicial recai sobre a opção segura.
  static Future<bool> confirmar(
    BuildContext context, {
    required String titulo,
    required String mensagem,
    String confirmarLabel = 'Confirmar',
    String cancelarLabel = 'Cancelar',
    bool destrutivo = false,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          destrutivo ? Icons.warning_amber_rounded : Icons.help_outline,
          color: destrutivo ? AppTheme.dangerRed : AppTheme.primaryGreen,
          size: 32,
        ),
        title: Text(titulo),
        content: Text(mensagem),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelarLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: destrutivo ? AppTheme.dangerRed : AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(AppTheme.minTouchTarget, 48),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmarLabel),
          ),
        ],
      ),
    );

    return resultado ?? false;
  }
}

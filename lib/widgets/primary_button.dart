import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Botão de ação principal, reutilizado nas telas de login, formulários e
/// confirmações de ação.
///
/// Concentra três cuidados de UX/acessibilidade da Etapa 3:
/// * altura mínima de 52 dp e largura preenchida, formando um alvo grande e
///   fácil de acertar (Lei de Fitts);
/// * estado de carregamento visível (`loading`), que desabilita o toque e
///   evita envio duplicado;
/// * rótulo semântico com dica opcional, lido por leitores de tela.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// Versão secundária, apenas contornada, para ações de menor peso.
  final bool outlined;

  /// Enquanto verdadeiro, o botão mostra um indicador de progresso e não
  /// responde a toques.
  final bool loading;

  /// Ações destrutivas (sair, excluir) recebem a cor de alerta.
  final bool destrutivo;

  /// Texto adicional lido por leitores de tela e exibido como tooltip.
  final String? dica;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.outlined = false,
    this.loading = false,
    this.destrutivo = false,
    this.dica,
  });

  @override
  Widget build(BuildContext context) {
    final cor = destrutivo ? AppTheme.dangerRed : AppTheme.primaryGreen;
    final habilitado = onPressed != null && !loading;

    final conteudo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: outlined ? cor : Colors.white,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 22),
        if (loading || icon != null) const SizedBox(width: 10),
        Flexible(
          child: Text(
            loading ? 'Aguarde…' : label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final botao = outlined
        ? OutlinedButton(
            onPressed: habilitado ? onPressed : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: cor,
              side: BorderSide(color: cor, width: 1.5),
              minimumSize: const Size(AppTheme.minTouchTarget, 52),
            ),
            child: conteudo,
          )
        : ElevatedButton(
            onPressed: habilitado ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: cor,
              foregroundColor: Colors.white,
              minimumSize: const Size(AppTheme.minTouchTarget, 52),
            ),
            child: conteudo,
          );

    // O próprio botão já se anuncia como "<rótulo>, botão"; aqui apenas
    // acrescentamos a dica (ou o aviso de processamento) a esse anúncio.
    final semantico = Semantics(
      hint: loading ? 'Processando, aguarde' : dica,
      child: botao,
    );

    return dica == null ? semantico : Tooltip(message: dica!, child: semantico);
  }
}

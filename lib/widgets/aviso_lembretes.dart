import 'package:flutter/material.dart';

import '../state/lembretes.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';

/// Liga ou desliga os lembretes e mostra a mensagem certa para cada
/// resultado. Usado pelo interruptor de Ajustes e pela faixa da tela de
/// Notificações.
Future<void> alternarLembretes(BuildContext context, bool ativar) async {
  final lembretes = LembretesScope.read(context);

  if (!ativar) {
    await lembretes.desativar();
    if (!context.mounted) return;
    AppFeedback.informacao(
      context,
      'Lembretes desativados. Os avisos já agendados foram cancelados.',
    );
    return;
  }

  final resultado = await lembretes.ativar();
  if (!context.mounted) return;

  switch (resultado) {
    case ResultadoAtivacao.ativado:
      final n = lembretes.quantidade;
      AppFeedback.sucesso(
        context,
        n == 0
            ? 'Lembretes ativados. Você será avisado às ${Lembretes.horaDoLembrete}h '
                'do dia de cada aplicação que for agendada.'
            : 'Lembretes ativados: ${_plural(n, 'aplicação agendada vai', 'aplicações agendadas vão')} '
                'gerar um aviso às ${Lembretes.horaDoLembrete}h do dia.',
      );
    case ResultadoAtivacao.permissaoNegada:
      AppFeedback.erro(
        context,
        'Sem permissão, o Plotter não consegue enviar lembretes. Libere as '
        'notificações do Plotter nas configurações do aparelho.',
        acaoLabel: 'Configurações',
        onAcao: () => abrirConfiguracoesDeNotificacao(context),
      );
    case ResultadoAtivacao.indisponivel:
      AppFeedback.informacao(
        context,
        'Este aparelho não oferece notificações para o Plotter. O restante '
        'do aplicativo continua funcionando normalmente.',
      );
    case ResultadoAtivacao.falha:
      AppFeedback.erro(
        context,
        'Não foi possível agendar os lembretes. Tente de novo em instantes.',
      );
  }
}

/// Abre as configurações de notificação do sistema. Se o aparelho não
/// permitir, explica o caminho para chegar até elas.
Future<void> abrirConfiguracoesDeNotificacao(BuildContext context) async {
  final abriu = await LembretesScope.read(context).abrirConfiguracoes();
  if (abriu || !context.mounted) return;
  AppFeedback.erro(
    context,
    'Não foi possível abrir as configurações. Acesse Configurações > Apps > '
    'Plotter > Notificações e permita as notificações.',
  );
}

/// Texto curto com a situação dos lembretes (subtítulo do interruptor de
/// Ajustes).
String descricaoLembretes(Lembretes lembretes) {
  final hora = '${Lembretes.horaDoLembrete}h';
  return switch (lembretes.situacao) {
    SituacaoLembretes.verificando => 'Verificando as notificações do aparelho…',
    SituacaoLembretes.desativados =>
      'Aviso no aparelho às $hora do dia de cada aplicação agendada',
    SituacaoLembretes.ativos => lembretes.quantidade == 0
        ? 'Ativos · nenhuma aplicação agendada no momento'
        : 'Ativos · ${_plural(lembretes.quantidade, 'lembrete agendado', 'lembretes agendados')} para as $hora',
    SituacaoLembretes.semPermissao =>
      'Bloqueados: as notificações do Plotter estão desligadas no aparelho',
    SituacaoLembretes.falha => 'Não foi possível agendar os lembretes',
    SituacaoLembretes.indisponivel => 'Indisponível neste aparelho',
  };
}

String _plural(int n, String singular, String plural) =>
    '$n ${n == 1 ? singular : plural}';

/// Faixa da tela de Notificações que convida a ativar os lembretes ou
/// explica por que eles não estão funcionando. Some quando os lembretes
/// estão ativos (ou quando o aparelho não oferece o recurso).
class AvisoLembretes extends StatelessWidget {
  /// Espaço em volta da faixa, aplicado só quando ela está visível.
  final EdgeInsetsGeometry margem;

  const AvisoLembretes({super.key, this.margem = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final lembretes = LembretesScope.of(context);

    final (IconData, Color, String, String, VoidCallback)? conteudo =
        switch (lembretes.situacao) {
      SituacaoLembretes.desativados => (
          Icons.alarm_add_outlined,
          AppTheme.primaryGreen,
          'Receba um aviso no aparelho às ${Lembretes.horaDoLembrete}h do dia '
              'de cada aplicação agendada, mesmo com o app fechado.',
          'Ativar lembretes',
          () => alternarLembretes(context, true),
        ),
      SituacaoLembretes.semPermissao => (
          Icons.notifications_off_outlined,
          AppTheme.pendingOrange,
          'As notificações do Plotter estão bloqueadas no aparelho, então os '
              'lembretes não serão entregues.',
          'Abrir configurações',
          () => abrirConfiguracoesDeNotificacao(context),
        ),
      SituacaoLembretes.falha => (
          Icons.error_outline,
          AppTheme.dangerRed,
          'Não foi possível agendar os lembretes no aparelho.',
          'Tentar de novo',
          lembretes.tentarDeNovo,
        ),
      SituacaoLembretes.verificando ||
      SituacaoLembretes.ativos ||
      SituacaoLembretes.indisponivel =>
        null,
    };
    if (conteudo == null) return const SizedBox.shrink();
    final (icone, cor, texto, acao, onAcao) = conteudo;

    return Container(
      margin: margem,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Icon(icone, color: cor)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(texto, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onAcao, child: Text(acao)),
          ),
        ],
      ),
    );
  }
}

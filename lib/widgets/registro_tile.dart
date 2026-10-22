import 'package:flutter/material.dart';

import '../data/plotter_crud.dart';
import '../models/registro.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';

/// Item de lista de um registro de aplicação, reutilizado no Histórico e no
/// detalhe do talhão.
///
/// Concentra as ações sobre um registro gravado: tocar no item abre a
/// edição e o menu "Opções" oferece editar, abrir o talhão e excluir — esta
/// última sempre com confirmação, por ser irreversível.
class RegistroTile extends StatelessWidget {
  final Registro registro;

  /// Quando informado, o nome do talhão aparece no item e o menu ganha a
  /// opção "Ver talhão" (usado no Histórico, que mistura vários talhões).
  final String? talhaoNome;

  const RegistroTile({super.key, required this.registro, this.talhaoNome});

  static IconData iconeDoTipo(TipoInsumo tipo) {
    switch (tipo) {
      case TipoInsumo.defensivo:
        return Icons.bug_report_outlined;
      case TipoInsumo.fertilizante:
        return Icons.grass_outlined;
      case TipoInsumo.outro:
        return Icons.science_outlined;
    }
  }

  Future<void> _editar(BuildContext context) async {
    final salvou = await Navigator.of(context)
        .pushNamed<Object?>(AppRoutes.editarRegistro, arguments: registro);
    if (!context.mounted || salvou != true) return;
    AppFeedback.sucesso(context, 'Registro atualizado com sucesso.');
  }

  void _verTalhao(BuildContext context) {
    final talhao = PlotterCrudScope.read(context).buscarTalhao(registro.talhaoId);
    if (talhao == null) {
      AppFeedback.informacao(context, 'O talhão deste registro não está mais cadastrado.');
      return;
    }
    AppRoutes.abrirTalhao(context, talhao);
  }

  Future<void> _excluir(BuildContext context) async {
    final crud = PlotterCrudScope.read(context);
    final confirmado = await AppFeedback.confirmar(
      context,
      titulo: 'Excluir registro?',
      mensagem: 'A aplicação "${registro.insumo}" de ${registro.dataFormatada} '
          'será apagada do aparelho. Esta ação não pode ser desfeita.',
      confirmarLabel: 'Excluir',
      destrutivo: true,
    );
    if (!context.mounted || !confirmado) return;

    try {
      await crud.removerRegistro(registro.id!);
    } catch (_) {
      if (!context.mounted) return;
      AppFeedback.erro(context, 'Não foi possível excluir o registro. Tente novamente.');
      return;
    }
    if (!context.mounted) return;
    AppFeedback.sucesso(context, 'Registro excluído.');
  }

  @override
  Widget build(BuildContext context) {
    final agendado = registro.agendado;
    final cor = agendado ? AppTheme.scheduledBlue : AppTheme.primaryGreen;
    final detalhes = [
      registro.tipo.label,
      registro.quantidade,
      if (registro.responsavel.isNotEmpty) registro.responsavel,
    ].join(' · ');

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
        leading: CircleAvatar(
          backgroundColor: cor.withValues(alpha: 0.12),
          foregroundColor: cor,
          child: Icon(agendado ? Icons.schedule : iconeDoTipo(registro.tipo)),
        ),
        title: Text(
          registro.insumo,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            ?talhaoNome,
            '${agendado ? 'Agendada para' : 'Aplicada em'} ${registro.dataFormatada}',
            detalhes,
          ].join('\n'),
        ),
        isThreeLine: true,
        onTap: () => _editar(context),
        trailing: PopupMenuButton<String>(
          tooltip: 'Opções do registro ${registro.insumo}',
          icon: const Icon(Icons.more_vert),
          onSelected: (valor) {
            switch (valor) {
              case 'editar':
                _editar(context);
              case 'talhao':
                _verTalhao(context);
              case 'excluir':
                _excluir(context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'editar',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Editar registro'),
              ),
            ),
            if (talhaoNome != null)
              const PopupMenuItem(
                value: 'talhao',
                child: ListTile(
                  leading: Icon(Icons.crop_square),
                  title: Text('Ver talhão'),
                ),
              ),
            const PopupMenuItem(
              value: 'excluir',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: AppTheme.dangerRed),
                title: Text('Excluir registro',
                    style: TextStyle(color: AppTheme.dangerRed)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

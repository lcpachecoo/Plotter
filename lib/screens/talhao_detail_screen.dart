import 'package:flutter/material.dart';

import '../data/plotter_api.dart';
import '../data/plotter_crud.dart';
import '../models/talhao.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import '../widgets/primary_button.dart';
import '../widgets/registro_tile.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Tela de detalhes do talhão: cultura, estágio, último e próximo manejo e
/// os registros de aplicação do talhão.
///
/// Recebe apenas o id e lê o talhão do banco a cada reconstrução: ao voltar
/// da edição, a tela já mostra os dados atualizados.
///
/// É uma tela secundária, sempre empilhada sobre uma das seções principais.
/// O retorno acontece pela seta da barra superior, pelo gesto/botão "voltar"
/// do aparelho ou automaticamente ao excluir o talhão.
class TalhaoDetailScreen extends StatefulWidget {
  final int talhaoId;

  const TalhaoDetailScreen({super.key, required this.talhaoId});

  @override
  State<TalhaoDetailScreen> createState() => _TalhaoDetailScreenState();
}

class _TalhaoDetailScreenState extends State<TalhaoDetailScreen> {
  /// Último estado lido do talhão. Ao excluí-lo, o banco avisa a tela antes
  /// de ela terminar de fechar; mantê-lo evita que a animação de saída
  /// mostre a tela de "não encontrado".
  Talhao? _ultimoLido;
  bool _excluido = false;

  Future<void> _novoRegistro(BuildContext context, Talhao talhao) async {
    final salvou = await Navigator.of(context)
        .pushNamed<Object?>(AppRoutes.novoRegistro, arguments: talhao);

    if (!context.mounted || salvou != true) return;
    AppFeedback.sucesso(context, 'Registro salvo para ${talhao.nome}.');
  }

  Future<void> _editar(BuildContext context, Talhao talhao) async {
    final salvou = await Navigator.of(context)
        .pushNamed<Object?>(AppRoutes.talhaoFormulario, arguments: talhao);

    if (!context.mounted || salvou != true) return;
    AppFeedback.sucesso(context, 'Talhão atualizado com sucesso.');
  }

  Future<void> _excluir(BuildContext context, Talhao talhao) async {
    final crud = PlotterCrudScope.read(context);
    final quantidade = crud.registrosDoTalhao(talhao.id!).length;

    final confirmado = await AppFeedback.confirmar(
      context,
      titulo: 'Excluir talhão?',
      mensagem: quantidade == 0
          ? '"${talhao.nome}" será apagado. '
              'Esta ação não pode ser desfeita.'
          : '"${talhao.nome}" e os $quantidade registro(s) de aplicação dele '
              'serão apagados. Esta ação não pode ser desfeita.',
      confirmarLabel: 'Excluir',
      destrutivo: true,
    );
    if (!context.mounted || !confirmado) return;

    try {
      _excluido = true;
      await crud.removerTalhao(talhao.id!);
    } catch (erro) {
      _excluido = false;
      if (!context.mounted) return;
      AppFeedback.erro(
        context,
        mensagemDeErro(erro, 'Não foi possível excluir o talhão. Tente novamente.'),
      );
      return;
    }
    if (!context.mounted) return;
    // A mensagem é exibida pela tela de origem (`AppRoutes.abrirTalhao`),
    // já que esta tela deixa de existir.
    Navigator.of(context).pop('Talhão "${talhao.nome}" excluído.');
  }

  @override
  Widget build(BuildContext context) {
    final talhaoId = widget.talhaoId;
    final crud = PlotterCrudScope.of(context);
    final lido = crud.buscarTalhao(talhaoId);
    if (lido != null) _ultimoLido = lido;
    final talhao = lido ?? (_excluido ? _ultimoLido : null);
    if (talhao == null) return const _TalhaoNaoEncontrado();

    final registros = crud.registrosDoTalhao(talhaoId);
    final isWide = AppBreakpoints.isWide(context);
    final larguraBotao = isWide ? 260.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: Text(talhao.nome),
        actions: [
          IconButton(
            tooltip: 'Editar talhão',
            onPressed: () => _editar(context, talhao),
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
                    '${talhao.areaHa.toStringAsFixed(1)} hectares'
                    '${talhao.pivo.isEmpty ? '' : ' · ${talhao.pivo}'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  _InfoCard(
                    icon: Icons.eco_outlined,
                    title: 'Estágio atual',
                    value: talhao.estagio.isEmpty ? 'Não informado' : talhao.estagio,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.history,
                    title: 'Última aplicação',
                    value: crud.resumoUltimaAplicacao(talhaoId),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.event_available,
                    title: 'Próxima aplicação',
                    value: crud.resumoProximaAplicacao(talhaoId),
                  ),
                  const SizedBox(height: 28),
                  // Ações do talhão: a principal (lançar aplicação) vem
                  // primeiro e em destaque; a secundária, contornada; a
                  // destrutiva, em vermelho e por último.
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: larguraBotao,
                        child: PrimaryButton(
                          label: 'Novo registro',
                          icon: Icons.add_task,
                          dica: 'Lança uma aplicação neste talhão',
                          onPressed: () => _novoRegistro(context, talhao),
                        ),
                      ),
                      SizedBox(
                        width: larguraBotao,
                        child: PrimaryButton(
                          label: 'Editar talhão',
                          icon: Icons.edit_outlined,
                          outlined: true,
                          dica: 'Altera cultura, área ou pivô associado',
                          onPressed: () => _editar(context, talhao),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SectionHeader(title: 'Registros deste talhão (${registros.length})'),
                  const SizedBox(height: 12),
                  if (registros.isEmpty)
                    Text(
                      'Nenhuma aplicação lançada para este talhão.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    for (final registro in registros)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RegistroTile(registro: registro),
                      ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: larguraBotao,
                    child: PrimaryButton(
                      label: 'Excluir talhão',
                      icon: Icons.delete_outline,
                      outlined: true,
                      destrutivo: true,
                      dica: 'Apaga o talhão e todos os registros dele',
                      onPressed: () => _excluir(context, talhao),
                    ),
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

/// Exibida se o talhão deixar de existir no banco enquanto a rota está
/// aberta, em vez de uma tela quebrada.
class _TalhaoNaoEncontrado extends StatelessWidget {
  const _TalhaoNaoEncontrado();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Talhão não encontrado')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Este talhão não está mais cadastrado.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
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

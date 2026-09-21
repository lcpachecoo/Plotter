import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/registro.dart';
import '../models/talhao.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';

/// Tela de Histórico e Agenda.
///
/// Usa abas (`TabBar`) para separar dois conteúdos do mesmo assunto sem
/// exigir uma nova tela: o que já foi aplicado e o que está agendado. A aba
/// ativa é indicada por cor, peso da fonte e sublinhado, e a troca é
/// anunciada para leitores de tela.
class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this)..addListener(_aoTrocarAba);

  static const _titulos = ['Realizadas', 'Agendadas'];

  void _aoTrocarAba() {
    if (_tabController.indexIsChanging) return;
    AppFeedback.anunciar(
      context,
      'Aba ${_titulos[_tabController.index]} selecionada.',
    );
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_aoTrocarAba)
      ..dispose();
    super.dispose();
  }

  IconData _iconFor(TipoInsumo tipo) {
    switch (tipo) {
      case TipoInsumo.defensivo:
        return Icons.bug_report_outlined;
      case TipoInsumo.fertilizante:
        return Icons.grass_outlined;
      case TipoInsumo.outro:
        return Icons.science_outlined;
    }
  }

  /// Abre o talhão relacionado ao registro, permitindo ir do histórico ao
  /// detalhe sem passar pelo Dashboard.
  void _abrirTalhaoPorNome(String nome) {
    final encontrados =
        MockData.talhoes.where((t) => t.nome == nome).toList(growable: false);
    if (encontrados.isEmpty) {
      AppFeedback.informacao(context, 'Talhão "$nome" não está mais cadastrado.');
      return;
    }
    Navigator.of(context)
        .pushNamed(AppRoutes.talhaoDetalhe, arguments: encontrados.first);
  }

  Future<void> _novoRegistro() async {
    final salvou =
        await Navigator.of(context).pushNamed<Object?>(AppRoutes.novoRegistro);
    if (!mounted || salvou != true) return;
    AppFeedback.sucesso(context, 'Registro lançado no histórico.');
  }

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);
    final agendadas = MockData.talhoes
        .where((t) => t.status != TalhaoStatus.feito)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico e Agenda'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          tabs: [
            Tab(
              // Altura confortável para o toque, mesmo com a fonte ampliada.
              height: 52,
              icon: const Icon(Icons.check_circle_outline),
              text: _titulos[0],
            ),
            Tab(
              height: 52,
              icon: const Icon(Icons.event_outlined),
              text: _titulos[1],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'historico_fab',
        onPressed: _novoRegistro,
        icon: const Icon(Icons.add),
        label: const Text('Registro'),
        tooltip: 'Lançar uma nova aplicação',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 700 : double.infinity),
          child: TabBarView(
            controller: _tabController,
            children: [
              _ListaRealizadas(
                registros: MockData.registros,
                iconeDoTipo: _iconFor,
                onAbrirTalhao: _abrirTalhaoPorNome,
              ),
              _ListaAgendadas(
                talhoes: agendadas,
                onAbrirTalhao: (talhao) => Navigator.of(context)
                    .pushNamed(AppRoutes.talhaoDetalhe, arguments: talhao),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListaRealizadas extends StatelessWidget {
  final List<Registro> registros;
  final IconData Function(TipoInsumo) iconeDoTipo;
  final void Function(String nomeTalhao) onAbrirTalhao;

  const _ListaRealizadas({
    required this.registros,
    required this.iconeDoTipo,
    required this.onAbrirTalhao,
  });

  @override
  Widget build(BuildContext context) {
    if (registros.isEmpty) {
      return const _ListaVazia(
        icone: Icons.inbox_outlined,
        mensagem: 'Nenhuma aplicação registrada até agora.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: registros.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final registro = registros[index];
        return Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
              foregroundColor: AppTheme.primaryGreen,
              child: Icon(iconeDoTipo(registro.tipo)),
            ),
            title: Text(
              registro.insumo,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${registro.talhaoNome}\n'
              '${registro.tipo.label} · ${registro.quantidade} · ${registro.responsavel}',
            ),
            isThreeLine: true,
            trailing: Text(
              registro.data,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () => onAbrirTalhao(registro.talhaoNome),
          ),
        );
      },
    );
  }
}

class _ListaAgendadas extends StatelessWidget {
  final List<Talhao> talhoes;
  final void Function(Talhao talhao) onAbrirTalhao;

  const _ListaAgendadas({required this.talhoes, required this.onAbrirTalhao});

  @override
  Widget build(BuildContext context) {
    if (talhoes.isEmpty) {
      return const _ListaVazia(
        icone: Icons.event_available_outlined,
        mensagem: 'Nenhuma aplicação agendada. Tudo em dia!',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: talhoes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final talhao = talhoes[index];
        final pendente = talhao.status == TalhaoStatus.pendente;
        final cor = pendente ? AppTheme.pendingOrange : AppTheme.scheduledBlue;

        return Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: cor.withValues(alpha: 0.12),
              foregroundColor: cor,
              child: Icon(pendente ? Icons.warning_amber_rounded : Icons.schedule),
            ),
            title: Text(
              talhao.proximaAplicacao,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${talhao.nome}\nSituação: ${talhao.status.label}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onAbrirTalhao(talhao),
          ),
        );
      },
    );
  }
}

class _ListaVazia extends StatelessWidget {
  final IconData icone;
  final String mensagem;

  const _ListaVazia({required this.icone, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../data/plotter_crud.dart';
import '../models/registro.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import '../widgets/registro_tile.dart';

/// Tela de Histórico e Agenda.
///
/// Usa abas (`TabBar`) para separar dois conteúdos do mesmo assunto sem
/// exigir uma nova tela: o que já foi aplicado e o que está agendado. A aba
/// ativa é indicada por cor, peso da fonte e sublinhado, e a troca é
/// anunciada para leitores de tela.
///
/// As duas abas mostram os registros gravados no banco: data até hoje em
/// "Realizadas" e data futura em "Agendadas". Cada item pode ser editado ou
/// excluído pelo próprio item (`RegistroTile`).
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

  Future<void> _novoRegistro() async {
    final salvou =
        await Navigator.of(context).pushNamed<Object?>(AppRoutes.novoRegistro);
    if (!mounted || salvou != true) return;
    AppFeedback.sucesso(context, 'Registro lançado no histórico.');
  }

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);
    final crud = PlotterCrudScope.of(context);

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
              _ListaRegistros(
                registros: crud.realizadas,
                nomeDoTalhao: (id) => crud.buscarTalhao(id)?.nome ?? '',
                iconeVazio: Icons.inbox_outlined,
                mensagemVazia: 'Nenhuma aplicação registrada até agora.',
              ),
              _ListaRegistros(
                registros: crud.agendadas,
                nomeDoTalhao: (id) => crud.buscarTalhao(id)?.nome ?? '',
                iconeVazio: Icons.event_available_outlined,
                mensagemVazia: 'Nenhuma aplicação agendada. Para agendar, '
                    'lance um registro com data futura.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListaRegistros extends StatelessWidget {
  final List<Registro> registros;
  final String Function(int talhaoId) nomeDoTalhao;
  final IconData iconeVazio;
  final String mensagemVazia;

  const _ListaRegistros({
    required this.registros,
    required this.nomeDoTalhao,
    required this.iconeVazio,
    required this.mensagemVazia,
  });

  @override
  Widget build(BuildContext context) {
    if (registros.isEmpty) {
      return _ListaVazia(icone: iconeVazio, mensagem: mensagemVazia);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: registros.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final registro = registros[index];
        return RegistroTile(
          registro: registro,
          talhaoNome: nomeDoTalhao(registro.talhaoId),
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

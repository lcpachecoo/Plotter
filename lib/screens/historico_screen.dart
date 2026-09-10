import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/registro.dart';
import '../theme/app_theme.dart';
import '../widgets/section_header.dart';
import 'novo_registro_screen.dart';

/// Tela de Histórico e Agenda: linha do tempo do que já foi aplicado e as
/// próximas aplicações planejadas.
class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final registros = MockData.registros;
    final isWide = AppBreakpoints.isWide(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico e Agenda')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'historico_fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NovoRegistroScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Registro'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 700 : double.infinity),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: registros.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: SectionHeader(title: 'Aplicações realizadas'),
                );
              }
              final registro = registros[index - 1];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    foregroundColor: AppTheme.primaryGreen,
                    child: Icon(_iconFor(registro.tipo)),
                  ),
                  title: Text(registro.insumo, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${registro.talhaoNome}\n${registro.quantidade} · ${registro.responsavel}'),
                  isThreeLine: true,
                  trailing: Text(registro.data, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'registro.dart';
import 'talhao.dart';

/// Aviso da central de notificações: um talhão que ainda pede atenção
/// (aplicação pendente ou agendada).
///
/// Os avisos não são gravados: são derivados dos talhões e registros a cada
/// leitura (`PlotterCrud.avisos`). O que é guardado é apenas quais deles o
/// usuário já leu (`Preferencias`), identificados pela [chave].
class Aviso {
  final Talhao talhao;

  /// Próxima aplicação agendada no talhão, se houver.
  final Registro? proximaAplicacao;

  const Aviso({required this.talhao, this.proximaAplicacao});

  bool get pendente => talhao.status == TalhaoStatus.pendente;

  /// Identifica a *situação* avisada, e não só o talhão: se o talhão muda de
  /// situação ou ganha outra próxima aplicação (ou a mesma muda de data), a
  /// chave muda e o aviso volta a aparecer como não lido.
  String get chave {
    final proxima = proximaAplicacao;
    final sufixo = proxima == null
        ? 'sem-agenda'
        : '${proxima.id}@${proxima.data.year}-${proxima.data.month}-${proxima.data.day}';
    return '${talhao.id}:${talhao.status.name}:$sufixo';
  }

  String get titulo => pendente
      ? 'Aplicação pendente em ${talhao.nome}'
      : 'Aplicação agendada em ${talhao.nome}';
}

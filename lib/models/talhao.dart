enum TalhaoStatus { feito, pendente, agendado }

extension TalhaoStatusLabel on TalhaoStatus {
  String get label {
    switch (this) {
      case TalhaoStatus.feito:
        return 'Em dia';
      case TalhaoStatus.pendente:
        return 'Pendente';
      case TalhaoStatus.agendado:
        return 'Agendado';
    }
  }
}

/// Talhão (ou pivô) da fazenda, gravado na tabela `talhoes` do banco local.
///
/// A última e a próxima aplicação não ficam guardadas aqui: são calculadas a
/// partir dos registros do talhão (`PlotterCrud.ultimaAplicacao` e
/// `PlotterCrud.proximaAplicacao`), o que evita informações desatualizadas.
class Talhao {
  /// Chave primária gerada pelo SQLite. É `null` enquanto o talhão ainda não
  /// foi gravado.
  final int? id;
  final String nome;
  final String cultura;
  final double areaHa;
  final String estagio;
  final String pivo;
  final TalhaoStatus status;

  const Talhao({
    this.id,
    required this.nome,
    required this.cultura,
    required this.areaHa,
    this.estagio = '',
    this.pivo = '',
    this.status = TalhaoStatus.pendente,
  });

  /// Converte o talhão em uma linha da tabela `talhoes`.
  Map<String, Object?> toMap() => {
        'id': id,
        'nome': nome,
        'cultura': cultura,
        'area_ha': areaHa,
        'estagio': estagio,
        'pivo': pivo,
        'status': status.name,
      };

  /// Reconstrói o talhão a partir de uma linha lida do banco.
  factory Talhao.fromMap(Map<String, Object?> map) => Talhao(
        id: map['id'] as int,
        nome: map['nome'] as String,
        cultura: map['cultura'] as String,
        areaHa: (map['area_ha'] as num).toDouble(),
        estagio: map['estagio'] as String,
        pivo: map['pivo'] as String,
        status: TalhaoStatus.values.byName(map['status'] as String),
      );

  Talhao copyWith({
    int? id,
    String? nome,
    String? cultura,
    double? areaHa,
    String? estagio,
    String? pivo,
    TalhaoStatus? status,
  }) =>
      Talhao(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        cultura: cultura ?? this.cultura,
        areaHa: areaHa ?? this.areaHa,
        estagio: estagio ?? this.estagio,
        pivo: pivo ?? this.pivo,
        status: status ?? this.status,
      );
}

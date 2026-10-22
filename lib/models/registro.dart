enum TipoInsumo { defensivo, fertilizante, outro }

extension TipoInsumoLabel on TipoInsumo {
  String get label {
    switch (this) {
      case TipoInsumo.defensivo:
        return 'Defensivo';
      case TipoInsumo.fertilizante:
        return 'Fertilizante';
      case TipoInsumo.outro:
        return 'Outro';
    }
  }
}

/// Aplicação de insumo em um talhão, gravada na tabela `registros`.
///
/// O mesmo modelo representa o que já foi feito e o que está agendado: um
/// registro com data até hoje é uma aplicação **realizada**; com data futura,
/// uma aplicação **agendada**.
class Registro {
  /// Chave primária gerada pelo SQLite. É `null` enquanto o registro ainda
  /// não foi gravado.
  final int? id;

  /// Chave estrangeira para `talhoes.id`.
  final int talhaoId;
  final String insumo;
  final TipoInsumo tipo;
  final DateTime data;
  final String quantidade;
  final String responsavel;
  final String observacoes;

  const Registro({
    this.id,
    required this.talhaoId,
    required this.insumo,
    required this.tipo,
    required this.data,
    required this.quantidade,
    this.responsavel = '',
    this.observacoes = '',
  });

  bool get agendado => data.isAfter(_hoje());

  /// Data no formato usado na interface (dd/mm/aaaa).
  String get dataFormatada => formatarData(data);

  /// Converte o registro em uma linha da tabela `registros`. A data é gravada
  /// como texto ISO (aaaa-mm-dd), que o SQLite ordena corretamente.
  Map<String, Object?> toMap() => {
        'id': id,
        'talhao_id': talhaoId,
        'insumo': insumo,
        'tipo': tipo.name,
        'data': _dataIso(data),
        'quantidade': quantidade,
        'responsavel': responsavel,
        'observacoes': observacoes,
      };

  /// Reconstrói o registro a partir de uma linha lida do banco.
  factory Registro.fromMap(Map<String, Object?> map) => Registro(
        id: map['id'] as int,
        talhaoId: map['talhao_id'] as int,
        insumo: map['insumo'] as String,
        tipo: TipoInsumo.values.byName(map['tipo'] as String),
        data: DateTime.parse(map['data'] as String),
        quantidade: map['quantidade'] as String,
        responsavel: map['responsavel'] as String,
        observacoes: map['observacoes'] as String,
      );

  Registro copyWith({
    int? id,
    int? talhaoId,
    String? insumo,
    TipoInsumo? tipo,
    DateTime? data,
    String? quantidade,
    String? responsavel,
    String? observacoes,
  }) =>
      Registro(
        id: id ?? this.id,
        talhaoId: talhaoId ?? this.talhaoId,
        insumo: insumo ?? this.insumo,
        tipo: tipo ?? this.tipo,
        data: data ?? this.data,
        quantidade: quantidade ?? this.quantidade,
        responsavel: responsavel ?? this.responsavel,
        observacoes: observacoes ?? this.observacoes,
      );

  static DateTime _hoje() {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day);
  }

  static String _dataIso(DateTime data) =>
      '${data.year.toString().padLeft(4, '0')}-'
      '${data.month.toString().padLeft(2, '0')}-'
      '${data.day.toString().padLeft(2, '0')}';
}

String formatarData(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year}';
}

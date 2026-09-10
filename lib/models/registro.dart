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

class Registro {
  final String id;
  final String talhaoNome;
  final String insumo;
  final TipoInsumo tipo;
  final String data;
  final String quantidade;
  final String responsavel;

  const Registro({
    required this.id,
    required this.talhaoNome,
    required this.insumo,
    required this.tipo,
    required this.data,
    required this.quantidade,
    required this.responsavel,
  });
}

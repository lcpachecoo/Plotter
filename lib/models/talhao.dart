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

class Talhao {
  final String id;
  final String nome;
  final String cultura;
  final double areaHa;
  final String estagio;
  final TalhaoStatus status;
  final String ultimaAplicacao;
  final String proximaAplicacao;

  const Talhao({
    required this.id,
    required this.nome,
    required this.cultura,
    required this.areaHa,
    required this.estagio,
    required this.status,
    required this.ultimaAplicacao,
    required this.proximaAplicacao,
  });
}

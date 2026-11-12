/// Previsão do tempo da fazenda (Etapa 6).
///
/// Vem da rota `GET /clima/previsao` do backend, que consulta o serviço
/// externo OpenWeatherMap e devolve um resumo por dia, já com a avaliação das
/// condições para pulverização. Não é gravada no banco local: é um dado que
/// envelhece rápido e só faz sentido consultado na hora.
class PrevisaoTempo {
  /// Serviço de origem dos dados ("OpenWeatherMap").
  final String fonte;

  /// Localidade mais próxima das coordenadas da fazenda.
  final String local;

  /// Momento em que o servidor obteve a previsão do serviço externo.
  final DateTime atualizadoEm;

  /// Até 5 dias, do mais próximo para o mais distante.
  final List<PrevisaoDia> dias;

  const PrevisaoTempo({
    required this.fonte,
    required this.local,
    required this.atualizadoEm,
    required this.dias,
  });

  /// Previsão para a [data] escolhida, ou `null` se ela estiver fora dos
  /// dias cobertos pelo serviço.
  PrevisaoDia? doDia(DateTime data) {
    for (final dia in dias) {
      if (dia.data.year == data.year &&
          dia.data.month == data.month &&
          dia.data.day == data.day) {
        return dia;
      }
    }
    return null;
  }

  factory PrevisaoTempo.fromJson(Map<String, Object?> json) => PrevisaoTempo(
        fonte: json['fonte'] as String,
        local: json['local'] as String,
        atualizadoEm: DateTime.parse(json['atualizadoEm'] as String).toLocal(),
        dias: (json['dias'] as List<Object?>)
            .cast<Map<String, Object?>>()
            .map(PrevisaoDia.fromJson)
            .toList(growable: false),
      );
}

/// Resumo de um dia da previsão.
class PrevisaoDia {
  final DateTime data;
  final String descricao;

  /// Código do ícone do OpenWeatherMap (ex.: "10d"), convertido em um ícone
  /// do próprio app pelo cartão de previsão.
  final String icone;
  final double tempMin;
  final double tempMax;
  final int umidade;
  final double ventoKmh;
  final int probChuva;
  final double chuvaMm;

  /// Se há ao menos um horário do dia com condições para pulverizar.
  final bool adequada;

  /// Explicação da avaliação ("Janela favorável: 06h–12h.").
  final String motivo;

  /// Início dos intervalos de 3 horas favoráveis ("06:00").
  final List<String> horarios;

  const PrevisaoDia({
    required this.data,
    required this.descricao,
    required this.icone,
    required this.tempMin,
    required this.tempMax,
    required this.umidade,
    required this.ventoKmh,
    required this.probChuva,
    required this.chuvaMm,
    required this.adequada,
    required this.motivo,
    this.horarios = const [],
  });

  factory PrevisaoDia.fromJson(Map<String, Object?> json) {
    final pulverizacao = json['pulverizacao'] as Map<String, Object?>;
    return PrevisaoDia(
      // A data chega como "aaaa-mm-dd", no fuso da fazenda.
      data: DateTime.parse(json['data'] as String),
      descricao: json['descricao'] as String,
      icone: json['icone'] as String,
      tempMin: (json['tempMin'] as num).toDouble(),
      tempMax: (json['tempMax'] as num).toDouble(),
      umidade: (json['umidade'] as num).round(),
      ventoKmh: (json['ventoKmh'] as num).toDouble(),
      probChuva: (json['probChuva'] as num).round(),
      chuvaMm: (json['chuvaMm'] as num).toDouble(),
      adequada: pulverizacao['adequada'] as bool,
      motivo: pulverizacao['motivo'] as String,
      horarios: (pulverizacao['horarios'] as List<Object?>).cast<String>(),
    );
  }

  /// "18–29 °C"
  String get faixaTemperatura => '${tempMin.round()}–${tempMax.round()} °C';

  /// "Chuva 80% (3,2 mm) · Vento 14 km/h"
  String get resumoChuvaVento {
    final chuva = chuvaMm > 0
        ? 'Chuva $probChuva% (${chuvaMm.toStringAsFixed(1).replaceAll('.', ',')} mm)'
        : 'Chuva $probChuva%';
    return '$chuva · Vento ${ventoKmh.round()} km/h';
  }
}

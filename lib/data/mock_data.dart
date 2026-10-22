import '../models/registro.dart';
import '../models/talhao.dart';

/// Carga inicial do banco local.
///
/// Até a Etapa 3 estes dados eram lidos diretamente pelas telas. A partir da
/// Etapa 4 eles são gravados no SQLite uma única vez, quando o banco é criado
/// (`DatabaseHelper`), apenas para que o aplicativo não abra vazio na
/// primeira execução. Depois disso, tudo o que aparece vem do banco.
class MockData {
  MockData._();

  static const List<Talhao> talhoes = [
    Talhao(
      nome: 'Talhão 01 - Pivô Norte',
      cultura: 'Soja',
      areaHa: 42.5,
      estagio: 'Floração (R2)',
      pivo: 'Pivô Norte',
      status: TalhaoStatus.pendente,
    ),
    Talhao(
      nome: 'Talhão 02 - Baixada',
      cultura: 'Milho',
      areaHa: 30.0,
      estagio: 'Vegetativo (V8)',
      status: TalhaoStatus.feito,
    ),
    Talhao(
      nome: 'Talhão 03 - Pivô Sul',
      cultura: 'Soja',
      areaHa: 55.2,
      estagio: 'Enchimento de grãos (R5)',
      pivo: 'Pivô Sul',
      status: TalhaoStatus.agendado,
    ),
    Talhao(
      nome: 'Talhão 04 - Fundo de Vale',
      cultura: 'Algodão',
      areaHa: 21.8,
      estagio: 'Formação de capulho',
      status: TalhaoStatus.pendente,
    ),
  ];

  /// Registros iniciais, ligados aos talhões acima pela posição na lista
  /// ([idsTalhoes] traz os ids gerados pelo banco, na mesma ordem).
  ///
  /// As datas são relativas a [hoje] para que sempre existam aplicações
  /// realizadas e agendadas, qualquer que seja o dia da primeira execução.
  static List<Registro> registros(List<int> idsTalhoes, DateTime hoje) {
    DateTime dia(int deslocamento) => hoje.add(Duration(days: deslocamento));

    return [
      Registro(
        talhaoId: idsTalhoes[1],
        insumo: 'Ureia 45%',
        tipo: TipoInsumo.fertilizante,
        data: dia(-3),
        quantidade: '180 kg/ha',
        responsavel: 'João Operador',
      ),
      Registro(
        talhaoId: idsTalhoes[2],
        insumo: 'Inseticida Lambda',
        tipo: TipoInsumo.defensivo,
        data: dia(-9),
        quantidade: '0.3 L/ha',
        responsavel: 'Maria Gerente',
      ),
      Registro(
        talhaoId: idsTalhoes[0],
        insumo: 'Fungicida Triazol',
        tipo: TipoInsumo.defensivo,
        data: dia(-11),
        quantidade: '0.5 L/ha',
        responsavel: 'João Operador',
      ),
      Registro(
        talhaoId: idsTalhoes[3],
        insumo: 'Regulador Mepiquat',
        tipo: TipoInsumo.defensivo,
        data: dia(-17),
        quantidade: '0.6 L/ha',
        responsavel: 'Maria Gerente',
      ),
      Registro(
        talhaoId: idsTalhoes[0],
        insumo: 'Inseticida',
        tipo: TipoInsumo.defensivo,
        data: dia(2),
        quantidade: '0.4 L/ha',
      ),
      Registro(
        talhaoId: idsTalhoes[1],
        insumo: 'Herbicida',
        tipo: TipoInsumo.defensivo,
        data: dia(10),
        quantidade: '2 L/ha',
      ),
      Registro(
        talhaoId: idsTalhoes[2],
        insumo: 'Fungicida',
        tipo: TipoInsumo.defensivo,
        data: dia(4),
        quantidade: '0.5 L/ha',
      ),
      Registro(
        talhaoId: idsTalhoes[3],
        insumo: 'Desfolhante',
        tipo: TipoInsumo.outro,
        data: dia(15),
        quantidade: '1.5 L/ha',
      ),
    ];
  }
}

import '../models/registro.dart';
import '../models/talhao.dart';

/// Dados fictícios usados nesta etapa, já que a aplicação ainda não possui
/// persistência local nem comunicação com servidor.
class MockData {
  MockData._();

  static const List<Talhao> talhoes = [
    Talhao(
      id: 't1',
      nome: 'Talhão 01 - Pivô Norte',
      cultura: 'Soja',
      areaHa: 42.5,
      estagio: 'Floração (R2)',
      status: TalhaoStatus.pendente,
      ultimaAplicacao: 'Fungicida - 28/08/2026',
      proximaAplicacao: 'Inseticida - 12/09/2026',
    ),
    Talhao(
      id: 't2',
      nome: 'Talhão 02 - Baixada',
      cultura: 'Milho',
      areaHa: 30.0,
      estagio: 'Vegetativo (V8)',
      status: TalhaoStatus.feito,
      ultimaAplicacao: 'Adubação de cobertura - 05/09/2026',
      proximaAplicacao: 'Herbicida - 20/09/2026',
    ),
    Talhao(
      id: 't3',
      nome: 'Talhão 03 - Pivô Sul',
      cultura: 'Soja',
      areaHa: 55.2,
      estagio: 'Enchimento de grãos (R5)',
      status: TalhaoStatus.agendado,
      ultimaAplicacao: 'Inseticida - 30/08/2026',
      proximaAplicacao: 'Fungicida - 14/09/2026',
    ),
    Talhao(
      id: 't4',
      nome: 'Talhão 04 - Fundo de Vale',
      cultura: 'Algodão',
      areaHa: 21.8,
      estagio: 'Formação de capulho',
      status: TalhaoStatus.pendente,
      ultimaAplicacao: 'Regulador de crescimento - 22/08/2026',
      proximaAplicacao: 'Desfolhante - 25/09/2026',
    ),
  ];

  static const List<Registro> registros = [
    Registro(
      id: 'r1',
      talhaoNome: 'Talhão 02 - Baixada',
      insumo: 'Ureia 45%',
      tipo: TipoInsumo.fertilizante,
      data: '05/09/2026',
      quantidade: '180 kg/ha',
      responsavel: 'João Operador',
    ),
    Registro(
      id: 'r2',
      talhaoNome: 'Talhão 03 - Pivô Sul',
      insumo: 'Inseticida Lambda',
      tipo: TipoInsumo.defensivo,
      data: '30/08/2026',
      quantidade: '0.3 L/ha',
      responsavel: 'Maria Gerente',
    ),
    Registro(
      id: 'r3',
      talhaoNome: 'Talhão 01 - Pivô Norte',
      insumo: 'Fungicida Triazol',
      tipo: TipoInsumo.defensivo,
      data: '28/08/2026',
      quantidade: '0.5 L/ha',
      responsavel: 'João Operador',
    ),
    Registro(
      id: 'r4',
      talhaoNome: 'Talhão 04 - Fundo de Vale',
      insumo: 'Regulador Mepiquat',
      tipo: TipoInsumo.defensivo,
      data: '22/08/2026',
      quantidade: '0.6 L/ha',
      responsavel: 'Maria Gerente',
    ),
  ];
}

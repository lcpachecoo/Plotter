import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:plotter/models/aviso.dart';
import 'package:plotter/models/registro.dart';
import 'package:plotter/models/talhao.dart';
import 'package:plotter/state/preferencias.dart';

/// Testes do estado global de preferências (Etapa 7): valores padrão,
/// gravação no aparelho, avisos lidos e notificação das telas.
void main() {
  // Armazenamento do aparelho simulado em memória, zerado a cada teste.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const talhao = Talhao(
    id: 1,
    nome: 'Talhão 01',
    cultura: 'Soja',
    areaHa: 10,
    status: TalhaoStatus.pendente,
  );
  const outroTalhao = Talhao(
    id: 2,
    nome: 'Talhão 02',
    cultura: 'Milho',
    areaHa: 12,
    status: TalhaoStatus.agendado,
  );

  test('primeira execução usa os valores padrão', () async {
    final preferencias = await Preferencias.carregar();

    expect(preferencias.persistente, isTrue);
    expect(preferencias.lembretesAtivos, isFalse);
    expect(preferencias.economiaDados, isFalse);
    expect(preferencias.naoLidos(const [Aviso(talhao: talhao)]), 1);
  });

  test('as escolhas são gravadas e voltam ao reabrir o app', () async {
    final antes = await Preferencias.carregar();
    await antes.definirLembretes(true);
    await antes.definirEconomiaDados(true);
    await antes.marcarComoLido(const Aviso(talhao: talhao));

    // "Reabre" o app: um objeto novo, lido do armazenamento.
    final depois = await Preferencias.carregar();

    expect(depois.lembretesAtivos, isTrue);
    expect(depois.economiaDados, isTrue);
    expect(depois.foiLido(const Aviso(talhao: talhao)), isTrue);
    expect(depois.foiLido(const Aviso(talhao: outroTalhao)), isFalse);
  });

  test('marcar todos como lidos zera o contador e descarta avisos antigos',
      () async {
    final preferencias = await Preferencias.carregar();
    const antigo = Aviso(talhao: Talhao(id: 9, nome: 'X', cultura: 'Y', areaHa: 1));
    await preferencias.marcarComoLido(antigo);

    const avisos = [Aviso(talhao: talhao), Aviso(talhao: outroTalhao)];
    expect(preferencias.naoLidos(avisos), 2);

    await preferencias.marcarTodosComoLidos(avisos);

    expect(preferencias.naoLidos(avisos), 0);
    expect(preferencias.foiLido(antigo), isFalse,
        reason: 'chaves de avisos que não existem mais são descartadas');
  });

  test('aviso volta a ficar não lido quando a situação do talhão muda',
      () async {
    final preferencias = Preferencias.emMemoria();
    final registro = Registro(
      id: 5,
      talhaoId: 1,
      insumo: 'Herbicida',
      tipo: TipoInsumo.defensivo,
      data: DateTime(2026, 12, 1),
      quantidade: '2 L/ha',
    );
    await preferencias.marcarComoLido(Aviso(talhao: talhao, proximaAplicacao: registro));

    // Mesma situação: continua lido.
    expect(preferencias.foiLido(Aviso(talhao: talhao, proximaAplicacao: registro)),
        isTrue);
    // Talhão mudou de situação.
    expect(
        preferencias.foiLido(Aviso(
            talhao: talhao.copyWith(status: TalhaoStatus.agendado),
            proximaAplicacao: registro)),
        isFalse);
    // A aplicação mudou de data.
    expect(
        preferencias.foiLido(Aviso(
            talhao: talhao,
            proximaAplicacao: registro.copyWith(data: DateTime(2026, 12, 3)))),
        isFalse);
  });

  test('cada mudança avisa as telas (ChangeNotifier), e só quando muda',
      () async {
    final preferencias = Preferencias.emMemoria();
    var avisosRecebidos = 0;
    preferencias.addListener(() => avisosRecebidos++);

    await preferencias.definirLembretes(true);
    await preferencias.definirLembretes(true); // mesmo valor: sem aviso
    await preferencias.definirEconomiaDados(true);
    await preferencias.marcarComoLido(const Aviso(talhao: talhao));
    await preferencias.marcarComoLido(const Aviso(talhao: talhao)); // já lido

    expect(avisosRecebidos, 3);
    expect(preferencias.persistente, isFalse);
  });
}

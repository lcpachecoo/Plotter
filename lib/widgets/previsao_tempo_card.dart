import 'package:flutter/material.dart';

import '../data/plotter_api.dart';
import '../data/plotter_crud.dart';
import '../models/previsao_tempo.dart';
import '../models/registro.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Estados da consulta à previsão do tempo (Etapa 6)
// ---------------------------------------------------------------------------

/// Situação da consulta ao serviço de previsão do tempo. Cada estado tem uma
/// apresentação própria nos cartões abaixo.
sealed class EstadoPrevisao {
  const EstadoPrevisao();
}

/// A requisição está em andamento.
class PrevisaoCarregando extends EstadoPrevisao {
  const PrevisaoCarregando();
}

/// O servidor devolveu a previsão com ao menos um dia.
class PrevisaoCarregada extends EstadoPrevisao {
  final PrevisaoTempo previsao;
  const PrevisaoCarregada(this.previsao);
}

/// O servidor respondeu, mas não há previsão para a fazenda.
class PrevisaoSemDados extends EstadoPrevisao {
  const PrevisaoSemDados();
}

/// A consulta falhou (sem conexão, serviço externo fora do ar, etc.).
class PrevisaoComErro extends EstadoPrevisao {
  final String mensagem;
  const PrevisaoComErro(this.mensagem);
}

/// Faz a consulta pelo [PlotterCrud] e reconstrói [builder] a cada mudança
/// de estado. [tentarDeNovo] refaz a consulta depois de um erro.
class ConsultaPrevisao extends StatefulWidget {
  final Widget Function(
    BuildContext context,
    EstadoPrevisao estado,
    VoidCallback tentarDeNovo,
  ) builder;

  const ConsultaPrevisao({super.key, required this.builder});

  @override
  State<ConsultaPrevisao> createState() => _ConsultaPrevisaoState();
}

class _ConsultaPrevisaoState extends State<ConsultaPrevisao> {
  EstadoPrevisao _estado = const PrevisaoCarregando();
  bool _iniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;

    // Previsão recebida há pouco (em outra tela) é exibida na hora.
    final recente = PlotterCrudScope.read(context).previsaoRecente;
    if (recente != null) {
      _estado = _estadoPara(recente);
    } else {
      _consultar();
    }
  }

  static EstadoPrevisao _estadoPara(PrevisaoTempo previsao) =>
      previsao.dias.isEmpty ? const PrevisaoSemDados() : PrevisaoCarregada(previsao);

  Future<void> _consultar() async {
    final crud = PlotterCrudScope.read(context);
    if (_estado is! PrevisaoCarregando) {
      setState(() => _estado = const PrevisaoCarregando());
    }

    EstadoPrevisao novo;
    try {
      novo = _estadoPara(await crud.previsaoDoTempo());
    } catch (erro) {
      novo = PrevisaoComErro(mensagemDeErro(
          erro, 'Não foi possível consultar a previsão do tempo.'));
    }
    if (!mounted) return;
    setState(() => _estado = novo);
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _estado, _consultar);
}

// ---------------------------------------------------------------------------
// Cartão do detalhe do talhão: próximos dias
// ---------------------------------------------------------------------------

/// "Condições para aplicação": previsão dos próximos dias com a indicação de
/// quais são favoráveis para pulverizar.
class PrevisaoTempoCard extends StatelessWidget {
  const PrevisaoTempoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConsultaPrevisao(
          builder: (context, estado, tentarDeNovo) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Cabecalho(
                subtitulo: estado is PrevisaoCarregada
                    ? 'Previsão do tempo · ${estado.previsao.local}'
                    : 'Previsão do tempo',
              ),
              const SizedBox(height: 12),
              // A região é anunciada pelo leitor de tela quando o conteúdo
              // muda (carregando → previsão ou erro).
              Semantics(
                liveRegion: true,
                child: switch (estado) {
                  PrevisaoCarregando() =>
                    const _Carregando('Consultando a previsão do tempo…'),
                  PrevisaoComErro(:final mensagem) =>
                    _Aviso(
                      icone: Icons.cloud_off_outlined,
                      mensagem: mensagem,
                      onTentarDeNovo: tentarDeNovo,
                    ),
                  PrevisaoSemDados() => _Aviso(
                      icone: Icons.cloud_queue,
                      mensagem: 'Nenhuma previsão disponível para a localização '
                          'da fazenda no momento.',
                      rotuloAcao: 'Consultar de novo',
                      onTentarDeNovo: tentarDeNovo,
                    ),
                  PrevisaoCarregada(:final previsao) =>
                    _ListaDias(previsao: previsao),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  final String subtitulo;
  const _Cabecalho({required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ExcludeSemantics(
          child: Icon(Icons.wb_sunny_outlined, color: AppTheme.primaryGreen, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Condições para aplicação',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(subtitulo, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListaDias extends StatelessWidget {
  final PrevisaoTempo previsao;
  const _ListaDias({required this.previsao});

  @override
  Widget build(BuildContext context) {
    final hora = TimeOfDay.fromDateTime(previsao.atualizadoEm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (indice, dia) in previsao.dias.indexed) ...[
          if (indice > 0) const Divider(height: 20),
          _LinhaDia(dia: dia),
        ],
        const SizedBox(height: 12),
        Text(
          'Fonte: ${previsao.fonte} · atualizada às '
          '${hora.hour.toString().padLeft(2, '0')}:'
          '${hora.minute.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _LinhaDia extends StatelessWidget {
  final PrevisaoDia dia;
  const _LinhaDia({required this.dia});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    // Lido como uma frase só: "Amanhã, Chuva leve, 18–29 °C, ... Favorável".
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(iconeDoTempo(dia.icone), color: AppTheme.textSecondary, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeDoDia(dia.data),
                  style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text('${dia.descricao} · ${dia.faixaTemperatura}', style: texto.bodyMedium),
                Text(dia.resumoChuvaVento, style: texto.bodySmall),
                const SizedBox(height: 2),
                Text(dia.motivo, style: texto.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SeloPulverizacao(adequada: dia.adequada),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cartão do formulário de registro: dia escolhido
// ---------------------------------------------------------------------------

/// Previsão para a data escolhida no formulário de uma aplicação agendada.
class PrevisaoDoDiaCard extends StatelessWidget {
  final DateTime data;
  const PrevisaoDoDiaCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.background,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Semantics(
          liveRegion: true,
          child: ConsultaPrevisao(
            builder: (context, estado, tentarDeNovo) => switch (estado) {
              PrevisaoCarregando() =>
                _Carregando('Consultando a previsão para ${formatarData(data)}…'),
              PrevisaoComErro(:final mensagem) => _Aviso(
                  icone: Icons.cloud_off_outlined,
                  mensagem: mensagem,
                  onTentarDeNovo: tentarDeNovo,
                ),
              PrevisaoSemDados() => _Aviso(
                  icone: Icons.cloud_queue,
                  mensagem: 'Não há previsão do tempo disponível no momento.',
                  rotuloAcao: 'Consultar de novo',
                  onTentarDeNovo: tentarDeNovo,
                ),
              PrevisaoCarregada(:final previsao) => _DiaEscolhido(
                  data: data,
                  dia: previsao.doDia(data),
                ),
            },
          ),
        ),
      ),
    );
  }
}

class _DiaEscolhido extends StatelessWidget {
  final DateTime data;
  final PrevisaoDia? dia;
  const _DiaEscolhido({required this.data, required this.dia});

  @override
  Widget build(BuildContext context) {
    final dia = this.dia;
    if (dia == null) {
      // Ausência de dados para a data: o serviço gratuito cobre 5 dias.
      return _Aviso(
        icone: Icons.event_busy_outlined,
        mensagem: 'Sem previsão do tempo para ${formatarData(data)}: '
            'ela fica disponível apenas para os próximos 5 dias.',
      );
    }

    final texto = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(iconeDoTempo(dia.icone), color: AppTheme.textSecondary, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Previsão para ${formatarData(data)}',
                  style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SeloPulverizacao(adequada: dia.adequada),
            ],
          ),
          const SizedBox(height: 6),
          Text('${dia.descricao} · ${dia.faixaTemperatura}', style: texto.bodyMedium),
          Text(dia.resumoChuvaVento, style: texto.bodySmall),
          const SizedBox(height: 2),
          Text(dia.motivo, style: texto.bodySmall),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Partes comuns
// ---------------------------------------------------------------------------

/// Selo "Favorável" / "Evitar". Assim como o selo de situação do talhão, usa
/// cor, ícone e texto juntos, nunca só a cor.
class SeloPulverizacao extends StatelessWidget {
  final bool adequada;
  const SeloPulverizacao({super.key, required this.adequada});

  @override
  Widget build(BuildContext context) {
    final cor = adequada ? AppTheme.doneGreen : AppTheme.pendingOrange;
    final rotulo = adequada ? 'Favorável' : 'Evitar';
    return Semantics(
      label: adequada ? 'Favorável para aplicar' : 'Evitar aplicação',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cor.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(adequada ? Icons.check_circle : Icons.do_not_disturb_on_outlined,
                size: 16, color: cor),
            const SizedBox(width: 5),
            Text(
              rotulo,
              style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _Carregando extends StatelessWidget {
  final String mensagem;
  const _Carregando(this.mensagem);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(mensagem, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

/// Mensagem de erro ou de ausência de dados, com ação opcional para
/// consultar de novo.
class _Aviso extends StatelessWidget {
  final IconData icone;
  final String mensagem;
  final String rotuloAcao;
  final VoidCallback? onTentarDeNovo;

  const _Aviso({
    required this.icone,
    required this.mensagem,
    this.rotuloAcao = 'Tentar de novo',
    this.onTentarDeNovo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(icone, color: AppTheme.textSecondary, size: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(mensagem, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
        if (onTentarDeNovo != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onTentarDeNovo,
              icon: const Icon(Icons.refresh),
              label: Text(rotuloAcao),
            ),
          ),
      ],
    );
  }
}

const _diasDaSemana = ['seg.', 'ter.', 'qua.', 'qui.', 'sex.', 'sáb.', 'dom.'];

/// "Hoje", "Amanhã" ou "sex., 15/11".
String nomeDoDia(DateTime data, {DateTime? hoje}) {
  final referencia = DateUtils.dateOnly(hoje ?? DateTime.now());
  final diferenca = DateUtils.dateOnly(data).difference(referencia).inDays;
  if (diferenca == 0) return 'Hoje';
  if (diferenca == 1) return 'Amanhã';
  final semana = _diasDaSemana[data.weekday - 1];
  return '$semana, ${formatarData(data).substring(0, 5)}';
}

/// Ícone do app correspondente ao código do OpenWeatherMap. São ícones do
/// Material (e não as imagens do serviço), para não depender de download.
IconData iconeDoTempo(String codigo) {
  final grupo = codigo.length >= 2 ? codigo.substring(0, 2) : '';
  return switch (grupo) {
    '01' => Icons.wb_sunny_outlined,
    '02' => Icons.wb_cloudy_outlined,
    '03' || '04' => Icons.cloud_outlined,
    '09' || '10' => Icons.water_drop_outlined,
    '11' => Icons.thunderstorm_outlined,
    '13' => Icons.ac_unit,
    '50' => Icons.foggy,
    _ => Icons.cloud_outlined,
  };
}

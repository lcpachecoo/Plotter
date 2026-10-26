import 'package:flutter/material.dart';

import '../data/plotter_api.dart';
import '../data/plotter_crud.dart';
import '../models/registro.dart';
import '../models/talhao.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

/// Formulário para lançar (ou editar) uma aplicação de insumo em um talhão.
///
/// - Com [talhao], o registro já nasce vinculado a ele (aberto pelo detalhe
///   do talhão).
/// - Com [registro], o formulário é pré-preenchido e salvar atualiza o
///   registro existente.
/// - Sem nenhum dos dois (aberto pelo Histórico), o usuário escolhe o talhão.
///
/// Ao salvar, o registro é gravado no banco local e a tela devolve `true`
/// para a tela anterior, que exibe a confirmação.
class NovoRegistroScreen extends StatefulWidget {
  final Talhao? talhao;
  final Registro? registro;

  const NovoRegistroScreen({super.key, this.talhao, this.registro});

  @override
  State<NovoRegistroScreen> createState() => _NovoRegistroScreenState();
}

class _NovoRegistroScreenState extends State<NovoRegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _insumoController =
      TextEditingController(text: widget.registro?.insumo ?? '');
  late final _quantidadeController =
      TextEditingController(text: widget.registro?.quantidade ?? '');
  late final _responsavelController =
      TextEditingController(text: widget.registro?.responsavel ?? '');
  late final _observacoesController =
      TextEditingController(text: widget.registro?.observacoes ?? '');

  final _quantidadeFocus = FocusNode();
  final _responsavelFocus = FocusNode();
  final _observacoesFocus = FocusNode();

  late TipoInsumo _tipo = widget.registro?.tipo ?? TipoInsumo.defensivo;
  late DateTime? _data = widget.registro?.data;
  late int? _talhaoId = widget.talhao?.id ?? widget.registro?.talhaoId;
  bool _salvando = false;
  bool _alterado = false;

  bool get _isEdicao => widget.registro != null;

  @override
  void dispose() {
    _insumoController.dispose();
    _quantidadeController.dispose();
    _responsavelController.dispose();
    _observacoesController.dispose();
    _quantidadeFocus.dispose();
    _responsavelFocus.dispose();
    _observacoesFocus.dispose();
    super.dispose();
  }

  void _marcarAlterado(String _) {
    if (!_alterado) setState(() => _alterado = true);
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppFeedback.erro(context, 'Preencha os campos obrigatórios destacados.');
      return;
    }

    final crud = PlotterCrudScope.read(context);
    final registro = Registro(
      id: widget.registro?.id,
      talhaoId: _talhaoId!,
      insumo: _insumoController.text.trim(),
      tipo: _tipo,
      data: _data!,
      quantidade: _quantidadeController.text.trim(),
      responsavel: _responsavelController.text.trim(),
      observacoes: _observacoesController.text.trim(),
    );

    setState(() => _salvando = true);
    try {
      if (_isEdicao) {
        await crud.atualizarRegistro(registro);
      } else {
        await crud.inserirRegistro(registro);
      }
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      AppFeedback.erro(
        context,
        mensagemDeErro(erro, 'Não foi possível salvar o registro. Tente novamente.'),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _salvando = false);

    Navigator.of(context).pop(true);
  }

  Future<void> _aoTentarVoltar(bool didPop, Object? resultado) async {
    if (didPop) return;

    final descartar = await AppFeedback.confirmar(
      context,
      titulo: _isEdicao ? 'Descartar alterações?' : 'Descartar registro?',
      mensagem: _isEdicao
          ? 'As alterações feitas neste registro não serão salvas.'
          : 'A aplicação que você começou a lançar não será salva.',
      confirmarLabel: 'Descartar',
      cancelarLabel: 'Continuar editando',
      destrutivo: true,
    );

    if (!mounted || !descartar) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);
    final talhoes = PlotterCrudScope.of(context).talhoes;

    return PopScope(
      canPop: !_alterado && !_salvando,
      onPopInvokedWithResult: _aoTentarVoltar,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdicao ? 'Editar Registro' : 'Novo Registro'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 560 : double.infinity),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.talhao != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            color: AppTheme.lightGreen.withValues(alpha: 0.18),
                            child: ListTile(
                              leading: const Icon(Icons.crop_square),
                              title: Text(widget.talhao!.nome),
                              subtitle: Text(
                                '${widget.talhao!.cultura} · '
                                '${widget.talhao!.areaHa.toStringAsFixed(1)} ha',
                              ),
                            ),
                          ),
                        )
                      else ...[
                        // Aberto pelo Histórico (ou em uma edição), o
                        // registro precisa de um talhão escolhido aqui.
                        DropdownButtonFormField<int>(
                          initialValue: talhoes.any((t) => t.id == _talhaoId)
                              ? _talhaoId
                              : null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Talhão *',
                            prefixIcon: Icon(Icons.crop_square),
                          ),
                          itemHeight: 56,
                          items: talhoes
                              .map((t) => DropdownMenuItem(
                                    value: t.id,
                                    child: Text(
                                      t.nome,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          validator: (v) => v == null
                              ? (talhoes.isEmpty
                                  ? 'Cadastre um talhão antes de lançar registros'
                                  : 'Escolha o talhão da aplicação')
                              : null,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _talhaoId = value;
                              _alterado = true;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      DropdownButtonFormField<TipoInsumo>(
                        initialValue: _tipo,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de insumo *',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        // Itens altos facilitam a seleção com o dedo.
                        itemHeight: 56,
                        items: TipoInsumo.values
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.label),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _tipo = value;
                            _alterado = true;
                          });
                          AppFeedback.anunciar(
                            context,
                            'Tipo de insumo ${value.label} selecionado.',
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Insumo aplicado',
                        hint: 'Ex.: Fungicida Triazol',
                        icon: Icons.science_outlined,
                        controller: _insumoController,
                        obrigatorio: true,
                        autofocus: !_isEdicao,
                        onChanged: _marcarAlterado,
                        onSubmitted: (_) => _quantidadeFocus.requestFocus(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o produto aplicado'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Quantidade / dose',
                        hint: 'Ex.: 0.5 L/ha',
                        ajuda: 'Informe a unidade usada na aplicação',
                        icon: Icons.straighten,
                        controller: _quantidadeController,
                        focusNode: _quantidadeFocus,
                        obrigatorio: true,
                        onChanged: _marcarAlterado,
                        onSubmitted: (_) => _responsavelFocus.requestFocus(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe a quantidade aplicada'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _CampoData(
                        data: _data,
                        onChanged: (novaData) => setState(() {
                          _data = novaData;
                          _alterado = true;
                        }),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Responsável',
                        hint: 'Ex.: João Operador',
                        ajuda: 'Opcional',
                        icon: Icons.person_outline,
                        controller: _responsavelController,
                        focusNode: _responsavelFocus,
                        onChanged: _marcarAlterado,
                        onSubmitted: (_) => _observacoesFocus.requestFocus(),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Observações',
                        ajuda: 'Opcional. Ex.: condições do tempo, equipamento',
                        icon: Icons.notes_outlined,
                        maxLines: 3,
                        controller: _observacoesController,
                        focusNode: _observacoesFocus,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        onChanged: _marcarAlterado,
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: _isEdicao ? 'Salvar alterações' : 'Salvar registro',
                        icon: Icons.save_outlined,
                        loading: _salvando,
                        onPressed: _salvar,
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Cancelar',
                        icon: Icons.close,
                        outlined: true,
                        onPressed: _salvando
                            ? null
                            : () => Navigator.of(context).maybePop(false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo de data construído sobre `FormField`, para que participe da
/// validação do formulário como qualquer outro campo — inclusive exibindo
/// mensagem de erro e sendo anunciado por leitores de tela.
///
/// Datas futuras são permitidas: um registro com data futura é uma
/// aplicação agendada.
class _CampoData extends StatelessWidget {
  final DateTime? data;
  final ValueChanged<DateTime> onChanged;

  const _CampoData({required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: data,
      validator: (_) => data == null ? 'Escolha a data da aplicação' : null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (campo) {
        final texto = data == null ? 'Toque para escolher' : formatarData(data!);
        final hoje = DateTime.now();

        return Semantics(
          button: true,
          label: 'Data da aplicação, campo obrigatório',
          value: data == null ? 'Nenhuma data escolhida' : texto,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              // Ao editar um registro antigo, o intervalo se estende até a
              // data dele (o seletor exige que a data inicial caiba nele).
              var inicio = DateTime(hoje.year - 1);
              var fim = DateTime(hoje.year + 1, 12, 31);
              if (data != null && data!.isBefore(inicio)) inicio = data!;
              if (data != null && data!.isAfter(fim)) fim = data!;

              final escolhida = await showDatePicker(
                context: context,
                initialDate: data ?? hoje,
                firstDate: inicio,
                lastDate: fim,
                helpText: 'Data da aplicação',
                cancelText: 'Cancelar',
                confirmText: 'Confirmar',
              );
              if (escolhida == null) return;
              onChanged(escolhida);
              campo.didChange(escolhida);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Data da aplicação *',
                helperText: 'Datas futuras ficam na aba "Agendadas"',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                errorText: campo.errorText,
              ),
              child: Text(
                texto,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: data == null
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}

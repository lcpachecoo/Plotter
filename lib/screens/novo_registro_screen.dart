import 'package:flutter/material.dart';

import '../models/registro.dart';
import '../models/talhao.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

/// Formulário para lançar uma nova aplicação (defensivo, fertilizante etc.)
/// em um talhão. Nesta etapa não há persistência: ao salvar, a tela devolve
/// `true` para a tela anterior, que exibe a confirmação.
class NovoRegistroScreen extends StatefulWidget {
  final Talhao? talhao;

  const NovoRegistroScreen({super.key, this.talhao});

  @override
  State<NovoRegistroScreen> createState() => _NovoRegistroScreenState();
}

class _NovoRegistroScreenState extends State<NovoRegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _insumoController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _observacoesController = TextEditingController();

  final _quantidadeFocus = FocusNode();
  final _observacoesFocus = FocusNode();

  TipoInsumo _tipo = TipoInsumo.defensivo;
  DateTime? _data;
  bool _salvando = false;
  bool _alterado = false;

  @override
  void dispose() {
    _insumoController.dispose();
    _quantidadeController.dispose();
    _observacoesController.dispose();
    _quantidadeFocus.dispose();
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

    setState(() => _salvando = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _salvando = false);

    Navigator.of(context).pop(true);
  }

  Future<void> _aoTentarVoltar(bool didPop, Object? resultado) async {
    if (didPop) return;

    final descartar = await AppFeedback.confirmar(
      context,
      titulo: 'Descartar registro?',
      mensagem: 'A aplicação que você começou a lançar não será salva.',
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

    return PopScope(
      canPop: !_alterado && !_salvando,
      onPopInvokedWithResult: _aoTentarVoltar,
      child: Scaffold(
        appBar: AppBar(title: const Text('Novo Registro')),
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
                        ),
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
                        autofocus: true,
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
                        onSubmitted: (_) => _observacoesFocus.requestFocus(),
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
                        label: 'Salvar registro',
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
class _CampoData extends StatelessWidget {
  final DateTime? data;
  final ValueChanged<DateTime> onChanged;

  const _CampoData({required this.data, required this.onChanged});

  static String _formatar(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: data,
      validator: (_) => data == null ? 'Escolha a data da aplicação' : null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (campo) {
        final texto = data == null ? 'Toque para escolher' : _formatar(data!);

        return Semantics(
          button: true,
          label: 'Data da aplicação, campo obrigatório',
          value: data == null ? 'Nenhuma data escolhida' : texto,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final escolhida = await showDatePicker(
                context: context,
                initialDate: data ?? DateTime.now(),
                firstDate: DateTime(DateTime.now().year - 1),
                lastDate: DateTime(DateTime.now().year + 1),
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

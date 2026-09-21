import 'package:flutter/material.dart';

import '../models/talhao.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

/// Tela para criar ou editar um talhão (cultura, área, pivô associado).
/// Quando [talhao] é informado, o formulário é pré-preenchido para edição.
///
/// Ao concluir, a tela devolve `true` para quem a abriu (`Navigator.pop`),
/// que então exibe a confirmação — assim a mensagem aparece já na tela de
/// destino, e não em uma tela que está sendo fechada.
class CadastroTalhaoScreen extends StatefulWidget {
  final Talhao? talhao;

  const CadastroTalhaoScreen({super.key, this.talhao});

  @override
  State<CadastroTalhaoScreen> createState() => _CadastroTalhaoScreenState();
}

class _CadastroTalhaoScreenState extends State<CadastroTalhaoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nomeController = TextEditingController(text: widget.talhao?.nome ?? '');
  late final _culturaController =
      TextEditingController(text: widget.talhao?.cultura ?? '');
  late final _areaController = TextEditingController(
    text: widget.talhao != null ? widget.talhao!.areaHa.toString() : '',
  );
  late final _pivoController = TextEditingController();

  final _culturaFocus = FocusNode();
  final _areaFocus = FocusNode();
  final _pivoFocus = FocusNode();

  TalhaoStatus _status = TalhaoStatus.pendente;
  bool _salvando = false;
  bool _alterado = false;

  @override
  void initState() {
    super.initState();
    _status = widget.talhao?.status ?? TalhaoStatus.pendente;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _culturaController.dispose();
    _areaController.dispose();
    _pivoController.dispose();
    _culturaFocus.dispose();
    _areaFocus.dispose();
    _pivoFocus.dispose();
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

    // O `true` informa à tela anterior que houve gravação.
    Navigator.of(context).pop(true);
  }

  /// Impede a perda silenciosa do que foi digitado: se houver alterações não
  /// salvas, o usuário confirma antes de sair.
  Future<void> _aoTentarVoltar(bool didPop, Object? resultado) async {
    if (didPop) return;

    final descartar = await AppFeedback.confirmar(
      context,
      titulo: 'Descartar alterações?',
      mensagem: 'As informações digitadas neste formulário serão perdidas.',
      confirmarLabel: 'Descartar',
      cancelarLabel: 'Continuar editando',
      destrutivo: true,
    );

    if (!mounted || !descartar) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.talhao != null;
    final isWide = AppBreakpoints.isWide(context);

    return PopScope(
      canPop: !_alterado && !_salvando,
      onPopInvokedWithResult: _aoTentarVoltar,
      child: Scaffold(
        appBar: AppBar(title: Text(isEdicao ? 'Editar Talhão' : 'Cadastrar Talhão')),
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
                      Text(
                        isEdicao
                            ? 'Altere os dados do talhão e salve para confirmar.'
                            : 'Os campos marcados com * são obrigatórios.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        label: 'Nome do talhão',
                        hint: 'Ex.: Talhão 05 - Pivô Leste',
                        icon: Icons.crop_square,
                        controller: _nomeController,
                        obrigatorio: true,
                        autofocus: !isEdicao,
                        onChanged: _marcarAlterado,
                        onSubmitted: (_) => _culturaFocus.requestFocus(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe um nome para identificar o talhão'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Cultura plantada',
                        hint: 'Ex.: Soja',
                        icon: Icons.eco_outlined,
                        controller: _culturaController,
                        focusNode: _culturaFocus,
                        obrigatorio: true,
                        onChanged: _marcarAlterado,
                        onSubmitted: (_) => _areaFocus.requestFocus(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe a cultura plantada'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Área',
                        hint: 'Ex.: 42.5',
                        ajuda: 'Em hectares, use ponto para decimais',
                        icon: Icons.straighten,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        controller: _areaController,
                        focusNode: _areaFocus,
                        obrigatorio: true,
                        onChanged: _marcarAlterado,
                        onSubmitted: (_) => _pivoFocus.requestFocus(),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe a área do talhão';
                          }
                          final valor = double.tryParse(v.replaceAll(',', '.'));
                          if (valor == null || valor <= 0) {
                            return 'Informe um número maior que zero (ex.: 42.5)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Pivô associado',
                        hint: 'Ex.: Pivô Norte',
                        ajuda: 'Opcional',
                        icon: Icons.water_drop_outlined,
                        controller: _pivoController,
                        focusNode: _pivoFocus,
                        textInputAction: TextInputAction.done,
                        onChanged: _marcarAlterado,
                      ),
                      const SizedBox(height: 20),
                      Semantics(
                        header: true,
                        child: Text(
                          'Situação inicial',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Seleção por "chips": alvos grandes, rótulo visível e
                      // estado selecionado indicado por cor e por marca de
                      // seleção (não apenas pela cor).
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final status in TalhaoStatus.values)
                            ChoiceChip(
                              label: Text(status.label),
                              selected: _status == status,
                              showCheckmark: true,
                              onSelected: (_) {
                                setState(() {
                                  _status = status;
                                  _alterado = true;
                                });
                                AppFeedback.anunciar(
                                  context,
                                  'Situação ${status.label} selecionada.',
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: isEdicao ? 'Salvar alterações' : 'Cadastrar talhão',
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

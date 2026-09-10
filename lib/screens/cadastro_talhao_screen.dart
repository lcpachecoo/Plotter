import 'package:flutter/material.dart';

import '../models/talhao.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

/// Tela para criar ou editar um talhão (cultura, área, pivô associado).
/// Quando [talhao] é informado, o formulário é pré-preenchido para edição.
class CadastroTalhaoScreen extends StatefulWidget {
  final Talhao? talhao;

  const CadastroTalhaoScreen({super.key, this.talhao});

  @override
  State<CadastroTalhaoScreen> createState() => _CadastroTalhaoScreenState();
}

class _CadastroTalhaoScreenState extends State<CadastroTalhaoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nomeController = TextEditingController(text: widget.talhao?.nome ?? '');
  late final _culturaController = TextEditingController(text: widget.talhao?.cultura ?? '');
  late final _areaController = TextEditingController(
    text: widget.talhao != null ? widget.talhao!.areaHa.toString() : '',
  );
  late final _pivoController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _culturaController.dispose();
    _areaController.dispose();
    _pivoController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState?.validate() ?? false) {
      final mensagem = widget.talhao == null ? 'Talhão cadastrado com sucesso.' : 'Talhão atualizado com sucesso.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.talhao != null;
    final isWide = AppBreakpoints.isWide(context);

    return Scaffold(
      appBar: AppBar(title: Text(isEdicao ? 'Editar Talhão' : 'Cadastrar Talhão')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 560 : double.infinity),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'Nome do talhão',
                      hint: 'Ex.: Talhão 05 - Pivô Leste',
                      icon: Icons.crop_square,
                      controller: _nomeController,
                      validator: (v) => (v == null || v.isEmpty) ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Cultura plantada',
                      hint: 'Ex.: Soja',
                      icon: Icons.eco_outlined,
                      controller: _culturaController,
                      validator: (v) => (v == null || v.isEmpty) ? 'Informe a cultura' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Área (hectares)',
                      hint: 'Ex.: 42.5',
                      icon: Icons.straighten,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      controller: _areaController,
                      validator: (v) => (v == null || v.isEmpty) ? 'Informe a área' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Pivô associado (opcional)',
                      hint: 'Ex.: Pivô Norte',
                      icon: Icons.water_drop_outlined,
                      controller: _pivoController,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: isEdicao ? 'Salvar alterações' : 'Cadastrar talhão',
                      icon: Icons.save_outlined,
                      onPressed: _salvar,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

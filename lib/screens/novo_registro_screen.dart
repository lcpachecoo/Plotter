import 'package:flutter/material.dart';

import '../models/registro.dart';
import '../models/talhao.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

/// Formulário para lançar uma nova aplicação (defensivo, fertilizante etc.)
/// em um talhão. Nesta etapa não há persistência: ao salvar, apenas exibe
/// uma confirmação e retorna à tela anterior.
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
  TipoInsumo _tipo = TipoInsumo.defensivo;

  @override
  void dispose() {
    _insumoController.dispose();
    _quantidadeController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro salvo com sucesso.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Registro')),
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
                    if (widget.talhao != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Talhão: ${widget.talhao!.nome}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    DropdownButtonFormField<TipoInsumo>(
                      initialValue: _tipo,
                      decoration: const InputDecoration(labelText: 'Tipo de insumo'),
                      items: TipoInsumo.values
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                          .toList(),
                      onChanged: (value) => setState(() => _tipo = value ?? _tipo),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Insumo aplicado',
                      hint: 'Ex.: Fungicida Triazol',
                      icon: Icons.science_outlined,
                      controller: _insumoController,
                      validator: (v) => (v == null || v.isEmpty) ? 'Informe o insumo' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Quantidade / dose',
                      hint: 'Ex.: 0.5 L/ha',
                      icon: Icons.straighten,
                      controller: _quantidadeController,
                      validator: (v) => (v == null || v.isEmpty) ? 'Informe a quantidade' : null,
                    ),
                    const SizedBox(height: 16),
                    _DatePickerField(),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Observações (opcional)',
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                      controller: _observacoesController,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(label: 'Salvar registro', icon: Icons.save_outlined, onPressed: _salvar),
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

class _DatePickerField extends StatefulWidget {
  @override
  State<_DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<_DatePickerField> {
  DateTime? _data;

  @override
  Widget build(BuildContext context) {
    final label = _data == null
        ? 'Data da aplicação'
        : '${_data!.day.toString().padLeft(2, '0')}/${_data!.month.toString().padLeft(2, '0')}/${_data!.year}';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(DateTime.now().year - 1),
          lastDate: DateTime(DateTime.now().year + 1),
        );
        if (picked != null) setState(() => _data = picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Data',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(label),
      ),
    );
  }
}

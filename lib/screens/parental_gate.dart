import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Pregunta para adultos antes de compras o pantallas para papás.
/// Requisito de Google Play Familias.
Future<bool> parentalGate(BuildContext context, {Random? random}) async {
  final r = random ?? Random();
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _GateDialog(a: 6 + r.nextInt(4), b: 6 + r.nextInt(4)),
  );
  return ok ?? false;
}

class _GateDialog extends StatefulWidget {
  const _GateDialog({required this.a, required this.b});
  final int a;
  final int b;

  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> {
  final _controller = TextEditingController();

  void _submit() => Navigator.pop(context, int.tryParse(_controller.text) == widget.a * widget.b);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bg,
      scrollable: true,
      title: const Text('Pregunta para adultos', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('¿Cuánto es ${widget.a} × ${widget.b}?',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            key: const Key('gate-input'),
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28),
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Continuar')),
      ],
    );
  }
}

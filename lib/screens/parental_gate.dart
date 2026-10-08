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
    builder: (_) => _GateDialog(random: r),
  );
  return ok ?? false;
}

class _GateDialog extends StatefulWidget {
  const _GateDialog({required this.random});
  final Random random;

  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> {
  final _controller = TextEditingController();
  late int _a, _b;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    _a = 6 + widget.random.nextInt(4);
    _b = 6 + widget.random.nextInt(4);
  }

  /// Si falla, avisa y pone otra pregunta (no muestra la respuesta: es un candado para adultos).
  void _submit() {
    if (int.tryParse(_controller.text) == _a * _b) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _failed = true;
      _controller.clear();
      _newQuestion();
    });
  }

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
          Text('¿Cuánto es $_a × $_b?',
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
          if (_failed) ...[
            const SizedBox(height: 12),
            const Text('Respuesta incorrecta. Prueba con esta otra.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.red, fontSize: 16)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Continuar')),
      ],
    );
  }
}

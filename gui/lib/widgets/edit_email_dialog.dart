import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditEmailDialog extends StatelessWidget {
  final String initialEmail;
  final Future<void> Function(String) onSave;
  final Future<void> Function(String) onConfirm;

  const EditEmailDialog({Key? key, required this.initialEmail, required this.onSave, required this.onConfirm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditEmailModel>(
        create: (_) => EditEmailModel(initialEmail, onSave, onConfirm),
        child: Consumer<EditEmailModel>(
            builder: (context, model, _) => AlertDialog(
                    constraints: const BoxConstraints(minWidth: 600),
                    title: const Text('Ručna rezervacija'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        Expanded(
                            child: TextField(
                                controller: model.controller,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                    labelText: 'Email',
                                    errorText: model.errorText,
                                    border: const OutlineInputBorder(),
                                    errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                                    focusedErrorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 2))))),
                        const SizedBox(width: 12),
                        ElevatedButton(
                            onPressed: model.saving || model.errorText != null || model.controller.text.trim().isEmpty
                                ? null
                                : () async {
                                    final ok = await model.save(context);
                                    if (ok && context.mounted) Navigator.of(context).pop();
                                  },
                            child: const Text('Ispravi i pošalji e-mail potvrde'))
                      ])
                    ]),
                    actions: [
                      ElevatedButton(
                          onPressed: model.saving
                              ? null
                              : () async {
                                  final ok = await model.save(context);
                                  if (ok && context.mounted) Navigator.of(context).pop();
                                },
                          child: const Text('Potvrdi rezervaciju bez e-maila')),
                      TextButton(onPressed: model.saving ? null : () => Navigator.of(context).pop(), child: const Text('Izlaz'))
                    ])));
  }
}

class EditEmailModel extends ChangeNotifier {
  final Future<void> Function(String) onSave;
  final Future<void> Function(String) onConfirm;
  final TextEditingController controller;
  String? errorText;
  bool saving = false;
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  EditEmailModel(String initialEmail, this.onSave, this.onConfirm) : controller = TextEditingController(text: initialEmail) {
    controller.addListener(_validateLive);
    _validateLive();
  }

  void _validateLive() {
    final value = controller.text.trim();
    // Show validation only when there's something typed (avoid immediate error on empty)
    if (value.isEmpty) {
      if (errorText != null) {
        errorText = null;
        notifyListeners();
      }
      return;
    }

    final isValid = _emailRegex.hasMatch(value);
    if (!isValid) {
      if (errorText != 'Unesite ispravan e-mail!') {
        errorText = 'Unesite ispravan e-mail!';
        notifyListeners();
      }
    } else {
      if (errorText != null) {
        errorText = null;
        notifyListeners();
      }
    }
  }

  Future<bool> save(BuildContext context) async {
    final value = controller.text.trim();
    if (!_emailRegex.hasMatch(value)) {
      errorText = 'Enter a valid email';
      notifyListeners();
      return false;
    }

    saving = true;
    notifyListeners();
    try {
      await onSave(value);
      return true;
    } catch (e) {
      saving = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update email: $e'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  @override
  void dispose() {
    controller.removeListener(_validateLive);
    controller.dispose();
    super.dispose();
  }
}

// lib/widgets/edit_email_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditEmailModel extends ChangeNotifier {
  final Future<void> Function(String) onSave;
  final TextEditingController controller;
  String? errorText;
  bool saving = false;

  EditEmailModel(String initialEmail, this.onSave) : controller = TextEditingController(text: initialEmail);

  void clearError() {
    if (errorText != null) {
      errorText = null;
      notifyListeners();
    }
  }

  Future<bool> save(BuildContext context) async {
    final value = controller.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
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
    controller.dispose();
    super.dispose();
  }
}

class EditEmailDialog extends StatelessWidget {
  final String initialEmail;
  final Future<void> Function(String) onSave;

  const EditEmailDialog({Key? key, required this.initialEmail, required this.onSave}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditEmailModel>(
        create: (_) => EditEmailModel(initialEmail, onSave),
        child: Consumer<EditEmailModel>(
            builder: (context, model, _) => AlertDialog(
                    title: const Text('Edit email'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: model.controller,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(labelText: 'Email', errorText: model.errorText),
                          onChanged: (_) => model.clearError())
                    ]),
                    actions: [
                      TextButton(onPressed: model.saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
                      ElevatedButton(
                          onPressed: model.saving
                              ? null
                              : () async {
                                  final ok = await model.save(context);
                                  if (ok && context.mounted) Navigator.of(context).pop();
                                },
                          child: const Text('Save'))
                    ])));
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/login_ui_provider.dart';
import 'approval_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();

  Future<void> _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final ui = Provider.of<LoginUiProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await ui.login(ui.username, ui.password, auth);
      if (success) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ApprovalScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login failed. Please check your username and password.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Form(
                            key: _formKey,
                            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              Consumer<LoginUiProvider>(
                                  builder: (context, ui, _) => TextFormField(
                                      initialValue: ui.username,
                                      onChanged: ui.setUsername,
                                      decoration: const InputDecoration(labelText: 'Korisnik', prefixIcon: Icon(Icons.person_outline)),
                                      autofillHints: const [AutofillHints.username],
                                      textInputAction: TextInputAction.next,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Unesite korisnika';
                                        }
                                        return null;
                                      })),
                              const SizedBox(height: 12),
                              Consumer<LoginUiProvider>(
                                  builder: (context, ui, _) => TextFormField(
                                      initialValue: ui.password,
                                      onChanged: ui.setPassword,
                                      obscureText: ui.obscurePassword,
                                      decoration: InputDecoration(
                                          labelText: 'Lozinka',
                                          prefixIcon: const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(icon: Icon(ui.obscurePassword ? Icons.visibility : Icons.visibility_off), onPressed: ui.toggleObscure)),
                                      autofillHints: const [AutofillHints.password],
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => ui.isLoading ? null : _login(context),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Unesite lozinku';
                                        }
                                        return null;
                                      })),
                              const SizedBox(height: 20),
                              Consumer<LoginUiProvider>(
                                  builder: (context, ui, _) => SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: ui.isLoading ? null : () => _login(context),
                                        style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                        child: ui.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Login'),
                                      )))
                            ])))))));
  }
}

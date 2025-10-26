import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/login_ui_provider.dart';
import 'approval_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final ui = Provider.of<LoginUiProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await ui.login(_usernameController.text, _passwordController.text, auth);
      if (success) {
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ApprovalScreen()));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid credentials. Try: operator/password'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.6)])),
            child: SafeArea(
                child: Center(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Form(
                                    key: _formKey,
                                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue),
                                      const SizedBox(height: 24),
                                      const Text('Operator Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text('Access reservation management', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                      const SizedBox(height: 32),
                                      TextFormField(
                                          controller: _usernameController,
                                          decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person)),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter username';
                                            }
                                            return null;
                                          }),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                          controller: _passwordController,
                                          obscureText: Provider.of<LoginUiProvider>(context).obscurePassword,
                                          decoration: InputDecoration(
                                              labelText: 'Password',
                                              prefixIcon: const Icon(Icons.lock),
                                              suffixIcon: Consumer<LoginUiProvider>(
                                                  builder: (context, ui, _) =>
                                                      IconButton(icon: Icon(ui.obscurePassword ? Icons.visibility : Icons.visibility_off), onPressed: ui.toggleObscure))),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter password';
                                            }
                                            return null;
                                          }),
                                      const SizedBox(height: 32),
                                      SizedBox(
                                          width: double.infinity,
                                          child: Consumer<LoginUiProvider>(
                                              builder: (context, ui, _) => ElevatedButton(
                                                  onPressed: ui.isLoading ? null : _login,
                                                  style: ElevatedButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                                  child: ui.isLoading
                                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                      : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))))),
                                      const SizedBox(height: 16),
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Back to Booking'))
                                    ])))))))));
  }
}

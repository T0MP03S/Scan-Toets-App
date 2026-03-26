import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:toets_scan_app/config/theme.dart';
import 'package:toets_scan_app/providers/auth_provider.dart';
import 'package:toets_scan_app/widgets/snackbar_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _showRegister = false;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _loginEmailController.text.trim(),
      _loginPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      showAppSnackBar(context, 'Welkom terug!', type: SnackBarType.success);
      context.go('/dashboard');
    } else {
      showAppSnackBar(context, auth.error ?? 'Inloggen mislukt', type: SnackBarType.error);
      auth.clearError();
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _registerEmailController.text.trim(),
      _registerPasswordController.text,
      _registerNameController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      showAppSnackBar(context, 'Account aangemaakt! Welkom.', type: SnackBarType.success);
      context.go('/dashboard');
    } else {
      showAppSnackBar(context, auth.error ?? 'Registratie mislukt', type: SnackBarType.error);
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.scanLine,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Toets Scan',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _showRegister
                      ? 'Maak een account aan om te beginnen'
                      : 'Log in om toetsen te scannen en te analyseren',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _showRegister
                        ? _buildRegisterForm(isLoading)
                        : _buildLoginForm(isLoading),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => setState(() => _showRegister = !_showRegister),
                  child: Text(
                    _showRegister
                        ? 'Al een account? Log in'
                        : 'Nog geen account? Registreer',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mailadres',
              prefixIcon: Icon(LucideIcons.mail, size: 18),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vul je e-mailadres in';
              if (!value.contains('@')) return 'Ongeldig e-mailadres';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            decoration: InputDecoration(
              labelText: 'Wachtwoord',
              prefixIcon: const Icon(LucideIcons.lock, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vul je wachtwoord in';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleLogin,
              child: isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Inloggen'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(bool isLoading) {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _registerNameController,
            decoration: const InputDecoration(
              labelText: 'Volledige naam',
              prefixIcon: Icon(LucideIcons.user, size: 18),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vul je naam in';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mailadres',
              prefixIcon: Icon(LucideIcons.mail, size: 18),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vul je e-mailadres in';
              if (!value.contains('@')) return 'Ongeldig e-mailadres';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerPasswordController,
            obscureText: _obscureRegisterPassword,
            decoration: InputDecoration(
              labelText: 'Wachtwoord (min. 8 tekens)',
              prefixIcon: const Icon(LucideIcons.lock, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegisterPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureRegisterPassword = !_obscureRegisterPassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vul een wachtwoord in';
              if (value.length < 8) return 'Wachtwoord moet minimaal 8 tekens zijn';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleRegister,
              child: isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Registreren'),
            ),
          ),
        ],
      ),
    );
  }
}

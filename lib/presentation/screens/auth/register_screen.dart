import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/config/helpers/auth_validators.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/widgets/auth/auth_field.dart';
import 'package:toktok/presentation/widgets/auth/auth_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusScope.of(context).unfocus();

    final error = await context.read<AuthProvider>().register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<AuthProvider>().isSubmitting;

    return AuthLayout(
      title: 'Crear cuenta',
      subtitle: 'El nombre se muestra en los videos que subas.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: 'Volver al ingreso',
                child: TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Volver'),
                ),
              ),
            ),
            AuthField(
              controller: _nameController,
              focusNode: _nameFocus,
              label: 'Nombre',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: AuthValidators.name,
              onFieldSubmitted: (_) => _emailFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            AuthField(
              controller: _emailController,
              focusNode: _emailFocus,
              label: 'Correo',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: AuthValidators.email,
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            AuthField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: 'Contraseña',
              obscureText: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: AuthValidators.password,
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            AuthField(
              controller: _confirmController,
              focusNode: _confirmFocus,
              label: 'Repetir contraseña',
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: (value) => AuthValidators.confirmPassword(
                value,
                _passwordController.text,
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            Semantics(
              button: true,
              label: 'Registrarse',
              child: FilledButton(
                onPressed: isSubmitting ? null : _submit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear cuenta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

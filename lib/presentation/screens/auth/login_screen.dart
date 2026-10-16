import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/config/helpers/auth_validators.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/screens/auth/register_screen.dart';
import 'package:toktok/presentation/widgets/auth/auth_field.dart';
import 'package:toktok/presentation/widgets/auth/auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusScope.of(context).unfocus();

    final error = await context.read<AuthProvider>().signIn(
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
      title: 'TokTik',
      subtitle: 'Ingresá para ver y subir videos.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: AuthValidators.password,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              Semantics(
                button: true,
                label: 'Iniciar sesión',
                child: FilledButton(
                  onPressed: isSubmitting ? null : _submit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ingresar'),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                button: true,
                label: 'Crear una cuenta nueva',
                child: TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                  child: const Text('Crear cuenta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

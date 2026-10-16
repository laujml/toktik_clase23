import 'package:flutter/material.dart';

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.textInputAction,
    required this.onFieldSubmitted,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final TextInputAction textInputAction;
  final ValueChanged<String> onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(labelText: label),
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      enableSuggestions: !obscureText,
      autocorrect: !obscureText,
    );
  }
}

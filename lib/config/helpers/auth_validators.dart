class AuthValidators {
  const AuthValidators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresá tu nombre.';
    if (text.length < 2) return 'El nombre es muy corto.';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresá tu correo.';
    if (!_emailPattern.hasMatch(text)) return 'Ingresá un correo válido.';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Ingresá tu contraseña.';
    if (text.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Repetí la contraseña.';
    if (value != original) return 'Las contraseñas no coinciden.';
    return null;
  }

  static String? caption(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Agregá una descripción.';
    if (text.length > 150) {
      return 'La descripción puede tener hasta 150 caracteres.';
    }
    return null;
  }
}

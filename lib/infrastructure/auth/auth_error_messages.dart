String messageForAuthCode(String code) {
  switch (code) {
    case 'invalid-email':
      return 'El correo no tiene un formato válido.';
    case 'user-disabled':
      return 'Esta cuenta está deshabilitada.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Correo o contraseña incorrectos.';
    case 'email-already-in-use':
      return 'Ese correo ya está registrado.';
    case 'weak-password':
      return 'La contraseña es muy débil. Usá al menos 6 caracteres.';
    case 'network-request-failed':
      return 'Sin conexión. Revisá tu red e intentá de nuevo.';
    case 'too-many-requests':
      return 'Demasiados intentos. Esperá un momento y volvé a intentar.';
    case 'operation-not-allowed':
      return 'El ingreso con correo no está habilitado. Activalo en Firebase Authentication.';
    default:
      return 'No se pudo completar la operación. Intentá de nuevo.';
  }
}

String messageForFirebaseCode(String code) {
  switch (code) {
    case 'permission-denied':
      return 'No tenés permiso para hacer eso. Revisá que hayas iniciado sesión.';
    case 'unavailable':
    case 'network-request-failed':
    case 'deadline-exceeded':
      return 'Sin conexión con el servidor. Revisá tu red e intentá de nuevo.';
    case 'unauthenticated':
      return 'Tu sesión venció. Volvé a iniciar sesión.';
    case 'not-found':
      return 'No se encontró el video.';
    case 'cancelled':
      return 'La operación se canceló.';
    default:
      return 'Ocurrió un error de red. Intentá de nuevo.';
  }
}

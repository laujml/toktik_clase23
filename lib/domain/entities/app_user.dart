class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  final String uid;
  final String email;
  final String displayName;

  String get authorName {
    final name = displayName.trim();
    if (name.isNotEmpty) return name;
    final at = email.indexOf('@');
    if (at > 0) return email.substring(0, at);
    return 'Usuario';
  }
}

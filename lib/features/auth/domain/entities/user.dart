// ============================================
// FILE 1: lib/features/auth/domain/entities/user.dart
// ============================================
class AppUser {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final DateTime createdAt;
  final String locale;
  final String timezone;

  AppUser({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    required this.createdAt,
    this.locale = 'np',
    this.timezone = 'Asia/Kathmandu',
  });
}

// ============================================
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';

class UserModel extends AppUser {
  UserModel({
    required super.id,
    required super.email,
    super.name,
    super.phone,
    required super.createdAt,
    super.locale,
    super.timezone,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'],
      phone: data['phone'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      locale: data['locale'] ?? 'np',
      timezone: data['timezone'] ?? 'Asia/Kathmandu',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
      'locale': locale,
      'timezone': timezone,
    };
  }
}
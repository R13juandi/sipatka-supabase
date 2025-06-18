import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String parentName;
  final String studentName;
  final String className;
  final String role; // 'user' atau 'admin'
  final double saldo;

  UserModel({
    required this.uid,
    required this.email,
    required this.parentName,
    required this.studentName,
    required this.className,
    required this.role,
    required this.saldo,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      parentName: data['parentName'] ?? '',
      studentName: data['studentName'] ?? '',
      className: data['className'] ?? '',
      role: data['role'] ?? 'user',
      saldo: (data['saldo'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'parentName': parentName,
      'studentName': studentName,
      'className': className,
      'role': role,
      'saldo': saldo,
    };
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sipatka/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _userModel;
  User? _firebaseUser;
  bool _isLoading = true;

  UserModel? get userModel => _userModel;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isLoading => _isLoading;
  String get userName => _userModel?.parentName ?? '';
  String get userEmail => _userModel?.email ?? '';
  String get studentName => _userModel?.studentName ?? '';
  String get className => _userModel?.className ?? '';
  String get userRole => _userModel?.role ?? 'user';

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      await _fetchUserModel(user.uid);
    } else {
      _userModel = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchUserModel(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
      } else {
        print("Dokumen user dengan UID $uid tidak ditemukan di Firestore.");
        _userModel = null;
      }
    } catch (e) {
      print("Error saat mengambil data user dari Firestore: $e");
    }
  }

  Future<UserModel?> getUserModelById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      print("Error fetching user model by ID: $e");
    }
    return null;
  }

  // --- FUNGSI LOGIN DENGAN PERBAIKAN CATCH ERROR ---
  Future<bool> login(String email, String password) async {
    try {
      // Tahap 1: Autentikasi
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Tahap 2: Mengambil data dari Firestore
      await _fetchUserModel(userCredential.user!.uid);

      notifyListeners();
      return true;
    } catch (e) {
      // Blok catch ini sekarang akan menangkap SEMUA jenis error
      // (Baik dari Auth maupun dari Firestore)
      print("!!! PENYEBAB LOGIN GAGAL: $e");
      return false;
    }
  }

  // --- FUNGSI REGISTER DENGAN PERBAIKAN CATCH ERROR ---
  Future<bool> register({
    required String parentName,
    required String email,
    required String password,
    required String studentName,
    required String className,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User newUser = userCredential.user!;
      _userModel = UserModel(
          uid: newUser.uid,
          email: email.trim(),
          parentName: parentName,
          studentName: studentName,
          className: className,
          role: 'user',
          saldo: 0.0);

      await _firestore
          .collection('users')
          .doc(newUser.uid)
          .set(_userModel!.toMap());
      await _fetchUserModel(newUser.uid);
      notifyListeners();
      return true;
    } catch (e) {
      // Blok catch ini juga menangkap SEMUA jenis error
      print("!!! PENYEBAB REGISTER GAGAL: $e");
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _userModel = null;
    _firebaseUser = null;
    notifyListeners();
  }
}
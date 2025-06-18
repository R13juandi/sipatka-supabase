import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../models/payment_model.dart';

class PaymentProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //final FirebaseStorage _storage = FirebaseStorage.instance;

  List<Payment> _payments = [];
  bool _isLoading = false;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;

  double get totalPaidAmount => _payments
      .where((p) => p.status == PaymentStatus.paid)
      .fold(0, (sum, item) => sum + item.amount);

  void fetchPayments(String userId) {
    if (userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .listen((snapshot) {
      _payments =
          snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      print("Error fetching payments: $error");
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> uploadProofOfPayment(
      String paymentId, File imageFile, String paymentMethod) async {
    // GANTI DENGAN API KEY ANDA
    const String apiKey = "4b1c984841c787d36cb6d8f46e8864cf";

    final uri = Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey");

    try {
      // 1. Buat request untuk upload gambar
      var request = http.MultipartRequest('POST', uri);

      // 2. Lampirkan file gambar
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));

      // 3. Kirim request dan tunggu responsenya
      print("Mengupload ke ImgBB...");
      var response = await request.send();

      if (response.statusCode == 200) {
        // 4. Baca dan parse response JSON
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);
        final String downloadUrl = jsonResponse['data']['url'];

        print("Upload berhasil. URL Gambar: $downloadUrl");

        // 5. Simpan URL ke Firestore (bagian ini tetap sama)
        await _firestore.collection('payments').doc(paymentId).update({
          'proofOfPaymentUrl': downloadUrl,
          'status': 'pending',
          'paidDate': Timestamp.now(),
          'paymentMethod': paymentMethod,
        });

        return true; // Berhasil
      } else {
        // Jika upload gagal
        final responseBody = await response.stream.bytesToString();
        print(
            "Gagal upload ke ImgBB. Status: ${response.statusCode}, Body: $responseBody");
        return false;
      }
    } catch (e) {
      print("Error saat upload bukti (ImgBB): $e");
      return false;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/models/user_model.dart';

class AdminProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<UserModel>> getStudents() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'user')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  Future<bool> createBill(
      String userId, String month, double amount, DateTime dueDate) async {
    try {
      await _firestore.collection('payments').add({
        'userId': userId,
        'month': month,
        'amount': amount,
        'dueDate': Timestamp.fromDate(dueDate),
        'status': 'unpaid',
        'isVerified': false,
        'paidDate': null,
        'paymentMethod': null,
        'proofOfPaymentUrl': null,
        'denda': 0.0,
        'dendaDiterapkan': false,
      });
      return true;
    } catch (e) {
      print("Error creating bill: $e");
      return false;
    }
  }

  Stream<List<Payment>> getPendingPayments() {
    return _firestore
        .collection('payments')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList());
  }

  Future<String> confirmPaymentWithAmount(
      String paymentId, double actualAmount) async {
    try {
      final functions =
          FirebaseFunctions.instanceFor(region: 'asia-southeast1');
      final callable =
          functions.httpsCallable('confirmPaymentAndManageBalance');
      final response = await callable.call({
        'paymentId': paymentId,
        'actualAmountPaid': actualAmount,
      });
      return response.data['message'] ?? 'Proses berhasil';
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? "Terjadi error tidak diketahui";
    } catch (e) {
      return "Terjadi error pada aplikasi.";
    }
  }

  Future<bool> rejectPayment(String paymentId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'unpaid',
        'proofOfPaymentUrl': FieldValue.delete(),
        'paidDate': FieldValue.delete(),
        'paymentMethod': FieldValue.delete(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, double>> getFinancialSummary() async {
    double totalIncome = 0;
    double monthlyIncome = 0;
    double totalArrears = 0;

    try {
      final paymentsSnapshot = await _firestore.collection('payments').get();

      if (paymentsSnapshot.docs.isNotEmpty) {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

        for (var doc in paymentsSnapshot.docs) {
          final payment = Payment.fromFirestore(doc);

          if (payment.status == PaymentStatus.paid) {
            totalIncome += payment.amount + payment.denda;

            if (payment.paidDate != null &&
                payment.paidDate!.isAfter(startOfMonth) &&
                payment.paidDate!.isBefore(endOfMonth)) {
              monthlyIncome += payment.amount + payment.denda;
            }
          }

          if (payment.status == PaymentStatus.unpaid ||
              payment.status == PaymentStatus.overdue) {
            totalArrears += payment.amount + payment.denda;
          }
        }
      }

      return {
        'totalIncome': totalIncome,
        'monthlyIncome': monthlyIncome,
        'totalArrears': totalArrears,
      };
    } catch (e) {
      print("Error calculating financial summary: $e");
      return {
        'totalIncome': 0,
        'monthlyIncome': 0,
        'totalArrears': 0,
      };
    }
  }

  Stream<List<Payment>> getPaymentsForStudent(String uid) {
    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: uid)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList());
  }

  Future<bool> updateStudentData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      notifyListeners();
      return true;
    } catch (e) {
      print("Gagal update data siswa: $e");
      return false;
    }
  }

  Future<bool> deleteStudent(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      return true;
    } catch (e) {
      print("Gagal menghapus siswa: $e");
      return false;
    }
  }

  Future<UserModel?> getStudentById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      print("Error fetching student by ID: $e");
    }
    return null;
  }

  // --- METHOD BARU DITAMBAHKAN DI SINI ---
  Future<Map<String, dynamic>> getFilteredFinancialReport(
      {required DateTime startDate, required DateTime endDate}) async {
    double filteredIncome = 0;
    List<Payment> transactions = [];

    try {
      // Query untuk mengambil pembayaran lunas dalam rentang tanggal
      // Pastikan endDate diatur ke akhir hari untuk mencakup semua transaksi di tanggal tsb
      final endOfDay =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('payments')
          .where('status', isEqualTo: 'paid')
          .where('paidDate', isGreaterThanOrEqualTo: startDate)
          .where('paidDate', isLessThanOrEqualTo: endOfDay)
          .orderBy('paidDate', descending: true) // Butuh index
          .get();

      for (var doc in snapshot.docs) {
        final payment = Payment.fromFirestore(doc);
        transactions.add(payment);
        filteredIncome += payment.amount + payment.denda;
      }

      return {
        'filteredIncome': filteredIncome,
        'transactions': transactions,
      };
    } catch (e) {
      print("Error getting filtered report: $e");
      // Jika terjadi error (misal index belum siap), kembalikan data kosong
      return {
        'filteredIncome': 0.0,
        'transactions': [],
      };
    }
  }
}

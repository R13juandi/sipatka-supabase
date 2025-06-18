// lib/models/payment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum PaymentStatus { paid, pending, unpaid, overdue }

class Payment {
  final String id;
  final String userId;
  final String month;
  final double amount;
  final DateTime dueDate;
  PaymentStatus status;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? proofOfPaymentUrl;
  final bool isVerified;
  final double denda;
  final bool dendaDiterapkan;

  Payment({
    required this.id,
    required this.userId,
    required this.month,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidDate,
    this.paymentMethod,
    this.proofOfPaymentUrl,
    this.isVerified = false,
    this.denda = 0.0,
    this.dendaDiterapkan = false,
  });

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    String statusString = data['status'] ?? 'unpaid';
    PaymentStatus status;

    switch (statusString) {
      case 'paid':
        status = PaymentStatus.paid;
        break;
      case 'pending':
        status = PaymentStatus.pending;
        break;
      default:
        status = PaymentStatus.unpaid;
    }

    if (status == PaymentStatus.unpaid &&
        (data['dueDate'] as Timestamp).toDate().isBefore(DateTime.now())) {
      status = PaymentStatus.overdue;
    }

    return Payment(
      id: doc.id,
      userId: data['userId'] ?? '',
      month: data['month'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      status: status,
      paidDate: data['paidDate'] != null
          ? (data['paidDate'] as Timestamp).toDate()
          : null,
      paymentMethod: data['paymentMethod'],
      proofOfPaymentUrl: data['proofOfPaymentUrl'],
      isVerified: data['isVerified'] ?? false,
      denda: (data['denda'] ?? 0.0).toDouble(),
      dendaDiterapkan: data['dendaDiterapkan'] ?? false,
    );
  }
}

// --- TAMBAHKAN EXTENSION INI DI LUAR CLASS ---
extension PaymentStatusInfo on Payment {
  Map<String, dynamic> getStatusInfo() {
    switch (status) {
      case PaymentStatus.paid:
        return {
          'text': 'Lunas',
          'color': Colors.green,
          'icon': Icons.check_circle
        };
      case PaymentStatus.pending:
        return {
          'text': 'Menunggu Verifikasi',
          'color': Colors.orange,
          'icon': Icons.pending
        };
      case PaymentStatus.unpaid:
        return {
          'text': 'Belum Bayar',
          'color': Colors.red,
          'icon': Icons.error
        };
      case PaymentStatus.overdue:
        return {
          'text': 'Terlambat',
          'color': Colors.red.shade800,
          'icon': Icons.warning
        };
    }
  }
}
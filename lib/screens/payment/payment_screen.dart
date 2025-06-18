// lib/screens/payment/payment_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/utils/app_theme.dart';
import '../../providers/payment_provider.dart';
import '../../models/payment_model.dart';
import 'upload_proof_screen.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PaymentProvider>(
        builder: (context, payment, _) {
          if (payment.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final unpaidPayments = payment.payments
              .where((p) =>
                  p.status == PaymentStatus.unpaid ||
                  p.status == PaymentStatus.overdue)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pembayaran SPP',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (unpaidPayments.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle,
                              size: 80, color: Colors.green),
                          SizedBox(height: 16),
                          Text(
                            'Semua tagihan sudah lunas!',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...unpaidPayments.map((p) => _buildPaymentCard(context, p)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    final isOverdue = payment.status == PaymentStatus.overdue;
    final totalAmount = payment.amount + payment.denda;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  payment.month,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (isOverdue)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'TERLAMBAT',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Jatuh tempo: ${DateFormat('dd MMMM yyyy').format(payment.dueDate)}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            if (payment.denda > 0)
              Text("Denda: ${currencyFormat.format(payment.denda)}",
                  style: const TextStyle(color: Colors.red)),
            const Divider(),

            // --- PERBAIKAN OVERFLOW ADA DI SINI ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  // 1. Bungkus Text dengan Expanded
                  child: Text(
                    currencyFormat.format(totalAmount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16), // 2. Beri jarak
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UploadProofScreen(payment: payment),
                      ),
                    );
                  },
                  child: const Text('Bayar Sekarang'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

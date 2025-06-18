import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/payment_provider.dart';
import '../../models/payment_model.dart';
import '../../utils/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PaymentProvider>(
        builder: (context, payment, _) {
          final currencyFormat =
              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

          if (payment.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Riwayat Pembayaran',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total Pembayaran Lunas',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        currencyFormat.format(payment.totalPaidAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                if (payment.payments.isEmpty)
                  const Center(child: Text("Tidak ada riwayat pembayaran."))
                else
                  // Payment History List
                  ...payment.payments
                      .map((p) => _buildHistoryItem(p, currencyFormat)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(Payment payment, NumberFormat currencyFormat) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (payment.status) {
      case PaymentStatus.paid:
        statusColor = Colors.green;
        statusText = 'Lunas';
        statusIcon = Icons.check_circle;
        break;
      case PaymentStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Menunggu Verifikasi';
        statusIcon = Icons.pending;
        break;
      case PaymentStatus.unpaid:
        statusColor = Colors.red;
        statusText = 'Belum Bayar';
        statusIcon = Icons.error;
        break;
      case PaymentStatus.overdue:
        statusColor = Colors.red.shade800;
        statusText = 'Terlambat';
        statusIcon = Icons.warning;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(payment.month),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Jatuh tempo: ${DateFormat('dd MMM yyyy').format(payment.dueDate)}'),
            if (payment.paidDate != null)
              Text(
                  'Dibayar: ${DateFormat('dd MMM yyyy').format(payment.paidDate!)}'),
            if (payment.paymentMethod != null)
              Text('Metode: ${payment.paymentMethod}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(payment.amount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              statusText,
              style: TextStyle(color: statusColor, fontSize: 12),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
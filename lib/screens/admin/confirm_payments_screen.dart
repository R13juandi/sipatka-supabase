// lib/screens/admin/confirm_payments_screen.dart

import 'package:cloud_functions/cloud_functions.dart'; // <-- Pastikan import ini ada
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/models/user_model.dart';
import 'package:sipatka/providers/admin_provider.dart';
import 'package:sipatka/providers/auth_provider.dart';

class ConfirmPaymentsScreen extends StatelessWidget {
  const ConfirmPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pembayaran')),
      body: StreamBuilder<List<Payment>>(
        stream: adminProvider.getPendingPayments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Tidak ada pembayaran yang perlu dikonfirmasi.'));
          }
          final payments = snapshot.data!;
          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(payment.month),
                  subtitle: FutureProvider<UserModel?>.value(
                    value: context
                        .read<AuthProvider>()
                        .getUserModelById(payment.userId),
                    initialData: null,
                    child: Consumer<UserModel?>(
                      builder: (context, user, child) {
                        if (user == null) {
                          return const Text("Memuat nama...");
                        }
                        return Text(
                            'Siswa: ${user.studentName}\nJumlah: ${currencyFormat.format(payment.amount + payment.denda)}');
                      },
                    ),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _showConfirmationDialog(context, payment, adminProvider),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showConfirmationDialog(
      BuildContext context, Payment payment, AdminProvider provider) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi: ${payment.month}'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Bukti Pembayaran:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (payment.proofOfPaymentUrl != null &&
                      payment.proofOfPaymentUrl!.isNotEmpty)
                    // --- PERBAIKAN GAMBAR GAGAL LOAD ADA DI SINI ---
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        payment.proofOfPaymentUrl!,
                        fit: BoxFit.cover,
                        // Tampilkan loading indicator saat gambar dimuat
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                        // Tampilkan ikon error jika gambar gagal dimuat
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red),
                              SizedBox(height: 8),
                              Text("Gagal memuat gambar"),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    const Text('Tidak ada bukti pembayaran.'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Diterima (Rp)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Jumlah tidak boleh kosong';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Masukkan angka yang valid';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // ... logika tolak pembayaran (opsional)
              },
              child: const Text('Tolak', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final actualAmount = double.parse(amountController.text);

                  showDialog(
                      context: context,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                      barrierDismissible: false);

                  // --- PERBAIKAN ERROR NOT_FOUND ADA DI SINI ---
                  try {
                    final message = await provider.confirmPaymentWithAmount(
                        payment.id, actualAmount);

                    if (context.mounted) {
                      Navigator.pop(context); // Tutup loading
                      Navigator.pop(context); // Tutup dialog konfirmasi
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(message),
                        backgroundColor: message.contains('berhasil')
                            ? Colors.green
                            : Colors.orange,
                      ));
                    }
                  } on FirebaseFunctionsException catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Tutup loading
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "Error: ${e.message}"), // Tampilkan pesan dari server
                        backgroundColor: Colors.red,
                      ));
                    }
                  }
                }
              },
              child: const Text('Konfirmasi'),
            ),
          ],
        );
      },
    );
  }
}

// lib/screens/admin/payment_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/utils/helpers.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  const PaymentConfirmationScreen({super.key});

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  late Stream<List<Map<String, dynamic>>> _pendingPaymentsStream;

  @override
  void initState() {
    super.initState();
    _pendingPaymentsStream = supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at')
        .map((maps) => maps.cast<Map<String, dynamic>>());
  }
  
  Future<String> _getStudentName(String studentId) async {
    try {
      final response = await supabase.from('students').select('full_name').eq('id', studentId).single();
      return response['full_name'] ?? 'Siswa tidak diketahui';
    } catch(e) {
      return '...';
    }
  }

  Future<void> _updatePaymentStatus(String paymentId, String newStatus) async {
    try {
      await supabase.from('payments').update({'status': newStatus}).eq('id', paymentId);
      if(mounted) showSuccessSnackBar(context, 'Status pembayaran berhasil diperbarui.');
    } catch (e) {
      if(mounted) showErrorSnackBar(context, 'Gagal memperbarui status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _pendingPaymentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final payments = snapshot.data ?? [];
        if (payments.isEmpty) {
          return const Center(child: Text('Tidak ada pembayaran yang perlu dikonfirmasi.'));
        }

        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _getStudentName(payment['student_id']),
                      builder: (context, nameSnapshot) {
                        return Text(
                          '${payment['month']} ${payment['year']} - ${nameSnapshot.data ?? '...'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('Tanggal Upload: ${DateFormat.yMd('id_ID').add_Hms().format(DateTime.parse(payment['paid_at']))}'),
                    const SizedBox(height: 8),
                    if (payment['proof_of_payment_url'] != null)
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text('Lihat Bukti Bayar'),
                          onPressed: () {
                            showDialog(context: context, builder: (_) => Dialog(
                              child: InteractiveViewer(child: Image.network(payment['proof_of_payment_url']))
                            ));
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _updatePaymentStatus(payment['id'], 'rejected'),
                          child: const Text('Tolak', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _updatePaymentStatus(payment['id'], 'confirmed'),
                          child: const Text('Konfirmasi'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
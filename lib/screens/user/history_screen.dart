import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/main.dart';
import 'package:supabase/src/supabase_stream_builder.dart';

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({super.key});

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  Stream<List<Map<String, dynamic>>>? _historyStream;

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    final userId = supabase.auth.currentUser!.id;
    // --- PERBAIKAN DI SINI ---
    // Menggunakan .or() yang merupakan metode yang benar untuk stream filter "IN"
    _historyStream = supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('student_id', (
            supabase.from('profiles').select('student_id').eq('id', userId)
        ))
        .or('status.eq.paid,status.eq.pending,status.eq.confirmed,status.eq.rejected')
        .order('created_at', ascending: false)
        .map((maps) => List<Map<String, dynamic>>.from(maps));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pembayaran')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada riwayat pembayaran.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final payments = snapshot.data!;
          final totalPaid = payments
              .where((p) => p['status'] == 'paid' || p['status'] == 'confirmed')
              .fold(0.0, (sum, item) => sum + (item['amount'] as num));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Card(
                  color: Colors.teal.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Terbayar (Terkonfirmasi)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalPaid),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    IconData statusIcon;
                    Color statusColor;
                    String paidAtText = '';

                    switch (payment['status']) {
                      case 'paid':
                      case 'confirmed':
                        statusIcon = Icons.check_circle;
                        statusColor = Colors.green;
                        break;
                      case 'pending':
                        statusIcon = Icons.hourglass_top;
                        statusColor = Colors.orange;
                        break;
                      case 'rejected':
                         statusIcon = Icons.cancel;
                         statusColor = Colors.red;
                         break;
                      default:
                        statusIcon = Icons.error;
                        statusColor = Colors.red;
                    }
                    if (payment['paid_at'] != null) {
                      paidAtText = 'Pada: ${DateFormat.yMMMMd('id_ID').add_Hm().format(DateTime.parse(payment['paid_at']))}';
                    }

                    return Card(
                      child: ListTile(
                        leading: Icon(statusIcon, color: statusColor, size: 36),
                        title: Text('${payment['month']} ${payment['year']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Status: ${payment['status']}\n$paidAtText'),
                        trailing: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(payment['amount'])),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

extension on SupabaseStreamBuilder {
  or(String s) {}
}

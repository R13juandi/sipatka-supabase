import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}
class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Future<Map<String, dynamic>>? _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _fetchDashboardData();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    // --- PERBAIKAN DI SINI ---
    final studentsCount = await supabase.from('students').count();
    final pendingPaymentsCount = await supabase.from('payments').count().eq('status', 'pending');
    final totalIncomeData = await supabase.from('payments').select('amount').or('status.eq.paid,status.eq.confirmed');
    
    double income = 0.0;
    if (totalIncomeData.isNotEmpty) {
        income = totalIncomeData.map((e) => (e['amount'] as num)).fold(0.0, (a, b) => a + b);
    }
    
    return {
      'total_students': studentsCount,
      'pending_payments': pendingPaymentsCount,
      'total_income': income,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => setState(() => _dashboardFuture = _fetchDashboardData()),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Selamat Datang, Admin!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildDashboardCard('Total Siswa', '${data['total_students']}', Icons.people, Colors.blue),
                  _buildDashboardCard('Pembayaran Pending', '${data['pending_payments']}', Icons.hourglass_top, Colors.orange),
                  _buildDashboardCard('Total Pemasukan', NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(data['total_income']), Icons.attach_money, Colors.green),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis,),
          ],
        ),
      ),
    );
  }
}

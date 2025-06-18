import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/models/user_model.dart';
import 'package:sipatka/providers/admin_provider.dart';
import 'package:sipatka/utils/app_theme.dart';

class LaporanKeuanganScreen extends StatefulWidget {
  const LaporanKeuanganScreen({super.key});

  @override
  State<LaporanKeuanganScreen> createState() => _LaporanKeuanganScreenState();
}

class _LaporanKeuanganScreenState extends State<LaporanKeuanganScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Future<Map<String, dynamic>>? _reportFuture;

  @override
  void initState() {
    super.initState();
    _getReportData();
  }

  void _getReportData() {
    final endOfDay =
        DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
    setState(() {
      _reportFuture = Provider.of<AdminProvider>(context, listen: false)
          .getFilteredFinancialReport(startDate: _startDate, endDate: endOfDay);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateFilter(),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _reportFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text("Terjadi error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(
                        child: Text(
                            'Gagal memuat data. Pastikan Indeks Firestore sudah dibuat.'));
                  }

                  final report = snapshot.data!;
                  final double filteredIncome = report['filteredIncome'] ?? 0.0;

                  // --- INI ADALAH PERBAIKAN FINAL YANG LEBIH AMAN ---
                  final List<Payment> transactions =
                      List<Payment>.from(report['transactions'] ?? []);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(
                        title: 'Total Pendapatan (Sesuai Filter)',
                        value: currencyFormat.format(filteredIncome),
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Daftar Transaksi Lunas",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Expanded(
                        child: transactions.isEmpty
                            ? const Center(
                                child: Text(
                                    "Tidak ada transaksi pada rentang tanggal ini."))
                            : ListView.builder(
                                itemCount: transactions.length,
                                itemBuilder: (context, index) {
                                  final payment = transactions[index];
                                  return _buildTransactionTile(
                                      payment, currencyFormat);
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Dari Tanggal", style: TextStyle(fontSize: 12)),
                  InkWell(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd MMM yyyy').format(_startDate)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sampai Tanggal", style: TextStyle(fontSize: 12)),
                  InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd MMM yyyy').format(_endDate)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.filter_list),
            label: const Text("Terapkan Filter"),
            onPressed: _getReportData,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Payment payment, NumberFormat formatter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(payment.month),
        subtitle: FutureProvider<UserModel?>.value(
          value: Provider.of<AdminProvider>(context, listen: false)
              .getStudentById(payment.userId),
          initialData: null,
          child: Consumer<UserModel?>(
            builder: (context, user, child) {
              return Text(
                  "Siswa: ${user?.studentName ?? '...'} | Dibayar: ${DateFormat('dd MMM yyyy').format(payment.paidDate!)}");
            },
          ),
        ),
        trailing: Text(formatter.format(payment.amount + payment.denda),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

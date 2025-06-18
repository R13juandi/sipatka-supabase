import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sipatka/main.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  Future<List<Map<String, dynamic>>>? _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = _fetchConfirmedPayments();
  }

  Future<List<Map<String, dynamic>>> _fetchConfirmedPayments() async {
    final response = await supabase
        .from('payments')
        .select('*, students(full_name)')
        .or('status.eq.paid,status.eq.confirmed')
        .order('paid_at', ascending: false);
    return response;
  }

  Future<void> _generateAndPrintPdf(List<Map<String, dynamic>> payments) async {
    final pdf = pw.Document();
    final totalIncome = payments.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as num),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header:
            (context) => pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Laporan Keuangan Sipatka',
                    style: pw.Theme.of(context).header3,
                  ),
                  pw.Text(DateFormat.yMMMMd('id_ID').format(DateTime.now())),
                ],
              ),
            ),
        build:
            (context) => [
              pw.Table.fromTextArray(
                headers: [
                  'Tanggal Konfirmasi',
                  'Siswa',
                  'Pembayaran Bulan',
                  'Jumlah',
                ],
                data:
                    payments
                        .map(
                          (p) => [
                            DateFormat.yMd(
                              'id_ID',
                            ).format(DateTime.parse(p['paid_at'])),
                            p['students']?['full_name'] ?? 'Siswa Dihapus',
                            '${p['month']} ${p['year']}',
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(p['amount']),
                          ],
                        )
                        .toList(),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Pemasukan: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(totalIncome),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _paymentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final payments = snapshot.data ?? [];
        final totalIncome = payments.fold<double>(
          0,
          (sum, item) => sum + (item['amount'] as num),
        );

        return Scaffold(
          floatingActionButton:
              payments.isNotEmpty
                  ? FloatingActionButton(
                    onPressed: () => _generateAndPrintPdf(payments),
                    tooltip: 'Cetak Laporan',
                    child: const Icon(Icons.print),
                  )
                  : null,
          body: RefreshIndicator(
            onRefresh:
                () async =>
                    setState(() => _paymentsFuture = _fetchConfirmedPayments()),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Total Pemasukan Terkonfirmasi: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalIncome)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child:
                      payments.isEmpty
                          ? const Center(
                            child: Text(
                              'Belum ada data pembayaran terkonfirmasi.',
                            ),
                          )
                          : ListView.builder(
                            itemCount: payments.length,
                            itemBuilder: (context, index) {
                              final payment = payments[index];
                              final student = payment['students'];
                              return ListTile(
                                title: Text(
                                  student != null
                                      ? student['full_name']
                                      : 'Siswa Dihapus',
                                ),
                                subtitle: Text(
                                  'Pembayaran bulan ${payment['month']} ${payment['year']}',
                                ),
                                trailing: Text(
                                  NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  ).format(payment['amount']),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// lib/screens/user/payment_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/utils/helpers.dart';

class UserPaymentScreen extends StatefulWidget {
  const UserPaymentScreen({super.key});

  @override
  State<UserPaymentScreen> createState() => _UserPaymentScreenState();
}

class _UserPaymentScreenState extends State<UserPaymentScreen> {
  Future<List<Map<String, dynamic>>>? _paymentsFuture;
  final Map<String, bool> _selectedMonths = {};
  double _totalAmount = 0.0;
  double _sppAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = _fetchPayments();
  }

  Future<List<Map<String, dynamic>>> _fetchPayments() async {
    final userId = supabase.auth.currentUser!.id;
    final profile = await supabase
        .from('profiles')
        .select('student_id')
        .eq('id', userId)
        .single();
    final studentId = profile['student_id'];

    if (studentId == null) {
      throw 'Siswa tidak ditemukan';
    }

    final studentData = await supabase
        .from('students')
        .select('spp_amount')
        .eq('id', studentId)
        .single();
    _sppAmount = (studentData['spp_amount'] as num).toDouble();

    final response = await supabase
        .from('payments')
        .select()
        .eq('student_id', studentId);
    
    final monthOrder = ['Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni'];
    response.sort((a, b) {
      int yearComp = a['year'].compareTo(b['year']);
      if (yearComp != 0) return yearComp;
      return monthOrder.indexOf(a['month']).compareTo(monthOrder.indexOf(b['month']));
    });

    return response;
  }
  
  void _onMonthSelected(bool? value, String monthId) {
    setState(() {
      _selectedMonths[monthId] = value ?? false;
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double total = 0;
    _selectedMonths.forEach((monthId, isSelected) {
      if (isSelected) {
        total += _sppAmount;
      }
    });
    setState(() {
      _totalAmount = total;
    });
  }

  void _showPaymentInstructions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Instruksi Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
              const SizedBox(height: 16),
              const Text('Silakan transfer sejumlah:'),
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_totalAmount),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text('Ke salah satu rekening berikut:'),
              const ListTile(leading: Icon(Icons.account_balance), title: Text('BCA'), subtitle: Text('7295237082 (a/n Yayasan)')),
              const ListTile(leading: Icon(Icons.account_balance), title: Text('Mandiri'), subtitle: Text('11221400941 (a/n Yayasan)')),
              const ListTile(leading: Icon(Icons.phone_android), title: Text('DANA'), subtitle: Text('081290589185 (a/n Heni Rizki Amalia)')),
              const SizedBox(height: 16),
              const Text('Setelah transfer, unggah bukti pembayaran.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _uploadProof,
                icon: const Icon(Icons.upload_file),
                label: const Text('Unggah Bukti Bayar'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadProof() async {
      final picker = ImagePicker();
      final imageFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (imageFile == null) return;
      
      if (!mounted) return;
      Navigator.pop(context); // Close the bottom sheet
      
      showSuccessSnackBar(context, 'Mengunggah bukti...');

      try {
        final userId = supabase.auth.currentUser!.id;
        final file = File(imageFile.path);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';
        final filePath = '$userId/$fileName';
        
        await supabase.storage.from('payment_proofs').upload(filePath, file);
        final imageUrl = supabase.storage.from('payment_proofs').getPublicUrl(filePath);

        final selectedPaymentIds = _selectedMonths.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();
        
        for (var paymentId in selectedPaymentIds) {
          await supabase.from('payments').update({
            'status': 'pending',
            'proof_of_payment_url': imageUrl,
            'paid_at': DateTime.now().toIso8601String(),
          }).eq('id', paymentId);
        }

        if(mounted) {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                    title: const Text('Upload Berhasil'),
                    content: const Text('Pembayaran Anda sedang diproses oleh tim admin. Silakan cek statusnya secara berkala di halaman Riwayat.'),
                    actions: [
                        TextButton(
                            onPressed: () {
                                if(mounted) Navigator.pop(context);
                                setState(() {
                                    _paymentsFuture = _fetchPayments();
                                    _selectedMonths.clear();
                                    _calculateTotal();
                                });
                            },
                            child: const Text('OK'),
                        )
                    ],
                )
            );
        }

      } catch (e) {
        if (mounted) showErrorSnackBar(context, 'Gagal mengunggah bukti: $e');
      }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bayar SPP')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _paymentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Data pembayaran tidak ditemukan.'));
          }

          final payments = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    final String monthId = payment['id'];
                    final bool isPaid = payment['status'] == 'paid' || payment['status'] == 'confirmed';
                    final bool isPending = payment['status'] == 'pending';
                    final bool isSelectable = !(isPaid || isPending);
                    
                    return Card(
                      color: isPaid ? Colors.green.shade50 : (isPending ? Colors.amber.shade50 : Colors.white),
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: CheckboxListTile(
                        title: Text('${payment['month']} ${payment['year']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Status: ${payment['status']}'),
                        secondary: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(payment['amount'])),
                        value: isSelectable ? (_selectedMonths[monthId] ?? false) : (isPaid || isPending),
                        onChanged: isSelectable ? (value) => _onMonthSelected(value, monthId) : null,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.teal,
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0,-5)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Tagihan Dipilih:', style: TextStyle(color: Colors.grey)),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_totalAmount),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _totalAmount > 0 ? _showPaymentInstructions : null,
                      child: const Text('BAYAR SEKARANG'),
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
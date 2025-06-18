// lib/screens/payment/upload_proof_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/providers/payment_provider.dart';
import 'package:sipatka/utils/app_theme.dart';

class UploadProofScreen extends StatefulWidget {
  final Payment payment;
  const UploadProofScreen({super.key, required this.payment});

  @override
  State<UploadProofScreen> createState() => _UploadProofScreenState();
}

class _UploadProofScreenState extends State<UploadProofScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _selectedMethod;
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

  // --- LANGKAH 1: Siapkan data rekening untuk setiap metode ---
  final Map<String, Map<String, String>> paymentDetails = {
    'Transfer Bank (BCA)': {
      'bank': 'BCA (Bank Central Asia)',
      'rekening': '7295237082',
      'nama': 'YAYASAN AN-NAAFI\'NUR'
    },
    'Transfer Bank (Mandiri)': {
      'bank': 'Bank Mandiri',
      'rekening': '1760005209604',
      'nama': 'YAYASAN AN-NAAFI\'NUR'
    },
    'E-Wallet (OVO)': {
      'bank': 'OVO',
      'rekening': '081290589185',
      'nama': 'TK AN-NAAFI\'NUR'
    },
    'E-Wallet (GoPay)': {
      'bank': 'GoPay',
      'rekening': '081290589185',
      'nama': 'TK AN-NAAFI\'NUR'
    },
    'E-Wallet (DANA)': {
      'bank': 'DANA',
      'rekening': '081290589185',
      'nama': 'TK AN-NAAFI\'NUR'
    },
  };

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadProof() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih metode pembayaran.')),
      );
      return;
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih gambar bukti pembayaran.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final success = await context
        .read<PaymentProvider>()
        .uploadProofOfPayment(widget.payment.id, _imageFile!, _selectedMethod!);

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Bukti pembayaran berhasil diunggah! Menunggu konfirmasi admin.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengunggah bukti pembayaran.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- LANGKAH 2: Logika untuk mendapatkan detail berdasarkan pilihan ---
    final details = paymentDetails[_selectedMethod];
    final totalAmount = widget.payment.amount + widget.payment.denda;

    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Bukti - ${widget.payment.month}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Metode & Lakukan Pembayaran',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // --- LANGKAH 4: Bangun dropdown dari data rekening ---
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              hint: const Text('Pilih metode yang digunakan'),
              isExpanded: true,
              items: paymentDetails.keys
                  .map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMethod = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Detail Transfer",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    // --- LANGKAH 3: Tampilkan detail transfer secara dinamis ---
                    if (details != null) ...[
                      _buildInfoRow('Tujuan', details['bank']!),
                      _buildInfoRow(
                          'No. Rekening / Telp', details['rekening']!),
                      _buildInfoRow('Atas Nama', details['nama']!),
                    ] else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Text(
                              "Pilih metode pembayaran untuk melihat detail.",
                              textAlign: TextAlign.center),
                        ),
                      ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Total Transfer',
                      currencyFormat.format(totalAmount),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload Bukti Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Center(
              child: _imageFile == null
                  ? Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                          child: Text('Belum ada gambar dipilih.')),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_imageFile!, height: 250)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Pilih dari Galeri'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_imageFile == null || _isUploading) ? null : _uploadProof,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Kirim Bukti Pembayaran'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

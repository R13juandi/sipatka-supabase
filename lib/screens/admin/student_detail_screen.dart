// lib/screens/admin/student_detail_screen.dart

import 'package:cloud_functions/cloud_functions.dart'; // <-- IMPORT BARU
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:sipatka/models/user_model.dart';
import 'package:sipatka/providers/admin_provider.dart';
import 'package:sipatka/utils/app_theme.dart';

class StudentDetailScreen extends StatefulWidget {
  final UserModel student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Key _profileCardKey;

  @override
  void initState() {
    super.initState();
    _profileCardKey = UniqueKey();
  }

  void _refreshProfile() {
    setState(() {
      _profileCardKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student.studentName),
        actions: [
          // --- TOMBOL KIRIM NOTIFIKASI BARU ---
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: "Kirim Notifikasi Pribadi",
            onPressed: () =>
                _showSendDirectNotificationDialog(context, widget.student),
          ),
          // ------------------------------------
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditStudentDialog(context, widget.student),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () =>
                _showDeleteConfirmation(context, widget.student.uid),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<UserModel?>(
              key: _profileCardKey,
              future: Provider.of<AdminProvider>(context, listen: false)
                  .getStudentById(widget.student.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return const Text("Gagal memuat data siswa.");
                }
                return _buildProfileCard(snapshot.data!);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              "Riwayat Tagihan",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildPaymentHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserModel student) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.child_care, "Nama Siswa", student.studentName),
            _buildInfoRow(Icons.class_, "Kelas", student.className),
            _buildInfoRow(Icons.person, "Nama Wali", student.parentName),
            _buildInfoRow(Icons.email, "Email", student.email),
            if (student.saldo > 0)
              _buildInfoRow(Icons.wallet, "Saldo",
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(student.saldo)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 16),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    return StreamBuilder<List<Payment>>(
      stream: adminProvider.getPaymentsForStudent(widget.student.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Belum ada riwayat tagihan."),
            ),
          );
        }
        final payments = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            return _buildPaymentTile(payments[index]);
          },
        );
      },
    );
  }

  Widget _buildPaymentTile(Payment payment) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    final totalAmount = payment.amount + payment.denda;
    final statusInfo = payment.getStatusInfo();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusInfo['icon'], color: statusInfo['color']),
        title: Text(payment.month),
        subtitle: Text(
            "Jatuh Tempo: ${DateFormat('dd MMM yyyy').format(payment.dueDate)}"),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(currencyFormat.format(totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(statusInfo['text'],
                style: TextStyle(color: statusInfo['color'], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showEditStudentDialog(BuildContext context, UserModel student) {
    final parentNameController = TextEditingController(text: student.parentName);
    final studentNameController = TextEditingController(text: student.studentName);
    final classNameController = TextEditingController(text: student.className);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Edit Data Siswa"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                      controller: parentNameController,
                      decoration: const InputDecoration(labelText: "Nama Wali")),
                  TextFormField(
                      controller: studentNameController,
                      decoration:
                          const InputDecoration(labelText: "Nama Siswa")),
                  TextFormField(
                      controller: classNameController,
                      decoration: const InputDecoration(labelText: "Kelas")),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newData = {
                    'parentName': parentNameController.text,
                    'studentName': studentNameController.text,
                    'className': classNameController.text,
                  };
                  final success = await context
                      .read<AdminProvider>()
                      .updateStudentData(student.uid, newData);
                  if (mounted) {
                    Navigator.pop(context); // Tutup dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(success
                              ? "Data berhasil diupdate"
                              : "Gagal mengupdate data")),
                    );
                    _refreshProfile(); // Panggil refresh
                  }
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Hapus Siswa"),
          content: const Text(
              "Apakah Anda yakin ingin menghapus data siswa ini? Tindakan ini tidak dapat dibatalkan."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final success =
                    await context.read<AdminProvider>().deleteStudent(uid);
                if (mounted) {
                  Navigator.pop(context); // Tutup dialog
                  Navigator.pop(context); // Kembali ke halaman daftar siswa
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(success
                            ? "Siswa berhasil dihapus"
                            : "Gagal menghapus siswa")),
                  );
                }
              },
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );
  }

  // --- METHOD BARU UNTUK DIALOG NOTIFIKASI ---
  void _showSendDirectNotificationDialog(
      BuildContext context, UserModel student) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Kirim Notifikasi ke ${student.parentName}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration:
                      const InputDecoration(labelText: 'Judul Notifikasi'),
                  validator: (v) =>
                      v!.isEmpty ? 'Judul tidak boleh kosong' : null,
                ),
                TextFormField(
                  controller: bodyController,
                  decoration: const InputDecoration(labelText: 'Isi Pesan'),
                  maxLines: 3,
                  validator: (v) =>
                      v!.isEmpty ? 'Isi pesan tidak boleh kosong' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    // Panggil Cloud Function
                    final functions = FirebaseFunctions.instanceFor(
                        region: 'asia-southeast1');
                    final callable =
                        functions.httpsCallable('sendDirectNotification');
                    await callable.call({
                      'userId': student.uid, // Kirim UID target
                      'title': titleController.text,
                      'body': bodyController.text,
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Notifikasi berhasil dikirim!'),
                            backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    print("Error memanggil cloud function: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Gagal mengirim notifikasi.'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Kirim'),
            ),
          ],
        );
      },
    );
  }
}
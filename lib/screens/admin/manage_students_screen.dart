// lib/screens/admin/manage_students_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/models/user_model.dart';
import 'package:sipatka/providers/admin_provider.dart';
import 'package:sipatka/screens/admin/admin_chat_detail_screen.dart';
import 'package:sipatka/screens/admin/student_detail_screen.dart';

class ManageStudentsScreen extends StatelessWidget {
  const ManageStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Siswa & Pesan')),
      body: StreamBuilder<List<UserModel>>(
        stream: adminProvider.getStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada data siswa terdaftar.'));
          }
          final students = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentDetailScreen(student: student),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    child: Text(student.studentName.isNotEmpty
                        ? student.studentName[0].toUpperCase()
                        : 'S'),
                  ),
                  title: Text(student.studentName),
                  subtitle: Text('Wali: ${student.parentName}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: "Chat dengan ${student.parentName}",
                        icon: const Icon(Icons.chat_bubble_outline),
                        color: Theme.of(context).primaryColor,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminChatDetailScreen(parent: student),
                            ),
                          );
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _showCreateBillDialog(
                              context, student, adminProvider);
                        },
                        child: const Text('Tagihan'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- PASTIKAN FUNGSI INI ADA DI DALAM CLASS ---
  void _showCreateBillDialog(
      BuildContext context, UserModel user, AdminProvider provider) {
    final monthController = TextEditingController();
    final amountController = TextEditingController();
    final dueDateController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Buat Tagihan untuk ${user.studentName}'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: monthController,
                    decoration: const InputDecoration(
                        labelText: 'Bulan (cth: Agustus 2025)'),
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                        labelText: 'Jumlah (cth: 350000)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: dueDateController,
                    decoration: const InputDecoration(
                        labelText: 'Tanggal Jatuh Tempo',
                        suffixIcon: Icon(Icons.calendar_today)),
                    readOnly: true,
                    onTap: () async {
                      selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (selectedDate != null) {
                        dueDateController.text =
                            DateFormat('dd-MM-yyyy').format(selectedDate!);
                      }
                    },
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                ],
              ),
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
                  final success = await provider.createBill(
                    user.uid,
                    monthController.text,
                    double.parse(amountController.text),
                    selectedDate!,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Tagihan berhasil dibuat'
                            : 'Gagal membuat tagihan'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
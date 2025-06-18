// lib/screens/admin/student_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/screens/shared/live_chat_screen.dart';
import 'package:sipatka/utils/helpers.dart';

class AdminStudentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  const AdminStudentDetailScreen({super.key, required this.student});

  Future<String?> _getUserIdForStudent(String studentId) async {
    try {
      final response = await supabase
        .from('profiles')
        .select('id')
        .eq('student_id', studentId)
        .single();
      return response['id'];
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(student['full_name'])),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow('Nama Siswa', student['full_name']),
                  _buildInfoRow('Nama Wali', student['parent_name']),
                  _buildInfoRow('Kelas', student['class_name']),
                  _buildInfoRow('SPP Bulanan', NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(student['spp_amount'])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Chat dengan Wali Murid'),
            onPressed: () async {
              final userId = await _getUserIdForStudent(student['id']);
              if (userId != null && context.mounted) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => LiveChatScreen(
                    userId: userId,
                    studentName: student['full_name'],
                    isAdmin: true,
                  )
                ));
              } else if (context.mounted) {
                showErrorSnackBar(context, 'Tidak dapat menemukan akun wali murid.');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
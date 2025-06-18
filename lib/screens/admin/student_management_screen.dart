// lib/screens/admin/student_management_screen.dart
import 'package:flutter/material.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/screens/admin/student_detail_screen.dart';


class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  late final Stream<List<Map<String, dynamic>>> _studentsStream;
  final _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _studentsStream = supabase
      .from('students')
      .stream(primaryKey: ['id'])
      .order('full_name');
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Cari Nama Siswa...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchTerm.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                : null,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _studentsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final students = snapshot.data!
                  .where((s) => s['full_name']
                      .toLowerCase()
                      .contains(_searchTerm.toLowerCase()))
                  .toList();
              
              if (students.isEmpty) {
                return const Center(child: Text('Siswa tidak ditemukan.'));
              }
              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(student['full_name'][0])),
                      title: Text(student['full_name']),
                      subtitle: Text('Kelas: ${student['class_name']}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminStudentDetailScreen(student: student)));
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
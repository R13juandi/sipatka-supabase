// lib/screens/user/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/screens/shared/live_chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Future<Map<String, dynamic>>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfileData();
  }

  Future<Map<String, dynamic>> _fetchProfileData() async {
    final userId = supabase.auth.currentUser!.id;
    final profileData = await supabase
        .from('profiles')
        .select('full_name, student_id')
        .eq('id', userId)
        .single();
    
    if (profileData['student_id'] == null) {
      throw 'Siswa tidak terkait.';
    }
    
    final studentData = await supabase
        .from('students')
        .select()
        .eq('id', profileData['student_id'])
        .single();
        
    return {
      'profile': profileData,
      'student': studentData,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Tidak ada data.'));
          }

          final data = snapshot.data!;
          final student = data['student'];
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Data Siswa'),
              _buildProfileCard([
                _buildInfoRow('Nama Lengkap', student['full_name']),
                _buildInfoRow('Nama Orang Tua/Wali', student['parent_name']),
                _buildInfoRow('Kelas', student['class_name']),
                _buildInfoRow('SPP per Bulan', NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(student['spp_amount'])),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('Informasi Sekolah'),
              _buildProfileCard([
                _buildInfoRow('Nama Sekolah', 'TK An-Naafi Nur'),
                _buildInfoRow('NPSN', '69909283'),
                _buildInfoRow('Akreditasi', 'B'),
                _buildInfoRow('Kepala Sekolah', 'MUHAMMAD RIZQI DJUWANDI'),
                _buildInfoRow('Alamat', 'Perum Orchid Park Blok D-1 No 1 Gebang Raya Periuk Kota Tangerang, Banten 15132'),
              ]),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                    final userId = supabase.auth.currentUser!.id;
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LiveChatScreen(userId: userId, studentName: student['full_name'])));
                },
                icon: const Icon(Icons.chat),
                label: const Text('Live Chat dengan Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
    );
  }

  Widget _buildProfileCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
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
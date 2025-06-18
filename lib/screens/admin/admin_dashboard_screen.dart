import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sipatka/providers/payment_provider.dart';
import 'package:sipatka/models/payment_model.dart';
import 'package:intl/intl.dart';
import 'package:sipatka/screens/admin/manage_students_screen.dart';
import 'package:sipatka/screens/admin/confirm_payments_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:sipatka/screens/admin/laporan_keuangan_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Keluar'),
                  content: const Text('Apakah Anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                           Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        }
                      },
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildMenuCard(
            context,
            title: 'Manajemen Siswa & Tagihan',
            icon: Icons.people,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ManageStudentsScreen()));
            },
          ),
          _buildMenuCard(
            context,
            title: 'Konfirmasi Pembayaran',
            icon: Icons.check_circle,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ConfirmPaymentsScreen()));
            },
          ),
          _buildMenuCard(
          context,
            title: 'Laporan Keuangan',
            icon: Icons.bar_chart,
            onTap: () {
              // Navigasi ke halaman laporan keuangan
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LaporanKeuanganScreen()),
              );
            },
          ),
          _buildMenuCard(
            context,
            title: 'Kirim Notifikasi',
            icon: Icons.send,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur sedang dikembangkan.')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
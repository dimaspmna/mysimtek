import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge(this.status, {super.key});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'aktif':
      case 'paid':
      case 'lunas':
      case 'selesai':
      case 'closed':
      case 'resolved':
        return AppColors.success;
      case 'suspend':
      case 'overdue':
      case 'failed':
        return AppColors.error;
      case 'pending':
      case 'open':
      case 'proses':
      case 'in_progress':
      case 'process':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  String get _label {
    const map = {
      'aktif': 'Aktif',
      'suspend': 'Ditangguhkan',
      'pending': 'Menunggu',
      'paid': 'Lunas',
      'lunas': 'Lunas',
      'overdue': 'Jatuh Tempo',
      'open': 'Terbuka',
      'closed': 'Selesai',
      'selesai': 'Selesai',
      'proses': 'Dalam Proses',
      'in_progress': 'Dalam Proses',
      'resolved': 'Selesai',
      'failed': 'Gagal',
    };
    return map[status.toLowerCase()] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

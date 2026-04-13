import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../providers/teknisi_provider.dart';
import '../../models/jadwal_model.dart';

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeknisiProvider>().loadJadwal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Jadwal Pemasangan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      body: Consumer<TeknisiProvider>(
        builder: (context, prov, _) {
          if (prov.jadwalState == LoadState.loading ||
              prov.jadwalState == LoadState.initial) {
            return const AppLoading();
          }
          if (prov.jadwalState == LoadState.error) {
            return AppErrorView(
              message: prov.jadwalError ?? 'Gagal memuat jadwal',
              onRetry: prov.loadJadwal,
            );
          }
          if (prov.jadwal.isEmpty) {
            return AppEmptyState(
              message: 'Tidak ada jadwal pemasangan.',
              icon: Icons.calendar_today_outlined,
              onRefresh: prov.loadJadwal,
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: prov.loadJadwal,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.jadwal.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final j = prov.jadwal[i];
                return _JadwalCard(jadwal: j);
              },
            ),
          );
        },
      ),
    );
  }
}

class _JadwalCard extends StatelessWidget {
  final JadwalInstallation jadwal;
  const _JadwalCard({required this.jadwal});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.wifi,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jadwal.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (jadwal.packageName != null)
                        Text(
                          jadwal.packageName!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                StatusBadge(jadwal.status),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.location_on_outlined, jadwal.address),
            const SizedBox(height: 6),
            _infoRow(Icons.access_time, 'Jadwal: ${jadwal.scheduledDate}'),
            if (jadwal.phone != null) ...[
              const SizedBox(height: 6),
              _infoRow(Icons.phone_outlined, jadwal.phone!),
            ],
            if (jadwal.notes != null && jadwal.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Catatan: ${jadwal.notes}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

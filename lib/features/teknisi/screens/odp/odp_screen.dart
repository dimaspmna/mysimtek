import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../providers/teknisi_provider.dart';
import '../../models/odp_model.dart';

class OdpScreen extends StatefulWidget {
  const OdpScreen({super.key});

  @override
  State<OdpScreen> createState() => _OdpScreenState();
}

class _OdpScreenState extends State<OdpScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeknisiProvider>().loadOdp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Data ODP',
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
          if (prov.odpState == LoadState.loading ||
              prov.odpState == LoadState.initial) {
            return const AppLoading();
          }
          if (prov.odpState == LoadState.error) {
            return AppErrorView(
              message: prov.odpError ?? 'Gagal memuat data ODP',
              onRetry: prov.loadOdp,
            );
          }
          if (prov.odp.isEmpty) {
            return AppEmptyState(
              message: 'Tidak ada data ODP.',
              icon: Icons.router_outlined,
              onRefresh: prov.loadOdp,
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: prov.loadOdp,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.odp.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _OdpCard(odp: prov.odp[i]),
            ),
          );
        },
      ),
    );
  }
}

class _OdpCard extends StatelessWidget {
  final OdpData odp;
  const _OdpCard({required this.odp});

  @override
  Widget build(BuildContext context) {
    final pct = odp.usagePercent;
    final Color barColor = pct >= 90
        ? AppColors.error
        : pct >= 70
        ? AppColors.warning
        : AppColors.success;

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
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.router,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        odp.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (odp.area != null)
                        Text(
                          odp.area!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                StatusBadge(odp.status),
              ],
            ),
            if (odp.location != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      odp.location!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kapasitas: ${odp.used}/${odp.capacity} port',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Tersedia: ${odp.available}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: AppColors.cardBorder,
                color: barColor,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

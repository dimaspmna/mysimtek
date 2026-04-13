import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../providers/teknisi_provider.dart';

class InfrastrukturScreen extends StatefulWidget {
  const InfrastrukturScreen({super.key});

  @override
  State<InfrastrukturScreen> createState() => _InfrastrukturScreenState();
}

class _InfrastrukturScreenState extends State<InfrastrukturScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeknisiProvider>().loadInfrastruktur();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Infrastruktur Jaringan',
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
          if (prov.infraState == LoadState.loading ||
              prov.infraState == LoadState.initial) {
            return const AppLoading();
          }
          if (prov.infraState == LoadState.error) {
            return AppErrorView(
              message: prov.infraError ?? 'Gagal memuat infrastruktur',
              onRetry: prov.loadInfrastruktur,
            );
          }
          if (prov.infrastruktur.isEmpty) {
            return AppEmptyState(
              message: 'Tidak ada data infrastruktur.',
              icon: Icons.cable_outlined,
              onRefresh: prov.loadInfrastruktur,
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: prov.loadInfrastruktur,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.infrastruktur.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final inf = prov.infrastruktur[i];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.info.withOpacity(0.1),
                      child: const Icon(
                        Icons.cable,
                        color: AppColors.info,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      inf.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (inf.type != null)
                          Text(
                            inf.type!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (inf.location != null)
                          Text(
                            inf.location!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (inf.description != null)
                          Text(
                            inf.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    trailing: StatusBadge(inf.status),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

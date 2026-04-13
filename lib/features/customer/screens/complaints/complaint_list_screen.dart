import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../providers/complaint_provider.dart';
import 'complaint_detail_screen.dart';
import 'create_complaint_screen.dart';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComplaintProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaduan'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateComplaintScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<ComplaintProvider>(
        builder: (context, prov, _) {
          if (prov.listLoading) return const AppLoading();
          if (prov.listError != null) {
            return AppErrorView(message: prov.listError!, onRetry: prov.load);
          }
          if (prov.complaints.isEmpty) {
            return AppEmptyState(
              message:
                  'Belum ada pengaduan.\nTekan + untuk buat pengaduan baru.',
              icon: Icons.feedback_outlined,
              onRefresh: prov.load,
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: prov.load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.complaints.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = prov.complaints[i];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  child: ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ComplaintDetailScreen(complaintId: c.id),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.warning.withOpacity(0.1),
                      child: const Icon(
                        Icons.feedback,
                        color: AppColors.warning,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      c.subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      c.createdAt.split('T').first,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: StatusBadge(c.status),
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

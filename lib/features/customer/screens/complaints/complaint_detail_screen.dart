import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../providers/complaint_provider.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final int complaintId;
  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final _replyCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComplaintProvider>().loadDetail(widget.complaintId);
    });
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Detail Pengaduan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      body: Consumer<ComplaintProvider>(
        builder: (context, prov, _) {
          if (prov.detailLoading) return const AppLoading();
          if (prov.detailError != null) {
            return AppErrorView(
              message: prov.detailError!,
              onRetry: () => prov.loadDetail(widget.complaintId),
            );
          }
          final complaint = prov.current;
          if (complaint == null) return const AppLoading();

          _scrollToBottom();

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint.subject,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dibuat: ${complaint.createdAt.split('T').first}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(complaint.status),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: complaint.replies.isEmpty
                    ? ListView(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.warning.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Deskripsi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(complaint.body),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: complaint.replies.length,
                        itemBuilder: (context, i) {
                          final r = complaint.replies[i];
                          return Align(
                            alignment: r.isFromCustomer
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: r.isFromCustomer
                                      ? AppColors.warning
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16)
                                      .copyWith(
                                        bottomRight: r.isFromCustomer
                                            ? Radius.zero
                                            : const Radius.circular(16),
                                        bottomLeft: r.isFromCustomer
                                            ? const Radius.circular(16)
                                            : Radius.zero,
                                      ),
                                  border: r.isFromCustomer
                                      ? null
                                      : Border.all(color: AppColors.cardBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!r.isFromCustomer)
                                      Text(
                                        r.senderName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.body,
                                      style: TextStyle(
                                        color: r.isFromCustomer
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      r.createdAt.split('T').first,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: r.isFromCustomer
                                            ? Colors.white70
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (complaint.status.toLowerCase() != 'closed')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyCtrl,
                            maxLines: 3,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Tulis balasan...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                  color: AppColors.cardBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                  color: AppColors.cardBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                  color: AppColors.warning,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        prov.submitting
                            ? const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    AppColors.warning,
                                  ),
                                ),
                              )
                            : IconButton(
                                onPressed: () async {
                                  final text = _replyCtrl.text.trim();
                                  if (text.isEmpty) return;
                                  final ok = await prov.reply(
                                    complaint.id,
                                    text,
                                  );
                                  if (ok) {
                                    _replyCtrl.clear();
                                    _scrollToBottom();
                                  }
                                },
                                icon: const Icon(Icons.send),
                                color: AppColors.warning,
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.warning
                                      .withOpacity(0.1),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../models/ticket_model.dart';
import '../../providers/ticket_provider.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _replyCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().loadTicketDetail(widget.ticketId);
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
          'Detail Tiket',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      body: Consumer<TicketProvider>(
        builder: (context, prov, _) {
          if (prov.detailLoading) return const AppLoading();
          if (prov.detailError != null) {
            return AppErrorView(
              message: prov.detailError!,
              onRetry: () => prov.loadTicketDetail(widget.ticketId),
            );
          }
          final ticket = prov.currentTicket;
          if (ticket == null) return const AppLoading();

          _scrollToBottom();

          return Column(
            children: [
              // Ticket info header
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
                          if (ticket.ticketNumber.isNotEmpty)
                            Text(
                              ticket.ticketNumber,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          Text(
                            ticket.subject,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dibuat: ${ticket.createdAt.split('T').first}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(ticket.status),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              // Progress tracking + technician info + messages
              Expanded(
                child: ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Progress tracking
                    _ProgressTracking(ticket: ticket),
                    const SizedBox(height: 12),
                    // Technician info
                    if (ticket.hasAssignedTechnician &&
                        ticket.technicianName != null) ...[
                      _TechnicianCard(ticket: ticket),
                      const SizedBox(height: 12),
                    ],
                    // Messages / description
                    if (ticket.messages.isEmpty)
                      _buildInitialDescription(ticket.body)
                    else
                      ...ticket.messages.map(
                        (msg) => _MessageBubble(
                          body: msg.body,
                          senderName: msg.senderName,
                          isFromCustomer: msg.isFromCustomer,
                          time: msg.createdAt.split('T').first,
                        ),
                      ),
                  ],
                ),
              ),
              // Reply input
              if (ticket.status.toLowerCase() != 'closed')
                _ReplyInput(
                  controller: _replyCtrl,
                  submitting: prov.submitting,
                  onSend: () async {
                    final text = _replyCtrl.text.trim();
                    if (text.isEmpty) return;
                    final ok = await prov.replyTicket(ticket.id, text);
                    if (ok) {
                      _replyCtrl.clear();
                      _scrollToBottom();
                    } else if (prov.detailError != null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(prov.detailError!),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInitialDescription(String body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deskripsi',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(body),
        ],
      ),
    );
  }
}

class _ProgressTracking extends StatelessWidget {
  final Ticket ticket;

  const _ProgressTracking({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final status = ticket.status;
    final fieldStatus = ticket.fieldStatus;
    final hasAssigned = ticket.hasAssignedTechnician;

    final steps = [
      (label: 'Diterima', done: true),
      (
        label: 'Diproses',
        done: ['in_progress', 'resolved', 'closed'].contains(status),
      ),
      (label: 'Teknisi', done: hasAssigned),
      (
        label: 'Perbaikan',
        done: [
          'preparing',
          'on_the_way',
          'working',
          'fixed',
        ].contains(fieldStatus),
      ),
      (label: 'Teratasi', done: ['resolved', 'closed'].contains(status)),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Penanganan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: steps[i].done
                              ? AppColors.primary
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: steps[i].done
                            ? const Icon(
                                Icons.check,
                                size: 13,
                                color: Colors.white,
                              )
                            : const Center(
                                child: SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Color(0xFFCBD5E1),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[i].label,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: (steps[i].done && steps[i + 1].done)
                          ? AppColors.primary.withOpacity(0.4)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  final Ticket ticket;

  const _TechnicianCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final name = ticket.technicianName!;
    final phone = ticket.technicianPhone;
    final fieldStatus = ticket.fieldStatus;
    final fieldLabel = _fieldStatusLabel(fieldStatus);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'T',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Teknisi${fieldLabel != null ? ' \u2022 $fieldLabel' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (phone != null && phone.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton.icon(
                onPressed: null,
                icon: const Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                label: const Text(
                  'Hubungi',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? _fieldStatusLabel(String? status) {
    const map = {
      'preparing': 'Mempersiapkan',
      'on_the_way': 'Dalam Perjalanan',
      'working': 'Sedang Mengerjakan',
      'fixed': 'Selesai Diperbaiki',
    };
    return status != null ? map[status] : null;
  }
}

class _MessageBubble extends StatelessWidget {
  final String body;
  final String senderName;
  final bool isFromCustomer;
  final String time;

  const _MessageBubble({
    required this.body,
    required this.senderName,
    required this.isFromCustomer,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isFromCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isFromCustomer ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: isFromCustomer
                  ? Radius.zero
                  : const Radius.circular(16),
              bottomLeft: isFromCustomer
                  ? const Radius.circular(16)
                  : Radius.zero,
            ),
            border: isFromCustomer
                ? null
                : Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isFromCustomer)
                Text(
                  senderName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(
                  color: isFromCustomer ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: isFromCustomer
                      ? Colors.white60
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplyInput extends StatelessWidget {
  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSend;

  const _ReplyInput({
    required this.controller,
    required this.submitting,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Tulis balasan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
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
            submitting
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  )
                : IconButton(
                    onPressed: onSend,
                    icon: const Icon(Icons.send),
                    color: AppColors.primary,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

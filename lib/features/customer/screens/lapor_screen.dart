import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/ticket_model.dart';
import '../providers/ticket_provider.dart';
import 'tickets/ticket_detail_screen.dart';
import 'tickets/create_ticket_screen.dart';

class LaporScreen extends StatefulWidget {
  const LaporScreen({super.key});

  @override
  State<LaporScreen> createState() => _LaporScreenState();
}

class _LaporScreenState extends State<LaporScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().loadTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Daftar Komplain',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
          );
          if (context.mounted) {
            context.read<TicketProvider>().loadTickets();
          }
        },
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<TicketProvider>(
        builder: (context, prov, _) {
          if (prov.listLoading) return const AppLoading();
          if (prov.listError != null) {
            return AppErrorView(
              message: prov.listError!,
              onRetry: prov.loadTickets,
            );
          }

          final tickets = prov.tickets;
          final total = tickets.length;
          final open = tickets
              .where((t) => t.status == 'open' || t.status == 'in_progress')
              .length;
          final resolved = tickets
              .where((t) => t.status == 'resolved' || t.status == 'closed')
              .length;

          if (tickets.isEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _StatsRow(
                    total: total,
                    open: open,
                    resolved: resolved,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: AppEmptyState(
                      message:
                          'Belum ada komplain baru.\nTekan + untuk buat tiket komplain baru.',
                      icon: Icons.handyman_outlined,
                    ),
                  ),
                ),
              ],
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: prov.loadTickets,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatsRow(total: total, open: open, resolved: resolved),
                const SizedBox(height: 12),
                ...tickets.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TicketCard(ticket: t),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int total;
  final int open;
  final int resolved;
  const _StatsRow({
    required this.total,
    required this.open,
    required this.resolved,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(label: 'Total', value: total),
        const SizedBox(width: 8),
        _StatCard(label: 'Proses', value: open),
        const SizedBox(width: 8),
        _StatCard(label: 'Selesai', value: resolved),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TicketDetailScreen(ticketId: ticket.id),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.handyman_outlined,
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
                          ticket.subject,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (ticket.ticketNumber.isNotEmpty)
                          Text(
                            '#${ticket.ticketNumber}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  StatusBadge(ticket.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    ticket.categoryLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (ticket.hasAssignedTechnician) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '\u2022',
                        style: TextStyle(
                          color: AppColors.divider,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.person_outline,
                      size: 11,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Teknisi',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 10,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket.createdAt.split('T').first,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

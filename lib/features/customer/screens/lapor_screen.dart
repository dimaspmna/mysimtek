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
          'Lapor Gangguan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
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

          final statsRow = Row(
            children: [
              _StatCard(
                label: 'Total',
                value: total,
                iconData: Icons.receipt_long_outlined,
              ),
              const SizedBox(width: 8),
              _StatCard(
                label: 'Berjalan',
                value: open,
                iconData: Icons.hourglass_top_outlined,
              ),
              const SizedBox(width: 8),
              _StatCard(
                label: 'Selesai',
                value: resolved,
                iconData: Icons.check_circle_outline,
              ),
            ],
          );

          if (tickets.isEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: statsRow,
                ),
                const Expanded(
                  child: Center(
                    child: AppEmptyState(
                      message:
                          'Belum ada laporan gangguan.\nTekan + untuk buat laporan baru.',
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
                statsRow,
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < tickets.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.cardBorder,
                          ),
                        _TicketItem(ticket: tickets[i]),
                      ],
                    ],
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

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData iconData;

  const _StatCard({
    required this.label,
    required this.value,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFEA580C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEA580C).withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(iconData, color: Colors.white.withOpacity(0.85), size: 18),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketItem extends StatelessWidget {
  final Ticket ticket;

  const _TicketItem({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TicketDetailScreen(ticketId: ticket.id),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
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
                  const SizedBox(height: 2),
                  Text(
                    ticket.subject,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ticket.categoryLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusBadge(ticket.status),
                      if (ticket.hasAssignedTechnician) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Teknisi',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              ticket.createdAt.split('T').first,
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

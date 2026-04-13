import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../providers/teknisi_provider.dart';
import '../../models/teknisi_ticket_model.dart';
import 'teknisi_ticket_detail_screen.dart';

class TeknisiTicketListScreen extends StatefulWidget {
  const TeknisiTicketListScreen({super.key});

  @override
  State<TeknisiTicketListScreen> createState() =>
      _TeknisiTicketListScreenState();
}

class _TeknisiTicketListScreenState extends State<TeknisiTicketListScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeknisiProvider>().loadTickets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TeknisiTicket> _filtered(List<TeknisiTicket> all) {
    if (_search.isEmpty) return all;
    final q = _search.toLowerCase();
    return all.where((t) {
      return t.ticketNumber.toLowerCase().contains(q) ||
          t.subject.toLowerCase().contains(q) ||
          (t.customerName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_outlined,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Tiket TRB',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 216, 29, 29),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      body: Consumer<TeknisiProvider>(
        builder: (context, prov, _) {
          if (prov.ticketState == LoadState.loading ||
              prov.ticketState == LoadState.initial) {
            return const AppLoading();
          }
          if (prov.ticketState == LoadState.error) {
            return AppErrorView(
              message: prov.ticketError ?? 'Gagal memuat tiket',
              onRetry: prov.loadTickets,
            );
          }

          final stats = prov.ticketStats;
          final filtered = _filtered(prov.tickets);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: prov.loadTickets,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Stats row ──────────────────────────────────────────
                Row(
                  children: [
                    _StatChip(label: 'Total', value: stats['total'] ?? 0),
                    const SizedBox(width: 8),
                    _StatChip(label: 'Terbuka', value: stats['open'] ?? 0),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Diproses',
                      value: stats['in_progress'] ?? 0,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(label: 'Selesai', value: stats['resolved'] ?? 0),
                  ],
                ),
                const SizedBox(height: 12),
                // ── Search ─────────────────────────────────────────────
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Cari tiket atau nama pelanggan...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // ── Ticket list ────────────────────────────────────────
                if (filtered.isEmpty)
                  AppEmptyState(
                    message: 'Tidak ada tiket yang di-assign.',
                    icon: Icons.construction_outlined,
                    onRefresh: prov.loadTickets,
                  )
                else
                  ...filtered.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
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

// ── Stat chip ───────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),

        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ticket card ─────────────────────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  final TeknisiTicket ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeknisiTicketDetailScreen(ticket: ticket),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.ticketNumber,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ticket.subject,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FieldStatusBadge(
                    ticket.fieldStatusLabel ?? ticket.fieldStatus ?? '',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Info rows
              if (ticket.customerName != null)
                _InfoRow(
                  icon: Icons.person_outline,
                  text: ticket.customerName!,
                ),
              if (ticket.customerPhone != null)
                _InfoRow(
                  icon: Icons.phone_outlined,
                  text: ticket.customerPhone!,
                ),
              if (ticket.address != null)
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: ticket.address!,
                  maxLines: 2,
                ),
              // Footer row
              const Divider(color: Color(0xFFF8FAFC), height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _StatusBadge(ticket.statusLabel),
                      if (ticket.priorityLabel != null) ...[
                        const SizedBox(width: 6),
                        _PriorityBadge(ticket.priorityLabel!),
                      ],
                    ],
                  ),
                  Text(
                    ticket.displayDate,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  const _InfoRow({required this.icon, required this.text, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldStatusBadge extends StatelessWidget {
  final String label;
  const _FieldStatusBadge(this.label);

  Color get _bg => switch (label) {
    _ when label.contains('Persiapan') => const Color(0xFFEDE9FE),
    _ when label.contains('Menuju') => const Color(0xFFDBEAFE),
    _ when label.contains('Dikerjakan') => const Color(0xFFFEF3C7),
    _ when label.contains('Selesai') => const Color(0xFFD1FAE5),
    _ when label.contains('Menunggu') => const Color.fromARGB(
      255,
      254,
      238,
      226,
    ),
    _ => const Color(0xFFF1F5F9),
  };

  Color get _fg => switch (label) {
    _ when label.contains('Persiapan') => const Color(0xFF7C3AED),
    _ when label.contains('Menuju') => const Color(0xFF2563EB),
    _ when label.contains('Dikerjakan') => const Color(0xFFD97706),
    _ when label.contains('Selesai') => const Color(0xFF059669),
    _ when label.contains('Menunggu') => const Color.fromARGB(
      255,
      220,
      117,
      38,
    ),
    _ => const Color(0xFF64748B),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _fg),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge(this.label);

  Color get _bg => switch (label.toLowerCase()) {
    _ when label.contains('Terbuka') => const Color(0xFFFEE2E2),
    _ when label.contains('Diproses') => const Color(0xFFDBEAFE),
    _ when label.contains('Selesai') || label.contains('selesai') =>
      const Color(0xFFD1FAE5),
    _ when label.contains('Ditutup') => const Color(0xFFF1F5F9),
    _ => const Color(0xFFF1F5F9),
  };
  Color get _fg => switch (label.toLowerCase()) {
    _ when label.contains('Terbuka') => const Color(0xFFDC2626),
    _ when label.contains('Diproses') => const Color(0xFF2563EB),
    _ when label.contains('Selesai') || label.contains('selesai') =>
      const Color(0xFF059669),
    _ when label.contains('Ditutup') => const Color(0xFF64748B),
    _ => const Color(0xFF64748B),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _fg),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String label;
  const _PriorityBadge(this.label);

  Color get _bg => switch (label) {
    'Prioritas Rendah' => const Color(0xFFF1F5F9),
    'Prioritas Sedang' => const Color(0xFFDBEAFE),
    'Prioritas Tinggi' => const Color(0xFFFEF3C7),
    'Prioritas Kritis' => const Color(0xFFFEE2E2),
    _ => const Color(0xFFF1F5F9),
  };
  Color get _fg => switch (label) {
    'Prioritas Rendah' => const Color(0xFF64748B),
    'Prioritas Sedang' => const Color(0xFF2563EB),
    'Prioritas Tinggi' => const Color(0xFFD97706),
    'Prioritas Kritis' => const Color(0xFFDC2626),
    _ => const Color(0xFF64748B),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _fg),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../models/teknisi_ticket_model.dart';
import '../../models/psb_ticket_model.dart';
import '../../providers/teknisi_provider.dart';
import '../tickets/teknisi_ticket_detail_screen.dart';
import '../psb/psb_detail_screen.dart';

class RiwayatTugasScreen extends StatefulWidget {
  const RiwayatTugasScreen({super.key});

  @override
  State<RiwayatTugasScreen> createState() => _RiwayatTugasScreenState();
}

class _RiwayatTugasScreenState extends State<RiwayatTugasScreen> {
  late DateTime _selectedMonth;
  String _typeFilter = 'semua'; // semua | trb | psb

  static const _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  void _prevMonth() => setState(() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
  });

  void _nextMonth() {
    if (_isCurrentMonth) return;
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  bool _inSelectedMonth(String? dateStr) {
    if (dateStr == null) return false;
    final d = DateTime.tryParse(dateStr);
    if (d == null) return false;
    return d.year == _selectedMonth.year && d.month == _selectedMonth.month;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final prov = context.watch<TeknisiProvider>();

    // TRB: only tickets assigned to current user in selected month
    final trbItems = _typeFilter != 'psb'
        ? prov.tickets
              .where((t) {
                if (user != null && t.assignedTo != user.id) return false;
                return _inSelectedMonth(t.createdAt);
              })
              .map(_Item.trb)
              .toList()
        : <_Item>[];

    // PSB: all tickets in selected month (backend already scopes to this user)
    final psbItems = _typeFilter != 'trb'
        ? prov.psbTickets
              .where((t) => _inSelectedMonth(t.scheduledDate ?? t.createdAt))
              .map(_Item.psb)
              .toList()
        : <_Item>[];

    final items = [...trbItems, ...psbItems]
      ..sort((a, b) => b.date.compareTo(a.date));

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
                Icons.history_outlined,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Riwayat Tugas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF334155),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: const Color(0xFF334155),
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: _prevMonth,
                ),
                Text(
                  '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: _isCurrentMonth ? Colors.white38 : Colors.white,
                  ),
                  onPressed: _isCurrentMonth ? null : _nextMonth,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  value: 'semua',
                  current: _typeFilter,
                  onTap: (v) => setState(() => _typeFilter = v),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'TRB',
                  value: 'trb',
                  current: _typeFilter,
                  onTap: (v) => setState(() => _typeFilter = v),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'PSB',
                  value: 'psb',
                  current: _typeFilter,
                  onTap: (v) => setState(() => _typeFilter = v),
                ),
                const Spacer(),
                Text(
                  '${items.length} tiket',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          // List
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.assignment_outlined,
                          size: 56,
                          color: Color(0xFFCBD5E1),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada tugas',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bulan ${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF334155),
                    onRefresh: () async {
                      await prov.loadTickets();
                      await prov.loadPsbTickets();
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final item = items[i];
                        return _TicketCard(
                          item: item,
                          onTap: () {
                            if (item.isPsb) {
                              Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PsbDetailScreen(ticket: item.psbTicket!),
                                ),
                              );
                            } else {
                              Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) => TeknisiTicketDetailScreen(
                                    ticket: item.trbTicket!,
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Item wrapper ─────────────────────────────────────────────────────────────

class _Item {
  final bool isPsb;
  final TeknisiTicket? trbTicket;
  final PsbTicket? psbTicket;

  _Item.trb(TeknisiTicket t) : isPsb = false, trbTicket = t, psbTicket = null;

  _Item.psb(PsbTicket t) : isPsb = true, psbTicket = t, trbTicket = null;

  String get ticketNumber =>
      isPsb ? psbTicket!.ticketNumber : trbTicket!.ticketNumber;

  String get customerName => isPsb
      ? (psbTicket!.customerName ?? '-')
      : (trbTicket!.customerName ?? '-');

  String get statusLabel =>
      isPsb ? psbTicket!.statusLabel : trbTicket!.statusLabel;

  String? get fieldStatusLabel =>
      isPsb ? psbTicket!.fieldStatusLabel : trbTicket!.fieldStatusLabel;

  /// ISO date string (yyyy-MM-dd) for sorting
  String get date {
    if (isPsb) {
      return psbTicket!.scheduledDate ?? psbTicket!.createdAt.substring(0, 10);
    }
    return trbTicket!.createdAt.substring(0, 10);
  }

  String get displayDate {
    final d = DateTime.tryParse(date);
    if (d == null) return date;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

// ── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final void Function(String) onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// ── Ticket card ──────────────────────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  final _Item item;
  final VoidCallback onTap;

  const _TicketCard({required this.item, required this.onTap});

  Color get _typeColor =>
      item.isPsb ? const Color(0xFF1D4ED8) : const Color(0xFFD81D1D);

  String get _typeLabel => item.isPsb ? 'PSB' : 'TRB';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: _typeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _typeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _typeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.ticketNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.customerName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (item.fieldStatusLabel != null &&
                        item.fieldStatusLabel!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.fieldStatusLabel!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.displayDate,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatusBadge(label: item.statusLabel),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  Color get _bg {
    final l = label.toLowerCase();
    if (l.contains('selesai') || l.contains('done') || l.contains('closed')) {
      return const Color(0xFFD1FAE5);
    }
    if (l.contains('progress') ||
        l.contains('dikerjakan') ||
        l.contains('proses')) {
      return const Color(0xFFFEF3C7);
    }
    if (l.contains('batal')) return const Color(0xFFFEE2E2);
    return const Color(0xFFEDE9FE);
  }

  Color get _fg {
    final l = label.toLowerCase();
    if (l.contains('selesai') || l.contains('done') || l.contains('closed')) {
      return const Color(0xFF059669);
    }
    if (l.contains('progress') ||
        l.contains('dikerjakan') ||
        l.contains('proses')) {
      return const Color(0xFFD97706);
    }
    if (l.contains('batal')) return const Color(0xFFDC2626);
    return const Color(0xFF7C3AED);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

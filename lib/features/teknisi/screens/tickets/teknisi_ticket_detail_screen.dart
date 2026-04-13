import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/teknisi_ticket_model.dart';
import '../../providers/teknisi_provider.dart';

class TeknisiTicketDetailScreen extends StatefulWidget {
  final TeknisiTicket ticket;
  const TeknisiTicketDetailScreen({super.key, required this.ticket});

  @override
  State<TeknisiTicketDetailScreen> createState() =>
      _TeknisiTicketDetailScreenState();
}

class _TeknisiTicketDetailScreenState extends State<TeknisiTicketDetailScreen> {
  int _tab = 0; // 0=info, 1=laporan, 2=thread
  final PageController _pageCtrl = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeknisiProvider>().loadTicketDetail(widget.ticket.id);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goToTab(int i) {
    _pageCtrl.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeknisiProvider>(
      builder: (context, prov, _) {
        final t =
            (prov.ticketDetailState == LoadState.loaded &&
                prov.ticketDetail?.id == widget.ticket.id)
            ? prov.ticketDetail!
            : widget.ticket;

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.ticketNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (t.customerName != null)
                      Text(
                        t.customerName!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            backgroundColor: const Color(0xFFD81D1D),
            foregroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            centerTitle: false,
          ),
          body: Column(
            children: [
              // ── Tab bar ──────────────────────────────────────────────
              Container(
                color: Colors.white,
                child: Row(
                  children: [
                    _TabBtn(
                      label: 'Info',
                      selected: _tab == 0,
                      onTap: () => _goToTab(0),
                    ),
                    _TabBtn(
                      label: t.photos.isNotEmpty
                          ? 'Laporan (${t.photos.length})'
                          : 'Laporan',
                      selected: _tab == 1,
                      onTap: () => _goToTab(1),
                    ),
                    _TabBtn(
                      label: t.messages.isNotEmpty
                          ? 'Thread (${t.messages.length})'
                          : 'Thread',
                      selected: _tab == 2,
                      onTap: () => _goToTab(2),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              if (prov.ticketDetailState == LoadState.loading)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  onPageChanged: (i) => setState(() => _tab = i),
                  children: [
                    _InfoTab(ticket: t, prov: prov),
                    _LaporanTab(ticket: t, prov: prov),
                    _ThreadTab(ticket: t, prov: prov),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Tab button ────────────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? Colors.red : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.red : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB: INFO
// ══════════════════════════════════════════════════════════════════════════════

class _InfoTab extends StatelessWidget {
  final TeknisiTicket ticket;
  final TeknisiProvider prov;
  const _InfoTab({required this.ticket, required this.prov});

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final isUnassigned = t.status == 'open' && t.assignedTo == null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isUnassigned) ...[
          _ClaimBanner(ticket: t, prov: prov),
          const SizedBox(height: 12),
        ],
        if (!isUnassigned) ...[
          _ProgressTimeline(ticket: t),
          const SizedBox(height: 12),
        ],
        _CustomerCard(ticket: t),
        const SizedBox(height: 12),
        _DetailCard(
          title: 'Status',
          children: [
            _DetailRow(label: 'Status Tiket', value: t.statusLabel),
            _DetailRow(label: 'Prioritas', value: t.priorityLabel ?? '-'),
            _DetailRow(label: 'Kategori', value: t.categoryLabel ?? '-'),
            _DetailRow(
              label: 'Status Lapangan',
              value: t.fieldStatusLabel ?? '-',
            ),
            _DetailRow(
              label: 'Ditugaskan kepada',
              value: t.assignerName ?? '-',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DetailCard(
          title: 'Keluhan / Masalah',
          children: [
            Text(
              t.subject,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            if (t.description != null && t.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                t.description!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
        if (t.fieldNotes != null && t.fieldNotes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _NoteCard(
            title: 'Catatan Lapangan',
            body: t.fieldNotes!,
            bg: const Color(0xFFFFFBEB),
            border: const Color(0xFFFDE68A),
            titleColor: const Color(0xFFD97706),
            bodyColor: const Color(0xFF92400E),
          ),
        ],
        if (t.resolution != null && t.resolution!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _NoteCard(
            title: 'Catatan Resolusi',
            body: t.resolution!,
            bg: const Color(0xFFECFDF5),
            border: const Color(0xFFA7F3D0),
            titleColor: const Color(0xFF059669),
            bodyColor: const Color(0xFF065F46),
          ),
        ],
        const SizedBox(height: 12),
        _TimelineCard(ticket: t),
        if (t.status == 'in_progress' &&
            (t.fieldStatus == null || t.fieldStatus!.isEmpty)) ...[
          const SizedBox(height: 16),
          _MulaiTrbButton(ticket: t, prov: prov),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── "Mulai TRB" Button ────────────────────────────────────────────────────────

class _MulaiTrbButton extends StatelessWidget {
  final TeknisiTicket ticket;
  final TeknisiProvider prov;
  const _MulaiTrbButton({required this.ticket, required this.prov});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Siap berangkat?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF065F46),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ketuk tombol di bawah untuk memulai TRB dan memberi tahu bahwa kamu sedang menuju lokasi.',
            style: TextStyle(fontSize: 11, color: Color(0xFF059669)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: prov.startingTrb
                  ? null
                  : () async {
                      final ok = await prov.startTrb(ticket.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'TRB dimulai! Menuju lokasi pelanggan.'
                                : 'Gagal memulai TRB. Coba lagi.',
                          ),
                          backgroundColor: ok
                              ? const Color(0xFF059669)
                              : Colors.red,
                        ),
                      );
                    },
              icon: prov.startingTrb
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.start_outlined),
              label: Text(
                prov.startingTrb ? 'Memulai...' : 'Mulai TRB Sekarang',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Claim banner ──────────────────────────────────────────────────────────────

class _ClaimBanner extends StatelessWidget {
  final TeknisiTicket ticket;
  final TeknisiProvider prov;
  const _ClaimBanner({required this.ticket, required this.prov});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        border: Border.all(color: const Color(0xFFA7F3D0)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiket Belum Ditugaskan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF065F46),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tiket ini tersedia dan belum diambil siapapun. Ambil tiket ini untuk mulai menangani keluhan pelanggan.',
            style: TextStyle(fontSize: 11, color: Color(0xFF059669)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: prov.claimingTicket
                  ? null
                  : () async {
                      final err = await prov.claimTicket(ticket.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err ?? 'Tiket berhasil diklaim!'),
                          backgroundColor: err == null
                              ? const Color(0xFF059669)
                              : Colors.red,
                        ),
                      );
                    },
              icon: prov.claimingTicket
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.assignment_turned_in_outlined),
              label: Text(
                prov.claimingTicket ? 'Mengklaim...' : 'Ambil Tiket Ini',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress timeline ────────────────────────────────────────────────────────

class _ProgressTimeline extends StatelessWidget {
  final TeknisiTicket ticket;
  const _ProgressTimeline({required this.ticket});

  int get _doneSteps {
    if (ticket.status == 'resolved' || ticket.status == 'closed') return 5;
    switch (ticket.fieldStatus) {
      case 'fixed':
        return 5;
      case 'working':
      case 'waiting_parts':
        return 4;
      case 'on_the_way':
        return 3;
      case 'preparing':
        return 2;
      default:
        return ticket.assignedTo != null ? 1 : 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Konfirmasi\nPenugasan',
      'Persiapan',
      'Menuju\nLokasi',
      'Proses\nPerbaikan',
      'Perbaikan\nSelesai',
    ];
    final done = _doneSteps;

    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Tiket',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final lineOffset = constraints.maxWidth / (steps.length * 2);
              return Stack(
                children: [
                  // Connecting lines
                  Positioned(
                    top: 13,
                    left: lineOffset,
                    right: lineOffset,
                    child: Row(
                      children: List.generate(steps.length - 1, (i) {
                        return Expanded(
                          child: Container(
                            height: 2,
                            color: i + 2 <= done
                                ? const Color(0xFF059669)
                                : const Color(0xFFE2E8F0),
                          ),
                        );
                      }),
                    ),
                  ),
                  // Step circles + labels
                  Row(
                    children: List.generate(steps.length, (i) {
                      final isDone = i + 1 <= done;
                      return Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isDone
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDone
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                isDone ? Icons.check : Icons.close,
                                size: 14,
                                color: isDone
                                    ? Colors.white
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              steps[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 8,
                                height: 1.3,
                                fontWeight: isDone
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isDone
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB: LAPORAN
// ══════════════════════════════════════════════════════════════════════════════

class _LaporanTab extends StatefulWidget {
  final TeknisiTicket ticket;
  final TeknisiProvider prov;
  const _LaporanTab({required this.ticket, required this.prov});

  @override
  State<_LaporanTab> createState() => _LaporanTabState();
}

class _LaporanTabState extends State<_LaporanTab> {
  String _fieldStatus = 'working';
  final _notesCtrl = TextEditingController();
  File? _photo;
  String _photoType = 'other';

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeri Foto'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _submit() async {
    final notes = _notesCtrl.text.trim();
    if (notes.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan minimal 10 karakter.')),
      );
      return;
    }
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih foto terlebih dahulu.')),
      );
      return;
    }

    final err = await widget.prov.submitTicketFieldReport(
      widget.ticket.id,
      fieldStatus: _fieldStatus,
      fieldNotes: notes,
      photo: _photo!,
      photoType: _photoType,
    );

    if (!mounted) return;
    if (err == null) {
      _notesCtrl.clear();
      setState(() => _photo = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dikirim!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final prov = widget.prov;
    final isUnassigned = t.status == 'open' && t.assignedTo == null;
    final isDone = t.status == 'resolved' || t.status == 'closed';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isUnassigned)
          _EmptyHint(
            icon: Icons.warning_amber_outlined,
            title: 'Ambil tiket terlebih dahulu',
            subtitle: 'Pergi ke tab Info dan klaim tiket untuk mulai melapor.',
          )
        else if (!isDone) ...[
          Container(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kirim Laporan Lapangan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                // Field status
                const Text(
                  'Status Lapangan *',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _fieldStatus,
                      isExpanded: true,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'preparing',
                          child: Text('Sedang Persiapan'),
                        ),
                        DropdownMenuItem(
                          value: 'on_the_way',
                          child: Text('Menuju Lokasi Pelanggan'),
                        ),
                        DropdownMenuItem(
                          value: 'working',
                          child: Text('Sedang Dikerjakan'),
                        ),
                        DropdownMenuItem(
                          value: 'fixed',
                          child: Text('Perbaikan Selesai'),
                        ),
                        DropdownMenuItem(
                          value: 'waiting_parts',
                          child: Text('Menunggu Alat'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Lainnya'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _fieldStatus = v!),
                    ),
                  ),
                ),
                if (_fieldStatus == 'fixed') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Status "Perbaikan Selesai" akan mengubah tiket menjadi Selesai.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF059669)),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Notes
                const Text(
                  'Laporan Lapangan *',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Tuliskan kondisi lapangan, apa yang ditemukan, dan apa yang dilakukan...',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFCBD5E1),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Photo type
                const Text(
                  'Jenis Foto',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _photoType,
                      isExpanded: true,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'before',
                          child: Text('Sebelum'),
                        ),
                        DropdownMenuItem(
                          value: 'after',
                          child: Text('Sesudah'),
                        ),
                        DropdownMenuItem(
                          value: 'damage',
                          child: Text('Kerusakan'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Lainnya'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _photoType = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Photo picker
                const Text(
                  'Foto Bukti *',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    height: _photo != null ? null : 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: _photo != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _photo!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() => _photo = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 28,
                                color: Color(0xFFCBD5E1),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Ketuk untuk pilih foto',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: prov.submittingTicketFieldReport
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: prov.submittingTicketFieldReport
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Kirim Laporan & Foto',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          _EmptyHint(
            icon: Icons.check_circle_sharp,
            title:
                'Tiket sudah ${t.status == 'resolved' ? 'selesai' : 'ditutup'}',
            subtitle: 'Laporan tidak dapat diubah lagi.',
          ),
          const SizedBox(height: 16),
        ],
        // Photo gallery
        if (t.photos.isNotEmpty) ...[
          Text(
            'Foto Terlampir (${t.photos.length})',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: t.photos.map((p) => _PhotoTile(photo: p)).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final TeknisiTicketPhoto photo;
  const _PhotoTile({required this.photo});

  @override
  Widget build(BuildContext context) {
    final url = photo.photoUrl.startsWith('http')
        ? photo.photoUrl
        : '${ApiConstants.storageUrl}${photo.photoUrl}';
    return GestureDetector(
      onTap: () => _openPhoto(context, url),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xBB000000), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Text(
                  photo.photoTypeLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(child: InteractiveViewer(child: Image.network(url))),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB: THREAD
// ══════════════════════════════════════════════════════════════════════════════

class _ThreadTab extends StatefulWidget {
  final TeknisiTicket ticket;
  final TeknisiProvider prov;
  const _ThreadTab({required this.ticket, required this.prov});

  @override
  State<_ThreadTab> createState() => _ThreadTabState();
}

class _ThreadTabState extends State<_ThreadTab> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) return;

    _msgCtrl.clear();
    final err = await widget.prov.sendTicketMessage(widget.ticket.id, msg);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final prov = widget.prov;
    final isClosed = t.status == 'closed';

    return Column(
      children: [
        Expanded(
          child: t.messages.isEmpty
              ? _EmptyHint(
                  icon: Icons.chat_bubble_outline,
                  title: 'Belum ada pesan',
                  subtitle: 'Mulai percakapan dengan tim support.',
                )
              : ListView.separated(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: t.messages.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (_, i) => _MessageBubble(msg: t.messages[i]),
                ),
        ),
        if (!isClosed)
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFCBD5E1),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: prov.sendingTicketMessage ? null : _send,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: prov.sendingTicketMessage
                          ? Colors.grey
                          : Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: prov.sendingTicketMessage
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TeknisiTicketMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    if (msg.type == 'system') {
      return Container(
        color: const Color(0xFFF8FAFC),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: Column(
            children: [
              Text(
                msg.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                _fmtDate(msg.createdAt),
                style: const TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
              ),
            ],
          ),
        ),
      );
    }

    if (msg.type == 'field_report') {
      return Container(
        color: const Color(0xFFFFFBEB),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Color(0xFFFBBF24), width: 3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(name: msg.userName ?? 'T', isTeknisi: true),
                  const SizedBox(width: 8),
                  const Text(
                    'Laporan Lapangan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    msg.userName ?? '',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _fmtDate(msg.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                msg.message,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isTeknisi = msg.senderRole == 'teknisi';
    return Container(
      color: isTeknisi ? const Color(0xFFFFF7F7) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: msg.userName ?? '?', isTeknisi: isTeknisi),
              const SizedBox(width: 8),
              Text(
                msg.userName ?? '-',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isTeknisi ? Colors.red : const Color(0xFF059669),
                ),
              ),
              const Spacer(),
              Text(
                _fmtDate(msg.createdAt),
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              msg.message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final bool isTeknisi;
  const _Avatar({required this.name, required this.isTeknisi});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isTeknisi ? const Color(0xFFFFE4E4) : const Color(0xFFDCFCE7),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isTeknisi ? Colors.red : const Color(0xFF059669),
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyHint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.green),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Customer card ─────────────────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  final TeknisiTicket ticket;
  const _CustomerCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final lat = ticket.customerLatitude;
    final lng = ticket.customerLongitude;
    final hasLocation =
        lat != null && lng != null && lat.isNotEmpty && lng.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.customerName ?? '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (ticket.customerPhone != null)
                        Text(
                          ticket.customerPhone!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (ticket.customerPhone != null) ...[
                  _IconBtn(
                    icon: const FaIcon(
                      FontAwesomeIcons.whatsapp,
                      color: Colors.white,
                      size: 22,
                    ),
                    label: 'WhatsApp',
                    onTap: () async {
                      final phone = ticket.customerPhone!.replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                      final normalized = phone.startsWith('0')
                          ? '62${phone.substring(1)}'
                          : phone;
                      final uri = Uri.parse('https://wa.me/$normalized');
                      if (await canLaunchUrl(uri)) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                if (hasLocation)
                  _IconBtn(
                    icon: const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    label: 'Maps',
                    onTap: () async {
                      final uri = Uri.parse(
                        'https://maps.google.com/?q=$lat,$lng',
                      );
                      if (await canLaunchUrl(uri)) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (ticket.address != null)
                  _DetailRow(label: 'Alamat', value: ticket.address!),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final Widget icon;
  final String? label;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          icon,
          if (label != null)
            Text(
              label!,
              style: const TextStyle(color: Colors.white70, fontSize: 9),
            ),
        ],
      ),
    );
  }
}

// ── Timeline card ─────────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  final TeknisiTicket ticket;
  const _TimelineCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    return _DetailCard(
      title: 'Timeline',
      children: [
        _TimelineRow(
          dot: Colors.grey.shade300,
          label: 'Dibuat',
          value: _fmtDate(t.createdAt),
        ),
        if (t.technicianDispatchedAt != null)
          _TimelineRow(
            dot: Colors.red,
            label: 'Ditugaskan',
            value: _fmtDate(t.technicianDispatchedAt!),
          ),
        if (t.resolvedAt != null)
          _TimelineRow(
            dot: const Color(0xFF10B981),
            label: 'Selesai',
            value: _fmtDate(t.resolvedAt!),
            highlight: true,
          ),
        if (t.closedAt != null)
          _TimelineRow(
            dot: Colors.grey.shade400,
            label: 'Ditutup',
            value: _fmtDate(t.closedAt!),
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final Color dot;
  final String label;
  final String value;
  final bool highlight;

  const _TimelineRow({
    required this.dot,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: highlight
                    ? const Color(0xFF059669)
                    : const Color(0xFF64748B),
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: highlight
                  ? const Color(0xFF059669)
                  : const Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _DetailCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String title;
  final String body;
  final Color bg;
  final Color border;
  final Color titleColor;
  final Color bodyColor;

  const _NoteCard({
    required this.title,
    required this.body,
    required this.bg,
    required this.border,
    required this.titleColor,
    required this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(fontSize: 12, color: bodyColor, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Date formatter ────────────────────────────────────────────────────────────

String _fmtDate(String iso) {
  if (iso.length < 10) return iso;
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso.substring(0, 10);
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final time = iso.length >= 19 ? ' ${iso.substring(11, 16)}' : '';
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}$time';
}

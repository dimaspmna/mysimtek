import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/psb_ticket_model.dart';
import '../../providers/teknisi_provider.dart';

class PsbDetailScreen extends StatefulWidget {
  final PsbTicket ticket;
  const PsbDetailScreen({super.key, required this.ticket});

  @override
  State<PsbDetailScreen> createState() => _PsbDetailScreenState();
}

class _PsbDetailScreenState extends State<PsbDetailScreen> {
  int _tab = 0; // 0=info, 1=laporan, 2=thread
  final PageController _pageCtrl = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeknisiProvider>().loadPsbTicketDetail(widget.ticket.id);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeknisiProvider>(
      builder: (context, prov, _) {
        // Use detail data if loaded, otherwise fall back to list data
        final t =
            (prov.psbDetailState == LoadState.loaded &&
                prov.psbTicketDetail?.id == widget.ticket.id)
            ? prov.psbTicketDetail!
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
                    Icons.build_circle_outlined,
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
            backgroundColor: const Color(0xFF1D4ED8),
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
                      onTap: () => _pageCtrl.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      ),
                    ),
                    _TabBtn(
                      label: t.photos.isNotEmpty
                          ? 'Laporan (${t.photos.length})'
                          : 'Laporan',
                      selected: _tab == 1,
                      onTap: () => _pageCtrl.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      ),
                    ),
                    _TabBtn(
                      label: t.messages.isNotEmpty
                          ? 'Thread (${t.messages.length})'
                          : 'Thread',
                      selected: _tab == 2,
                      onTap: () => _pageCtrl.animateToPage(
                        2,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              // Detail loading indicator
              if (prov.psbDetailState == LoadState.loading)
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
                color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
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
              color: selected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF64748B),
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
  final PsbTicket ticket;
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
        _CustomerCard(ticket: t),
        const SizedBox(height: 12),
        _DetailCard(
          title: 'Detail Tiket',
          children: [
            if (t.scheduledDate != null && t.scheduledDate!.isNotEmpty)
              _DetailRow(
                label: 'Jadwal Pasang',
                value:
                    '${_fmtDate(t.scheduledDate!)}${t.scheduledTime != null ? ' — ${t.scheduledTime!.substring(0, 5)} WIB' : ''}',
              ),
            _DetailRow(label: 'Status Tiket', value: t.statusLabel),
            _DetailRow(
              label: 'Status Lapangan',
              value: t.fieldStatusLabel ?? '-',
            ),
            if (t.servicePackage != null)
              _DetailRow(label: 'Paket', value: t.servicePackage!),
            _DetailRow(label: 'Dibuat oleh', value: t.creatorName ?? '-'),
            _DetailRow(label: 'Tanggal', value: _fmtDate(t.createdAt)),
          ],
        ),
        if (t.notes != null && t.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _NoteCard(
            title: 'Catatan dari Sales',
            body: t.notes!,
            bg: const Color(0xFFEFF6FF),
            border: const Color(0xFFBFDBFE),
            titleColor: const Color(0xFF2563EB),
            bodyColor: const Color(0xFF1E3A8A),
          ),
        ],
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
            title: 'Catatan Penyelesaian',
            body: t.resolution!,
            bg: const Color(0xFFECFDF5),
            border: const Color(0xFFA7F3D0),
            titleColor: const Color(0xFF059669),
            bodyColor: const Color(0xFF065F46),
          ),
        ],
        const SizedBox(height: 12),
        _TimelineCard(ticket: t),
        if (t.status == 'confirmed') ...[
          const SizedBox(height: 16),
          _MulaiPsbButton(ticket: t, prov: prov),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Claim banner ──────────────────────────────────────────────────────────────

class _ClaimBanner extends StatelessWidget {
  final PsbTicket ticket;
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
            'Tiket PSB ini tersedia dan belum diambil siapapun. Ambil tiket ini untuk mulai menangani pemasangan pelanggan.',
            style: TextStyle(fontSize: 11, color: Color(0xFF059669)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: prov.claimingPsbTicket
                  ? null
                  : () async {
                      final err = await prov.claimPsbTicket(ticket.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err ?? 'Tiket PSB berhasil diklaim!'),
                          backgroundColor: err == null
                              ? const Color(0xFF059669)
                              : Colors.red,
                        ),
                      );
                    },
              icon: prov.claimingPsbTicket
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
                prov.claimingPsbTicket ? 'Mengklaim...' : 'Ambil Tiket Ini',
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

// ── "Mulai PSB" Button ────────────────────────────────────────────────────────

class _MulaiPsbButton extends StatelessWidget {
  final PsbTicket ticket;
  final TeknisiProvider prov;
  const _MulaiPsbButton({required this.ticket, required this.prov});

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
            'Ketuk tombol di bawah untuk memulai PSB dan memberi tahu bahwa kamu sedang menuju lokasi.',
            style: TextStyle(fontSize: 11, color: Color(0xFF059669)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: prov.startingPsb
                  ? null
                  : () async {
                      final ok = await prov.startPsb(ticket.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'PSB dimulai! Menuju lokasi pelanggan.'
                                : 'Gagal memulai PSB. Coba lagi.',
                          ),
                          backgroundColor: ok
                              ? const Color(0xFF059669)
                              : Colors.red,
                        ),
                      );
                    },
              icon: prov.startingPsb
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
                prov.startingPsb ? 'Memulai...' : 'Mulai PSB Sekarang',
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

// ══════════════════════════════════════════════════════════════════════════════
// TAB: LAPORAN
// ══════════════════════════════════════════════════════════════════════════════

class _LaporanTab extends StatefulWidget {
  final PsbTicket ticket;
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
    final xFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (xFile != null) setState(() => _photo = File(xFile.path));
  }

  Future<void> _submit() async {
    if (_notesCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan minimal 10 karakter.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto bukti wajib dipilih.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final err = await widget.prov.submitFieldReport(
      widget.ticket.id,
      fieldStatus: _fieldStatus,
      fieldNotes: _notesCtrl.text.trim(),
      photo: _photo!,
      photoType: _photoType,
    );

    if (!mounted) return;
    if (err == null) {
      _notesCtrl.clear();
      setState(() => _photo = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan dan foto berhasil disimpan.'),
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
    final isDoneOrClosed = t.status == 'done' || t.status == 'closed';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Field Report Form ────────────────────────────────────────
        if (!isDoneOrClosed) ...[
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
                  'Update Progress Pemasangan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                // Status lapangan
                const Text(
                  'Status Lapangan *',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _fieldStatus,
                  decoration: _inputDeco(),
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
                      value: 'done',
                      child: Text('Pemasangan Selesai'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text('Dibatalkan / Tidak Bisa Dipasang'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                  ],
                  onChanged: (v) =>
                      setState(() => _fieldStatus = v ?? _fieldStatus),
                ),
                const SizedBox(height: 12),
                // Laporan text
                const Text(
                  'Laporan Lapangan *',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  decoration: _inputDeco().copyWith(
                    hintText:
                        'Tuliskan kondisi di lokasi, proses pemasangan, kendala...',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Jenis foto
                const Text(
                  'Jenis Foto',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _photoType,
                  decoration: _inputDeco(),
                  items: const [
                    DropdownMenuItem(
                      value: 'before',
                      child: Text('Sebelum (Before)'),
                    ),
                    DropdownMenuItem(
                      value: 'after',
                      child: Text('Sesudah (After)'),
                    ),
                    DropdownMenuItem(value: 'progress', child: Text('Proses')),
                    DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                  ],
                  onChanged: (v) =>
                      setState(() => _photoType = v ?? _photoType),
                ),
                const SizedBox(height: 12),
                // Foto
                const Text(
                  'Foto Bukti *',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickPhoto,
                  child: _photo == null
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 32,
                                color: Color(0xFF94A3B8),
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
                        )
                      : Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _photo!,
                                width: double.infinity,
                                height: 180,
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
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _pickPhoto,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Ganti Foto',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: prov.submittingFieldReport ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: prov.submittingFieldReport
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Mengirim...'),
                            ],
                          )
                        : const Text(
                            'Kirim Laporan',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_sharp,
                    size: 48,
                    color: t.status == 'done'
                        ? const Color(0xFF059669)
                        : Colors.green,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.status == 'done'
                        ? 'Tiket ini sudah selesai'
                        : 'Tiket ini sudah ditutup',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Laporan tidak dapat diubah lagi.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ),
        ],
        // ── Photo Gallery ────────────────────────────────────────────
        if (t.photos.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Foto Terlampir (${t.photos.length})',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemCount: t.photos.length,
            itemBuilder: (_, i) {
              final photo = t.photos[i];
              final fullUrl = photo.photoUrl.startsWith('http')
                  ? photo.photoUrl
                  : '${ApiConstants.storageUrl}${photo.photoUrl}';
              return GestureDetector(
                onTap: () => _showLightbox(context, fullUrl),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        fullUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                photo.photoTypeLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (photo.caption != null)
                                Text(
                                  photo.caption!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  void _showLightbox(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB: THREAD
// ══════════════════════════════════════════════════════════════════════════════

class _ThreadTab extends StatefulWidget {
  final PsbTicket ticket;
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

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    final err = await widget.prov.sendPsbMessage(widget.ticket.id, text);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
    } else {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.ticket.messages;

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 40,
                        color: Color(0xFFCBD5E1),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Belum ada pesan',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _MessageBubble(msg: messages[i]),
                ),
        ),
        // Message input
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          padding: EdgeInsets.only(
            left: 12,
            right: 8,
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
                  decoration: InputDecoration(
                    hintText: 'Tulis pesan...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
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
                      borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              widget.prov.sendingPsbMessage
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: _send,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1D4ED8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 18,
                        ),
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
  final PsbTicketMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    if (msg.type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  msg.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmtTime(msg.createdAt),
                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (msg.type == 'field_report') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            border: const Border(
              left: BorderSide(color: Color(0xFFF59E0B), width: 3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDE68A),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (msg.userName ?? 'T').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Laporan Lapangan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  if (msg.userName != null)
                    Text(
                      '  ${msg.userName}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    _fmtTime(msg.createdAt),
                    style: const TextStyle(
                      fontSize: 9,
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
                  color: Color(0xFF1E293B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal message
    final isTeknisi = msg.senderRole == 'teknisi';
    return Padding(
      padding: EdgeInsets.only(
        left: isTeknisi ? 48 : 12,
        right: isTeknisi ? 12 : 48,
        top: 3,
        bottom: 3,
      ),
      child: Column(
        crossAxisAlignment: isTeknisi
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isTeknisi)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 2),
              child: Text(
                msg.userName ?? '-',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isTeknisi
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12).copyWith(
                bottomRight: isTeknisi ? const Radius.circular(2) : null,
                bottomLeft: !isTeknisi ? const Radius.circular(2) : null,
              ),
            ),
            child: Text(
              msg.message,
              style: TextStyle(
                fontSize: 12,
                color: isTeknisi
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF14532D),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _fmtTime(msg.createdAt),
            style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Customer card (Info tab)
// ══════════════════════════════════════════════════════════════════════════════

class _CustomerCard extends StatelessWidget {
  final PsbTicket ticket;
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
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                          fontWeight: FontWeight.w600,
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
                  GestureDetector(
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
                    child: const Column(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'WhatsApp',
                          style: TextStyle(color: Colors.white70, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (hasLocation)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(
                        'https://maps.google.com/?q=$lat,$lng',
                      );
                      if (await canLaunchUrl(uri)) launchUrl(uri);
                    },
                    child: const Column(
                      children: [
                        Icon(Icons.location_on, color: Colors.white, size: 22),
                        Text(
                          'Maps',
                          style: TextStyle(color: Colors.white70, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              children: [
                if (ticket.address != null)
                  _DetailRow(label: 'Alamat', value: ticket.address!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Timeline card
// ══════════════════════════════════════════════════════════════════════════════

class _TimelineCard extends StatelessWidget {
  final PsbTicket ticket;
  const _TimelineCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    return _DetailCard(
      title: 'Timeline',
      children: [
        _TimelineRow(
          dot: const Color(0xFFCBD5E1),
          label: 'Dibuat',
          value: _fmtDatetime(t.createdAt),
        ),
        if (t.confirmedAt != null)
          _TimelineRow(
            dot: const Color(0xFF60A5FA),
            label: 'Dikonfirmasi',
            value: _fmtDatetime(t.confirmedAt!),
          ),
        if (t.resolvedAt != null)
          _TimelineRow(
            dot: const Color(0xFF10B981),
            label: 'Selesai',
            value: _fmtDatetime(t.resolvedAt!),
            highlight: true,
          ),
        if (t.closedAt != null)
          _TimelineRow(
            dot: const Color(0xFF94A3B8),
            label: 'Ditutup',
            value: _fmtDatetime(t.closedAt!),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Reusable small widgets
// ══════════════════════════════════════════════════════════════════════════════

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

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDate(String raw) {
  if (raw.length < 10) return raw;
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw.substring(0, 10);
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
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

String _fmtDatetime(String iso) {
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

String _fmtTime(String iso) {
  if (iso.length < 16) return iso;
  final dt = DateTime.tryParse(iso);
  if (dt == null && iso.length >= 16) return iso.substring(11, 16);
  if (dt == null) return iso;
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
  final now = DateTime.now();
  if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
    return iso.substring(11, 16);
  }
  return '${dt.day} ${months[dt.month - 1]} ${iso.substring(11, 16)}';
}

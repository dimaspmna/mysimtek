import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../models/invoice_model.dart';

class ReceiptScreen extends StatefulWidget {
  final Invoice invoice;
  const ReceiptScreen({super.key, required this.invoice});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final _receiptKey = GlobalKey();
  bool _savingImage = false;

  Future<Uint8List?> _captureImage() async {
    final boundary =
        _receiptKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) throw Exception('Tidak dapat menangkap struk');
    await Future.delayed(const Duration(milliseconds: 100));
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Gagal encode gambar');
    return byteData.buffer.asUint8List();
  }

  Future<void> _saveImage() async {
    if (_savingImage) return;
    setState(() => _savingImage = true);
    try {
      final pngBytes = await _captureImage();
      if (pngBytes == null) throw Exception('Gagal encode gambar');
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) throw Exception('Izin penyimpanan ditolak');
      }
      final safeNum = widget.invoice.invoiceNumber.replaceAll(
        RegExp(r'[/\\:*?"<>|]'),
        '-',
      );
      await Gal.putImageBytes(
        pngBytes,
        name: 'struk_$safeNum',
        album: 'MySimtek',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Struk tersimpan ke Galeri',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Struk Pembayaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).padding.bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                RepaintBoundary(
                  key: _receiptKey,
                  child: Container(
                    color: const Color(0xFFF1F5F9),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _ReceiptCard(invoice: widget.invoice, fmt: fmt),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _savingImage ? null : _saveImage,
                    icon: _savingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Unduh Bukti Bayar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Receipt Card ──────────────────────────────────────────────────────────────

class _ReceiptCard extends StatelessWidget {
  final Invoice invoice;
  final NumberFormat fmt;

  const _ReceiptCard({required this.invoice, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.09),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _ReceiptHeader(),
          _TearOffLine(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                const Text(
                  'BUKTI PEMBAYARAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 14),
                const _DashedLine(),
                const SizedBox(height: 12),
                if (invoice.customerName != null)
                  _DetailRow(label: 'Pelanggan', value: invoice.customerName!),
                _DetailRow(
                  label: 'No. Invoice',
                  value: invoice.invoiceNumber,
                  mono: true,
                ),
                if (invoice.createdAt.isNotEmpty)
                  _DetailRow(
                    label: 'Diterbitkan',
                    value: _fmtDate(invoice.createdAt),
                  ),
                if (invoice.paidAt != null) ...[
                  _DetailRow(
                    label: 'Tgl Lunas',
                    value: _fmtDate(invoice.paidAt!),
                  ),
                  _DetailRow(
                    label: 'Waktu Lunas',
                    value: '${_fmtTime(invoice.paidAt!)} WIB',
                  ),
                ],

                if (invoice.packageName != null)
                  _DetailRow(label: 'Paket', value: invoice.packageName!),
                if (invoice.period != null)
                  _DetailRow(label: 'Periode', value: invoice.formattedPeriod),
                if (invoice.paymentMethod != null)
                  _DetailRow(
                    label: 'Metode Bayar',
                    value: invoice.paymentMethod!.toUpperCase(),
                  ),
                if (invoice.items.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const _DashedLine(),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rincian',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...invoice.items.map(
                    (item) => _DetailRow(
                      label: item.description,
                      value: fmt.format(item.amount),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const _DashedLine(thick: true),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL DIBAYAR',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      fmt.format(invoice.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _LunasStamp(),
                const SizedBox(height: 20),
                const _DashedLine(),
                const SizedBox(height: 14),
                const Text(
                  'Terima kasih telah melakukan pembayaran.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Dokumen ini sah tanpa tanda tangan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw.split('T').first);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return raw.split('T').first;
    }
  }

  static String _fmtTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ReceiptHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset('assets/logo/mysimtek.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SIMTEK',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                  height: 1.1,
                ),
              ),
              Text(
                'PT GUSTI GLOBAL GROUP',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.85),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tear-off Line ─────────────────────────────────────────────────────────────

class _TearOffLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          ClipRect(
            child: Align(
              alignment: Alignment.centerRight,
              widthFactor: 0.5,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final count = (constraints.maxWidth / 10).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    count,
                    (_) => Container(
                      width: 5,
                      height: 1,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                );
              },
            ),
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 0.5,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dashed Line ───────────────────────────────────────────────────────────────

class _DashedLine extends StatelessWidget {
  final bool thick;
  const _DashedLine({this.thick = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final dashW = thick ? 8.0 : 6.0;
        const gapW = 4.0;
        final count = (constraints.maxWidth / (dashW + gapW)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashW,
              height: thick ? 1.5 : 1,
              margin: const EdgeInsets.only(right: gapW),
              color: thick ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
            ),
          ),
        );
      },
    );
  }
}

// ── Detail Row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _DetailRow({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── LUNAS Stamp ───────────────────────────────────────────────────────────────

class _LunasStamp extends StatelessWidget {
  const _LunasStamp();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.18,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF10B981), width: 3),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF10B981).withOpacity(0.04),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_outlined, color: Color(0xFF10B981), size: 22),
            SizedBox(height: 2),
            Text(
              'LUNAS',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF10B981),
                letterSpacing: 8,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

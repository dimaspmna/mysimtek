import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../models/map_data_model.dart';
import '../../providers/teknisi_provider.dart';

class InfrastrukturMapScreen extends StatefulWidget {
  const InfrastrukturMapScreen({super.key});

  @override
  State<InfrastrukturMapScreen> createState() => _InfrastrukturMapScreenState();
}

class _InfrastrukturMapScreenState extends State<InfrastrukturMapScreen> {
  final MapController _mapCtrl = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String? _activeType; // null = show all, 'pop'/'otb'/etc = filter by type
  double _mapRotation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeknisiProvider>().loadMapData();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  // Color per marker type
  static const _typeColors = {
    'pop': Color(0xFF7C3AED),
    'otb': Color(0xFF0EA5E9),
    'odc_utama': Color(0xFFF97316),
    'odc': Color(0xFF10B981),
    'odp': Color(0xFFEF4444),
    'customer': Color(0xFF3B82F6),
  };

  static const _typeLabels = {
    'pop': 'POP',
    'otb': 'OTB',
    'odc_utama': 'ODC Utama',
    'odc': 'ODC',
    'odp': 'ODP',
    'customer': 'Customer',
  };

  static const _typeIcons = {
    'pop': Icons.dns_outlined,
    'otb': Icons.hub_outlined,
    'odc_utama': Icons.account_tree_outlined,
    'odc': Icons.account_tree_outlined,
    'odp': Icons.router_outlined,
    'customer': Icons.person_pin_circle_outlined,
  };

  List<MapMarker> _filteredMarkers(TekMapData data) {
    var markers = data.markers.toList();
    // Filter by active type
    if (_activeType != null) {
      markers = markers.where((m) => m.type == _activeType).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      markers = markers.where((m) {
        return m.name.toLowerCase().contains(q) ||
            (m.code?.toLowerCase().contains(q) ?? false) ||
            (m.address?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return markers;
  }

  bool get _showCables => _activeType == null || _activeType == 'cables';

  void _goToMarker(MapMarker m) {
    _mapCtrl.move(LatLng(m.latitude, m.longitude), 17);
    _showMarkerDetail(m);
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
                Icons.map_outlined,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Data Infrastruktur',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF334155),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      body: Consumer<TeknisiProvider>(
        builder: (context, prov, _) {
          if (prov.mapState == LoadState.loading ||
              prov.mapState == LoadState.initial) {
            return const AppLoading();
          }
          if (prov.mapState == LoadState.error) {
            return AppErrorView(
              message: prov.mapError ?? 'Gagal memuat data peta',
              onRetry: prov.loadMapData,
            );
          }
          final data = prov.mapData;
          if (data == null) {
            return AppErrorView(
              message: 'Data peta tidak tersedia',
              onRetry: prov.loadMapData,
            );
          }

          final markers = _filteredMarkers(data);
          final cables = _showCables ? data.cables : <MapCableLine>[];

          // Calculate center from all markers
          LatLng center = const LatLng(-6.2088, 106.8456);
          if (markers.isNotEmpty) {
            center = LatLng(markers.first.latitude, markers.first.longitude);
          }

          return Column(
            children: [
              // Search + layer toggles
              _buildSearchBar(data),
              // Layer toggle chips
              _buildLayerChips(data),
              // Search warning
              if (_search.isNotEmpty && markers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: const Color(0xFFFFF7ED),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Color(0xFFF97316),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Data tidak ditemukan untuk "$_search"',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFEA580C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              // Map
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapCtrl,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 14,
                        maxZoom: 20,
                        minZoom: 5,
                        onMapEvent: (event) {
                          final rotation = _mapCtrl.camera.rotation;
                          if (rotation != _mapRotation) {
                            setState(() => _mapRotation = rotation);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://mt{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
                          subdomains: const ['0', '1', '2', '3'],
                          maxZoom: 22,
                          maxNativeZoom: 21,
                          userAgentPackageName: 'com.simtek.mysimtek',
                        ),
                        // Cable lines
                        if (cables.isNotEmpty)
                          PolylineLayer(
                            polylines: cables
                                .map(
                                  (c) => Polyline(
                                    points: [
                                      LatLng(c.odpLat, c.odpLng),
                                      LatLng(c.custLat, c.custLng),
                                    ],
                                    color: const Color(
                                      0xFF64748B,
                                    ).withOpacity(0.5),
                                    strokeWidth: 1.5,
                                  ),
                                )
                                .toList(),
                          ),
                        // Markers
                        MarkerLayer(
                          markers: markers.map((m) {
                            final color =
                                _typeColors[m.type] ?? const Color(0xFF64748B);
                            return Marker(
                              point: LatLng(m.latitude, m.longitude),
                              width: 32,
                              height: 32,
                              child: GestureDetector(
                                onTap: () => _showMarkerDetail(m),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _typeIcons[m.type] ?? Icons.location_on,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    // Legend button
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: _buildLegendButton(),
                    ),
                    // Compass
                    Positioned(bottom: 16, right: 16, child: _buildCompass()),
                    // Marker count
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${markers.length} titik',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(TekMapData data) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) {
          setState(() => _search = v);
          // Auto-navigate to first result
          if (v.isNotEmpty) {
            final results = _filteredMarkers(data);
            if (results.isNotEmpty) {
              _mapCtrl.move(
                LatLng(results.first.latitude, results.first.longitude),
                16,
              );
            }
          }
        },
        decoration: InputDecoration(
          hintText: 'Cari POP, OTB, ODC, ODP, Customer...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: Color(0xFF94A3B8),
          ),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          isDense: true,
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
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  Widget _buildLayerChips(TekMapData data) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "Semua" button
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _activeType = null);
                  // Fit to all markers
                  final all = data.markers;
                  if (all.isNotEmpty) {
                    _mapCtrl.move(
                      LatLng(all.first.latitude, all.first.longitude),
                      14,
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _activeType == null
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _activeType == null
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    'Semua',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _activeType == null
                          ? Colors.white
                          : const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            ),
            ..._typeLabels.entries.map((e) {
              final active = _activeType == e.key;
              final color = _typeColors[e.key] ?? const Color(0xFF64748B);
              // Get count for this type
              final count = data.markers.where((m) => m.type == e.key).length;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _activeType = active ? null : e.key);
                    if (!active) {
                      // Navigate to first marker of this type
                      final typeMarkers = data.markers
                          .where((m) => m.type == e.key)
                          .toList();
                      if (typeMarkers.isNotEmpty) {
                        _mapCtrl.move(
                          LatLng(
                            typeMarkers.first.latitude,
                            typeMarkers.first.longitude,
                          ),
                          16,
                        );
                      }
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: active ? color : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? color : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active ? Colors.white : color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${e.value} ($count)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendButton() {
    return GestureDetector(
      onTap: _showLegend,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_outlined, size: 16, color: Color(0xFF334155)),
            SizedBox(width: 4),
            Text(
              'Legenda',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompass() {
    return GestureDetector(
      onTap: () {
        _mapCtrl.rotate(0);
        setState(() => _mapRotation = 0);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x330F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: -_mapRotation * (3.14159265 / 180),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 6,
                child: Text(
                  'N',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                child: Text(
                  'S',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              Positioned(
                left: 7,
                child: Text(
                  'W',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              Positioned(
                right: 7,
                child: Text(
                  'E',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLegend() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Legenda Peta',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _typeLabels.entries.map((e) {
                final color = _typeColors[e.key]!;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 2,
                  color: const Color(0xFF64748B).withOpacity(0.5),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Kabel (ODP → Customer)',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkerDetail(MapMarker m) {
    final color = _typeColors[m.type] ?? const Color(0xFF64748B);
    final typeLabel = _typeLabels[m.type] ?? m.type.toUpperCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.25,
        maxChildSize: 0.65,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _typeIcons[m.type] ?? Icons.location_on,
                    color: Colors.white,
                    size: 20,
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
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          if (m.code != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              m.code!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Status
            _detailRow(
              'Status',
              m.status.replaceAll('_', ' ').toUpperCase(),
              valueColor: m.status == 'active' || m.status == 'installed'
                  ? const Color(0xFF059669)
                  : const Color(0xFF94A3B8),
            ),
            // Address
            if (m.address != null && m.address!.isNotEmpty)
              _detailRow('Alamat', m.address!),
            // Parent
            if (m.parentName != null && m.parentName!.isNotEmpty)
              _detailRow(
                m.type == 'otb'
                    ? 'POP'
                    : m.type == 'odc_utama'
                    ? 'OTB'
                    : m.type == 'odc'
                    ? 'ODC Utama'
                    : m.type == 'odp'
                    ? 'ODC'
                    : 'Induk',
                m.parentName!,
              ),
            // Port capacity
            if (m.capacityPort != null) ...[
              _detailRow('Kapasitas Port', '${m.capacityPort}'),
              if (m.portUsed != null)
                _detailRow('Port Terpakai', '${m.portUsed}'),
              if (m.portAvailable != null)
                _detailRow(
                  'Port Tersedia',
                  '${m.portAvailable}',
                  valueColor: (m.portAvailable ?? 0) > 0
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
            ],
            // Customer-specific
            if (m.type == 'customer') ...[
              if (m.phone != null && m.phone!.isNotEmpty)
                _detailRow('Telepon', m.phone!),
              if (m.servicePackage != null && m.servicePackage!.isNotEmpty)
                _detailRow('Paket', m.servicePackage!),
            ],
            // Coordinates
            _detailRow(
              'Koordinat',
              '${m.latitude.toStringAsFixed(6)}, ${m.longitude.toStringAsFixed(6)}',
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(
                        'https://maps.google.com/?q=${m.latitude},${m.longitude}',
                      );
                      if (await canLaunchUrl(uri)) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.navigation_outlined, size: 16),
                    label: const Text('Google Maps'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (m.type == 'customer' &&
                    m.phone != null &&
                    m.phone!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final phone = m.phone!.replaceAll(
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
                      icon: const Icon(Icons.chat_outlined, size: 16),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: valueColor ?? const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

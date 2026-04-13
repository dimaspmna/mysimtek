/// Represents a single infrastructure marker on the map.
class MapMarker {
  final int id;
  final String type; // pop, otb, odc_utama, odc, odp, customer
  final String? code;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String status;
  final String? parentName; // pop_name, otb_name, odc_name, etc.
  final int? capacityPort;
  final int? portUsed;
  final int? portAvailable;
  final String? phone;
  final String? servicePackage;

  const MapMarker({
    required this.id,
    required this.type,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.code,
    this.address,
    this.parentName,
    this.capacityPort,
    this.portUsed,
    this.portAvailable,
    this.phone,
    this.servicePackage,
  });
}

/// Cable line connecting ODP to Customer
class MapCableLine {
  final int id;
  final String odpName;
  final String custName;
  final double odpLat;
  final double odpLng;
  final double custLat;
  final double custLng;

  const MapCableLine({
    required this.id,
    required this.odpName,
    required this.custName,
    required this.odpLat,
    required this.odpLng,
    required this.custLat,
    required this.custLng,
  });
}

/// Parsed map data from API
class TekMapData {
  final List<MapMarker> markers;
  final List<MapCableLine> cables;

  const TekMapData({required this.markers, required this.cables});

  factory TekMapData.fromJson(Map<String, dynamic> json) {
    final markers = <MapMarker>[];

    // POPs
    for (final p in (json['pops'] as List? ?? [])) {
      markers.add(
        MapMarker(
          id: p['id'],
          type: 'pop',
          code: p['code']?.toString(),
          name: p['name']?.toString() ?? '',
          latitude: (p['latitude'] as num).toDouble(),
          longitude: (p['longitude'] as num).toDouble(),
          address: p['address']?.toString(),
          status: p['status']?.toString() ?? 'active',
        ),
      );
    }

    // OTBs
    for (final o in (json['otbs'] as List? ?? [])) {
      markers.add(
        MapMarker(
          id: o['id'],
          type: 'otb',
          code: o['code']?.toString(),
          name: o['name']?.toString() ?? '',
          latitude: (o['latitude'] as num).toDouble(),
          longitude: (o['longitude'] as num).toDouble(),
          address: o['address']?.toString(),
          status: o['status']?.toString() ?? 'active',
          parentName: o['pop_name']?.toString(),
        ),
      );
    }

    // ODC Utamas
    for (final o in (json['odc_utamas'] as List? ?? [])) {
      markers.add(
        MapMarker(
          id: o['id'],
          type: 'odc_utama',
          code: o['code']?.toString(),
          name: o['name']?.toString() ?? '',
          latitude: (o['latitude'] as num).toDouble(),
          longitude: (o['longitude'] as num).toDouble(),
          address: o['address']?.toString(),
          status: o['status']?.toString() ?? 'active',
          parentName: o['otb_name']?.toString(),
          capacityPort: o['capacity_port'] as int?,
        ),
      );
    }

    // ODCs
    for (final o in (json['odcs'] as List? ?? [])) {
      markers.add(
        MapMarker(
          id: o['id'],
          type: 'odc',
          code: o['code']?.toString(),
          name: o['name']?.toString() ?? '',
          latitude: (o['latitude'] as num).toDouble(),
          longitude: (o['longitude'] as num).toDouble(),
          address: o['address']?.toString(),
          status: o['status']?.toString() ?? 'active',
          parentName: o['odc_utama_name']?.toString(),
          capacityPort: o['capacity_port'] as int?,
        ),
      );
    }

    // NocODPs
    for (final o in (json['noc_odps'] as List? ?? [])) {
      markers.add(
        MapMarker(
          id: o['id'],
          type: 'odp',
          code: o['code']?.toString(),
          name: o['name']?.toString() ?? '',
          latitude: (o['latitude'] as num).toDouble(),
          longitude: (o['longitude'] as num).toDouble(),
          address: o['address']?.toString(),
          status: o['status']?.toString() ?? 'installed',
          parentName: o['odc_name']?.toString(),
          capacityPort: o['capacity_port'] as int?,
          portUsed: o['port_used'] as int?,
          portAvailable: o['port_available'] as int?,
        ),
      );
    }

    // Customers
    for (final c in (json['customers'] as List? ?? [])) {
      markers.add(
        MapMarker(
          id: c['id'],
          type: 'customer',
          name: c['name']?.toString() ?? '',
          latitude: (c['latitude'] as num).toDouble(),
          longitude: (c['longitude'] as num).toDouble(),
          address: c['address']?.toString(),
          status: c['status']?.toString() ?? 'active',
          phone: c['phone']?.toString(),
          servicePackage: c['service_package']?.toString(),
        ),
      );
    }

    // Cables
    final cables = <MapCableLine>[];
    for (final c in (json['cables'] as List? ?? [])) {
      cables.add(
        MapCableLine(
          id: c['id'],
          odpName: c['odp_name']?.toString() ?? '',
          custName: c['cust_name']?.toString() ?? '',
          odpLat: (c['odp_lat'] as num).toDouble(),
          odpLng: (c['odp_lng'] as num).toDouble(),
          custLat: (c['cust_lat'] as num).toDouble(),
          custLng: (c['cust_lng'] as num).toDouble(),
        ),
      );
    }

    return TekMapData(markers: markers, cables: cables);
  }
}

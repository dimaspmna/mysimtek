class OdpData {
  final int id;
  final String name;
  final String? location;
  final int capacity;
  final int used;
  final String status;
  final String? coordinates;
  final String? area;

  const OdpData({
    required this.id,
    required this.name,
    this.location,
    required this.capacity,
    required this.used,
    required this.status,
    this.coordinates,
    this.area,
  });

  int get available => capacity - used;
  double get usagePercent => capacity > 0 ? (used / capacity) * 100 : 0;

  factory OdpData.fromJson(Map<String, dynamic> json) => OdpData(
    id: json['id'] as int,
    name: json['name']?.toString() ?? json['nama']?.toString() ?? '',
    location: json['location']?.toString() ?? json['lokasi']?.toString(),
    capacity: (json['capacity'] ?? json['kapasitas'] ?? 0) as int,
    used: (json['used'] ?? json['terpakai'] ?? 0) as int,
    status: json['status']?.toString() ?? 'aktif',
    coordinates:
        json['coordinates']?.toString() ?? json['koordinat']?.toString(),
    area: json['area']?.toString() ?? json['wilayah']?.toString(),
  );
}

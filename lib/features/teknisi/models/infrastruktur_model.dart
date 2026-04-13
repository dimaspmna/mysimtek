class Infrastruktur {
  final int id;
  final String name;
  final String? type;
  final String status;
  final String? location;
  final String? description;

  const Infrastruktur({
    required this.id,
    required this.name,
    this.type,
    required this.status,
    this.location,
    this.description,
  });

  factory Infrastruktur.fromJson(Map<String, dynamic> json) => Infrastruktur(
    id: json['id'] as int,
    name: json['name']?.toString() ?? json['nama']?.toString() ?? '',
    type: json['type']?.toString() ?? json['tipe']?.toString(),
    status: json['status']?.toString() ?? 'aktif',
    location: json['location']?.toString() ?? json['lokasi']?.toString(),
    description:
        json['description']?.toString() ?? json['deskripsi']?.toString(),
  );
}

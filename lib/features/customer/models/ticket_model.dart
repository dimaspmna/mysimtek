class TicketMessage {
  final int id;
  final String body;
  final String senderName;
  final bool isFromCustomer;
  final String createdAt;

  const TicketMessage({
    required this.id,
    required this.body,
    required this.senderName,
    required this.isFromCustomer,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) => TicketMessage(
    id: json['id'] as int,
    body: json['body']?.toString() ?? json['message']?.toString() ?? '',
    senderName:
        json['sender_name']?.toString() ??
        json['sender']?['name']?.toString() ??
        json['user']?['name']?.toString() ??
        'Staff',
    isFromCustomer:
        json['is_from_customer'] == true ||
        json['sender_role'] == 'customer' ||
        json['role'] == 'customer',
    createdAt: json['created_at']?.toString() ?? '',
  );
}

class Ticket {
  final int id;
  final String subject;
  final String body;
  final String status;
  final String category;
  final String ticketNumber;
  final bool hasAssignedTechnician;
  final String? technicianName;
  final String? technicianPhone;
  final String? fieldStatus;
  final String createdAt;
  final List<TicketMessage> messages;

  const Ticket({
    required this.id,
    required this.subject,
    required this.body,
    required this.status,
    required this.category,
    required this.ticketNumber,
    required this.hasAssignedTechnician,
    this.technicianName,
    this.technicianPhone,
    this.fieldStatus,
    required this.createdAt,
    this.messages = const [],
  });

  String get categoryLabel {
    const map = {
      // Gangguan Layanan
      'no_internet_access': 'Tidak Ada Sinyal',
      'slow_internet': 'Internet Lambat',
      'intermittent_connection': 'Koneksi Putus-Nyambung',
      'power_loss': 'Power Loss',
      // Kabel & Jalur
      'cable_cut_damaged': 'Jalur Kabel Putus/Rusak',
      'main_cable_cut': 'Jalur Utama Putus',
      'pigtail_cut': 'Pigtail Putus',
      'fiber_cut': 'Fiber Cut',
      'cable_routing': 'Penataan Kabel',
      'new_cable_installation': 'Pasang Jalur Baru',
      'cable_migration': 'Migrasi Jalur',
      'pole_relocation': 'Relokasi Tiang / Jalur',
      'collapsed_pole': 'Tiang Roboh/Miring',
      'short_distance_routing': 'Tarikan Jalur Jarak Dekat',
      'short_distance_installation': 'Instalasi Jangkauan Dekat',
      'short_distance_expansion': 'Perluasan Jangkauan Dekat',
      // Perangkat Pelanggan
      'device_damage': 'Kerusakan Perangkat',
      'modem_router_damage': 'Modem/Router Rusak',
      'onu_ont_offline': 'ONU/ONT Offline',
      'adapter_damage': 'Adaptor Rusak',
      'device_reset': 'Reset Perangkat',
      'device_upgrade': 'Upgrade Perangkat',
      // ODP/ODC/Core
      'odp_damage': 'ODP Rusak',
      'odc_damage': 'ODC Rusak',
      'high_attenuation': 'Redaman Tinggi',
      'odp_audit_labeling': 'Audit & Labelling ODP',
      'core_down': 'Core Down',
      'switch_down': 'Switch Down',
      'port_error': 'Port Error / Port Mati',
      'pln_outage': 'Gangguan Listrik PLN',
      // Maintenance
      'urgent_maintenance': 'Maintenance Urgent',
      'backbone_repair': 'Perbaikan Backbone',
      'network_troubleshooting': 'Troubleshooting Onsite',
      'monitoring': 'Monitoring Gangguan',
      'system_reconfiguration': 'Konfigurasi Ulang',
      // Wireless & AP
      'wireless_link_down': 'Wireless Link Down',
      'access_point_trouble': 'Trouble Access Point',
      'cctv_ip_camera_issue': 'Gangguan CCTV/IP Camera',
      // Aktivasi
      'new_customer_activation': 'Aktivasi Pelanggan Baru',
      'package_change': 'Perubahan Paket Internet',
      // Kendala
      'mass_outage': 'Gangguan Massal Area',
      'pending_materials': 'Pending Material',
      'waiting_location_permit': 'Menunggu Izin Lokasi',
      'weather_disaster': 'Kendala Cuaca / Bencana',
      'short_range_limitation': 'Kendala Jangkauan Dekat',
      'short_range_coverage': 'Area Cover Jangkauan Dekat',
      'short_range_survey': 'Survey Jangkauan Dekat',
      'short_range_optimization': 'Optimasi Jangkauan Dekat',
      // Lainnya
      'others': 'Lainnya',
    };
    return map[category] ?? category;
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final msgs = json['messages'] as List?;
    final tech = json['technician'] as Map<String, dynamic>?;
    return Ticket(
      id: json['id'] as int,
      subject: json['subject']?.toString() ?? '',
      body: json['body']?.toString() ?? json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      category: json['category']?.toString() ?? 'other',
      ticketNumber: json['ticket_number']?.toString() ?? '',
      hasAssignedTechnician: json['assigned_to'] != null || tech != null,
      technicianName: tech?['name']?.toString(),
      technicianPhone: tech?['phone']?.toString(),
      fieldStatus: json['field_status']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      messages:
          msgs
              ?.map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

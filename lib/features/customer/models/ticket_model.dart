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
      'no_signal': 'Tidak Ada Sinyal',
      'slow_speed': 'Internet Lambat',
      'intermittent': 'Putus-putus',
      'hardware': 'Kerusakan Perangkat',
      'other': 'Lainnya',
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

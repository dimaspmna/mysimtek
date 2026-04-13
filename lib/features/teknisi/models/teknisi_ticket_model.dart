class TeknisiTicketMessage {
  final int id;
  final String? userName;
  final String senderRole;
  final String type;
  final String message;
  final String createdAt;

  const TeknisiTicketMessage({
    required this.id,
    required this.senderRole,
    required this.type,
    required this.message,
    required this.createdAt,
    this.userName,
  });

  factory TeknisiTicketMessage.fromJson(Map<String, dynamic> json) =>
      TeknisiTicketMessage(
        id: json['id'] as int,
        userName: json['user_name']?.toString(),
        senderRole: json['sender_role']?.toString() ?? '',
        type: json['type']?.toString() ?? 'normal',
        message: json['message']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
      );
}

class TeknisiTicketPhoto {
  final int id;
  final String photoUrl;
  final String photoType;
  final String photoTypeLabel;
  final String? caption;
  final String createdAt;

  const TeknisiTicketPhoto({
    required this.id,
    required this.photoUrl,
    required this.photoType,
    required this.photoTypeLabel,
    required this.createdAt,
    this.caption,
  });

  factory TeknisiTicketPhoto.fromJson(Map<String, dynamic> json) =>
      TeknisiTicketPhoto(
        id: json['id'] as int,
        photoUrl: json['photo_url']?.toString() ?? '',
        photoType: json['photo_type']?.toString() ?? 'other',
        photoTypeLabel: json['photo_type_label']?.toString() ?? '',
        caption: json['caption']?.toString(),
        createdAt: json['created_at']?.toString() ?? '',
      );
}

class TeknisiTicket {
  final int id;
  final String ticketNumber;
  final String subject;
  final String status;
  final String statusLabel;
  final String? priority;
  final String? priorityLabel;
  final String? category;
  final String? categoryLabel;
  final String? fieldStatus;
  final String? fieldStatusLabel;
  final String? fieldNotes;
  final String? resolution;
  final int? assignedTo;
  final String? customerName;
  final String? customerPhone;
  final String? address;
  final String? customerLatitude;
  final String? customerLongitude;
  final String? assignerName;
  final String? description;
  final String? technicianDispatchedAt;
  final String? resolvedAt;
  final String? closedAt;
  final String createdAt;
  final List<TeknisiTicketMessage> messages;
  final List<TeknisiTicketPhoto> photos;

  const TeknisiTicket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
    this.priority,
    this.priorityLabel,
    this.category,
    this.categoryLabel,
    this.fieldStatus,
    this.fieldStatusLabel,
    this.fieldNotes,
    this.resolution,
    this.assignedTo,
    this.customerName,
    this.customerPhone,
    this.address,
    this.customerLatitude,
    this.customerLongitude,
    this.assignerName,
    this.description,
    this.technicianDispatchedAt,
    this.resolvedAt,
    this.closedAt,
    this.messages = const [],
    this.photos = const [],
  });

  factory TeknisiTicket.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final assigner = json['assigner'] as Map<String, dynamic>?;
    return TeknisiTicket(
      id: json['id'] as int,
      ticketNumber: json['ticket_number']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      statusLabel:
          json['status_label']?.toString() ?? json['status']?.toString() ?? '',
      priority: json['priority']?.toString(),
      priorityLabel: json['priority_label']?.toString(),
      category: json['category']?.toString(),
      categoryLabel: json['category_label']?.toString(),
      fieldStatus: json['field_status']?.toString(),
      fieldStatusLabel: json['field_status_label']?.toString(),
      fieldNotes: json['field_notes']?.toString(),
      resolution: json['resolution']?.toString(),
      assignedTo: json['assigned_to'] as int?,
      customerName: customer?['name']?.toString(),
      customerPhone: customer?['phone']?.toString(),
      address: customer?['address']?.toString(),
      customerLatitude: customer?['latitude']?.toString(),
      customerLongitude: customer?['longitude']?.toString(),
      assignerName: assigner?['name']?.toString(),
      description: json['description']?.toString(),
      technicianDispatchedAt: json['technician_dispatched_at']?.toString(),
      resolvedAt: json['resolved_at']?.toString(),
      closedAt: json['closed_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      messages:
          (json['messages'] as List?)
              ?.map(
                (e) => TeknisiTicketMessage.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      photos:
          (json['photos'] as List?)
              ?.map(
                (e) => TeknisiTicketPhoto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  String get displayDate =>
      createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
}

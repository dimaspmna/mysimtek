class PsbTicketMessage {
  final int id;
  final String? userName;
  final String? senderRole;
  final String type; // system | field_report | normal
  final String message;
  final String createdAt;

  const PsbTicketMessage({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    this.userName,
    this.senderRole,
  });

  factory PsbTicketMessage.fromJson(Map<String, dynamic> json) {
    return PsbTicketMessage(
      id: json['id'] as int,
      userName: json['user_name']?.toString(),
      senderRole: json['sender_role']?.toString(),
      type: json['type']?.toString() ?? 'normal',
      message: json['message']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class PsbTicketPhoto {
  final int id;
  final String photoUrl;
  final String photoType;
  final String photoTypeLabel;
  final String? caption;
  final String createdAt;

  const PsbTicketPhoto({
    required this.id,
    required this.photoUrl,
    required this.photoType,
    required this.photoTypeLabel,
    required this.createdAt,
    this.caption,
  });

  factory PsbTicketPhoto.fromJson(Map<String, dynamic> json) {
    return PsbTicketPhoto(
      id: json['id'] as int,
      photoUrl: json['photo_url']?.toString() ?? '',
      photoType: json['photo_type']?.toString() ?? 'other',
      photoTypeLabel: json['photo_type_label']?.toString() ?? 'Lainnya',
      caption: json['caption']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class PsbTicket {
  final int id;
  final String ticketNumber;
  final String status;
  final String statusLabel;
  final String? fieldStatus;
  final String? fieldStatusLabel;
  final String? fieldNotes;
  final String? resolution;
  final String? servicePackage;
  final String? notes;
  final String? scheduledDate;
  final String? scheduledTime;
  final String? customerName;
  final String? customerPhone;
  final String? address;
  final String? customerLatitude;
  final String? customerLongitude;
  final int? assignedTo;
  final String? creatorName;
  final String? confirmedAt;
  final String? resolvedAt;
  final String? closedAt;
  final String createdAt;
  final List<PsbTicketMessage> messages;
  final List<PsbTicketPhoto> photos;

  const PsbTicket({
    required this.id,
    required this.ticketNumber,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
    this.fieldStatus,
    this.fieldStatusLabel,
    this.fieldNotes,
    this.resolution,
    this.servicePackage,
    this.notes,
    this.scheduledDate,
    this.scheduledTime,
    this.customerName,
    this.customerPhone,
    this.address,
    this.customerLatitude,
    this.customerLongitude,
    this.assignedTo,
    this.creatorName,
    this.confirmedAt,
    this.resolvedAt,
    this.closedAt,
    this.messages = const [],
    this.photos = const [],
  });

  factory PsbTicket.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final creator = json['creator'] as Map<String, dynamic>?;

    final rawMessages = json['messages'] as List<dynamic>? ?? [];
    final rawPhotos = json['photos'] as List<dynamic>? ?? [];

    return PsbTicket(
      id: json['id'] as int,
      ticketNumber: json['ticket_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      statusLabel:
          json['status_label']?.toString() ?? json['status']?.toString() ?? '',
      fieldStatus: json['field_status']?.toString(),
      fieldStatusLabel: json['field_status_label']?.toString(),
      fieldNotes: json['field_notes']?.toString(),
      resolution: json['resolution']?.toString(),
      servicePackage: json['service_package']?.toString(),
      notes: json['notes']?.toString(),
      scheduledDate: json['scheduled_date']?.toString(),
      scheduledTime: json['scheduled_time']?.toString(),
      customerName: customer?['name']?.toString(),
      customerPhone: customer?['phone']?.toString(),
      address: customer?['address']?.toString(),
      customerLatitude: customer?['latitude']?.toString(),
      customerLongitude: customer?['longitude']?.toString(),
      assignedTo: json['assigned_to'] as int?,
      creatorName: creator?['name']?.toString(),
      confirmedAt: json['confirmed_at']?.toString(),
      resolvedAt: json['resolved_at']?.toString(),
      closedAt: json['closed_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      messages: rawMessages
          .map((e) => PsbTicketMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      photos: rawPhotos
          .map((e) => PsbTicketPhoto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Returns a copy with updated fields (for local state refresh)
  PsbTicket copyWith({
    String? status,
    String? statusLabel,
    String? fieldStatus,
    String? fieldStatusLabel,
    String? fieldNotes,
    List<PsbTicketMessage>? messages,
    List<PsbTicketPhoto>? photos,
  }) {
    return PsbTicket(
      id: id,
      ticketNumber: ticketNumber,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      createdAt: createdAt,
      fieldStatus: fieldStatus ?? this.fieldStatus,
      fieldStatusLabel: fieldStatusLabel ?? this.fieldStatusLabel,
      fieldNotes: fieldNotes ?? this.fieldNotes,
      resolution: resolution,
      servicePackage: servicePackage,
      notes: notes,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      customerName: customerName,
      customerPhone: customerPhone,
      address: address,
      customerLatitude: customerLatitude,
      customerLongitude: customerLongitude,
      assignedTo: assignedTo,
      creatorName: creatorName,
      confirmedAt: confirmedAt,
      resolvedAt: resolvedAt,
      closedAt: closedAt,
      messages: messages ?? this.messages,
      photos: photos ?? this.photos,
    );
  }

  String get displayDate {
    if (scheduledDate != null && scheduledDate!.isNotEmpty) {
      return scheduledDate!;
    }
    return createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
  }
}

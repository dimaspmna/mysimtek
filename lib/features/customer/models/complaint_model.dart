class ComplaintReply {
  final int id;
  final String body;
  final String senderName;
  final bool isFromCustomer;
  final String createdAt;

  const ComplaintReply({
    required this.id,
    required this.body,
    required this.senderName,
    required this.isFromCustomer,
    required this.createdAt,
  });

  factory ComplaintReply.fromJson(Map<String, dynamic> json) => ComplaintReply(
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

class Complaint {
  final int id;
  final String subject;
  final String body;
  final String status;
  final String createdAt;
  final List<ComplaintReply> replies;

  const Complaint({
    required this.id,
    required this.subject,
    required this.body,
    required this.status,
    required this.createdAt,
    this.replies = const [],
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    final replyData = json['replies'] as List?;
    return Complaint(
      id: json['id'] as int,
      subject: json['subject']?.toString() ?? '',
      body: json['body']?.toString() ?? json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      createdAt: json['created_at']?.toString() ?? '',
      replies:
          replyData
              ?.map((e) => ComplaintReply.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

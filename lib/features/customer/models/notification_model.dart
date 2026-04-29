class AppNotification {
  final int id;
  final String title;
  final String body;
  final String
  type; // 'announcement' | 'customer' | 'invoice' | 'ticket_update'
  final String createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(
    Map<String, dynamic> json, {
    String type = 'announcement',
  }) => AppNotification(
    id: json['id'] as int,
    title: json['title']?.toString() ?? json['judul']?.toString() ?? '',
    body:
        json['content']?.toString() ??
        json['body']?.toString() ??
        json['message']?.toString() ??
        json['isi']?.toString() ??
        '',
    type: json['type']?.toString() ?? type,
    createdAt: json['created_at']?.toString() ?? '',
    isRead: json['is_read'] == true || json['read_at'] != null,
  );
}

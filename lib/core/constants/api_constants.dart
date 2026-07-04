class ApiConstants {
  // static const String baseUrl = 'http://127.0.0.1:8000/api';
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  // static const String baseUrl = "http://192.168.1.33:8000/api";
  // static const String baseUrl = "https://dev-mysimtek.coglinetech.com/api";
  static const String baseUrl = "https://mysimtek.coglinetech.com/api";

  /// Public storage URL (for serving uploaded files like PSB photos)
  static String get storageUrl => baseUrl.replaceFirst('/api', '');

  // Auth
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';
  static const String fcmTokenUpdate = '/fcm-token';
  static const String verifyPassword = '/verify-password';
  static const String changePassword = '/change-password';

  // OTA Access (Minta Akses Masuk)
  static const String requestAccess = '/v1/auth/request-access';

  // Notifications
  static const String announcements = '/notifications/announcements';
  static String announcementMarkRead(int id) =>
      '/notifications/announcements/$id/read';
  static const String financeNotifications = '/notifications/finance';
  static const String customerNotifications = '/notifications/customer';
  static String customerNotificationMarkRead(int id) =>
      '/notifications/customer/$id/read';
  static const String customerNotificationsReadAll =
      '/notifications/customer/read-all';

  // Customer
  static const String customerDashboard = '/customer/dashboard';
  static const String customerProfile = '/customer/profile';
  static const String customerBilling = '/customer/billing';
  static const String customerBillingHistory = '/customer/billing/history';
  static const String customerInvoices = '/customer/invoices';
  static String customerInvoiceDetail(dynamic id) => '/customer/invoices/$id';
  static String customerInvoiceReceipt(dynamic id) =>
      '/customer/invoices/$id/receipt';
  static String customerPaymentUrl(dynamic invoiceId) =>
      '/customer/billing/$invoiceId/payment-url';
  static const String customerTickets = '/customer/tickets';
  static String customerTicketDetail(dynamic id) => '/customer/tickets/$id';
  static String customerTicketMessages(dynamic id) =>
      '/customer/tickets/$id/messages';
  static const String customerTicketCategories = '/customer/ticket-categories';
  static const String customerComplaints = '/customer/complaints';
  static String customerComplaintDetail(dynamic id) =>
      '/customer/complaints/$id';
  static String customerComplaintReply(dynamic id) =>
      '/customer/complaints/$id/reply';
}

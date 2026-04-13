class ApiConstants {
  // static const String baseUrl = 'http://127.0.0.1:8000/api';
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  // static const String baseUrl = "http://192.168.1.33:8000/api";
  static const String baseUrl = "https://dev-mysimtek.coglinetech.com/api";

  /// Public storage URL (for serving uploaded files like PSB photos)
  static String get storageUrl => baseUrl.replaceFirst('/api', '');

  // Auth
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';

  // Notifications
  static const String announcements = '/notifications/announcements';
  static String announcementMarkRead(int id) =>
      '/notifications/announcements/$id/read';
  static const String financeNotifications = '/notifications/finance';

  // Customer
  static const String customerDashboard = '/customer/dashboard';
  static const String customerProfile = '/customer/profile';
  static const String customerBilling = '/customer/billing';
  static const String customerBillingHistory = '/customer/billing/history';
  static const String customerInvoices = '/customer/invoices';
  static String customerInvoiceDetail(dynamic id) => '/customer/invoices/$id';
  static String customerInvoiceReceipt(dynamic id) =>
      '/customer/invoices/$id/receipt';
  static String customerSnapToken(dynamic invoiceId) =>
      '/customer/billing/$invoiceId/snap-token';
  static String customerPaymentStatus(dynamic invoiceId) =>
      '/customer/billing/$invoiceId/status';
  static const String customerTickets = '/customer/tickets';
  static String customerTicketDetail(dynamic id) => '/customer/tickets/$id';
  static String customerTicketMessages(dynamic id) =>
      '/customer/tickets/$id/messages';
  static const String customerComplaints = '/customer/complaints';
  static String customerComplaintDetail(dynamic id) =>
      '/customer/complaints/$id';
  static String customerComplaintReply(dynamic id) =>
      '/customer/complaints/$id/reply';

  // Teknisi
  static const String teknisiOdp = '/teknisi/odp';
  static const String teknisiJadwal = '/teknisi/jadwal';
  static const String teknisiTickets = '/teknisi/tickets';
  static String teknisiTicketDetail(dynamic id) => '/teknisi/tickets/$id';
  static String teknisiTicketClaim(dynamic id) => '/teknisi/tickets/$id/claim';
  static String teknisiTicketStart(dynamic id) => '/teknisi/tickets/$id/start';
  static String teknisiTicketFieldReport(dynamic id) =>
      '/teknisi/tickets/$id/field-report';
  static String teknisiTicketMessages(dynamic id) =>
      '/teknisi/tickets/$id/messages';
  static const String teknisiPsbTickets = '/teknisi/psb-tickets';
  static String teknisiPsbTicketDetail(dynamic id) =>
      '/teknisi/psb-tickets/$id';
  static String teknisiPsbTicketClaim(dynamic id) =>
      '/teknisi/psb-tickets/$id/claim';
  static String teknisiPsbTicketStart(dynamic id) =>
      '/teknisi/psb-tickets/$id/start';
  static String teknisiPsbTicketFieldReport(dynamic id) =>
      '/teknisi/psb-tickets/$id/field-report';
  static String teknisiPsbTicketMessages(dynamic id) =>
      '/teknisi/psb-tickets/$id/messages';
  static const String nocInfrastructureAll = '/noc/infrastructure/all';
  static const String teknisiMapData = '/teknisi/map-data';
}

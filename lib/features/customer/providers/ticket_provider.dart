import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/ticket_model.dart';

class TicketProvider extends ChangeNotifier {
  final ApiService _api;

  bool _listLoading = false;
  List<Ticket> _tickets = [];
  String? _listError;

  bool _detailLoading = false;
  Ticket? _currentTicket;
  String? _detailError;

  bool _submitting = false;

  bool get listLoading => _listLoading;
  List<Ticket> get tickets => _tickets;
  String? get listError => _listError;

  bool get detailLoading => _detailLoading;
  Ticket? get currentTicket => _currentTicket;
  String? get detailError => _detailError;

  bool get submitting => _submitting;

  TicketProvider(this._api);

  Future<void> loadTickets() async {
    _listLoading = true;
    _listError = null;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.customerTickets);
      final list = (res is Map && res.containsKey('tickets'))
          ? res['tickets'] as List
          : (res is List ? res : []);
      _tickets = list
          .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _listError = e.message;
    }
    _listLoading = false;
    notifyListeners();
  }

  Future<void> loadTicketDetail(int id) async {
    _detailLoading = true;
    _detailError = null;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.customerTicketDetail(id));
      final data = (res is Map && res.containsKey('ticket'))
          ? res['ticket'] as Map<String, dynamic>
          : res as Map<String, dynamic>;
      _currentTicket = Ticket.fromJson(data);
    } on ApiException catch (e) {
      _detailError = e.message;
    }
    _detailLoading = false;
    notifyListeners();
  }

  Future<bool> createTicket(
    String subject,
    String body,
    String category,
  ) async {
    _submitting = true;
    notifyListeners();
    try {
      await _api.post(ApiConstants.customerTickets, {
        'subject': subject,
        'description': body,
        'category': category,
      });
      _submitting = false;
      notifyListeners();
      await loadTickets();
      return true;
    } on ApiException catch (e) {
      _listError = e.message;
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> replyTicket(int ticketId, String message) async {
    _submitting = true;
    notifyListeners();
    try {
      await _api.post(ApiConstants.customerTicketMessages(ticketId), {
        'message': message,
      });
      _submitting = false;
      notifyListeners();
      await loadTicketDetail(ticketId);
      return true;
    } on ApiException catch (e) {
      _detailError = e.message;
      _submitting = false;
      notifyListeners();
      return false;
    }
  }
}

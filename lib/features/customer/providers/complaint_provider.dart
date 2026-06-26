import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/complaint_model.dart';

class ComplaintProvider extends ChangeNotifier {
  final ApiService _api;

  bool _listLoading = false;
  List<Complaint> _complaints = [];
  String? _listError;

  bool _detailLoading = false;
  Complaint? _current;
  String? _detailError;

  bool _submitting = false;

  bool get listLoading => _listLoading;
  List<Complaint> get complaints => _complaints;
  String? get listError => _listError;

  bool get detailLoading => _detailLoading;
  Complaint? get current => _current;
  String? get detailError => _detailError;

  bool get submitting => _submitting;

  ComplaintProvider(this._api);

  Future<void> load() async {
    _listLoading = true;
    _listError = null;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.customerTickets);
      final list = (res is Map && res.containsKey('tickets'))
          ? res['tickets'] as List
          : (res is List ? res : []);
      _complaints = list
          .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _listError = e.message;
    }
    _listLoading = false;
    notifyListeners();
  }

  Future<void> loadDetail(int id) async {
    _detailLoading = true;
    _detailError = null;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.customerTicketDetail(id));
      final data = (res is Map && res.containsKey('ticket'))
          ? res['ticket'] as Map<String, dynamic>
          : res as Map<String, dynamic>;
      _current = Complaint.fromJson(data);
    } on ApiException catch (e) {
      _detailError = e.message;
    }
    _detailLoading = false;
    notifyListeners();
  }

  Future<bool> create(String subject, String body, String category) async {
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
      await load();
      return true;
    } on ApiException catch (e) {
      _listError = e.message;
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reply(int complaintId, String message) async {
    _submitting = true;
    notifyListeners();
    try {
      await _api.post(ApiConstants.customerTicketMessages(complaintId), {
        'message': message,
      });
      _submitting = false;
      notifyListeners();
      await loadDetail(complaintId);
      return true;
    } on ApiException catch (e) {
      _detailError = e.message;
      _submitting = false;
      notifyListeners();
      return false;
    }
  }
}

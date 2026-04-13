import 'dart:io';

import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/jadwal_model.dart';
import '../models/teknisi_ticket_model.dart';
import '../models/psb_ticket_model.dart';
import '../models/odp_model.dart';
import '../models/infrastruktur_model.dart';
import '../models/map_data_model.dart';

enum LoadState { initial, loading, loaded, error }

class TeknisiProvider extends ChangeNotifier {
  final ApiService _api;

  // Jadwal
  LoadState _jadwalState = LoadState.initial;
  List<JadwalInstallation> _jadwal = [];
  String? _jadwalError;

  // TRB Tickets
  LoadState _ticketState = LoadState.initial;
  List<TeknisiTicket> _tickets = [];
  String? _ticketError;
  Map<String, int> _ticketStats = {
    'total': 0,
    'open': 0,
    'in_progress': 0,
    'resolved': 0,
  };

  // PSB Tickets
  LoadState _psbState = LoadState.initial;
  List<PsbTicket> _psbTickets = [];
  String? _psbError;
  Map<String, int> _psbStats = {
    'total': 0,
    'confirmed': 0,
    'in_progress': 0,
    'done': 0,
  };

  // PSB Ticket Detail
  LoadState _psbDetailState = LoadState.initial;
  PsbTicket? _psbTicketDetail;
  String? _psbDetailError;
  bool _submittingFieldReport = false;
  bool _claimingPsbTicket = false;
  bool _startingPsb = false;
  bool _sendingPsbMessage = false;

  // TRB Ticket Detail
  LoadState _ticketDetailState = LoadState.initial;
  TeknisiTicket? _ticketDetail;
  String? _ticketDetailError;
  bool _claimingTicket = false;
  bool _startingTrb = false;
  bool _submittingTicketFieldReport = false;
  bool _sendingTicketMessage = false;

  // ODP
  LoadState _odpState = LoadState.initial;
  List<OdpData> _odp = [];
  String? _odpError;

  // Infrastruktur
  LoadState _infraState = LoadState.initial;
  List<Infrastruktur> _infrastruktur = [];
  String? _infraError;

  // Map data
  LoadState _mapState = LoadState.initial;
  TekMapData? _mapData;
  String? _mapError;

  // Getters
  LoadState get jadwalState => _jadwalState;
  List<JadwalInstallation> get jadwal => _jadwal;
  String? get jadwalError => _jadwalError;

  LoadState get ticketState => _ticketState;
  List<TeknisiTicket> get tickets => _tickets;
  String? get ticketError => _ticketError;
  Map<String, int> get ticketStats => _ticketStats;

  LoadState get psbState => _psbState;
  List<PsbTicket> get psbTickets => _psbTickets;
  String? get psbError => _psbError;
  Map<String, int> get psbStats => _psbStats;

  LoadState get psbDetailState => _psbDetailState;
  PsbTicket? get psbTicketDetail => _psbTicketDetail;
  String? get psbDetailError => _psbDetailError;
  bool get submittingFieldReport => _submittingFieldReport;
  bool get claimingPsbTicket => _claimingPsbTicket;
  bool get startingPsb => _startingPsb;
  bool get sendingPsbMessage => _sendingPsbMessage;

  LoadState get ticketDetailState => _ticketDetailState;
  TeknisiTicket? get ticketDetail => _ticketDetail;
  String? get ticketDetailError => _ticketDetailError;
  bool get claimingTicket => _claimingTicket;
  bool get startingTrb => _startingTrb;
  bool get submittingTicketFieldReport => _submittingTicketFieldReport;
  bool get sendingTicketMessage => _sendingTicketMessage;

  LoadState get odpState => _odpState;
  List<OdpData> get odp => _odp;
  String? get odpError => _odpError;

  LoadState get infraState => _infraState;
  List<Infrastruktur> get infrastruktur => _infrastruktur;
  String? get infraError => _infraError;

  LoadState get mapState => _mapState;
  TekMapData? get mapData => _mapData;
  String? get mapError => _mapError;

  TeknisiProvider(this._api);

  Future<void> loadJadwal() async {
    _jadwalState = LoadState.loading;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.teknisiJadwal);
      final list = res is List ? res : [];
      _jadwal = list
          .map((e) => JadwalInstallation.fromJson(e as Map<String, dynamic>))
          .toList();
      _jadwalState = LoadState.loaded;
    } on ApiException catch (e) {
      _jadwalError = e.message;
      _jadwalState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadTickets() async {
    _ticketState = LoadState.loading;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.teknisiTickets);
      final list = (res is Map ? res['data'] : res) as List? ?? [];
      _tickets = list
          .map((e) => TeknisiTicket.fromJson(e as Map<String, dynamic>))
          .toList();
      if (res is Map && res['stats'] != null) {
        _ticketStats = Map<String, int>.from(
          (res['stats'] as Map).map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ),
        );
      }
      _ticketState = LoadState.loaded;
    } on ApiException catch (e) {
      _ticketError = e.message;
      _ticketState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadPsbTickets() async {
    _psbState = LoadState.loading;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.teknisiPsbTickets);
      final list = (res is Map ? res['data'] : res) as List? ?? [];
      _psbTickets = list
          .map((e) => PsbTicket.fromJson(e as Map<String, dynamic>))
          .toList();
      if (res is Map && res['stats'] != null) {
        _psbStats = Map<String, int>.from(
          (res['stats'] as Map).map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ),
        );
      }
      _psbState = LoadState.loaded;
    } on ApiException catch (e) {
      _psbError = e.message;
      _psbState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadOdp() async {
    _odpState = LoadState.loading;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.teknisiOdp);
      final list = res is List ? res : [];
      _odp = list
          .map((e) => OdpData.fromJson(e as Map<String, dynamic>))
          .toList();
      _odpState = LoadState.loaded;
    } on ApiException catch (e) {
      _odpError = e.message;
      _odpState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadInfrastruktur() async {
    _infraState = LoadState.loading;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.nocInfrastructureAll);
      final list = res is List ? res : [];
      _infrastruktur = list
          .map((e) => Infrastruktur.fromJson(e as Map<String, dynamic>))
          .toList();
      _infraState = LoadState.loaded;
    } on ApiException catch (e) {
      _infraError = e.message;
      _infraState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadMapData() async {
    _mapState = LoadState.loading;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.teknisiMapData);
      final data = res is Map<String, dynamic> ? res : <String, dynamic>{};
      _mapData = TekMapData.fromJson(data);
      _mapState = LoadState.loaded;
    } on ApiException catch (e) {
      _mapError = e.message;
      _mapState = LoadState.error;
    }
    notifyListeners();
  }

  // ── TRB Ticket Detail ──────────────────────────────────────────────────────

  Future<void> loadTicketDetail(int id) async {
    _ticketDetailState = LoadState.loading;
    _ticketDetailError = null;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.teknisiTicketDetail(id));
      final data = res is Map ? res['data'] ?? res : res;
      _ticketDetail = TeknisiTicket.fromJson(data as Map<String, dynamic>);
      _ticketDetailState = LoadState.loaded;
    } on ApiException catch (e) {
      _ticketDetailError = e.message;
      _ticketDetailState = LoadState.error;
    }
    notifyListeners();
  }

  /// Klaim tiket yang belum di-assign. Returns null on success, error message on failure.
  Future<String?> claimTicket(int id) async {
    _claimingTicket = true;
    notifyListeners();
    try {
      await _api.post(ApiConstants.teknisiTicketClaim(id), {});
      await loadTicketDetail(id);
      await loadTickets();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _claimingTicket = false;
      notifyListeners();
    }
  }

  /// Mulai TRB: set field_status ke on_the_way. Returns true on success, false on failure.
  Future<bool> startTrb(int id) async {
    _startingTrb = true;
    notifyListeners();
    try {
      await _api.post(ApiConstants.teknisiTicketStart(id), {});
      await loadTicketDetail(id);
      return true;
    } on ApiException {
      return false;
    } finally {
      _startingTrb = false;
      notifyListeners();
    }
  }

  /// Kirim laporan lapangan + foto untuk TRB ticket.
  /// Returns null on success, error message on failure.
  Future<String?> submitTicketFieldReport(
    int id, {
    required String fieldStatus,
    required String fieldNotes,
    required File photo,
    String photoType = 'other',
    String? caption,
  }) async {
    _submittingTicketFieldReport = true;
    notifyListeners();
    try {
      final fields = {
        'field_status': fieldStatus,
        'field_notes': fieldNotes,
        'photo_type': photoType,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      };
      await _api.postMultipart(
        ApiConstants.teknisiTicketFieldReport(id),
        fields,
        file: photo,
        fileField: 'photo',
      );
      await loadTicketDetail(id);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _submittingTicketFieldReport = false;
      notifyListeners();
    }
  }

  /// Kirim pesan di thread TRB ticket. Returns null on success, error message on failure.
  Future<String?> sendTicketMessage(int id, String message) async {
    _sendingTicketMessage = true;
    notifyListeners();
    try {
      await _api.post(ApiConstants.teknisiTicketMessages(id), {
        'message': message,
      });
      await loadTicketDetail(id);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _sendingTicketMessage = false;
      notifyListeners();
    }
  }

  // ── PSB Ticket Detail ──────────────────────────────────────────────────────

  Future<void> loadPsbTicketDetail(int id) async {
    _psbDetailState = LoadState.loading;
    _psbDetailError = null;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.teknisiPsbTicketDetail(id));
      _psbTicketDetail = PsbTicket.fromJson(res as Map<String, dynamic>);
      _psbDetailState = LoadState.loaded;
    } on ApiException catch (e) {
      _psbDetailError = e.message;
      _psbDetailState = LoadState.error;
    }
    notifyListeners();
  }

  /// Klaim tiket PSB yang belum di-assign. Returns null on success, error message on failure.
  Future<String?> claimPsbTicket(int id) async {
    _claimingPsbTicket = true;
    notifyListeners();
    try {
      await _api.post(ApiConstants.teknisiPsbTicketClaim(id), {});
      await loadPsbTicketDetail(id);
      await loadPsbTickets();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _claimingPsbTicket = false;
      notifyListeners();
    }
  }

  /// Start PSB: set status to in_progress and field_status to on_the_way.
  /// Returns true on success, false on failure.
  Future<bool> startPsb(int id) async {
    _startingPsb = true;
    notifyListeners();
    try {
      await _api.post(ApiConstants.teknisiPsbTicketStart(id), {});
      // Reload detail to reflect new status
      await loadPsbTicketDetail(id);
      return true;
    } on ApiException {
      return false;
    } finally {
      _startingPsb = false;
      notifyListeners();
    }
  }

  /// Submit field report with photo. Returns null on success, error message on failure.
  Future<String?> submitFieldReport(
    int id, {
    required String fieldStatus,
    required String fieldNotes,
    required File photo,
    String photoType = 'other',
  }) async {
    _submittingFieldReport = true;
    notifyListeners();
    try {
      await _api.postMultipart(
        ApiConstants.teknisiPsbTicketFieldReport(id),
        {
          'field_status': fieldStatus,
          'field_notes': fieldNotes,
          'photo_type': photoType,
        },
        file: photo,
        fileField: 'photo',
      );
      await loadPsbTicketDetail(id);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _submittingFieldReport = false;
      notifyListeners();
    }
  }

  /// Send a thread message. Returns null on success, error message on failure.
  Future<String?> sendPsbMessage(int id, String message) async {
    _sendingPsbMessage = true;
    notifyListeners();
    try {
      await _api.post(ApiConstants.teknisiPsbTicketMessages(id), {
        'message': message,
      });
      await loadPsbTicketDetail(id);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _sendingPsbMessage = false;
      notifyListeners();
    }
  }
}

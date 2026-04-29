import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/billing_model.dart';
import '../models/invoice_model.dart';

class BillingProvider extends ChangeNotifier {
  final ApiService _api;

  bool _billingLoading = false;
  BillingInfo? _activeBilling;
  String? _billingError;

  bool _historyLoading = false;
  List<Invoice> _history = [];
  String? _historyError;

  bool _invoiceLoading = false;
  Invoice? _currentInvoice;
  String? _invoiceError;

  String? _paymentUrlError;

  bool get billingLoading => _billingLoading;
  BillingInfo? get activeBilling => _activeBilling;
  String? get billingError => _billingError;

  bool get historyLoading => _historyLoading;
  List<Invoice> get history => _history;
  String? get historyError => _historyError;

  bool get invoiceLoading => _invoiceLoading;
  Invoice? get currentInvoice => _currentInvoice;
  String? get invoiceError => _invoiceError;

  String? get paymentUrlError => _paymentUrlError;

  BillingProvider(this._api);

  Future<void> loadActiveBilling() async {
    _billingLoading = true;
    _billingError = null;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.customerBilling);
      final map = res is Map<String, dynamic>
          ? res
          : Map<String, dynamic>.from(res as Map);
      _activeBilling = BillingInfo.fromJson(map);
    } catch (e) {
      _billingError = e is ApiException
          ? e.message
          : 'Gagal memuat tagihan. Coba lagi.';
    } finally {
      _billingLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory({String? status}) async {
    _historyLoading = true;
    _historyError = null;
    notifyListeners();
    try {
      final query = (status != null && status.isNotEmpty)
          ? {'status': status}
          : null;
      final res = await _api.get(
        ApiConstants.customerBillingHistory,
        query: query,
      );
      final List rawList;
      if (res is Map && res.containsKey('invoices')) {
        rawList = res['invoices'] as List? ?? [];
      } else if (res is List) {
        rawList = res;
      } else {
        rawList = [];
      }
      _history = rawList
          .map((e) => Invoice.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      _historyError = e is ApiException
          ? e.message
          : 'Gagal memuat riwayat tagihan. Coba lagi.';
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadInvoiceDetail(int id) async {
    _invoiceLoading = true;
    _invoiceError = null;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.customerInvoiceDetail(id));
      final Map<String, dynamic> data;
      if (res is Map && res.containsKey('invoice')) {
        data = Map<String, dynamic>.from(res['invoice'] as Map);
      } else {
        data = Map<String, dynamic>.from(res as Map);
      }
      _currentInvoice = Invoice.fromJson(data);
    } catch (e) {
      _invoiceError = e is ApiException
          ? e.message
          : 'Gagal memuat detail invoice. Coba lagi.';
    } finally {
      _invoiceLoading = false;
      notifyListeners();
    }
  }

  /// Mengembalikan public payment URL (/pay/{token}) untuk dibuka via WebView.
  /// URL ini tidak memerlukan login dan langsung memuat halaman pembayaran Midtrans.
  Future<String?> getPaymentUrl(int invoiceId) async {
    _paymentUrlError = null;
    try {
      // ApiService auto-unwraps { status, data } → returns data map directly
      final res = await _api.get(ApiConstants.customerPaymentUrl(invoiceId));
      if (res is Map) {
        final url = res['payment_url']?.toString();
        if (url != null && url.isNotEmpty) return url;
      }
      return null;
    } catch (e) {
      _paymentUrlError = e is ApiException
          ? e.message
          : 'Gagal mendapatkan link pembayaran';
      notifyListeners();
      return null;
    }
  }
}

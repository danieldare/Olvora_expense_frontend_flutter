import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../data/services/receipt_scan_service.dart';

/// Provider for ReceiptScanService with lazy initialization
/// The service is only created when actually accessed, preventing early native initialization
final receiptScanServiceProvider = Provider<ReceiptScanService>((ref) {
  final apiService = ref.watch(apiServiceV2Provider);
  return ReceiptScanService(apiService);
});

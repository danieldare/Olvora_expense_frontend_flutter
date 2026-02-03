import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../features/receipts/presentation/screens/scan_receipt_screen.dart';
import '../../features/trips/presentation/providers/trip_providers.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/state/auth_state.dart';
import '../navigation/navigator_service.dart';
import '../navigation/app_phase_provider.dart';
import '../widgets/receipt_share_confirmation_modal.dart';
import '../widgets/batch_receipt_modal.dart';
import 'local_notification_service.dart';
import 'receipt_queue_service.dart';

/// Constants for share handler service
class _ShareHandlerConstants {
  // Timing constants
  static const Duration initialCheckDelay = Duration(milliseconds: 500);
  static const Duration navigatorCheckInterval = Duration(milliseconds: 200);
  static const Duration appPhaseCheckInterval = Duration(milliseconds: 200);
  static const Duration maxWaitForAppReady = Duration(seconds: 10);

  // File validation constants
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB per file
  static const int maxBatchFiles = 10; // Max files in a batch
  static const Duration fileOperationTimeout = Duration(seconds: 10);

  // Supported file extensions
  static const List<String> supportedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.heic',
    '.gif',
    '.webp',
  ];

  static const List<String> supportedPdfExtensions = ['.pdf'];

  static List<String> get allSupportedExtensions => [
    ...supportedImageExtensions,
    ...supportedPdfExtensions,
  ];
}

/// Represents a shared file with validation status
class SharedFileItem {
  final String path;
  final SharedFileType type;
  final int? sizeBytes;
  final bool isValid;
  final String? errorMessage;

  SharedFileItem({
    required this.path,
    required this.type,
    this.sizeBytes,
    this.isValid = true,
    this.errorMessage,
  });

  String get fileName => path.split('/').last;

  bool get isImage => _ShareHandlerConstants.supportedImageExtensions.any(
    (ext) => path.toLowerCase().endsWith(ext),
  );

  bool get isPdf => _ShareHandlerConstants.supportedPdfExtensions.any(
    (ext) => path.toLowerCase().endsWith(ext),
  );
}

enum SharedFileType { image, pdf, unknown }

/// Result of batch processing
class BatchProcessingResult {
  final int totalFiles;
  final int successfulFiles;
  final int failedFiles;
  final int queuedFiles;
  final List<String> errors;

  BatchProcessingResult({
    required this.totalFiles,
    required this.successfulFiles,
    required this.failedFiles,
    required this.queuedFiles,
    this.errors = const [],
  });

  bool get hasErrors => failedFiles > 0 || errors.isNotEmpty;
  bool get allSuccessful => successfulFiles == totalFiles;
}

/// Service to handle shared content (images/receipts/PDFs) from other apps
///
/// Features:
/// - Single and multi-image batch processing
/// - PDF receipt support
/// - Offline queue for later processing
/// - Progress tracking for batch operations
class ShareHandlerService {
  static final ShareHandlerService _instance = ShareHandlerService._internal();
  factory ShareHandlerService() => _instance;
  ShareHandlerService._internal();

  StreamSubscription? _mediaStreamSubscription;
  StreamSubscription? _textStreamSubscription;
  bool _isInitialized = false;
  bool _hasCheckedInitialContent = false;
  int _initialContentCheckAttempts = 0;
  final ReceiveSharingIntent _receiveSharingIntent =
      ReceiveSharingIntent.instance;

  // Provider container for accessing Riverpod providers from service
  ProviderContainer? _providerContainer;

  // Track if app was already running when share was received
  bool _appWasRunning = false;

  // Batch processing state
  final StreamController<BatchProcessingProgress> _progressController =
      StreamController<BatchProcessingProgress>.broadcast();

  /// Stream of batch processing progress
  Stream<BatchProcessingProgress> get processingProgress =>
      _progressController.stream;

  /// Set the provider container (called from app initialization)
  void setProviderContainer(ProviderContainer container) {
    _providerContainer = container;
  }

  /// Initialize the share handler service
  void initialize() {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('ℹ️ ShareHandlerService already initialized');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('🚀 Initializing ShareHandlerService...');
    }

    // Listen for shared media (images/PDFs)
    _mediaStreamSubscription = _receiveSharingIntent.getMediaStream().listen(
      (List<SharedMediaFile> sharedFiles) {
        if (kDebugMode) {
          debugPrint(
            '📨 Received ${sharedFiles.length} file(s) via stream (app was running)',
          );
        }
        _appWasRunning = true;
        if (sharedFiles.isNotEmpty) {
          _handleSharedMedia(sharedFiles);
        }
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('❌ Error in share media stream: $error');
        }
      },
    );

    // Check for initial shared content
    Future.delayed(_ShareHandlerConstants.initialCheckDelay, () {
      if (!_hasCheckedInitialContent) {
        _checkInitialSharedContent();
      }
    });

    _checkWhenNavigatorReady();

    // Register so tapping "Receipt Shared - Tap to process" opens scan for queued receipt
    LocalNotificationService().registerShareReceiptHandler(
      () => _handleShareReceiptNotificationTap(),
    );

    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('✅ ShareHandlerService initialized');
    }
  }

  /// Called when user taps the "Receipt Shared - Tap to process" notification.
  /// Processes the next queued receipt by navigating to ScanReceiptScreen.
  Future<void> _handleShareReceiptNotificationTap() async {
    try {
      await ReceiptQueueService().initialize();
      final next = ReceiptQueueService().getNextPending();
      if (next == null) {
        final context = NavigatorService.context;
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No queued receipts to process'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final path = ReceiptQueueService().getFilePath(next);
      if (path == null) {
        await ReceiptQueueService().removeReceipt(next.id);
        if (kDebugMode) {
          debugPrint('⚠️ Queued receipt file missing, removed from queue');
        }
        return;
      }

      final appReady = await waitForAppReady(timeout: const Duration(seconds: 5));
      if (!appReady) {
        if (kDebugMode) {
          debugPrint('⚠️ App not ready for share receipt tap');
        }
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        await ReceiptQueueService().removeReceipt(next.id);
        return;
      }

      if (next.isPdf) {
        // PDFs: show queued message; full PDF flow can be added later
        final context = NavigatorService.context;
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(child: Text('PDF receipt is queued for processing')),
                ],
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      await _navigateToScanReceipt(file, tripId: next.tripId);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error handling share receipt notification tap: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Check for shared content when app is first opened.
  /// If first call returns empty (e.g. on iOS with many share targets), we allow
  /// one retry when the app becomes ready via _checkWhenNavigatorReady.
  Future<void> _checkInitialSharedContent() async {
    if (_hasCheckedInitialContent) {
      if (kDebugMode) {
        debugPrint('ℹ️ Already checked for initial shared content');
      }
      return;
    }

    try {
      _initialContentCheckAttempts++;
      if (kDebugMode) {
        debugPrint(
          '🔍 Checking for initial shared content (attempt $_initialContentCheckAttempts)...',
        );
      }

      final sharedFiles = await _receiveSharingIntent.getInitialMedia();

      if (kDebugMode) {
        debugPrint('📦 Initial shared files count: ${sharedFiles.length}');
        debugPrint('📦 App was running: $_appWasRunning');
      }

      if (sharedFiles.isNotEmpty) {
        _hasCheckedInitialContent = true;
        if (kDebugMode) {
          debugPrint(
            '📦 Found ${sharedFiles.length} shared file(s), waiting for app to be ready...',
          );
        }

        final appReady = await waitForAppReady(
          timeout: _ShareHandlerConstants.maxWaitForAppReady,
        );

        if (appReady) {
          if (kDebugMode) {
            debugPrint(
              '✅ App is ready, handling shared media...',
            );
          }
          await Future.delayed(const Duration(milliseconds: 300));
          // Don't show notifications during initial content check (startup/hot restart)
          // to avoid confusing users with stale notifications
          await _handleSharedMedia(sharedFiles, showNotifications: false);
        } else {
          if (kDebugMode) {
            debugPrint(
              '❌ App not ready after timeout, queueing files for later',
            );
          }
          await _queueFilesForLater(sharedFiles);
          // Don't show notification during initial content check (startup/hot restart)
          // to avoid confusing users with stale notifications
        }

        // CRITICAL: Reset the shared intent after handling to prevent
        // stale data from being returned on hot restart
        _receiveSharingIntent.reset();
        if (kDebugMode) {
          debugPrint('🔄 Shared intent reset after handling');
        }
      } else {
        // Only mark as checked after a retry or we risk infinite retries
        if (_initialContentCheckAttempts >= 2) {
          _hasCheckedInitialContent = true;
        }
        if (kDebugMode) {
          debugPrint('ℹ️ No initial shared content found');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error checking initial shared content: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      _hasCheckedInitialContent = true;
    }
  }

  /// Wait for app to be ready for share handling (Navigator + ProviderContainer).
  /// Does not require AppPhase.running so shared receipts can open sooner.
  Future<bool> waitForAppReady({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // Check if already ready
    if (_isAppReady()) {
      return true;
    }

    final checkInterval = _ShareHandlerConstants.appPhaseCheckInterval;
    final maxRetries = timeout.inMilliseconds ~/ checkInterval.inMilliseconds;
    int retries = 0;

    while (!_isAppReady() && retries < maxRetries) {
      await Future.delayed(checkInterval);
      retries++;
    }

    final isReady = _isAppReady();

    if (kDebugMode) {
      if (isReady) {
        debugPrint(
          '✅ App ready after ${retries * checkInterval.inMilliseconds}ms',
        );
      } else {
        debugPrint('⚠️ App not ready after ${timeout.inSeconds}s');
        debugPrint('   Navigator: ${NavigatorService.isAvailable}');
        debugPrint('   AppPhase: ${_getAppPhase()}');
        debugPrint('   ProviderContainer: ${_providerContainer != null}');
      }
    }

    return isReady;
  }

  /// Check if app is ready for share handling (Navigator + ProviderContainer).
  /// We do not require AppPhase.running so shared receipts can open sooner and
  /// avoid timeout/queue when auth or phase transition is slow.
  bool _isAppReady() {
    if (!NavigatorService.isAvailable) {
      return false;
    }
    if (_providerContainer == null) {
      return false;
    }
    return true;
  }

  /// Get current AppPhase (for debugging)
  AppPhase? _getAppPhase() {
    if (_providerContainer == null) return null;
    try {
      return _providerContainer!.read(appPhaseProvider);
    } catch (e) {
      return null;
    }
  }

  /// Unified helper to wait for Navigator to be ready
  Future<bool> waitForNavigatorReady({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (NavigatorService.isAvailable) {
      return true;
    }

    final checkInterval = _ShareHandlerConstants.navigatorCheckInterval;
    final maxRetries = timeout.inMilliseconds ~/ checkInterval.inMilliseconds;
    int retries = 0;

    while (!NavigatorService.isAvailable && retries < maxRetries) {
      await Future.delayed(checkInterval);
      retries++;
    }

    final isAvailable = NavigatorService.isAvailable;

    if (kDebugMode) {
      if (isAvailable) {
        debugPrint(
          '✅ Navigator available after ${retries * checkInterval.inMilliseconds}ms',
        );
      } else {
        debugPrint('⚠️ Navigator not available after ${timeout.inSeconds}s');
      }
    }

    return isAvailable;
  }

  /// Handle shared media files (images and PDFs)
  ///
  /// [showNotifications] - If false, don't show error notifications (used during
  /// startup/hot restart to avoid showing stale notifications for old intents)
  Future<void> _handleSharedMedia(
    List<SharedMediaFile> sharedFiles, {
    bool showNotifications = true,
  }) async {
    if (sharedFiles.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ Shared files list is empty');
      }
      return;
    }

    try {
      // Validate and categorize all files
      final validatedFiles = await _validateSharedFiles(sharedFiles);
      final validFiles = validatedFiles.where((f) => f.isValid).toList();
      final invalidFiles = validatedFiles.where((f) => !f.isValid).toList();

      if (kDebugMode) {
        debugPrint('📷 Valid files: ${validFiles.length}');
        debugPrint('❌ Invalid files: ${invalidFiles.length}');
        for (final invalid in invalidFiles) {
          debugPrint('   - ${invalid.fileName}: ${invalid.errorMessage}');
        }
      }

      if (validFiles.isEmpty) {
        if (showNotifications) {
          await _showErrorNotification(
            invalidFiles.first.errorMessage ?? 'No valid files to process',
          );
        }
        return;
      }

      // CRITICAL: Wait for app to be fully ready (Navigator + AppPhase + ProviderContainer)
      // This ensures we can safely navigate even if app was backgrounded
      final appReady = await waitForAppReady(
        timeout: const Duration(seconds: 5),
      );

      if (!appReady) {
        if (kDebugMode) {
          debugPrint('⚠️ App not ready, queueing files for later');
        }
        await _queueFilesForLater(sharedFiles);
        if (showNotifications) {
          await _showShareReceivedNotification();
        }
        return;
      }

      // Check authentication
      final isAuthenticated = await _checkAuthentication();
      if (!isAuthenticated) {
        if (kDebugMode) {
          debugPrint('⚠️ User not authenticated - queueing files');
        }
        await _queueFilesForLater(sharedFiles);
        if (showNotifications) {
          await _showErrorNotification(
            'Please sign in to process receipts. Files queued for later.',
          );
        }
        return;
      }

      // Handle based on file count
      if (validFiles.length == 1) {
        // Single file - use existing flow
        await _handleSingleFile(validFiles.first);
      } else {
        // Multiple files - show batch processing modal
        await _handleBatchFiles(validFiles, invalidFiles);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error handling shared media: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      if (showNotifications) {
        await _showErrorNotification(
          'Failed to process shared files. Please try again.',
        );
      }
    }
  }

  /// Validate all shared files
  Future<List<SharedFileItem>> _validateSharedFiles(
    List<SharedMediaFile> sharedFiles,
  ) async {
    final results = <SharedFileItem>[];

    // Limit to max batch size
    final filesToProcess = sharedFiles
        .take(_ShareHandlerConstants.maxBatchFiles)
        .toList();

    for (final sharedFile in filesToProcess) {
      final validationResult = await _validateSharedFile(sharedFile);
      final fileType = _getFileType(sharedFile.path);

      results.add(
        SharedFileItem(
          path: sharedFile.path,
          type: fileType,
          sizeBytes: await _getFileSize(sharedFile.path),
          isValid: validationResult.isValid,
          errorMessage: validationResult.errorMessage,
        ),
      );
    }

    // Warn if files were skipped
    if (sharedFiles.length > _ShareHandlerConstants.maxBatchFiles) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Skipped ${sharedFiles.length - _ShareHandlerConstants.maxBatchFiles} files (max batch size: ${_ShareHandlerConstants.maxBatchFiles})',
        );
      }
    }

    return results;
  }

  /// Get file type from path
  SharedFileType _getFileType(String path) {
    final lowerPath = path.toLowerCase();

    if (_ShareHandlerConstants.supportedImageExtensions.any(
      (ext) => lowerPath.endsWith(ext),
    )) {
      return SharedFileType.image;
    }

    if (_ShareHandlerConstants.supportedPdfExtensions.any(
      (ext) => lowerPath.endsWith(ext),
    )) {
      return SharedFileType.pdf;
    }

    return SharedFileType.unknown;
  }

  /// Get file size safely
  Future<int?> _getFileSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error getting file size: $e');
      }
    }
    return null;
  }

  /// Handle single file (existing flow with modal)
  Future<void> _handleSingleFile(SharedFileItem fileItem) async {
    if (kDebugMode) {
      debugPrint('📷 Processing single file: ${fileItem.fileName}');
    }

    final file = File(fileItem.path);

    // Show confirmation modal
    final shouldProceed = await _showConfirmationModal(file.path);
    if (!shouldProceed) {
      if (kDebugMode) {
        debugPrint('ℹ️ User cancelled receipt processing');
      }
      return;
    }

    // Get active trip ID
    String? tripId;
    try {
      tripId = await _getActiveTripId();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Could not check for active trip: $e');
      }
    }

    // Navigate based on file type
    if (fileItem.isPdf) {
      await _navigateToPdfProcessing(file, tripId: tripId);
    } else {
      await _navigateToScanReceipt(file, tripId: tripId);
    }
  }

  /// Handle batch files with batch modal
  Future<void> _handleBatchFiles(
    List<SharedFileItem> validFiles,
    List<SharedFileItem> invalidFiles,
  ) async {
    if (kDebugMode) {
      debugPrint('📷 Processing batch: ${validFiles.length} files');
    }

    final context = NavigatorService.context;
    if (context == null) {
      if (kDebugMode) {
        debugPrint('⚠️ Cannot show batch modal: context is null');
      }
      return;
    }

    // Ensure we're on the right frame
    await SchedulerBinding.instance.endOfFrame;

    final finalContext = NavigatorService.context;
    if (finalContext == null) return;

    try {
      // Show batch processing modal
      final result = await BatchReceiptModal.show(
        context: finalContext,
        files: validFiles,
        invalidFiles: invalidFiles,
        onProcess: (selectedFiles) => _processBatchFiles(selectedFiles),
      );

      if (result != null) {
        if (kDebugMode) {
          debugPrint('📷 Batch processing result:');
          debugPrint('   Total: ${result.totalFiles}');
          debugPrint('   Successful: ${result.successfulFiles}');
          debugPrint('   Failed: ${result.failedFiles}');
          debugPrint('   Queued: ${result.queuedFiles}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error showing batch modal: $e');
      }
    }
  }

  /// Process batch files
  Future<BatchProcessingResult> _processBatchFiles(
    List<SharedFileItem> files,
  ) async {
    int successful = 0;
    int failed = 0;
    int queued = 0;
    final errors = <String>[];

    // Get active trip ID once
    String? tripId;
    try {
      tripId = await _getActiveTripId();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Could not get active trip: $e');
      }
    }

    // For batch processing, navigate to scan screen for each file sequentially
    // User will process them one by one
    for (int i = 0; i < files.length; i++) {
      final fileItem = files[i];

      // Emit progress
      _progressController.add(
        BatchProcessingProgress(
          currentIndex: i,
          totalFiles: files.length,
          currentFileName: fileItem.fileName,
          status: BatchProcessingStatus.processing,
        ),
      );

      try {
        // Check if we're online
        final isOnline = await _checkConnectivity();

        if (!isOnline) {
          // Queue for later
          await ReceiptQueueService().queueReceipt(
            filePath: fileItem.path,
            tripId: tripId,
            fileType: fileItem.isPdf ? 'pdf' : 'image',
          );
          queued++;
          continue;
        }

        // Navigate to scan screen for this file
        // For batch, we navigate to each file sequentially
        // The user will process them one by one
        final file = File(fileItem.path);

        if (fileItem.isPdf) {
          // PDFs are queued for now (backend processing)
          await ReceiptQueueService().queueReceipt(
            filePath: fileItem.path,
            tripId: tripId,
            fileType: 'pdf',
            priority: QueuePriority.normal,
          );
          queued++;
        } else {
          // Navigate to scan screen for image
          // Only navigate to first file immediately
          // Subsequent files will be processed after user finishes with previous one
          if (i == 0) {
            await _navigateToScanReceipt(file, tripId: tripId);
            successful++;
          } else {
            // Queue remaining files - they'll be processed after user finishes with first
            await ReceiptQueueService().queueReceipt(
              filePath: fileItem.path,
              tripId: tripId,
              fileType: 'image',
              priority: QueuePriority.normal,
            );
            queued++;
          }
        }
      } catch (e) {
        failed++;
        errors.add('Error processing ${fileItem.fileName}: $e');
        if (kDebugMode) {
          debugPrint('❌ Error processing file ${fileItem.fileName}: $e');
        }
      }
    }

    // Emit completion
    _progressController.add(
      BatchProcessingProgress(
        currentIndex: files.length,
        totalFiles: files.length,
        status: BatchProcessingStatus.completed,
      ),
    );

    // Show notification if files were queued
    if (queued > 0 && files.length > 1) {
      final context = NavigatorService.context;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.queue, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    queued == 1
                        ? '1 receipt queued for processing'
                        : '$queued receipts queued for processing',
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    return BatchProcessingResult(
      totalFiles: files.length,
      successfulFiles: successful,
      failedFiles: failed,
      queuedFiles: queued,
      errors: errors,
    );
  }

  /// Navigate to PDF processing screen
  Future<void> _navigateToPdfProcessing(File file, {String? tripId}) async {
    // For now, queue the PDF and show a message
    // PDF processing will be handled by the backend
    try {
      await ReceiptQueueService().queueReceipt(
        filePath: file.path,
        tripId: tripId,
        fileType: 'pdf',
        priority: QueuePriority.high,
      );

      final context = NavigatorService.context;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('PDF queued for processing')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error processing PDF: $e');
      }
    }
  }

  /// Queue files for later processing
  Future<void> _queueFilesForLater(List<SharedMediaFile> sharedFiles) async {
    try {
      for (final file in sharedFiles) {
        final fileType = _getFileType(file.path);
        await ReceiptQueueService().queueReceipt(
          filePath: file.path,
          tripId: await _getActiveTripId(),
          fileType: fileType == SharedFileType.pdf ? 'pdf' : 'image',
          priority: QueuePriority.normal,
        );
      }

      if (kDebugMode) {
        debugPrint('✅ Queued ${sharedFiles.length} files for later processing');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error queueing files: $e');
      }
    }
  }

  /// Check connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Validate shared file (existence, size, extension)
  Future<_FileValidationResult> _validateSharedFile(
    SharedMediaFile sharedFile,
  ) async {
    try {
      final file = File(sharedFile.path);

      // Check file existence with timeout
      final fileExists = await file.exists().timeout(
        _ShareHandlerConstants.fileOperationTimeout,
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⏱️ File existence check timed out');
          }
          return false;
        },
      );

      if (!fileExists) {
        return _FileValidationResult(
          isValid: false,
          errorMessage:
              'The shared file is no longer available. Please try sharing again.',
        );
      }

      // Check file extension
      final extension = _getFileExtension(sharedFile.path);
      if (extension == null ||
          !_ShareHandlerConstants.allSupportedExtensions.contains(
            extension.toLowerCase(),
          )) {
        return _FileValidationResult(
          isValid: false,
          errorMessage:
              'Unsupported file type. Please share a JPEG, PNG, HEIC image, or PDF.',
        );
      }

      // Check file size with timeout
      try {
        final fileSize = await file.length().timeout(
          _ShareHandlerConstants.fileOperationTimeout,
          onTimeout: () {
            if (kDebugMode) {
              debugPrint('⏱️ File size check timed out');
            }
            return _ShareHandlerConstants.maxFileSizeBytes + 1;
          },
        );

        if (fileSize > _ShareHandlerConstants.maxFileSizeBytes) {
          final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
          return _FileValidationResult(
            isValid: false,
            errorMessage:
                'File is too large ($sizeMB MB). Maximum size is 10 MB.',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error checking file size: $e');
        }
      }

      return _FileValidationResult(isValid: true);
    } catch (e) {
      return _FileValidationResult(
        isValid: false,
        errorMessage: 'Failed to validate file: ${e.toString()}',
      );
    }
  }

  /// Get file extension from path
  String? _getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1 || lastDot == path.length - 1) {
      return null;
    }
    return path.substring(lastDot);
  }

  /// Check if auth state is terminal (no longer transitioning)
  bool _isTerminalAuthState(AuthState state) {
    return state is AuthStateAuthenticated ||
        state is AuthStateUnauthenticated ||
        state is AuthStateError ||
        state is AuthStateLoggingOut;
  }

  /// Check if user is authenticated
  ///
  /// Uses a reactive listener to wait for auth to reach a terminal state.
  /// During cold start, auth goes through Initializing → EstablishingSession → Authenticated.
  /// This method efficiently waits for this process to complete using Riverpod's
  /// built-in subscription mechanism instead of polling.
  Future<bool> _checkAuthentication({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_providerContainer == null) {
      return false;
    }

    try {
      // Check current state first - avoid waiting if already terminal
      final currentState = _providerContainer!.read(authNotifierProvider);
      if (_isTerminalAuthState(currentState)) {
        final isAuthenticated = currentState is AuthStateAuthenticated;
        if (kDebugMode) {
          debugPrint(
            isAuthenticated
                ? '✅ Auth check: Already authenticated'
                : '❌ Auth check: Not authenticated (${currentState.runtimeType})',
          );
        }
        return isAuthenticated;
      }

      if (kDebugMode) {
        debugPrint(
          '⏳ Waiting for auth to complete (current: ${currentState.runtimeType})...',
        );
      }

      // Use Completer with listener for reactive, efficient waiting
      final completer = Completer<bool>();

      // Subscribe to auth state changes
      final subscription = _providerContainer!.listen<AuthState>(
        authNotifierProvider,
        (previous, next) {
          if (_isTerminalAuthState(next) && !completer.isCompleted) {
            final isAuthenticated = next is AuthStateAuthenticated;
            if (kDebugMode) {
              debugPrint(
                isAuthenticated
                    ? '✅ Auth check complete: Authenticated'
                    : '❌ Auth check complete: Not authenticated (${next.runtimeType})',
              );
            }
            completer.complete(isAuthenticated);
          }
        },
        fireImmediately: false,
      );

      try {
        // Wait for completion or timeout
        final result = await completer.future.timeout(
          timeout,
          onTimeout: () {
            final finalState = _providerContainer!.read(authNotifierProvider);
            if (kDebugMode) {
              debugPrint(
                '⚠️ Auth check timeout after ${timeout.inSeconds}s (final: ${finalState.runtimeType})',
              );
            }
            return finalState is AuthStateAuthenticated;
          },
        );
        return result;
      } finally {
        // Always clean up the subscription
        subscription.close();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking authentication: $e');
      }
      return false;
    }
  }

  /// Show confirmation modal for receipt processing
  Future<bool> _showConfirmationModal(String imagePath) async {
    final navigatorReady = await waitForNavigatorReady(
      timeout: const Duration(seconds: 5),
    );

    if (!navigatorReady) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Cannot show confirmation modal: Navigator not available after 5s',
        );
      }
      return false;
    }

    final context = NavigatorService.context;
    if (context == null) {
      if (kDebugMode) {
        debugPrint('⚠️ Cannot show confirmation modal: context is null');
      }
      return false;
    }

    await SchedulerBinding.instance.endOfFrame;

    final finalContext = NavigatorService.context;
    if (finalContext == null) {
      if (kDebugMode) {
        debugPrint('⚠️ Context became null after frame');
      }
      return false;
    }

    try {
      if (kDebugMode) {
        debugPrint('📱 Showing confirmation modal for receipt processing...');
        debugPrint('📱 Image path: $imagePath');
      }

      final result = await ReceiptShareConfirmationModal.show(
        context: finalContext,
        imagePath: imagePath,
      );

      if (kDebugMode) {
        debugPrint('📱 Confirmation modal result: $result');
      }

      return result == true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error showing confirmation modal: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Get active trip ID if available
  Future<String?> _getActiveTripId() async {
    if (_providerContainer == null) {
      return null;
    }

    try {
      final activeTripAsync = _providerContainer!.read(activeTripProvider);
      return await activeTripAsync.when(
        data: (trip) => trip?.id,
        loading: () => null,
        error: (_, __) => null,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error getting active trip: $e');
      }
      return null;
    }
  }

  /// Show notification when share is received but app is in background
  Future<void> _showShareReceivedNotification() async {
    try {
      await LocalNotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Receipt Shared',
        body: 'Tap to process the receipt you shared to Olvora',
        payload: 'share_receipt',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to show share notification: $e');
      }
    }
  }

  /// Show error notification
  Future<void> _showErrorNotification(String message) async {
    try {
      await LocalNotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000 + 1,
        title: 'Share Failed',
        body: message,
        payload: null,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to show error notification: $e');
      }
    }
  }

  /// Navigate to scan receipt screen with shared file
  Future<void> _navigateToScanReceipt(File file, {String? tripId}) async {
    try {
      final navigatorReady = await waitForNavigatorReady(
        timeout: const Duration(seconds: 5),
      );

      if (!navigatorReady) {
        if (kDebugMode) {
          debugPrint('❌ Cannot navigate: Navigator not available');
        }
        return;
      }

      final context = NavigatorService.context;
      final navigator = NavigatorService.navigator;

      if (kDebugMode) {
        debugPrint('🧭 Attempting navigation to ScanReceiptScreen...');
        debugPrint('🧭 Context available: ${context != null}');
        debugPrint('🧭 Navigator available: ${navigator != null}');
        if (tripId != null) {
          debugPrint('🧭 Trip ID: $tripId');
        }
      }

      if (context == null || navigator == null) {
        if (kDebugMode) {
          debugPrint('❌ Cannot navigate: context or navigator is null');
        }
        return;
      }

      await SchedulerBinding.instance.endOfFrame;

      if (!NavigatorService.isAvailable) {
        if (kDebugMode) {
          debugPrint('⚠️ Navigator became unavailable after frame');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('✅ Navigating to ScanReceiptScreen with shared file');
      }

      await navigator.push(
        MaterialPageRoute(
          builder: (context) =>
              ScanReceiptScreen.fromSharedFile(file, tripId: tripId),
        ),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error navigating to scan receipt: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Check for shared content when Navigator becomes ready
  Future<void> _checkWhenNavigatorReady() async {
    // Wait for app to be fully ready (not just Navigator)
    final appReady = await waitForAppReady(timeout: const Duration(seconds: 8));

    if (appReady) {
      if (kDebugMode) {
        debugPrint('✅ App is ready, checking for shared content...');
      }

      if (!_hasCheckedInitialContent) {
        await _checkInitialSharedContent();
      }
    } else {
      if (kDebugMode) {
        debugPrint('⚠️ App not ready, will check shared content later');
      }
      // Retry after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (!_hasCheckedInitialContent) {
          _checkInitialSharedContent();
        }
      });
    }
  }

  /// Dispose the service
  void dispose() {
    _mediaStreamSubscription?.cancel();
    _textStreamSubscription?.cancel();
    _mediaStreamSubscription = null;
    _textStreamSubscription = null;
    _isInitialized = false;
    _hasCheckedInitialContent = false;
    _initialContentCheckAttempts = 0;
    _providerContainer = null;
    _progressController.close();
  }
}

/// File validation result
class _FileValidationResult {
  final bool isValid;
  final String? errorMessage;

  _FileValidationResult({required this.isValid, this.errorMessage});
}

/// Batch processing progress
class BatchProcessingProgress {
  final int currentIndex;
  final int totalFiles;
  final String? currentFileName;
  final BatchProcessingStatus status;
  final String? message;

  BatchProcessingProgress({
    required this.currentIndex,
    required this.totalFiles,
    this.currentFileName,
    required this.status,
    this.message,
  });

  double get progress => totalFiles > 0 ? currentIndex / totalFiles : 0;
  bool get isComplete => status == BatchProcessingStatus.completed;
}

enum BatchProcessingStatus { pending, processing, completed, failed }

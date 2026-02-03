import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/category_icon_utils.dart';
import '../../../../core/models/currency.dart';
import '../../domain/models/parsed_receipt.dart';
import '../../data/services/receipt_scan_service.dart';
import '../providers/receipt_providers.dart';
import '../../../expenses/presentation/screens/add_expense_screen.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/presentation/providers/expenses_providers.dart';
import '../../../expenses/presentation/services/intent_routing_service.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../domain/models/raw_receipt_data.dart';

class ScanReceiptScreen extends ConsumerStatefulWidget {
  const ScanReceiptScreen({super.key, this.sharedFile, this.tripId});

  /// Create from a shared file (e.g., from share extension)
  const ScanReceiptScreen.fromSharedFile(File file, {super.key, this.tripId})
    : sharedFile = file;

  final File? sharedFile;
  final String? tripId;

  @override
  ConsumerState<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends ConsumerState<ScanReceiptScreen>
    with TickerProviderStateMixin {
  File? _selectedImage;
  ParsedReceipt? _parsedReceipt;
  bool _isProcessing = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _processingStatus;
  double _processingProgress = 0.0;
  bool _lineItemsExpanded = false;

  final ImagePicker _imagePicker = ImagePicker();
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
        );

    // Pulse animation for processing indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Progress animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController?.forward();

      // If a shared file was provided, process it immediately
      if (widget.sharedFile != null) {
        _handleSharedFile(widget.sharedFile!);
      }
    });
  }

  /// Handle a shared file (from share extension)
  ///
  /// CRITICAL: This follows the same flow as manual image selection:
  /// 1. Validate file exists
  /// 2. Show cropping interface (user can crop the image)
  /// 3. Process the cropped/selected image
  ///
  /// This ensures users can crop shared images before processing, just like
  /// manually selected images.
  Future<void> _handleSharedFile(File sharedFile) async {
    if (!mounted) return;

    try {
      // Validate file exists
      if (!await sharedFile.exists()) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Shared file is no longer available';
          });
        }
        return;
      }

      // CRITICAL: Show cropping interface FIRST, just like manual image selection
      // This allows users to crop the shared image before processing
      final croppedFile = await _cropImageImmediately(sharedFile);

      if (croppedFile != null && mounted) {
        // User cropped the image - use the cropped version
        final croppedImageFile = File(croppedFile.path);
        if (!await croppedImageFile.exists()) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Cropped image file is no longer available';
            });
          }
          return;
        }

        setState(() {
          _selectedImage = croppedImageFile;
          _parsedReceipt = null;
          _errorMessage = null;
        });

        // Process the cropped image
        await _processReceipt();
      } else if (mounted) {
        // User cancelled cropping, but we still have the original image
        // Check if file still exists
        if (await sharedFile.exists()) {
          setState(() {
            _selectedImage = sharedFile;
            _parsedReceipt = null;
            _errorMessage = null;
          });
          // Process the original image (user chose not to crop)
          await _processReceipt();
        } else {
          setState(() {
            _errorMessage = 'Shared file is no longer available';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to process shared image: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _triggerHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  void _triggerSuccessHaptic() {
    HapticFeedback.mediumImpact();
  }

  void _triggerErrorHaptic() {
    HapticFeedback.heavyImpact();
  }

  /// Cleans up error messages to be more user-friendly
  String _cleanErrorMessage(String error) {
    final errorLower = error.toLowerCase();

    // Connection timeout errors
    if (errorLower.contains('timeout') ||
        errorLower.contains('connection took longer')) {
      return 'The request took too long. Please check your internet connection and try again.';
    }

    // Network errors
    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('socket')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    // Server errors
    if (errorLower.contains('500') ||
        errorLower.contains('internal server error')) {
      return 'Server error. Please try again later.';
    }

    // Parse errors
    if (errorLower.contains('parse') ||
        errorLower.contains('failed to parse')) {
      return 'Unable to read the receipt. Please try a clearer image.';
    }

    // Permission errors
    if (errorLower.contains('permission') ||
        errorLower.contains('access denied')) {
      return 'Permission denied. Please check app permissions in Settings.';
    }

    // Generic error - extract meaningful part if possible
    if (errorLower.contains('exception:')) {
      final parts = error.split(':');
      if (parts.length > 1) {
        final message = parts.sublist(1).join(':').trim();
        if (message.isNotEmpty && message.length < 100) {
          return message;
        }
      }
    }

    // If error is too long, provide generic message
    if (error.length > 150) {
      return 'Unable to process receipt. Please try again or use a different image.';
    }

    // Return cleaned error (remove technical prefixes)
    return error
        .replaceAll(RegExp(r'Exception:\s*'), '')
        .replaceAll(RegExp(r'Error:\s*'), '')
        .trim();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!mounted) return;

    _triggerHapticFeedback();

    try {
      // Use pickImage with proper error handling
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        requestFullMetadata: false, // Faster processing
      );

      if (image != null && mounted) {
        try {
          // Validate that the file path exists and is accessible
          final imageFile = File(image.path);

          // Check if file exists
          if (!await imageFile.exists()) {
            throw Exception(
              'Selected image file does not exist or is not accessible',
            );
          }

          // Immediately show cropping interface after image selection
          final croppedFile = await _cropImageImmediately(imageFile);

          if (croppedFile != null && mounted) {
            // Validate cropped file exists
            final croppedImageFile = File(croppedFile.path);
            if (!await croppedImageFile.exists()) {
              throw Exception('Cropped image file does not exist');
            }

            // User cropped the image
            setState(() {
              _selectedImage = croppedImageFile;
              _parsedReceipt = null;
              _errorMessage = null;
            });
            // Process the cropped image
            await _processReceipt();
          } else if (mounted) {
            // User cancelled cropping, but we still have the original image
            // Double-check file still exists
            if (await imageFile.exists()) {
              setState(() {
                _selectedImage = imageFile;
                _parsedReceipt = null;
                _errorMessage = null;
              });
              await _processReceipt();
            } else {
              throw Exception('Image file is no longer accessible');
            }
          }
        } catch (fileError) {
          debugPrint('File handling error: $fileError');
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to access image file. Please try again.';
            });
            _triggerErrorHaptic();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to access image: ${fileError.toString()}',
                ),
                backgroundColor: AppTheme.errorColor,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } else if (image == null && mounted) {
        // User cancelled - no error needed
        return;
      }
    } on PlatformException catch (e) {
      // Handle platform-specific exceptions with detailed error messages
      String errorMessage = 'Failed to pick image';
      final String errorCode = e.code;
      final String? errorDetails = e.message;

      debugPrint(
        'ImagePicker PlatformException: code=$errorCode, message=$errorDetails',
      );

      if (errorCode == 'camera_access_denied' ||
          errorCode == 'photo_access_denied' ||
          errorCode == 'permission_denied') {
        errorMessage =
            'Camera/Gallery access denied. Please enable permissions in Settings > Privacy & Security > Camera/Photos.';
      } else if (errorCode == 'camera_unavailable' ||
          errorCode == 'camera_error' ||
          errorCode == 'camera_access_restricted') {
        errorMessage =
            'Camera is not available on this device. Please use gallery instead.';
      } else if (errorCode == 'photo_library_access_denied') {
        errorMessage =
            'Photo library access denied. Please enable permissions in Settings > Privacy & Security > Photos.';
      } else if (errorDetails != null && errorDetails.isNotEmpty) {
        errorMessage = errorDetails;
      } else if (errorCode.isNotEmpty) {
        errorMessage = 'Error: $errorCode';
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
        });
        _triggerErrorHaptic();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () {
                // Open app settings (would need permission_handler package)
                // For now, just dismiss
              },
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Log the full error for debugging
      debugPrint('ImagePicker Error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        String errorMsg;
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('camera') ||
            errorString.contains('permission') ||
            errorString.contains('access')) {
          errorMsg =
              'Camera/Gallery access issue. Please check app permissions in Settings.';
        } else if (errorString.contains('timeout')) {
          errorMsg = 'Operation timed out. Please try again.';
        } else {
          errorMsg = 'Failed to pick image. Please try again.';
        }

        setState(() {
          _errorMessage = errorMsg;
        });
        _triggerErrorHaptic();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _processReceipt() async {
    if (_selectedImage == null) return;

    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _processingStatus = 'Scanning receipt...';
      _processingProgress = 0.0;
    });

    _progressController.forward();
    _pulseController.repeat();

    // Simulate progress updates with smooth transitions
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _isProcessing) {
        setState(() {
          _processingStatus = 'Extracting text...';
          _processingProgress = 0.3;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _isProcessing) {
        setState(() {
          _processingStatus = 'Analyzing data...';
          _processingProgress = 0.6;
        });
      }
    });

    try {
      ReceiptScanService? scanService;
      try {
        scanService = ref.read(receiptScanServiceProvider);
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to initialize scan service: $e';
            _isProcessing = false;
            _processingStatus = null;
            _processingProgress = 0.0;
          });
        }
        _triggerErrorHaptic();
        _progressController.reset();
        _pulseController.stop();
        return;
      }

      if (scanService == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Scan service is not available';
            _isProcessing = false;
            _processingStatus = null;
            _processingProgress = 0.0;
          });
        }
        _triggerErrorHaptic();
        _progressController.reset();
        _pulseController.stop();
        return;
      }

      // Sensor-style flow: Extract raw text with bounding boxes
      debugPrint('🔍 [Receipt Scan] Starting sensor-style receipt scan...');

      // Step 1: Extract raw text with bounding boxes using ML Kit
      final mlKitOCR = scanService.getMLKitOCR();
      RawReceiptData? rawReceiptData;

      if (mlKitOCR != null) {
        try {
          if (mounted && _isProcessing) {
            setState(() {
              _processingStatus = 'Extracting text with coordinates...';
              _processingProgress = 0.3;
            });
          }

          rawReceiptData = await mlKitOCR.extractRawTextWithBoundingBoxes(
            _selectedImage!,
          );

          if (rawReceiptData != null && rawReceiptData.blocks.isNotEmpty) {
            debugPrint(
              '✅ [Receipt Scan] Extracted ${rawReceiptData.blocks.length} text blocks with bounding boxes',
            );

            // Step 2: Send to backend for parsing
            if (mounted && _isProcessing) {
              setState(() {
                _processingStatus = 'Processing receipt...';
                _processingProgress = 0.5;
              });
            }

            try {
              final parseService = scanService.parseService;
              final parsedReceipt = await parseService.parseFromRawData(
                rawReceiptData,
              );

              // Success - backend parsed the receipt
              _triggerSuccessHaptic();
              _progressController.forward();
              _pulseController.stop();

              await Future.delayed(const Duration(milliseconds: 300));

              if (mounted) {
                setState(() {
                  _parsedReceipt = parsedReceipt;
                  _isProcessing = false;
                  _processingStatus = null;
                  _processingProgress = 1.0;
                });
              }

              debugPrint(
                '✅ [Receipt Scan] SUCCESS: Sensor-style (ML Kit + Backend parsing)',
              );
              return;
            } catch (e) {
              // Backend parsing failed or timed out - fallback to existing flow
              debugPrint(
                '⚠️ [Receipt Scan] Backend parsing failed, falling back to existing flow: $e',
              );
              if (mounted && _isProcessing) {
                setState(() {
                  _processingStatus = 'Trying alternative method...';
                  _processingProgress = 0.6;
                });
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ [Receipt Scan] ML Kit extraction failed: $e');
          // Fall through to existing flow
        }
      }

      // Fallback: Use existing hybrid scan flow
      debugPrint('🔄 [Receipt Scan] Falling back to existing scan flow...');
      var result = await scanService.scanReceipt(_selectedImage!);

      // If fast scan fails, automatically retry with server-side processing
      if (result.hasError) {
        debugPrint(
          '⚠️ [Receipt Scan] Initial scan failed, retrying with server-side only...',
        );
        if (mounted && _isProcessing) {
          setState(() {
            _processingStatus = 'Trying alternative method...';
            _processingProgress = 0.7;
          });
        }

        // Automatically retry with server-side processing
        result = await scanService.scanReceiptServerSide(_selectedImage!);
      }

      // Log final result
      if (result.hasReceipt && result.receipt != null) {
        final method = result.method == ScanMethod.clientSide
            ? 'Client-side (ML Kit)'
            : result.method == ScanMethod.serverSide
            ? 'Server-side (Backend)'
            : 'Unknown';
        debugPrint(
          '✅ [Receipt Scan] Final result: SUCCESS using $method (fallback)',
        );
      } else {
        debugPrint(
          '❌ [Receipt Scan] Final result: FAILED - ${result.error ?? "Unknown error"}',
        );
      }

      if (result.hasError) {
        _triggerErrorHaptic();
        _progressController.reset();
        _pulseController.stop();
        if (mounted) {
          setState(() {
            _errorMessage = _cleanErrorMessage(result.error ?? 'Unknown error');
            _isProcessing = false;
            _processingStatus = null;
            _processingProgress = 0.0;
          });
        }
        return;
      }

      if (!result.hasReceipt || result.receipt == null) {
        _triggerErrorHaptic();
        _progressController.reset();
        _pulseController.stop();
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to parse receipt data';
            _isProcessing = false;
            _processingStatus = null;
            _processingProgress = 0.0;
          });
        }
        return;
      }

      _triggerSuccessHaptic();
      _progressController.forward();
      _pulseController.stop();

      // Small delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _parsedReceipt = result.receipt;
          _isProcessing = false;
          _processingStatus = null;
          _processingProgress = 1.0;
        });
      }
    } catch (e) {
      _triggerErrorHaptic();
      _progressController.reset();
      _pulseController.stop();
      setState(() {
        _errorMessage = _cleanErrorMessage(e.toString());
        _isProcessing = false;
        _processingStatus = null;
        _processingProgress = 0.0;
      });
    }
  }

  Future<void> _navigateToAddExpense() async {
    if (_parsedReceipt == null) return;

    _triggerSuccessHaptic();

    // Get raw text for intent classification
    final rawText = _parsedReceipt!.rawText ?? '';

    // If no raw text, fallback to direct navigation
    if (rawText.isEmpty) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              AddExpenseScreen(
                preFilledData: _parsedReceipt!,
                entryMode: EntryMode.scan,
                tripId: widget.tripId,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.0, 0.1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
      return;
    }

    // Show loading indicator
    if (mounted) {
      setState(() {
        _isProcessing = true;
        _processingStatus = 'Classifying intent...';
      });
    }

    try {
      // Use intent routing service to classify and route
      final routingService = ref.read(intentRoutingServiceProvider);
      final routed = await routingService.classifyAndRoute(
        context: context,
        text: rawText,
        source: 'receipt',
        parsedReceipt: _parsedReceipt,
        entryMode: EntryMode.scan,
      );

      if (!routed && mounted) {
        // If routing failed, fallback to expense screen with animation
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                AddExpenseScreen(
                  preFilledData: _parsedReceipt!,
                  entryMode: EntryMode.scan,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0.0, 0.1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } catch (e) {
      // On error, fallback to expense screen
      if (mounted) {
        debugPrint('Intent routing failed: $e');
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                AddExpenseScreen(
                  preFilledData: _parsedReceipt!,
                  entryMode: EntryMode.scan,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0.0, 0.1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStatus = null;
        });
      }
    }
  }

  void _navigateToEditExpense() {
    if (_parsedReceipt == null) return;

    _triggerHapticFeedback();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddExpenseScreen(
              preFilledData: _parsedReceipt!,
              entryMode: EntryMode.scan,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  ExpenseCategory _mapCategoryToExpenseCategory(CategoryModel category) {
    final categoryName = category.name.toLowerCase();
    if (categoryName.contains('food')) return ExpenseCategory.food;
    if (categoryName.contains('transport')) return ExpenseCategory.transport;
    if (categoryName.contains('entertainment')) {
      return ExpenseCategory.entertainment;
    }
    if (categoryName.contains('shopping')) return ExpenseCategory.shopping;
    if (categoryName.contains('bill')) return ExpenseCategory.bills;
    if (categoryName.contains('health')) return ExpenseCategory.health;
    if (categoryName.contains('education')) return ExpenseCategory.education;
    if (categoryName.contains('debit')) return ExpenseCategory.debit;
    return ExpenseCategory.other;
  }

  CategoryModel? _matchCategoryFromReceipt(
    String suggestedCategory,
    List<CategoryModel> categories,
  ) {
    final lowerSuggested = suggestedCategory.toLowerCase();

    // Try to find matching category
    CategoryModel? matchedCategory;

    for (final category in categories) {
      final categoryName = category.name.toLowerCase();
      if (categoryName.contains(lowerSuggested) ||
          lowerSuggested.contains(categoryName)) {
        matchedCategory = category;
        break;
      }
    }

    // If no exact match, try common mappings
    if (matchedCategory == null) {
      final categoryMappings = {
        'food': ['food', 'restaurant', 'grocery', 'dining'],
        'transport': ['transport', 'car', 'travel', 'taxi', 'uber'],
        'shopping': ['shopping', 'store', 'retail'],
        'bills': ['bill', 'utility', 'electricity', 'water'],
        'health': ['health', 'medical', 'pharmacy', 'hospital'],
        'entertainment': ['entertainment', 'movie', 'game', 'cinema'],
        'education': ['education', 'school', 'book', 'course'],
      };

      for (final entry in categoryMappings.entries) {
        if (entry.value.any((keyword) => lowerSuggested.contains(keyword))) {
          matchedCategory = categories.firstWhere(
            (cat) => cat.name.toLowerCase().contains(entry.key),
            orElse: () => categories.first,
          );
          break;
        }
      }
    }

    return matchedCategory ?? categories.first;
  }

  Future<void> _showSaveConfirmation() async {
    if (_parsedReceipt == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
        title: Text(
          'Save Expense?',
          style: AppFonts.textStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'This will save the expense directly to your account. You can edit it later if needed.',
          style: AppFonts.textStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppFonts.textStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save',
              style: AppFonts.textStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _saveExpenseDirectly();
    }
  }

  Future<void> _saveExpenseDirectly() async {
    if (_parsedReceipt == null) return;

    // Validate required fields
    if (_parsedReceipt!.totalAmount == null ||
        _parsedReceipt!.totalAmount! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid receipt amount'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final apiService = ref.read(apiServiceV2Provider);

      // Wait for categories to load (handles loading state automatically)
      final categories = await ref.read(categoriesProvider.future);

      if (categories.isEmpty) {
        throw Exception('No categories available');
      }

      // Match category from suggested category or use first category
      CategoryModel selectedCategory;
      if (_parsedReceipt!.suggestedCategory != null) {
        selectedCategory =
            _matchCategoryFromReceipt(
              _parsedReceipt!.suggestedCategory!,
              categories,
            ) ??
            categories.first;
      } else {
        selectedCategory = categories.first;
      }

      final expenseCategory = _mapCategoryToExpenseCategory(selectedCategory);

      // Prepare line items for backend
      List<Map<String, dynamic>>? lineItemsData;
      // Use line items if available
      if (_parsedReceipt!.lineItems != null &&
          _parsedReceipt!.lineItems!.isNotEmpty) {
        lineItemsData = _parsedReceipt!.lineItems!
            .map(
              (item) => {
                'description': item.description,
                'amount': item.amount,
                if (item.quantity != null) 'quantity': item.quantity,
              },
            )
            .toList();
      }

      // Calculate total amount (use line items total if available, otherwise use main amount)
      double totalAmount = _parsedReceipt!.totalAmount!;
      // Calculate from line items if available
      if (_parsedReceipt!.lineItems != null &&
          _parsedReceipt!.lineItems!.isNotEmpty) {
        totalAmount = _parsedReceipt!.lineItems!.fold<double>(
          0.0,
          (sum, item) => sum + (item.amount * (item.quantity ?? 1)),
        );
      }

      // Build description with extra information if available
      // Note: We don't include rawText in description because it contains all receipt content.
      // The description should only contain structured extra information, not the entire OCR text.
      final extraInfoParts = <String>[];
      if (_parsedReceipt!.address != null &&
          _parsedReceipt!.address!.isNotEmpty) {
        extraInfoParts.add('Address: ${_parsedReceipt!.address!}');
      }
      if (_parsedReceipt!.receiptNumber != null &&
          _parsedReceipt!.receiptNumber!.isNotEmpty) {
        extraInfoParts.add('Receipt #: ${_parsedReceipt!.receiptNumber!}');
      }
      if (_parsedReceipt!.telephone != null &&
          _parsedReceipt!.telephone!.isNotEmpty) {
        extraInfoParts.add('Tel: ${_parsedReceipt!.telephone!}');
      }

      // Only include extra information in description, not rawText
      String? description;
      if (extraInfoParts.isNotEmpty) {
        description = extraInfoParts.join(' • ');
      }

      // Determine currency: use detected currency from receipt if available,
      // otherwise use user preference currency
      String currencyCode;
      if (_parsedReceipt!.currency != null &&
          _parsedReceipt!.currency!.isNotEmpty) {
        currencyCode = _parsedReceipt!.currency!;
      } else {
        // Get user preference currency
        try {
          final selectedCurrencyAsync = ref.read(selectedCurrencyProvider);
          currencyCode =
              selectedCurrencyAsync.valueOrNull?.code ??
              Currency.defaultCurrency.code;
        } catch (e) {
          currencyCode = Currency.defaultCurrency.code;
        }
      }

      final expenseData = {
        'title': _parsedReceipt!.merchant ?? selectedCategory.name,
        'amount': totalAmount,
        'category': expenseCategory.name.toLowerCase(),
        'date': (_parsedReceipt!.date ?? DateTime.now())
            .toIso8601String()
            .split('T')[0],
        'entryMode': EntryMode.scan.name,
        'currency': currencyCode, // Use detected currency or user preference
        if (description != null && description.isNotEmpty)
          'description': description,
        if (_parsedReceipt!.merchant != null)
          'merchant': _parsedReceipt!.merchant,
        if (lineItemsData != null && lineItemsData.isNotEmpty)
          'lineItems': lineItemsData,
      };

      await apiService.dio.post('/expenses', data: expenseData);

      // Invalidate expenses providers to refresh the lists
      ref.invalidate(expensesProvider);
      ref.invalidate(recentTransactionsProvider);

      if (mounted) {
        _triggerSuccessHaptic();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Expense saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.screenBackgroundColor;

    // Safely access currency provider
    Currency currency;
    try {
      final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
      currency = selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;
    } catch (e) {
      currency = Currency.defaultCurrency;
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(),
        title: Text(
          'Scan Receipt',
          style: AppFonts.textStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          // Edit button - only show when receipt is parsed
          if (_parsedReceipt != null && !_isProcessing)
            IconButton(
              icon: Icon(Icons.edit_rounded, color: AppTheme.textPrimary),
              onPressed: _navigateToEditExpense,
              tooltip: 'Edit Receipt',
            ),
        ],
      ),
      body:
          _animationController == null ||
              _fadeAnimation == null ||
              _slideAnimation == null
          ? const SizedBox.shrink()
          : AnimatedBuilder(
              animation: _animationController!,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation!,
                  child: SlideTransition(
                    position: _slideAnimation!,
                    child: Stack(
                      children: [
                        // Full screen image or empty state
                        if (_selectedImage != null)
                          _buildFullScreenImage(isDark)
                        else
                          _buildEmptyState(isDark),

                        // Processing overlay
                        if (_isProcessing) _buildProcessingOverlay(isDark),

                        // Bottom sheet for results/actions
                        if (_parsedReceipt != null && !_isProcessing)
                          _buildResultsBottomSheet(currency, isDark),

                        // Error bottom sheet
                        if (_errorMessage != null && !_isProcessing)
                          _buildErrorBottomSheet(isDark),

                        // Floating action buttons
                        if (_selectedImage == null && !_isProcessing)
                          _buildFloatingActions(isDark),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 64,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 48),
              Text(
                'Scan Receipt',
                style: AppFonts.textStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -1.2,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Capture or select a receipt\nto extract expense details',
                textAlign: TextAlign.center,
                style: AppFonts.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenImage(bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'receipt-image',
          child: Image.file(_selectedImage!, fit: BoxFit.cover),
        ),
        // Gradient overlay at top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 200,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Crop image immediately after selection (before processing)
  Future<CroppedFile?> _cropImageImmediately(File imageFile) async {
    if (!mounted) return null;

    try {
      // Validate file exists before cropping
      if (!await imageFile.exists()) {
        debugPrint('Image file does not exist: ${imageFile.path}');
        return null;
      }

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Receipt',
            toolbarColor: AppTheme.primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: AppTheme.primaryColor,
            dimmedLayerColor: Colors.black.withValues(alpha: 0.8),
            cropFrameColor: AppTheme.primaryColor,
            cropGridColor: AppTheme.primaryColor.withValues(alpha: 0.5),
            cropFrameStrokeWidth: 3,
            cropGridStrokeWidth: 1,
            showCropGrid: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Receipt',
            resetAspectRatioEnabled: true,
            aspectRatioLockEnabled: false,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioPickerButtonHidden: false,
            resetButtonHidden: false,
          ),
        ],
      );

      return croppedFile;
    } on PlatformException catch (e) {
      debugPrint(
        'PlatformException while cropping image: ${e.code} - ${e.message}',
      );
      if (mounted) {
        // Don't show error if user cancelled
        if (e.code != 'crop_cancelled') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to crop image: ${e.message ?? e.code}'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error cropping image: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to crop image. Please try again.'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return null;
    }
  }

  Widget _buildFloatingActions(bool isDark) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFloatingActionButton(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                onTap: () => _pickImage(ImageSource.camera),
                isDark: isDark,
              ),
              SizedBox(width: 16),
              _buildFloatingActionButton(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: () => _pickImage(ImageSource.gallery),
                isDark: isDark,
                isSecondary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isSecondary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            gradient: isSecondary
                ? null
                : LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
            color: isSecondary
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05))
                : null,
            borderRadius: BorderRadius.circular(20),
            border: isSecondary
                ? Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: isSecondary
                    ? Colors.black.withValues(alpha: 0.1)
                    : AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSecondary ? AppTheme.textPrimary : Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: AppFonts.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSecondary ? AppTheme.textPrimary : Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  )
                : null,
            color: isPrimary ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isPrimary
                ? null
                : Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary ? Colors.white : AppTheme.primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: AppFonts.textStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? Colors.white : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay(bool isDark) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.accentColor,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 3,
                                value: _processingProgress > 0
                                    ? _processingProgress
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _processingStatus ?? 'Processing receipt...',
                    key: ValueKey(_processingStatus),
                    style: AppFonts.textStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please wait...',
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _processingProgress > 0
                            ? _processingProgress
                            : _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.accentColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsBottomSheet(Currency currency, bool isDark) {
    final r = _parsedReceipt!;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final secondaryColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.textSecondary;
    double subtotal = 0.0;
    if (r.lineItems != null && r.lineItems!.isNotEmpty) {
      subtotal = r.lineItems!.fold<double>(
        0.0,
        (sum, item) => sum + (item.amount * (item.quantity ?? 1)),
      );
    } else {
      subtotal = (r.totalAmount ?? 0.0) - (r.tax ?? 0.0);
    }
    final tax = r.tax ?? 0.0;
    final total = r.totalAmount ?? 0.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.modalBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(AppSpacing.screenHorizontal),
                  children: [
                    // Receipt Scanned header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.successColor,
                                AppTheme.successColor.withValues(alpha: 0.8),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Receipt Scanned',
                                softWrap: true,
                                style: AppFonts.textStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Information extracted successfully',
                                softWrap: true,
                                style: AppFonts.textStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Receipt-style card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF111827),
                                  const Color(0xFF1E293B),
                                ]
                              : [Colors.white, const Color(0xFFF9FAFB)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : AppTheme.borderColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (r.merchant != null && r.merchant!.isNotEmpty) ...[
                            _buildReceiptRow('Merchant', r.merchant!, isDark),
                            _buildReceiptDivider(isDark),
                          ],
                          if (r.suggestedCategory != null &&
                              r.suggestedCategory!.isNotEmpty) ...[
                            _buildReceiptRowWithIcon(
                              'Category',
                              r.suggestedCategory!,
                              CategoryIconUtils.getCategoryIconFromName(
                                r.suggestedCategory!,
                              ),
                              isDark,
                            ),
                            _buildReceiptDivider(isDark),
                          ],
                          if (r.date != null) ...[
                            _buildReceiptRow(
                              'Date',
                              DateFormat('MMM d, y • h:mm a').format(r.date!),
                              isDark,
                            ),
                            _buildReceiptDivider(isDark),
                          ],
                          if (r.receiptNumber != null &&
                              r.receiptNumber!.isNotEmpty) ...[
                            _buildReceiptRow(
                              'Receipt No',
                              r.receiptNumber!,
                              isDark,
                            ),
                            _buildReceiptDivider(isDark),
                          ],
                          if (r.description != null &&
                              r.description!.isNotEmpty) ...[
                            _buildReceiptRow('Note', r.description!, isDark),
                            _buildReceiptDivider(isDark),
                          ],
                          if (r.address != null && r.address!.isNotEmpty) ...[
                            _buildReceiptRow('Address', r.address!, isDark),
                            _buildReceiptDivider(isDark),
                          ],
                          if (r.telephone != null &&
                              r.telephone!.isNotEmpty) ...[
                            _buildReceiptRow('Tel', r.telephone!, isDark),
                            _buildReceiptDivider(isDark),
                          ],
                          if (r.lineItems != null &&
                              r.lineItems!.isNotEmpty) ...[
                            SizedBox(height: 12),
                            Text(
                              'ITEMS',
                              style: AppFonts.textStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: secondaryColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 8),
                            _buildReceiptLineItems(
                              r.lineItems!,
                              currency,
                              isDark,
                              textColor,
                              secondaryColor,
                              maxVisible: 5,
                              isExpanded: _lineItemsExpanded,
                              onToggle: () {
                                setState(() {
                                  _lineItemsExpanded = !_lineItemsExpanded;
                                });
                              },
                            ),
                            SizedBox(height: 12),
                          ],
                          if (tax > 0) ...[
                            _buildReceiptRow(
                              'Subtotal',
                              CurrencyFormatter.format(subtotal, currency),
                              isDark,
                            ),
                            _buildReceiptDivider(isDark),
                            _buildReceiptRow(
                              'Tax',
                              CurrencyFormatter.format(tax, currency),
                              isDark,
                            ),
                            _buildReceiptDivider(isDark),
                          ],
                          _buildReceiptDivider(isDark),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL',
                                style: AppFonts.textStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: secondaryColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(total, currency),
                                style: AppFonts.textStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_selectedImage != null) ...[
                            Material(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                onTap: () async {
                                  _triggerHapticFeedback();
                                  setState(() {
                                    _parsedReceipt = null;
                                    _errorMessage = null;
                                    _selectedImage = null;
                                  });
                                  await _pickImage(ImageSource.camera);
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: SizedBox(
                                  width: 56,
                                  child: Center(
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      size: 24,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                          ],
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.accentColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isSaving ? null : _showSaveConfirmation,
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isSaving)
                                        LoadingSpinnerVariants.white(
                                          size: 20,
                                          strokeWidth: 2,
                                        )
                                      else
                                        Icon(
                                          Icons.check_rounded,
                                          size: 22,
                                          color: Colors.white,
                                        ),
                                      SizedBox(width: 12),
                                      Text(
                                        _isSaving
                                            ? 'Saving...'
                                            : 'Use This Receipt',
                                        style: AppFonts.textStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBottomSheet(bool isDark) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.modalBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(AppSpacing.screenHorizontal),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 32,
                          color: AppTheme.errorColor,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Scan Failed',
                        style: AppFonts.textStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _errorMessage ?? 'Unknown error occurred',
                          textAlign: TextAlign.center,
                          style: AppFonts.textStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            _triggerHapticFeedback();
                            setState(() {
                              _errorMessage = null;
                            });
                            await _processReceipt();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Try Again',
                                style: AppFonts.textStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLineItemsSection(Currency currency, bool isDark) {
    if (_parsedReceipt!.lineItems == null ||
        _parsedReceipt!.lineItems!.isEmpty) {
      return const SizedBox.shrink();
    }

    final lineItems = _parsedReceipt!.lineItems!;
    final cardColor = AppTheme.cardBackground;
    // Show all items when section is expanded (no internal limit)
    final itemsToShow = lineItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // Left side - Items Purchased
              Expanded(
                child: Text(
                  'Items Purchased',
                  softWrap: true,
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              // Right side - Amount (aligned with the amount column)
              SizedBox(
                width: 100, // Match the approximate width of the amount column
                child: Text(
                  'Amount',
                  textAlign: TextAlign.right,
                  softWrap: true,
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Column(
          children: [
            ...itemsToShow.asMap().entries.map((entry) {
              final displayIndex = entry.key;
              final item = entry.value;
              final isLast = displayIndex == itemsToShow.length - 1;
              return _buildReceiptLineItemRow(
                item,
                currency,
                isDark,
                cardColor,
                displayIndex,
                isLast,
              );
            }),
            // Subtotal row
            if (itemsToShow.isNotEmpty) ...[
              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.borderColor.withValues(alpha: 0.25),
                indent: 16,
                endIndent: 16,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: AppFonts.textStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(
                        lineItems.fold<double>(
                          0.0,
                          (sum, item) =>
                              sum + (item.amount * (item.quantity ?? 1)),
                        ),
                        currency,
                      ),
                      textAlign: TextAlign.right,
                      style: AppFonts.textStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildReceiptLineItemRow(
    LineItem item,
    Currency currency,
    bool isDark,
    Color cardColor,
    int index,
    bool isLast,
  ) {
    final totalAmount = item.amount * (item.quantity ?? 1);
    final unitPrice = item.amount;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      softWrap: true,
                      style: AppFonts.textStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    // Quantity and unit price
                    if (item.quantity != null && item.quantity! > 1)
                      Text(
                        '${item.quantity}x ${CurrencyFormatter.format(unitPrice, currency)}',
                        softWrap: true,
                        style: AppFonts.textStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      )
                    else
                      Text(
                        CurrencyFormatter.format(unitPrice, currency),
                        softWrap: true,
                        style: AppFonts.textStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              // Total amount - aligned to extreme right
              Text(
                CurrencyFormatter.format(totalAmount, currency),
                textAlign: TextAlign.right,
                softWrap: true,
                style: AppFonts.textStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.borderColor.withValues(alpha: 0.25),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }

  Widget _buildAmountBreakdown(Currency currency, bool isDark) {
    // Calculate subtotal from line items if available, otherwise use total - tax
    double subtotal = 0.0;
    if (_parsedReceipt!.lineItems != null &&
        _parsedReceipt!.lineItems!.isNotEmpty) {
      subtotal = _parsedReceipt!.lineItems!.fold<double>(
        0.0,
        (sum, item) => sum + (item.amount * (item.quantity ?? 1)),
      );
    } else {
      // If no line items, calculate subtotal as total - tax
      final tax = _parsedReceipt!.tax ?? 0.0;
      final total = _parsedReceipt!.totalAmount ?? 0.0;
      subtotal = total - tax;
    }

    // Get tax if available
    final tax = _parsedReceipt!.tax ?? 0.0;

    // Get main total from receipt
    final mainTotal = _parsedReceipt!.totalAmount ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Enhanced contrast: increased from 0.08 to 0.25-0.35
        color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(
            alpha: 0.3,
          ), // Increased from 0.15
          width: 1,
        ),
        // Add subtle shadow for depth
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                CurrencyFormatter.format(subtotal, currency),
                textAlign: TextAlign.right,
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          // Tax (if available)
          if (tax > 0) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tax',
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(tax, currency),
                  textAlign: TextAlign.right,
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
          // Divider
          SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.borderColor.withValues(alpha: 0.25),
          ),
          SizedBox(height: 12),
          // Total (main total in yellow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppFonts.textStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppTheme.textPrimary,
                ),
              ),
              Text(
                CurrencyFormatter.format(mainTotal, currency),
                textAlign: TextAlign.right,
                style: AppFonts.textStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.warningColor.withValues(
                    alpha: 0.95,
                  ), // Yellow for total
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required bool isDark,
    required List<Widget> children,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header - always visible
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: AppTheme.primaryColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: AppFonts.textStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (onToggle != null)
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 24,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Content - collapsible
          if (isExpanded || onToggle == null) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              indent: 16,
              endIndent: 16,
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionRow(String description, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Enhanced contrast: increased from 0.08 to 0.25-0.35
        color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(
            alpha: 0.3,
          ), // Increased from 0.15
          width: 1,
        ),
        // Add subtle shadow for depth
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_rounded,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                'DESCRIPTION',
                style: AppFonts.textStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            description,
            style: AppFonts.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final secondaryColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: AppFonts.textStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: secondaryColor,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRowWithIcon(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final secondaryColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: AppFonts.textStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: secondaryColor,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(icon, size: 18, color: textColor),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.textStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptDivider(bool isDark) {
    final color = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppTheme.borderColor.withValues(alpha: 0.9);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _ScanReceiptDashedLinePainter(color: color),
      ),
    );
  }

  Widget _buildReceiptLineItems(
    List<LineItem> lineItems,
    Currency currency,
    bool isDark,
    Color textColor,
    Color secondaryColor, {
    required int maxVisible,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final showToggle = lineItems.length > maxVisible;
    final visibleItems = showToggle && !isExpanded
        ? lineItems.take(maxVisible).toList()
        : lineItems;
    final hiddenCount = lineItems.length - maxVisible;

    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : AppTheme.borderColor.withValues(alpha: 0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...visibleItems.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == visibleItems.length - 1;
          final lineTotal = item.amount * (item.quantity ?? 1);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.description,
                        style: AppFonts.textStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (item.quantity != null && item.quantity! > 1)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${item.quantity}x',
                          style: AppFonts.textStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: secondaryColor,
                          ),
                        ),
                      ),
                    Text(
                      CurrencyFormatter.format(lineTotal, currency),
                      style: AppFonts.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Divider(height: 1, thickness: 1, color: dividerColor),
                ),
            ],
          );
        }),
        if (showToggle)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isExpanded
                          ? 'Show less'
                          : 'Show more ($hiddenCount more)',
                      style: AppFonts.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isDark, {
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isHighlight
            ? Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 1,
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: AppFonts.textStyle(
              fontSize: isHighlight ? 13 : 12,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
              color: isHighlight
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppTheme.textPrimary)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.textSecondary),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(width: 24),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              style: AppFonts.textStyle(
                fontSize: isHighlight ? 18 : 15,
                fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
                color: isHighlight
                    ? AppTheme.warningColor.withValues(alpha: 0.95)
                    : AppTheme.textPrimary,
                letterSpacing: isHighlight ? -0.3 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator(bool isDark) {
    return Container(
      key: const ValueKey('processing'),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.cardBackground, AppTheme.surfaceColor],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 3.5,
                          value: _processingProgress > 0
                              ? _processingProgress
                              : null,
                        ),
                      ),
                      if (_processingProgress < 0.1)
                        LoadingSpinnerVariants.white(size: 20, strokeWidth: 2),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 28),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _processingStatus ?? 'Processing receipt...',
              key: ValueKey(_processingStatus),
              style: AppFonts.textStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'This may take a few seconds',
            style: AppFonts.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              letterSpacing: -0.1,
            ),
          ),
          SizedBox(height: 20),
          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _processingProgress > 0
                      ? _processingProgress
                      : _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.accentColor],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.errorColor),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPreview(
    ParsedReceipt receipt,
    Currency currency,
    bool isDark,
  ) {
    return Container(
      key: const ValueKey('preview'),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF111827), const Color(0xFF1E293B)]
              : [Colors.white, const Color(0xFFF9FAFB)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.successColor.withValues(alpha: 0.4),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.successColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receipt Scanned',
                      style: AppFonts.textStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Information extracted successfully',
                      style: AppFonts.textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          if (receipt.merchant != null) ...[
            _buildPreviewRow('Store', receipt.merchant!, isDark),
            SizedBox(height: 16),
          ],
          if (receipt.totalAmount != null) ...[
            _buildPreviewRow(
              'Total',
              CurrencyFormatter.format(receipt.totalAmount!, currency),
              isDark,
              isHighlight: true,
            ),
            SizedBox(height: 16),
          ],
          if (receipt.date != null) ...[
            _buildPreviewRow(
              'Date',
              DateFormat('MMM d, y • h:mm a').format(receipt.date!),
              isDark,
            ),
            SizedBox(height: 16),
          ],
          if (receipt.lineItems != null && receipt.lineItems!.isNotEmpty) ...[
            _buildPreviewRow(
              'Items',
              '${receipt.lineItems!.length} ${receipt.lineItems!.length == 1 ? 'item' : 'items'}',
              isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewRow(
    String label,
    String value,
    bool isDark, {
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isHighlight
            ? Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 1,
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: AppFonts.textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(width: 24),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              style: AppFonts.textStyle(
                fontSize: isHighlight ? 18 : 15,
                fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
                color: isHighlight
                    ? AppTheme.warningColor.withValues(alpha: 0.95)
                    : AppTheme.textPrimary,
                letterSpacing: isHighlight ? -0.3 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Container(
      key: const ValueKey('actions'),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor, AppTheme.accentColor],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSaving ? null : _saveExpenseDirectly,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: _isSaving
                            ? LoadingSpinnerVariants.white(
                                size: 20,
                                strokeWidth: 2,
                              )
                            : Icon(
                                Icons.check_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                      ),
                      SizedBox(width: 14),
                      Text(
                        _isSaving ? 'Saving...' : 'Use This Receipt',
                        style: AppFonts.textStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a horizontal dashed line for receipt-style dividers.
class _ScanReceiptDashedLinePainter extends CustomPainter {
  final Color color;

  _ScanReceiptDashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 4;
    const gap = 4;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

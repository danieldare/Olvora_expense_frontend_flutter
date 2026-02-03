import 'dart:async';
import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/models/currency.dart';
import '../../data/services/voice_input_service.dart';
import '../../data/services/voice_parser_service.dart';
import '../../data/services/voice_parse_service.dart';
import '../../../expenses/presentation/screens/add_expense_screen.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../receipts/domain/models/parsed_receipt.dart';

/// World-class voice expense input: real-time waveform, smart parsing, polished UX.
class VoiceInputScreen extends ConsumerStatefulWidget {
  final String? tripId;

  const VoiceInputScreen({super.key, this.tripId});

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen>
    with TickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService();
  final VoiceParserService _parserService = VoiceParserService();
  VoiceParseService? _voiceParseService;

  RecorderController? _recorderController;
  String? _recordingPath;
  Timer? _durationTimer;
  Duration _duration = Duration.zero;
  bool _isRecording = false;
  bool _isProcessing = false;
  String _recognizedText = '';
  ParsedReceipt? _parsedReceipt;
  String? _errorMessage;

  static const _maxDuration = Duration(seconds: 60);

  late AnimationController _idlePulseController;
  late Animation<double> _idlePulseAnimation;

  @override
  void initState() {
    super.initState();
    _idlePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _idlePulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _idlePulseController, curve: Curves.easeInOut),
    );
    _idlePulseController.repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    final apiService = ref.read(apiServiceV2Provider);
    _voiceParseService = VoiceParseService(apiService);
    await _voiceService.initialize();

    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100
      ..bitRate = 128000;
  }

  Future<void> _startRecording() async {
    // Check permission
    final hasPermission = await _voiceService.isPermissionGranted();
    if (!hasPermission) {
      final status = await _voiceService.requestPermission();
      if (status != PermissionStatus.granted) {
        _showPermissionDialog();
        return;
      }
    }

    HapticFeedback.mediumImpact();

    // Generate file path
    final appDir = await getApplicationDocumentsDirectory();
    final voiceDir = Directory('${appDir.path}/voice_recordings');
    if (!await voiceDir.exists()) {
      await voiceDir.create(recursive: true);
    }
    _recordingPath = '${voiceDir.path}/${const Uuid().v4()}.m4a';

    String? speechError;
    final listeningStarted = await _voiceService.startListening(
      onResult: (text) {
        if (mounted) {
          setState(() => _recognizedText = text);
        }
      },
      onDone: () {},
      onError: (error) {
        speechError = error;
        debugPrint('Speech recognition error: $error');
      },
    );

    if (!listeningStarted || !mounted) {
      setState(() {
        _isRecording = false;
        _errorMessage =
            speechError ?? 'Could not start speech recognition. Please try again.';
      });
      return;
    }

    _idlePulseController.stop();

    try {
      setState(() {
        _isRecording = true;
        _duration = Duration.zero;
        _recognizedText = '';
        _parsedReceipt = null;
        _errorMessage = null;
      });

      await _recorderController?.record(path: _recordingPath);
      _startDurationTimer();
    } catch (e) {
      await _voiceService.stopListening();
      setState(() {
        _isRecording = false;
        _errorMessage = 'Failed to start recording';
      });
    }
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && _isRecording) {
        setState(() {
          _duration += const Duration(milliseconds: 100);
        });

        if (_duration >= _maxDuration) {
          HapticFeedback.heavyImpact();
          _stopRecording();
        }
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    HapticFeedback.mediumImpact();
    _durationTimer?.cancel();

    setState(() => _isRecording = false);

    try {
      await _voiceService.stopListening();
      await _recorderController?.stop();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }

    // Give the speech engine time to deliver the final result (often sent after stop()).
    await Future.delayed(const Duration(milliseconds: 450));

    if (!mounted) return;
    final textToUse = _recognizedText.trim();

    if (textToUse.isNotEmpty) {
      await _processVoiceInput();
    } else {
      setState(() {
        _errorMessage = 'No speech detected. Please try again.';
      });
    }
  }

  Future<void> _processVoiceInput() async {
    if (_recognizedText.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    try {
      // Try backend parsing first
      if (_voiceParseService != null) {
        try {
          final parsed = await _voiceParseService!.parseFromVoiceText(
            _recognizedText,
          );
          if (mounted) {
            setState(() {
              _parsedReceipt = parsed;
              _isProcessing = false;
            });
            HapticFeedback.mediumImpact();
            return;
          }
        } catch (e) {
          debugPrint('Backend parsing failed: $e');
        }
      }

      // Fallback to local parsing
      final categoriesAsync = ref.read(categoriesProvider);
      categoriesAsync.when(
        data: (categories) {
          if (!mounted) return;
          final parsed = _parserService.parseVoiceInput(
            _recognizedText,
            categories,
          );
          setState(() {
            _parsedReceipt = parsed.toParsedReceipt();
            _isProcessing = false;
          });
          HapticFeedback.mediumImpact();
        },
        loading: () {},
        error: (_, __) {
          final parsed = _parserService.parseVoiceInput(_recognizedText, []);
          setState(() {
            _parsedReceipt = parsed.toParsedReceipt();
            _isProcessing = false;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Failed to process. Please try again.';
        });
      }
    }
  }

  void _useResult() {
    if (_parsedReceipt == null) return;
    HapticFeedback.mediumImpact();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          preFilledData: _parsedReceipt!,
          entryMode: EntryMode.voice,
          tripId: widget.tripId,
        ),
      ),
    );
  }

  void _reset() {
    HapticFeedback.lightImpact();
    _idlePulseController.repeat(reverse: true);
    setState(() {
      _recognizedText = '';
      _parsedReceipt = null;
      _errorMessage = null;
      _duration = Duration.zero;
    });
  }

  void _showPermissionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCardBackground : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.mic_off_rounded, color: AppTheme.errorColor, size: 24),
            SizedBox(width: 12),
            Text(
              'Microphone Required',
              style: AppFonts.textStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Please enable microphone access in Settings to use voice input.',
          style: AppFonts.textStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _voiceService.openSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _idlePulseController.dispose();
    _recorderController?.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.screenBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: KeyedSubtree(
                              key: ValueKey<String>(
                                _isRecording
                                    ? 'recording'
                                    : _isProcessing
                                        ? 'processing'
                                        : 'idle',
                              ),
                              child: _buildMainArea(isDark),
                            ),
                          ),
                          if (_recognizedText.isNotEmpty && !_isRecording)
                            Padding(
                              padding: EdgeInsets.only(
                                top: AppSpacing.sectionMedium,
                              ),
                              child: _buildRecognizedText(isDark),
                            ),
                          if (_errorMessage != null)
                            Padding(
                              padding: EdgeInsets.only(
                                top: AppSpacing.sectionMedium,
                              ),
                              child: _buildErrorMessage(isDark),
                            ),
                          if (_parsedReceipt != null && !_isProcessing) ...[
                            Padding(
                              padding: EdgeInsets.only(
                                top: AppSpacing.sectionMedium,
                              ),
                              child: _buildParsedResult(isDark),
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                top: AppSpacing.sectionMedium,
                              ),
                              child: _buildActionButtons(isDark),
                            ),
                          ],
                          if (!_isRecording &&
                              _recognizedText.isEmpty &&
                              _parsedReceipt == null &&
                              _errorMessage == null)
                            Padding(
                              padding: EdgeInsets.only(
                                top: AppSpacing.sectionLarge,
                              ),
                              child: _buildTips(isDark),
                            ),
                          SizedBox(height: AppSpacing.sectionLarge),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
      child: Row(
        children: [
          AppBackButton(),
          Text(
            'Add with voice',
            style: AppFonts.textStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainArea(bool isDark) {
    if (_isRecording) return _buildRecordingBar(isDark);
    if (_isProcessing) return _buildProcessingState();
    return _buildIdleState(isDark);
  }

  /// Idle: inviting mic with subtle pulse and clear value prop.
  Widget _buildIdleState(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'Tap to start recording your expense',
          child: GestureDetector(
            onTap: _startRecording,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: _idlePulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _idlePulseAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.spacingMedium + 4),
        Text(
          'Tap to speak',
          style: AppFonts.textStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.spacingXSmall),
        Text(
          'Say an expense in one sentence',
          style: AppFonts.textStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Centered loading state while parsing.
  Widget _buildProcessingState() {
    return Semantics(
      liveRegion: true,
      label: 'Processing your expense',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
            SizedBox(height: AppSpacing.spacingMedium + 4),
            Text(
              'Understanding…',
              style: AppFonts.textStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.spacingXSmall),
            Text(
              'Turning your words into an expense',
              style: AppFonts.textStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Recording bar: stop, waveform, timer; live transcript below.
  Widget _buildRecordingBar(bool isDark) {
    final minutes = _duration.inMinutes;
    final seconds = _duration.inSeconds % 60;
    final timeString =
        '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Semantics(
      liveRegion: true,
      label: 'Recording. $timeString. Tap stop when done.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(29),
              border: Border.all(
                color: AppTheme.errorColor.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Stop recording',
                  child: GestureDetector(
                    onTap: _stopRecording,
                    child: Container(
                      width: 46,
                      height: 46,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.errorColor.withValues(alpha: 0.14),
                      ),
                      child: Icon(
                        Icons.stop_rounded,
                        color: AppTheme.errorColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _recorderController != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: AudioWaveforms(
                            recorderController: _recorderController!,
                            size: const Size(double.infinity, 42),
                            waveStyle: WaveStyle(
                              waveColor: AppTheme.errorColor,
                              extendWaveform: true,
                              showMiddleLine: false,
                              spacing: 5,
                              waveThickness: 2.5,
                              showDurationLabel: false,
                            ),
                            enableGesture: false,
                          ),
                        )
                      : const SizedBox(height: 42),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Text(
                    timeString,
                    style: AppFonts.textStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.errorColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_recognizedText.isNotEmpty) ...[
            SizedBox(height: AppSpacing.spacingMedium),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.cardPaddingSmall,
                vertical: AppSpacing.spacingMedium,
              ),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                border: Border.all(
                  color: AppTheme.borderColor.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                _recognizedText,
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecognizedText(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.cardPaddingSmall),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You said',
            style: AppFonts.textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: AppSpacing.spacingXSmall),
          Text(
            _recognizedText,
            style: AppFonts.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPaddingSmall,
        vertical: AppSpacing.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 22,
            color: AppTheme.errorColor,
          ),
          SizedBox(width: AppSpacing.spacingSmall),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.errorColor,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: _reset,
            child: Text(
              'Try again',
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedResult(bool isDark) {
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = currencyAsync.valueOrNull ?? Currency.defaultCurrency;
    final receipt = _parsedReceipt!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.cardPaddingSmall),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(
          color: AppTheme.successColor.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppTheme.successColor,
              ),
              SizedBox(width: AppSpacing.spacingXSmall),
              Text(
                'Looks good',
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          if (receipt.totalAmount != null) ...[
            SizedBox(height: AppSpacing.spacingMedium),
            Text(
              CurrencyFormatter.format(receipt.totalAmount!, currency),
              style: AppFonts.textStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.spacingSmall),
          Wrap(
            spacing: AppSpacing.spacingSmall,
            runSpacing: AppSpacing.spacingSmall,
            children: [
              if (receipt.suggestedCategory != null)
                _buildDetailChip(
                  Icons.category_rounded,
                  receipt.suggestedCategory!,
                  isDark,
                ),
              if (receipt.merchant != null)
                _buildDetailChip(
                  Icons.store_rounded,
                  receipt.merchant!,
                  isDark,
                ),
              if (receipt.date != null)
                _buildDetailChip(
                  Icons.calendar_today_rounded,
                  DateFormat('MMM d').format(receipt.date!),
                  isDark,
                ),
            ],
          ),
          if (receipt.description != null &&
              receipt.description!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.spacingSmall),
            Text(
              receipt.description!,
              style: AppFonts.textStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingSmall + 2,
        vertical: AppSpacing.spacingXSmall + 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.borderColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppTheme.textSecondary,
          ),
          SizedBox(width: AppSpacing.spacingXSmall),
          Text(
            text,
            style: AppFonts.textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _useResult,
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: Text(
              'Add expense',
              style: AppFonts.textStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              elevation: 0,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.spacingSmall),
        TextButton(
          onPressed: _reset,
          child: Text(
            'Say something else',
            style: AppFonts.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTips(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPaddingSmall,
        vertical: AppSpacing.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Examples',
            style: AppFonts.textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: AppSpacing.spacingSmall),
          Text(
            '"\$20 for lunch at Chipotle"',
            style: AppFonts.textStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
          SizedBox(height: 2),
          Text(
            '"Coffee, five dollars"',
            style: AppFonts.textStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
          SizedBox(height: 2),
          Text(
            '"Uber yesterday, twelve pounds"',
            style: AppFonts.textStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

extension ParsedVoiceExpenseExtension on ParsedVoiceExpense {
  ParsedReceipt toParsedReceipt() {
    return ParsedReceipt(
      merchant: merchant,
      totalAmount: amount,
      date: date,
      suggestedCategory: category?.name,
      lineItems: null,
      rawText: rawText,
      tax: null,
      currency: null,
    );
  }
}

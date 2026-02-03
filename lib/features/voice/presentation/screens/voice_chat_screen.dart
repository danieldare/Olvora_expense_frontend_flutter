import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/voice_expense_providers.dart';
import '../../data/services/raw_audio_recorder_service.dart';
import '../../data/services/voice_input_service.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/voice_input_button.dart';
import '../widgets/live_waveform_widget.dart';
import '../widgets/expense_summary_card.dart';
import '../widgets/field_progress_indicator.dart';
import '../widgets/empty_state_widget.dart';
import '../../domain/models/voice_expense_session.dart';
import '../../../home/presentation/screens/home_screen.dart';

class VoiceChatScreen extends ConsumerStatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  ConsumerState<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends ConsumerState<VoiceChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final VoiceInputService _voiceService = VoiceInputService();
  StreamSubscription<RecordingResult>? _recordingSubscription;
  StreamSubscription<double>? _audioLevelSubscription;
  Timer? _permissionCheckTimer;
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    // Add app lifecycle observer for settings return detection
    WidgetsBinding.instance.addObserver(this);

    // Start new session when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceExpenseProvider.notifier).startNewSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingSubscription?.cancel();
    _audioLevelSubscription?.cancel();
    _permissionCheckTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Detect when app returns from background (e.g., from Settings)
    if (state == AppLifecycleState.paused) {
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      // Re-check permission when returning from settings
      _recheckPermissionAfterSettings();
    }
  }

  /// Re-check permission status after returning from settings
  Future<void> _recheckPermissionAfterSettings() async {
    final isGranted = await _voiceService.isPermissionGranted();
    if (isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Microphone permission granted! You can now use voice input.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _scrollToBottom({bool smooth = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (smooth) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(voiceExpenseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Scroll to bottom when new messages arrive
    ref.listen<VoiceExpenseSession>(voiceExpenseProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
      // Scroll immediately when state changes to confirming
      if (next.state == ConversationState.confirming &&
          previous?.state != ConversationState.confirming) {
        _scrollToBottom(smooth: false);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.screenBackgroundColor,
      appBar: _buildAppBar(isDark, session),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            if (session.state != ConversationState.idle &&
                session.state != ConversationState.saved &&
                session.voiceSegments.isNotEmpty)
              FieldProgressIndicator(data: session.expenseData, isDark: isDark),

            // Chat messages or empty state
            Expanded(
              child: session.messages.isEmpty
                  ? EmptyStateWidget(isDark: isDark)
                  : _buildChatList(session, isDark),
            ),

            // Live Waveform (when listening) - World-Class Real-time Visualization
            if (session.state == ConversationState.listening)
              Consumer(
                builder: (context, ref, child) {
                  final audioRecorder = ref.watch(
                    rawAudioRecorderServiceProvider,
                  );
                  return LiveWaveformWidget(
                    audioLevelStream: audioRecorder.audioLevelStream,
                    isActive: true,
                    height: 80,
                  );
                },
              ),

            // Bottom input area
            _buildBottomArea(session, isDark),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, VoiceExpenseSession session) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: AppBackButton(
        onPressed: () {
          if (session.state == ConversationState.gathering ||
              session.state == ConversationState.confirming) {
            _showExitConfirmation();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor, AppTheme.accentColor],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(Icons.mic_rounded, color: Colors.white, size: 22),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice Expense',
                style: AppFonts.textStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (session.voiceSegments.isNotEmpty)
                Text(
                  '${session.voiceSegments.length} input${session.voiceSegments.length > 1 ? 's' : ''}',
                  style: AppFonts.textStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (session.voiceSegments.isNotEmpty)
          TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(voiceExpenseProvider.notifier).startNewSession();
            },
            icon: Icon(
              Icons.refresh_rounded,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            label: Text(
              'Reset',
              style: AppFonts.textStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatList(VoiceExpenseSession session, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount:
          session.messages.length +
          (session.state == ConversationState.confirming ? 1 : 0),
      itemBuilder: (context, index) {
        // Show summary card before last message in confirming state
        if (session.state == ConversationState.confirming &&
            index == session.messages.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ExpenseSummaryCard(
              data: session.expenseData,
              isDark: isDark,
            ),
          );
        }

        final message = session.messages[index];
        final previousMessage = index > 0 ? session.messages[index - 1] : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: ChatMessageBubble(
            message: message,
            isDark: isDark,
            previousMessage: previousMessage,
            showTypingAnimation:
                index == session.messages.length - 1 &&
                !message.isUser &&
                session.state == ConversationState.processing,
          ),
        );
      },
    );
  }

  Widget _buildBottomArea(VoiceExpenseSession session, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show action buttons in confirming state
          if (session.state == ConversationState.confirming)
            _buildConfirmationButtons(isDark),

          // Voice input button
          if (session.state != ConversationState.saved &&
              session.state != ConversationState.cancelled)
            Center(
              child: VoiceInputButton(
                isListening: session.state == ConversationState.listening,
                isProcessing: session.state == ConversationState.processing,
                onTap: _handleVoiceTap,
              ),
            ),

          // Success state
          if (session.state == ConversationState.saved) _buildSuccessActions(),
        ],
      ),
    );
  }

  Widget _buildConfirmationButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Cancel',
              icon: Icons.close_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(voiceExpenseProvider.notifier).cancel();
              },
              isPrimary: false,
              isDark: isDark,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildActionButton(
              label: 'Save Expense',
              icon: Icons.check_rounded,
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await ref.read(voiceExpenseProvider.notifier).confirmAndSave();
              },
              isPrimary: true,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
    required bool isDark,
  }) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: AppFonts.textStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(
            color: isDark
                ? Colors.grey[700]!
                : AppTheme.textSecondary.withOpacity(0.3),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDark ? Colors.white70 : AppTheme.textSecondary,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSuccessActions() {
    return Column(
      children: [
        // Success animation
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: EdgeInsets.all(AppSpacing.screenHorizontal),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.successColor.withOpacity(0.15),
                      AppTheme.successColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.successColor,
                        size: 48,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Expense Saved!',
                      style: AppFonts.textStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.successColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your expense has been recorded',
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
          },
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Done',
                  style: AppFonts.textStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(voiceExpenseProvider.notifier).startNewSession();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Add Another',
                  style: AppFonts.textStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleVoiceTap() async {
    final notifier = ref.read(voiceExpenseProvider.notifier);
    final audioRecorder = ref.read(rawAudioRecorderServiceProvider);
    final state = ref.read(voiceExpenseProvider).state;

    HapticFeedback.mediumImpact();

    if (state == ConversationState.listening) {
      // Stop recording manually (user controls when to stop - NO auto-stop)
      try {
        await audioRecorder.stopRecording();
        notifier.stopListening();
        // Recording completion will be handled by _recordingSubscription
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error stopping recording: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        notifier.stopListening();
      }
    } else if (state != ConversationState.processing) {
      // Start recording
      notifier.startListening();
      await _startRawAudioRecording();
    }
  }

  /// Start raw audio recording - World-Class Implementation
  Future<void> _startRawAudioRecording() async {
    final audioRecorder = ref.read(rawAudioRecorderServiceProvider);
    final notifier = ref.read(voiceExpenseProvider.notifier);

    // CRITICAL: Check and request microphone permission using centralized flow
    final permissionGranted = await _voiceService.requestPermissionWithExplanation(
      shouldShowExplanation: () => _showPermissionExplanationDialog(),
      onPermanentlyDenied: () => _showPermissionDeniedDialog(),
    );

    if (!permissionGranted) {
      // Permission denied or user cancelled
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Microphone permission is required to use voice input',
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      notifier.stopListening();
      return;
    }

    // Start permission monitoring during recording
    _startPermissionMonitoring(notifier);

    try {
      // Start raw audio recording
      final filePath = await audioRecorder.startRecording();

      // Set up recording completion listener
      _recordingSubscription?.cancel();
      _recordingSubscription = audioRecorder.recordingCompleteStream.listen(
        (result) async {
          if (!mounted) return;

          if (result.success && result.hasValidAudio) {
            // Recording completed successfully
            // Add voice segment with audio file path
            await notifier.addVoiceSegment(
              audioFilePath: result.filePath!,
              durationMs: result.durationMs,
              averageAudioLevel: result.averageAudioLevel,
            );
          } else if (result.isTooShort) {
            // Recording too short
            notifier.stopListening();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    "I didn't catch that. Could you try again?",
                  ),
                  backgroundColor: AppTheme.warningColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else {
            // Recording failed
            notifier.stopListening();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.error ?? 'Recording failed. Please try again.',
                  ),
                  backgroundColor: AppTheme.errorColor,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
        onError: (error) {
          notifier.stopListening();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Recording error: $error'),
                backgroundColor: AppTheme.errorColor,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      );

      debugPrint('Raw audio recording started: $filePath');
    } catch (e) {
      notifier.stopListening();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show explanation dialog before requesting permission
  Future<bool> _showPermissionExplanationDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;
    final dialogBgColor = isDark ? AppTheme.darkCardBackground : Colors.white;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return AlertDialog(
              backgroundColor: dialogBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.mic_rounded,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Microphone Access',
                      style: AppFonts.textStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                'To use voice input for expense tracking, we need access to your microphone. This allows you to speak your expenses instead of typing them.',
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
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
                      color: subtitleColor,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: AppFonts.textStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.mic_off_rounded, color: AppTheme.errorColor, size: 24),
            SizedBox(width: 12),
            const Expanded(child: Text('Microphone Permission Required')),
          ],
        ),
        content: const Text(
          'Voice input requires microphone permission. Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppFonts.textStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: AppFonts.textStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Start monitoring permission during recording to detect mid-recording revocation
  void _startPermissionMonitoring(dynamic notifier) {
    // Cancel any existing timer
    _permissionCheckTimer?.cancel();

    // Check permission every 2 seconds during recording
    _permissionCheckTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) async {
        final hasPermission = await _voiceService.checkPermissionDuringRecording();
        if (!hasPermission) {
          // Permission was revoked during recording
          timer.cancel();
          notifier.stopListening();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Microphone access was revoked. Recording stopped.',
                ),
                backgroundColor: AppTheme.errorColor,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }

        // Stop monitoring if not recording
        final state = ref.read(voiceExpenseProvider);
        if (state.state != ConversationState.listening) {
          timer.cancel();
        }
      },
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: AppTheme.cardBackground,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: AppTheme.warningColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Discard expense?',
                      style: AppFonts.textStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'You have an expense in progress. Are you sure you want to leave?',
                style: AppFonts.textStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Keep editing',
                      style: AppFonts.textStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to home screen and clear navigation stack
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Discard',
                      style: AppFonts.textStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

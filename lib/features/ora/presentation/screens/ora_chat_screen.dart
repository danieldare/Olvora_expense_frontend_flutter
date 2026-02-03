import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/ora_message.dart';
import '../../domain/models/ora_conversation_state.dart';
import '../providers/ora_providers.dart';
import '../widgets/ora_message_list.dart';
import '../widgets/ora_input_bar.dart';
import '../widgets/ora_chat_background.dart';
import '../../../../features/voice/presentation/widgets/live_waveform_widget.dart';
import '../../../../features/voice/presentation/providers/voice_expense_providers.dart';
import '../../../expenses/presentation/providers/expenses_providers.dart';

/// Main chat screen for Ora AI Assistant
class OraChatScreen extends ConsumerStatefulWidget {
  const OraChatScreen({super.key});

  @override
  ConsumerState<OraChatScreen> createState() => _OraChatScreenState();
}

class _OraChatScreenState extends ConsumerState<OraChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    // Initialize conversation immediately to prevent flicker
    // Use a microtask to ensure the widget is built first
    Future.microtask(() {
      if (!mounted) return;
      final notifier = ref.read(oraConversationProvider.notifier);
      final currentState = ref.read(oraConversationProvider);

      // Only initialize if still initializing (prevents double initialization)
      if (currentState.isInitializing) {
        // Use the new initialize method that handles loading most recent conversation
        notifier.initializeConversation();
      }
    });

    // Scroll to bottom after initial build and when messages are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait a bit for the layout to complete, then scroll to bottom smoothly
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _scrollToBottom(smooth: true);
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool smooth = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        // For normal ListView, scroll to max scroll position (bottom)
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (smooth) {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(
              milliseconds: 400,
            ), // Increased for smoother feel
            curve: Curves.easeInOutCubic, // Smoother curve
          );
        } else {
          _scrollController.jumpTo(maxScroll);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversationState = ref.watch(oraConversationProvider);

    // Scroll to bottom when new messages arrive or when messages are first loaded
    ref.listen<OraConversationState>(oraConversationProvider, (previous, next) {
      final previousLength = previous?.messages.length ?? 0;
      final nextLength = next.messages.length;
      final wasInitializing = previous?.isInitializing ?? true;
      final isNowInitialized = !next.isInitializing;

      // Scroll when messages change (new message added or history loaded)
      if (previousLength != nextLength) {
        // Use a slightly longer delay to ensure layout is complete
        final isNewMessage = nextLength > previousLength;
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            _scrollToBottom(smooth: isNewMessage);
          }
        });
      }

      // Also scroll when conversation finishes initializing (first load)
      if (wasInitializing && isNowInitialized && nextLength > 0) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _scrollToBottom(smooth: true);
          }
        });
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppTheme.screenBackgroundColor,
      appBar: _buildAppBar(context),
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: isDark
              ? null
              : BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: AppTheme.borderColor.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                ),
          child: OraChatBackground(
            child: Column(
            children: [
              // Message list
              Expanded(
              child: conversationState.isInitializing
                  ? const Center(child: CircularProgressIndicator())
                  : OraMessageList(
                      messages: conversationState.messages,
                      scrollController: _scrollController,
                      onActionPressed: _handleAction,
                      onLoadMore: conversationState.conversationId.isNotEmpty
                          ? () {
                              ref
                                  .read(oraConversationProvider.notifier)
                                  .loadMoreMessages();
                            }
                          : null,
                      onSuggestionTap: (prompt) {
                        // Send the suggestion as a message
                        ref
                            .read(oraConversationProvider.notifier)
                            .sendMessage(prompt);
                      },
                    ),
            ),

            // Spacing between messages and input bar
            const SizedBox(height: 12),

            // Voice waveform visualization
            if (_isRecording)
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

            // Input bar
            OraInputBar(
              controller: _textController,
              focusNode: _focusNode,
              isProcessing: conversationState.isProcessing,
              inputState: conversationState.inputState,
              onSendText: _handleSendText,
              onSendVoice: _handleSendVoice,
              onAttachImage: _handleAttachImage,
              onRecordingStateChanged: (isRecording) {
                setState(() {
                  _isRecording = isRecording;
                });
              },
            ),
          ],
        ),
        ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor,
      elevation: 0,
      title: Row(
        children: [
          // Ora avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'O',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ora',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Your expense assistant',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'More',
          onSelected: (value) {
            if (value == 'new_conversation') {
              ref.read(oraConversationProvider.notifier).startNewConversation();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'new_conversation',
              child: Row(
                children: [
                  Icon(Icons.add_comment_outlined, size: 22),
                  SizedBox(width: 12),
                  Text('New conversation'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleSendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(oraConversationProvider.notifier).sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _handleSendVoice(File audioFile) {
    ref.read(oraConversationProvider.notifier).sendVoice(audioFile);
    _scrollToBottom();
  }

  void _handleAttachImage() async {
    final picker = ImagePicker();

    // Show source selection dialog
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      if (image != null) {
        final imageFile = File(image.path);

        // Validate file exists
        if (!await imageFile.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Selected image file is not accessible'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          return;
        }

        // Show cropping interface (like scan receipt flow)
        final croppedFile = await _cropImage(imageFile);

        if (croppedFile != null && mounted) {
          // User cropped the image - use the cropped version
          final croppedImageFile = File(croppedFile.path);
          if (await croppedImageFile.exists()) {
            ref
                .read(oraConversationProvider.notifier)
                .sendImage(croppedImageFile);
            _scrollToBottom();
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Cropped image file is not accessible'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }
        } else if (mounted) {
          // User cancelled cropping, but we still have the original image
          if (await imageFile.exists()) {
            ref.read(oraConversationProvider.notifier).sendImage(imageFile);
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Crop image using ImageCropper (matching scan receipt flow)
  Future<CroppedFile?> _cropImage(File imageFile) async {
    if (!mounted) return null;

    try {
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
            content: const Text('Failed to crop image. Please try again.'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return null;
    }
  }

  void _handleAction(OraActionButton action) async {
    final notifier = ref.read(oraConversationProvider.notifier);
    final response = await notifier.executeAction(action);

    // If expense was confirmed, always refresh expense providers
    // Backend logs show expenses are being created successfully, so always refresh
    if (action.actionType == OraActionType.confirm ||
        action.actionType == OraActionType.confirmAll) {
      debugPrint('Confirm action executed. Refreshing expense providers...');

      // Wait a bit for backend to complete, then refresh
      await Future.delayed(const Duration(milliseconds: 800));

      // Invalidate and refresh providers to ensure lists are updated
      ref.invalidate(expensesProvider);
      ref.invalidate(recentTransactionsProvider);

      // Force immediate refresh
      ref.refresh(expensesProvider);
      ref.refresh(recentTransactionsProvider);

      debugPrint('✓ Refreshed expense providers after confirmation');
    }
  }
}

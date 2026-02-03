/// Domain models for Ora AI Assistant messages
library;

enum AttachmentType {
  image,
  audio,
  receipt,
}

enum StructuredContentType {
  expenseCreated,
  expenseList,
  expensesPending,
  budgetStatus,
  spendingSummary,
  tripCreated,
  confirmationRequired,
  receiptSummary,
  capabilities,
  error,
}

enum OraActionType {
  confirm,
  confirmAll,
  edit,
  editIndividual,
  undo,
  cancel,
  viewDetails,
  retry,
}

enum OraSystemMessageType {
  typing,
  error,
  info,
}

/// Base class for Ora messages
abstract class OraMessage {
  final String id;
  final DateTime timestamp;

  const OraMessage({
    required this.id,
    required this.timestamp,
  });
}

/// User message
class UserMessage extends OraMessage {
  final String text;
  final List<OraAttachment>? attachments;
  final Map<String, dynamic>? metadata;

  const UserMessage({
    required super.id,
    required this.text,
    this.attachments,
    this.metadata,
    required super.timestamp,
  });

  /// Check if this message was created via voice input
  bool get isVoice => metadata?['isVoice'] == true;
}

/// Assistant message
class AssistantMessage extends OraMessage {
  final String text;
  final OraStructuredContent? structuredContent;
  final List<OraActionButton>? actions;
  final bool isStreaming;

  const AssistantMessage({
    required super.id,
    required this.text,
    this.structuredContent,
    this.actions,
    required super.timestamp,
    this.isStreaming = false,
  });
}

/// System message
class SystemMessage extends OraMessage {
  final String text;
  final OraSystemMessageType type;

  const SystemMessage({
    required super.id,
    required this.text,
    required this.type,
    required super.timestamp,
  });
}

/// Attachment for messages
class OraAttachment {
  final AttachmentType type;
  final String? url;
  final String? localPath;
  final String? mimeType;
  final Map<String, dynamic>? metadata;

  const OraAttachment({
    required this.type,
    this.url,
    this.localPath,
    this.mimeType,
    this.metadata,
  });
}

/// Structured content in assistant messages
class OraStructuredContent {
  final StructuredContentType type;
  final Map<String, dynamic> data;

  const OraStructuredContent({
    required this.type,
    required this.data,
  });
}

/// Action button in assistant messages
class OraActionButton {
  final String id;
  final String label;
  final OraActionType actionType;
  final Map<String, dynamic>? payload;
  final bool isPrimary;

  const OraActionButton({
    required this.id,
    required this.label,
    required this.actionType,
    this.payload,
    this.isPrimary = false,
  });
}

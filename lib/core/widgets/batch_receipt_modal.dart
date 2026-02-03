import 'dart:io';
import 'package:flutter/material.dart';
import '../services/share_handler_service.dart';
import '../theme/app_theme.dart';
import '../theme/dynamic_theme_colors.dart';

/// Modal for batch receipt processing
///
/// Features:
/// - Shows preview of all shared files
/// - Allows selection/deselection of files
/// - Shows validation errors for invalid files
/// - Progress indicator during processing
class BatchReceiptModal extends StatefulWidget {
  final List<SharedFileItem> files;
  final List<SharedFileItem> invalidFiles;
  final Future<BatchProcessingResult> Function(List<SharedFileItem>) onProcess;

  const BatchReceiptModal({
    super.key,
    required this.files,
    required this.invalidFiles,
    required this.onProcess,
  });

  /// Show the batch receipt modal
  static Future<BatchProcessingResult?> show({
    required BuildContext context,
    required List<SharedFileItem> files,
    required List<SharedFileItem> invalidFiles,
    required Future<BatchProcessingResult> Function(List<SharedFileItem>) onProcess,
  }) async {
    return showModalBottomSheet<BatchProcessingResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BatchReceiptModal(
        files: files,
        invalidFiles: invalidFiles,
        onProcess: onProcess,
      ),
    );
  }

  @override
  State<BatchReceiptModal> createState() => _BatchReceiptModalState();
}

class _BatchReceiptModalState extends State<BatchReceiptModal> {
  late Set<String> _selectedPaths;
  bool _isProcessing = false;
  BatchProcessingResult? _result;
  int _currentProcessingIndex = 0;

  @override
  void initState() {
    super.initState();
    // Select all valid files by default
    _selectedPaths = widget.files.map((f) => f.path).toSet();
  }

  void _toggleSelection(String path) {
    if (_isProcessing) return;

    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  void _selectAll() {
    if (_isProcessing) return;

    setState(() {
      _selectedPaths = widget.files.map((f) => f.path).toSet();
    });
  }

  void _deselectAll() {
    if (_isProcessing) return;

    setState(() {
      _selectedPaths.clear();
    });
  }

  Future<void> _processSelected() async {
    if (_selectedPaths.isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _currentProcessingIndex = 0;
    });

    try {
      final selectedFiles = widget.files
          .where((f) => _selectedPaths.contains(f.path))
          .toList();

      // Listen to progress updates
      ShareHandlerService().processingProgress.listen((progress) {
        if (mounted) {
          setState(() {
            _currentProcessingIndex = progress.currentIndex;
          });
        }
      });

      final result = await widget.onProcess(selectedFiles);

      if (mounted) {
        setState(() {
          _result = result;
          _isProcessing = false;
        });

        // Show result briefly then close
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(result);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? DynamicThemeColors.surfaceColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isProcessing
                            ? 'Processing Receipts...'
                            : _result != null
                                ? 'Processing Complete'
                                : 'Shared Receipts',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isProcessing
                            ? 'Processing ${_currentProcessingIndex + 1} of ${_selectedPaths.length}'
                            : _result != null
                                ? '${_result!.successfulFiles} processed, ${_result!.queuedFiles} queued'
                                : '${widget.files.length} files ready to process',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isProcessing && _result == null) ...[
                  TextButton(
                    onPressed: _selectedPaths.length == widget.files.length
                        ? _deselectAll
                        : _selectAll,
                    child: Text(
                      _selectedPaths.length == widget.files.length
                          ? 'Deselect All'
                          : 'Select All',
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Progress indicator
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _selectedPaths.isNotEmpty
                        ? (_currentProcessingIndex + 1) / _selectedPaths.length
                        : 0,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

          // Result summary
          if (_result != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildResultSummary(),
            ),

          // File list
          if (_result == null)
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.files.length + widget.invalidFiles.length,
                itemBuilder: (context, index) {
                  if (index < widget.files.length) {
                    return _buildFileItem(widget.files[index]);
                  } else {
                    final invalidIndex = index - widget.files.length;
                    return _buildInvalidFileItem(widget.invalidFiles[invalidIndex]);
                  }
                },
              ),
            ),

          // Action buttons
          if (!_isProcessing && _result == null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _selectedPaths.isNotEmpty ? _processSelected : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Process ${_selectedPaths.length} Receipt${_selectedPaths.length == 1 ? '' : 's'}',
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
  }

  Widget _buildResultSummary() {
    final result = _result!;
    final theme = Theme.of(context);

    return Column(
      children: [
        // Success icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: result.hasErrors
                ? Colors.orange.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            result.hasErrors ? Icons.warning_rounded : Icons.check_rounded,
            size: 32,
            color: result.hasErrors ? Colors.orange : Colors.green,
          ),
        ),
        const SizedBox(height: 16),

        // Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              icon: Icons.check_circle,
              color: Colors.green,
              value: result.successfulFiles.toString(),
              label: 'Processed',
            ),
            if (result.queuedFiles > 0)
              _buildStatItem(
                icon: Icons.schedule,
                color: Colors.blue,
                value: result.queuedFiles.toString(),
                label: 'Queued',
              ),
            if (result.failedFiles > 0)
              _buildStatItem(
                icon: Icons.error,
                color: Colors.red,
                value: result.failedFiles.toString(),
                label: 'Failed',
              ),
          ],
        ),

        // Errors
        if (result.errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Errors:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                ...result.errors.take(3).map((e) => Text(
                      '• $e',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red[700],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFileItem(SharedFileItem file) {
    final isSelected = _selectedPaths.contains(file.path);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleSelection(file.path),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                // Thumbnail or icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: file.isImage
                      ? Image.file(
                          File(file.path),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFileIcon(file),
                        )
                      : _buildFileIcon(file),
                ),
                const SizedBox(width: 12),

                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.fileName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildFileTypeChip(file),
                          if (file.sizeBytes != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              _formatFileSize(file.sizeBytes!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Checkbox
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(file.path),
                  activeColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvalidFileItem(SharedFileItem file) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            // Error icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),

            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.fileName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.red[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file.errorMessage ?? 'Invalid file',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon(SharedFileItem file) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: file.isPdf
            ? Colors.red.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        file.isPdf ? Icons.picture_as_pdf : Icons.image,
        color: file.isPdf ? Colors.red : Colors.blue,
      ),
    );
  }

  Widget _buildFileTypeChip(SharedFileItem file) {
    final color = file.isPdf ? Colors.red : Colors.blue;
    final label = file.isPdf ? 'PDF' : 'Image';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

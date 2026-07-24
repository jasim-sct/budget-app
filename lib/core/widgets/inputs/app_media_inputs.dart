import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// File, Document, Image Attachment & Receipt Scanner Widget.
class FileUploadWidget extends StatefulWidget {
  final String label;
  final List<String> initialFiles;
  final ValueChanged<List<String>> onFilesChanged;

  const FileUploadWidget({
    super.key,
    this.label = 'ATTACH RECEIPT OR INVOICE',
    this.initialFiles = const [],
    required this.onFilesChanged,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  late List<String> _files;

  @override
  void initState() {
    super.initState();
    _files = List<String>.from(widget.initialFiles);
  }

  void _addSampleFile() {
    setState(() {
      _files.add('Receipt_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.pdf');
    });
    widget.onFilesChanged(_files);
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
    widget.onFilesChanged(_files);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTypography.sectionLabel(isDark)),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: _addSampleFile,
          borderRadius: AppRadius.borderSm,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
              borderRadius: AppRadius.borderSm,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Tap or drag files / receipt images here',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_files.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Column(
            children: _files.asMap().entries.map((entry) {
              final idx = entry.key;
              final fileName = entry.value;
              return Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 16, color: AppColors.primaryBlue),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 14),
                      onPressed: () => _removeFile(idx),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

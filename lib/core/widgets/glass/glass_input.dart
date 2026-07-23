import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/glass_tokens.dart';

/// Glassmorphic Text Input component with focus glow border and backdrop blur.
class GlassInput extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool isCurrency;
  final FocusNode? focusNode;

  const GlassInput({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.isCurrency = false,
    this.focusNode,
  });

  @override
  State<GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<GlassInput> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: AppTypography.labelSmall(isDark),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.borderMd,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: GlassTokens.blurMd, sigmaY: GlassTokens.blurMd),
            child: TextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              obscureText: _isObscured,
              keyboardType: widget.keyboardType,
              onChanged: widget.onChanged,
              validator: widget.validator,
              style: widget.isCurrency
                  ? AppTypography.currency(isDark, fontSize: 24)
                  : TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                      : AppColors.lightTextSecondary.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: isDark
                    ? GlassTokens.darkGlassSurface
                    : GlassTokens.lightGlassSurface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                prefixIcon: widget.isCurrency
                    ? Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8, top: 12),
                        child: Text(
                          '\$',
                          style: AppTypography.currency(isDark, fontSize: 22, color: AppColors.primaryEmerald),
                        ),
                      )
                    : widget.prefixIcon != null
                        ? Icon(widget.prefixIcon, size: 20, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                        : null,
                suffixIcon: widget.obscureText
                    ? IconButton(
                        icon: Icon(
                          _isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _isObscured = !_isObscured),
                      )
                    : widget.suffixIcon,
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.borderMd,
                  borderSide: BorderSide(
                    color: isDark ? GlassTokens.borderHighlightDark : GlassTokens.borderHighlightLight,
                    width: 1,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.borderMd,
                  borderSide: BorderSide(
                    color: AppColors.primaryEmerald,
                    width: 2,
                  ),
                ),
                errorBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.borderMd,
                  borderSide: BorderSide(
                    color: AppColors.expenseRed,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.borderMd,
                  borderSide: BorderSide(
                    color: AppColors.expenseRed,
                    width: 2,
                  ),
                ),
                errorText: widget.errorText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

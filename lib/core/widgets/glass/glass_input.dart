import 'package:flutter/material.dart';
import '../services/currency_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Professional text input – unified with AppTextField styling.
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
          widget.label,
          style: AppTypography.sectionLabel(isDark),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _isObscured,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          validator: widget.validator,
          style: widget.isCurrency
              ? AppTypography.currency(isDark, fontSize: 20)
              : TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.isCurrency
                ? ValueListenableBuilder<CurrencyOption>(
                    valueListenable: CurrencyProvider.instance,
                    builder: (context, currency, _) {
                      return Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm, top: 10),
                        child: Text(
                          currency.symbol,
                          style: AppTypography.currency(isDark, fontSize: 18, color: AppColors.primaryBlue),
                        ),
                      );
                    },
                  )
                : widget.prefixIcon != null
                    ? Icon(widget.prefixIcon, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                    : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  )
                : widget.suffixIcon,
            errorText: widget.errorText,
          ),
        ),
      ],
    );
  }
}

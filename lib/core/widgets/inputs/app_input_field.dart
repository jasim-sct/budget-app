import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/currency_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Enhanced text field with rich formatting, character counters, validation feedback, and keyboard actions.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool isCurrency;
  final FocusNode? focusNode;
  final int? maxLines;
  final int? maxLength;
  final bool showCounter;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.isCurrency = false,
    this.focusNode,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = false,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.textInputAction,
    this.onSubmitted,
    this.inputFormatters,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
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
        if (widget.label.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: AppTypography.sectionLabel(isDark),
              ),
              if (widget.showCounter && widget.maxLength != null && widget.controller != null)
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller!,
                  builder: (context, value, _) {
                    return Text(
                      '${value.text.length}/${widget.maxLength}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: value.text.length > widget.maxLength!
                            ? AppColors.expenseRed
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _isObscured,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          validator: widget.validator,
          maxLines: _isObscured ? 1 : widget.maxLines,
          maxLength: widget.showCounter ? widget.maxLength : null,
          buildCounter: widget.showCounter ? (_, {required currentLength, required isFocused, maxLength}) => null : null,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          onTap: widget.onTap,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          inputFormatters: widget.inputFormatters,
          style: widget.isCurrency
              ? AppTypography.currency(isDark, fontSize: 20)
              : TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.enabled
                      ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            helperStyle: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            prefixIcon: widget.isCurrency
                ? ValueListenableBuilder<CurrencyOption>(
                    valueListenable: CurrencyProvider.instance,
                    builder: (context, currency, _) {
                      return Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xs),
                        child: Center(
                          widthFactor: 1.0,
                          heightFactor: 1.0,
                          child: Text(
                            currency.symbol,
                            style: AppTypography.currency(isDark, fontSize: 18, color: AppColors.primaryBlue),
                          ),
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

/// Specialized Search Input Component with instant clear and live filtering callback.
class AppSearchInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final bool autoFocus;

  const AppSearchInput({
    super.key,
    required this.controller,
    this.hint = 'Search transactions, categories, wallets...',
    required this.onChanged,
    this.onClear,
    this.autoFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          autofocus: autoFocus,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel_rounded, size: 18),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                      if (onClear != null) onClear!();
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          ),
        );
      },
    );
  }
}

/// 4 or 6-Digit OTP / PIN Input Grid Component.
class AppPinOtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final bool obscure;

  const AppPinOtpInput({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.obscure = true,
  });

  @override
  State<AppPinOtpInput> createState() => _AppPinOtpInputState();
}

class _AppPinOtpInputState extends State<AppPinOtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _checkComplete() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            obscureText: widget.obscure,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTypography.headline(isDark).copyWith(fontSize: 22),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
            onChanged: (val) {
              if (val.isNotEmpty) {
                if (index < widget.length - 1) {
                  _focusNodes[index + 1].requestFocus();
                } else {
                  _focusNodes[index].unfocus();
                }
              } else if (index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
              _checkComplete();
            },
          ),
        );
      }),
    );
  }
}

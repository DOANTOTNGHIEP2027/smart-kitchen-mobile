import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors_extension.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_icons.dart';
import '../../utils/l10n_x.dart';

/// Ô nhập liệu dùng chung (design-system.md §7.6).
///
/// Label nằm trên ô (DESIGN_SYSTEM.md §3.2); viền/màu lấy từ
/// `inputDecorationTheme`. [errorText] từ bên ngoài (lỗi server) thắng kết quả
/// [validator] — truyền qua `forceErrorText` vì `TextFormField` để validator
/// thắng `InputDecoration.errorText`.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.hint,
    this.errorText,
    this.helperText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.prefixIcon,
    this.maxLines = 1,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.inputFormatters,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.autofocus = false,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? hint;
  final String? errorText;
  final String? helperText;

  /// `true` → ô mật khẩu, kèm nút ẩn/hiện.
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final IconData? prefixIcon;
  final int maxLines;
  final AutovalidateMode autovalidateMode;
  final List<TextInputFormatter>? inputFormatters;

  /// Giới hạn ký tự; bộ đếm bị ẩn (khớp DESIGN_SYSTEM §3.2).
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool autofocus;
  final bool readOnly;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.prefixIcon;
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    // Không dùng MergeSemantics: nó nuốt nút ẩn/hiện mật khẩu khỏi TalkBack
    // (code review M1). Label được gắn thẳng vào node của ô nhập.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: widget.enabled
                ? labelStyle
                : labelStyle?.copyWith(color: context.appColors.textDisabled),
          ),
        ),
        const SizedBox(height: AppDimens.xs),
        Semantics(
          label: widget.label,
          child: TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            forceErrorText: widget.errorText,
            autovalidateMode: widget.autovalidateMode,
            obscureText: _obscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            inputFormatters: widget.inputFormatters,
            maxLength: widget.maxLength,
            textCapitalization: widget.textCapitalization,
            autofillHints: widget.autofillHints,
            // Flutter không cho obscureText nhiều dòng.
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            decoration: InputDecoration(
              hintText: widget.hint,
              counterText: widget.maxLength == null ? null : '',
              helperText: widget.helperText,
              prefixIcon: prefix == null ? null : Icon(prefix),
              suffixIcon: widget.obscureText ? _visibilityToggle() : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _visibilityToggle() => IconButton(
        tooltip: _obscured
            ? context.l10n.commonShowPassword
            : context.l10n.commonHidePassword,
        icon: Icon(_obscured ? AppIcons.visibility : AppIcons.visibilityOff),
        onPressed: () => setState(() => _obscured = !_obscured),
      );
}

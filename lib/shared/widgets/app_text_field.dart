import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors_extension.dart';

class AppTextField extends StatefulWidget {
  final String hintText;
  final String? label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? maxLength;
  final bool digitsOnly;

  const AppTextField({
    super.key,
    required this.hintText,
    this.label,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.digitsOnly = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Widget? suffix = widget.suffixIcon;

    if (widget.obscureText && suffix == null) {
      suffix = IconButton(
        icon: Icon(
          _obscured ? CupertinoIcons.eye_fill : CupertinoIcons.eye_slash_fill,
          color: colors.textSecondary,
          size: 18,
        ),
        onPressed: () {
          setState(() {
            _obscured = !_obscured;
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.digitsOnly
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: colors.textHint,
            ),
            filled: true,
            fillColor: colors.bgAlt,
            prefixIcon: widget.prefixIcon,
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            counterText: '',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
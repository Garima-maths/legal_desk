import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:legal_desk/theme/app_theme.dart';

class LegalSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final int? resultCount;

  const LegalSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.resultCount,
  });

  @override
  State<LegalSearchBar> createState() => _LegalSearchBarState();
}

class _LegalSearchBarState extends State<LegalSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(value);
    });
  }

  void _clearSearch() {
    _controller.clear();
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = _controller.text.isNotEmpty;
    final bool showResultCount = widget.resultCount != null && hasText;

    final textField = TextField(
      controller: _controller,
      onChanged: _onTextChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(Icons.search, color: AppColors.muted),
        suffixIcon: hasText
            ? IconButton(
                icon: Icon(Icons.close, color: AppColors.muted),
                onPressed: _clearSearch,
              )
            : null,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.saffron, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );

    Widget content;
    if (showResultCount) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          textField,
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              '${widget.resultCount} result${widget.resultCount == 1 ? '' : 's'}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
            ),
          ),
        ],
      );
    } else {
      content = textField;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: content,
    );
  }
}

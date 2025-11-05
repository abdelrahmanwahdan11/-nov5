import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/utils/app_scope.dart';
import '../../controllers/display_controller.dart';

class SensitiveText extends StatefulWidget {
  const SensitiveText({
    super.key,
    required this.privacyListenable,
    required this.visibleText,
    this.hiddenText,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final ValueListenable<bool> privacyListenable;
  final String visibleText;
  final String? hiddenText;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<SensitiveText> createState() => _SensitiveTextState();
}

class _SensitiveTextState extends State<SensitiveText> {
  late bool _revealed;
  DisplayController? _displayController;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _revealed = !widget.privacyListenable.value;
    widget.privacyListenable.addListener(_handlePrivacyChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.maybeOf(context);
    final controller = scope?.displayController;
    if (_displayController == controller) {
      return;
    }
    _displayController?.reduceMotionNotifier.removeListener(_handleReduceMotion);
    _displayController = controller;
    _reduceMotion = controller?.reduceMotionNotifier.value ?? false;
    controller?.reduceMotionNotifier.addListener(_handleReduceMotion);
  }

  @override
  void didUpdateWidget(covariant SensitiveText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.privacyListenable != widget.privacyListenable) {
      oldWidget.privacyListenable.removeListener(_handlePrivacyChange);
      _revealed = !widget.privacyListenable.value;
      widget.privacyListenable.addListener(_handlePrivacyChange);
    }
  }

  @override
  void dispose() {
    widget.privacyListenable.removeListener(_handlePrivacyChange);
    _displayController?.reduceMotionNotifier.removeListener(_handleReduceMotion);
    super.dispose();
  }

  void _handlePrivacyChange() {
    if (!mounted) return;
    setState(() {
      _revealed = !widget.privacyListenable.value;
    });
  }

  void _handleReduceMotion() {
    if (!mounted) return;
    setState(() {
      _reduceMotion = _displayController?.reduceMotionNotifier.value ?? false;
    });
  }

  void _toggleReveal() {
    if (!widget.privacyListenable.value) {
      return;
    }
    setState(() {
      _revealed = !_revealed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isPrivacyEnabled = widget.privacyListenable.value;
    final isObscured = isPrivacyEnabled && !_revealed;
    final hiddenText = widget.hiddenText ?? '••••';
    final tooltip = isPrivacyEnabled
        ? _revealed
            ? t.translate('privacyTapToHide')
            : t.translate('privacyTapToReveal')
        : null;
    final semanticsLabel = isObscured
        ? t.translate('privacyHiddenLabel')
        : widget.visibleText;

    Widget content = AnimatedSwitcher(
      duration:
          _reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
      transitionBuilder: (child, animation) {
        if (_reduceMotion) {
          return child;
        }
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      child: Text(
        isObscured ? hiddenText : widget.visibleText,
        key: ValueKey<bool>(isObscured),
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      ),
    );

    if (tooltip != null) {
      content = Tooltip(message: tooltip, child: content);
    }

    return Semantics(
      button: isPrivacyEnabled,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: isPrivacyEnabled ? _toggleReveal : null,
        child: FocusableActionDetector(
          enabled: isPrivacyEnabled,
          mouseCursor: isPrivacyEnabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: content,
        ),
      ),
    );
  }
}

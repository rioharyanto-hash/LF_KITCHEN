import 'package:flutter/material.dart';

/// Custom Toast Notification - Premium Floating Toast
class CustomToast {
  static OverlayEntry? _currentToast;

  /// Show success toast at top center
  static void showSuccess({
    required BuildContext context,
    required String title,
    String? subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      title: title,
      subtitle: subtitle,
      icon: Icons.check,
      iconBackgroundColor: EmeraldColor.emerald.shade100,
      iconColor: EmeraldColor.emerald.shade600,
      borderColor: EmeraldColor.emerald.shade100,
      duration: duration,
    );
  }

  /// Show error toast at top center
  static void showError({
    required BuildContext context,
    required String title,
    String? subtitle,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context: context,
      title: title,
      subtitle: subtitle,
      icon: Icons.close,
      iconBackgroundColor: Colors.red.shade100,
      iconColor: Colors.red.shade600,
      borderColor: Colors.red.shade100,
      duration: duration,
    );
  }

  /// Show warning toast at top center
  static void showWarning({
    required BuildContext context,
    required String title,
    String? subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      title: title,
      subtitle: subtitle,
      icon: Icons.warning_amber_rounded,
      iconBackgroundColor: Colors.amber.shade100,
      iconColor: Colors.amber.shade700,
      borderColor: Colors.amber.shade100,
      duration: duration,
    );
  }

  /// Show info toast at top center
  static void showInfo({
    required BuildContext context,
    required String title,
    String? subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      title: title,
      subtitle: subtitle,
      icon: Icons.info_outline,
      iconBackgroundColor: Colors.blue.shade100,
      iconColor: Colors.blue.shade600,
      borderColor: Colors.blue.shade100,
      duration: duration,
    );
  }

  static void _show({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconBackgroundColor,
    required Color iconColor,
    required Color borderColor,
    required Duration duration,
  }) {
    // Remove existing toast if any
    _currentToast?.remove();
    _currentToast = null;

    final overlay = Overlay.of(context);

    _currentToast = OverlayEntry(
      builder: (context) => _ToastWidget(
        title: title,
        subtitle: subtitle,
        icon: icon,
        iconBackgroundColor: iconBackgroundColor,
        iconColor: iconColor,
        borderColor: borderColor,
        duration: duration,
        onDismiss: () {
          _currentToast?.remove();
          _currentToast = null;
        },
      ),
    );

    overlay.insert(_currentToast!);
  }

  /// Dismiss current toast immediately
  static void dismiss() {
    _currentToast?.remove();
    _currentToast = null;
  }
}

class _ToastWidget extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color borderColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.borderColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -20,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(opacity: _fadeAnimation.value, child: child),
          );
        },
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(minWidth: 320, maxWidth: 420),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? widget.borderColor.withValues(alpha: 0.3)
                      : widget.borderColor,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? widget.iconColor.withValues(alpha: 0.2)
                          : widget.iconBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close button
                  GestureDetector(
                    onTap: _dismiss,
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension to use emerald color (like Tailwind)
extension EmeraldColor on Colors {
  static MaterialColor get emerald =>
      const MaterialColor(0xFF10B981, <int, Color>{
        50: Color(0xFFECFDF5),
        100: Color(0xFFD1FAE5),
        200: Color(0xFFA7F3D0),
        300: Color(0xFF6EE7B7),
        400: Color(0xFF34D399),
        500: Color(0xFF10B981),
        600: Color(0xFF059669),
        700: Color(0xFF047857),
        800: Color(0xFF065F46),
        900: Color(0xFF064E3B),
      });
}

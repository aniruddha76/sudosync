import 'package:flutter/material.dart';

enum DialogType { success, error, warning, info }

class AppDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    String? message,
    DialogType type = DialogType.info,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return _DialogUI(
          title: title,
          message: message,
          type: type,
          actions: actions,
        );
      },
      transitionBuilder: (_, anim, __, child) {
        final scale = Tween(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  static Widget action(String text, VoidCallback onTap,
      {Color color = const Color(0xFFB6FF00)}) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DialogUI extends StatelessWidget {
  final String title;
  final String? message;
  final DialogType type;
  final List<Widget>? actions;

  const _DialogUI({
    required this.title,
    this.message,
    required this.type,
    this.actions,
  });

  IconData _getIcon() {
    switch (type) {
      case DialogType.success:
        return Icons.check_circle;
      case DialogType.error:
        return Icons.error;
      case DialogType.warning:
        return Icons.warning;
      case DialogType.info:
        return Icons.info;
    }
  }

  Color _getColor() {
    switch (type) {
      case DialogType.success:
        return Colors.green;
      case DialogType.error:
        return Colors.red;
      case DialogType.warning:
        return Colors.orange;
      case DialogType.info:
        return const Color(0xFFB6FF00);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getIcon(), color: color, size: 40),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                // textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: 10),
                Text(
                  message!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  // textAlign: TextAlign.center,
                ),
              ],
              if (actions != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Primary action button with clean, product-style visuals.
class BrutalButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final IconData? icon;
  final bool isPrimary;

  const BrutalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.icon,
    this.isPrimary = true,
  });

  @override
  State<BrutalButton> createState() => _BrutalButtonState();
}

class _BrutalButtonState extends State<BrutalButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final background = AppColors.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          boxShadow: _isPressed ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: widget.isLoading ? null : widget.onPressed,
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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

/// Icon button with subtle interaction feedback.
class BrutalIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final String? tooltip;
  final Color? color;
  final bool isPrimary;

  const BrutalIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 56,
    this.tooltip,
    this.color,
    this.isPrimary = false,
  });

  @override
  State<BrutalIconButton> createState() => _BrutalIconButtonState();
}

class _BrutalIconButtonState extends State<BrutalIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.color ?? (widget.isPrimary ? AppColors.primary : AppColors.surface);
    final iconColor = widget.isPrimary ? Colors.white : AppColors.textPrimary;

    final button = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
          boxShadow: _isPressed ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          widget.icon,
          color: iconColor,
          size: widget.size * 0.5,
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }
    return button;
  }
}

/// Outline button variant.
class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;

  const OutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;
    
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: buttonColor,
        side: BorderSide(color: buttonColor, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Text button variant
class TextActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;

  const TextActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primaryBlue;
    
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: buttonColor, size: 20),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: buttonColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

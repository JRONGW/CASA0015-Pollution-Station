import 'dart:ui';

import 'package:flutter/material.dart';

const Color kGlassButtonColor = Color(0xFFFFFFFF);
const double kGlassButtonHeight = 155;
const Color kGlassButtonGlowColor = Color(0xFFE8E8E8);

class GlassStyleButton extends StatefulWidget {
  const GlassStyleButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.subtitle,
    this.icon,
  });

  final VoidCallback onPressed;
  final String label;
  final String? subtitle;
  final IconData? icon;

  @override
  State<GlassStyleButton> createState() => _GlassStyleButtonState();
}

class _GlassStyleButtonState extends State<GlassStyleButton> {
  bool _hovering = false;
  bool _pressing = false;

  void _setHovering(bool value) {
    if (_hovering != value) setState(() => _hovering = value);
  }

  void _setPressing(bool value) {
    if (_pressing != value) setState(() => _pressing = value);
  }

  @override
  Widget build(BuildContext context) {
    final scale = (_hovering ? 1.02 : 1.0) * (_pressing ? 0.98 : 1.0);
    return MouseRegion(
      onEnter: (_) => _setHovering(true),
      onExit: (_) => _setHovering(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _setPressing(true),
        onTapUp: (_) => _setPressing(false),
        onTapCancel: () => _setPressing(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: SizedBox(
            height: kGlassButtonHeight,
            width: double.infinity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_hovering ? 0.1 : 0.06),
                    blurRadius: _hovering ? 16 : 12,
                    offset: Offset(0, _hovering ? 5 : 4),
                  ),
                  BoxShadow(
                    color: const Color.fromARGB(255, 251, 251, 251).withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: kGlassButtonColor.withOpacity(_hovering ? 0.22 : 0.28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  color: Colors.black38,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                              ],
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.label,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                    if (widget.subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.subtitle!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.black38, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

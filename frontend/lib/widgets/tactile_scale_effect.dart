import 'package:flutter/material.dart';

class TactileScaleEffect extends StatefulWidget {
  final Widget child;
  final double scaleDownTo;
  final bool enabled;

  const TactileScaleEffect({
    super.key,
    required this.child,
    this.scaleDownTo = 0.95,
    this.enabled = true,
  });

  @override
  State<TactileScaleEffect> createState() => _TactileScaleEffectState();
}

class _TactileScaleEffectState extends State<TactileScaleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDownTo).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(TactileScaleEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _controller.value > 0.0) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (widget.enabled) {
          _controller.forward();
        }
      },
      onPointerUp: (event) {
        if (widget.enabled) {
          _controller.reverse();
        }
      },
      onPointerCancel: (event) {
        if (widget.enabled) {
          _controller.reverse();
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

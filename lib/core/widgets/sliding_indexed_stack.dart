import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Slides complete, already-mounted destinations as one visual layer.
///
/// Every child stays mounted offstage, so switching tabs does not expose a
/// half-built destination or discard scroll/form state. Only the two complete
/// page layers participating in the transition are painted.
class SlidingIndexedStack extends StatefulWidget {
  const SlidingIndexedStack({
    required this.index,
    required this.children,
    super.key,
  });

  final int index;
  final List<Widget> children;

  @override
  State<SlidingIndexedStack> createState() => _SlidingIndexedStackState();
}

class _SlidingIndexedStackState extends State<SlidingIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _outgoingIndex;
  var _direction = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.standard,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(SlidingIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    _direction = widget.index > oldWidget.index ? 1 : -1;
    if (context.animationsReduced) {
      _outgoingIndex = null;
      _controller.value = 1;
      return;
    }
    _outgoingIndex = oldWidget.index;
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _outgoingIndex = null);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => ClipRect(
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            for (final (childIndex, child) in widget.children.indexed)
              Offstage(
                offstage:
                    childIndex != widget.index && childIndex != _outgoingIndex,
                child: TickerMode(
                  enabled: childIndex == widget.index,
                  child: ExcludeSemantics(
                    excluding: childIndex != widget.index,
                    child: IgnorePointer(
                      ignoring: childIndex != widget.index,
                      child: FractionalTranslation(
                        translation: _translationFor(childIndex),
                        child: RepaintBoundary(child: child),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Offset _translationFor(int childIndex) {
    final progress = AppMotion.standardCurve.transform(_controller.value);
    if (childIndex == widget.index) {
      return Offset(_direction * (1 - progress), 0);
    }
    if (childIndex == _outgoingIndex) {
      return Offset(-_direction * progress, 0);
    }
    return Offset.zero;
  }
}

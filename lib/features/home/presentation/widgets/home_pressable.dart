import 'package:flutter/material.dart';
import 'package:port/features/home/presentation/widgets/home_entrance.dart';

/// A small physical response shared by the journal's shortcuts and books.
class HomePressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  final BorderSide side;
  final BorderRadius borderRadius;
  final int entranceOrder;
  const HomePressable({
    super.key,
    required this.child,
    required this.onTap,
    required this.color,
    this.side = BorderSide.none,
    this.entranceOrder = 0,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  @override
  State<HomePressable> createState() => _HomePressableState();
}

class _HomePressableState extends State<HomePressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => HomeEntrance(
    order: widget.entranceOrder,
    child: AnimatedScale(
      scale: _pressed && !MediaQuery.disableAnimationsOf(context) ? .97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: widget.color,
        shape: RoundedRectangleBorder(
          borderRadius: widget.borderRadius,
          side: widget.side,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: widget.child,
        ),
      ),
    ),
  );
}

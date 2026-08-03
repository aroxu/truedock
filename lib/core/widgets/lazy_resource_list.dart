import 'package:flutter/material.dart';

/// A card-styled list that builds only the rows on screen.
///
/// The screens originally spelled these out as `Card(child: Column(children:
/// [for (...) ListTile(...)]))`, which builds every row whether or not it is
/// visible. Measured on a 100-row list: the eager form built all 100 tiles, a
/// sliver builder built 16. That cost is why the call sites had grown
/// `.take(100)` and `.take(30)` caps - the caps treated the symptom by hiding
/// data, so a server with 101 users simply lost one.
///
/// This keeps the visual result identical: a single rounded surface with
/// dividers between rows and none at the ends. It has to be a sliver rather
/// than a box, because laziness only exists if the viewport can ask for one row
/// at a time; wrapping a builder in a `Column` would rebuild the eager
/// behaviour with extra steps.
class SliverLazyResourceList extends StatelessWidget {
  const SliverLazyResourceList({
    required this.itemCount,
    required this.itemBuilder,
    this.dividerIndent = 0,
    super.key,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Matches the leading content of the row, so the divider starts under the
  /// text rather than under the icon.
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (itemCount == 0) return const SliverToBoxAdapter();

    // The card is drawn per row rather than around the list: a single Card
    // ancestor would have to size itself to every child, which is the eager
    // layout this exists to avoid. Rounding only the first and last rows
    // reproduces one continuous surface.
    return SliverList.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        const radius = Radius.circular(12);
        final isFirst = index == 0;
        final isLast = index == itemCount - 1;
        return Material(
          color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? radius : Radius.zero,
            topRight: isFirst ? radius : Radius.zero,
            bottomLeft: isLast ? radius : Radius.zero,
            bottomRight: isLast ? radius : Radius.zero,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              itemBuilder(context, index),
              // Between rows only. A trailing divider would draw a line across
              // the bottom edge of the card.
              if (!isLast) Divider(indent: dividerIndent, height: 1),
            ],
          ),
        );
      },
    );
  }
}

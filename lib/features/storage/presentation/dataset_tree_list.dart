import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../resources/domain/server_resources.dart';

typedef DatasetTreeItemBuilder =
    Widget Function(
      BuildContext context,
      Dataset dataset,
      bool hasChildren,
      bool isExpanded,
      VoidCallback? onToggle,
    );

/// A collapsible view of datasets derived from their slash-separated names.
class DatasetTreeList extends StatefulWidget {
  const DatasetTreeList({
    required this.datasets,
    required this.itemBuilder,
    super.key,
  });

  final List<Dataset> datasets;
  final DatasetTreeItemBuilder itemBuilder;

  @override
  State<DatasetTreeList> createState() => _DatasetTreeListState();
}

class _DatasetTreeListState extends State<DatasetTreeList> {
  final Set<String> _expanded = {};

  @override
  void didUpdateWidget(DatasetTreeList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIds = widget.datasets.map((dataset) => dataset.id).toSet();
    _expanded.removeWhere((id) => !currentIds.contains(id));
  }

  @override
  Widget build(BuildContext context) {
    final children = _childrenByParent();
    final visible = _visibleDatasets(children);

    return Card(
      child: AnimatedSize(
        duration: context.motionDuration(AppMotion.standard),
        curve: AppMotion.standardCurve,
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            for (final (index, dataset) in visible.indexed) ...[
              widget.itemBuilder(
                context,
                dataset,
                children[dataset.name]?.isNotEmpty == true,
                _expanded.contains(dataset.id),
                children[dataset.name]?.isNotEmpty == true
                    ? () => setState(() {
                        if (!_expanded.add(dataset.id)) {
                          _expanded.remove(dataset.id);
                        }
                      })
                    : null,
              ),
              if (index < visible.length - 1)
                const Divider(indent: 68, height: 1),
            ],
          ],
        ),
      ),
    );
  }

  List<Dataset> _visibleDatasets(Map<String, List<Dataset>> children) {
    final visible = <Dataset>[];

    void append(Dataset dataset) {
      visible.add(dataset);
      if (!_expanded.contains(dataset.id)) return;
      for (final child in children[dataset.name] ?? const <Dataset>[]) {
        append(child);
      }
    }

    for (final root in _roots()) {
      append(root);
    }
    return visible;
  }

  Map<String, List<Dataset>> _childrenByParent() {
    final children = <String, List<Dataset>>{};
    final names = widget.datasets.map((dataset) => dataset.name).toSet();
    for (final dataset in widget.datasets) {
      final parent = _parentName(dataset.name);
      if (parent == null || !names.contains(parent)) continue;
      (children[parent] ??= []).add(dataset);
    }
    return children;
  }

  List<Dataset> _roots() {
    final names = widget.datasets.map((dataset) => dataset.name).toSet();
    return widget.datasets
        .where((dataset) => !names.contains(_parentName(dataset.name)))
        .toList();
  }

  String? _parentName(String name) {
    final separator = name.lastIndexOf('/');
    return separator < 0 ? null : name.substring(0, separator);
  }
}

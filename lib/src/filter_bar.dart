part of 'paged_datatable.dart';

/// The filter bar is displayed before the table header
class _FilterBar<K extends Comparable<K>, T> extends StatefulWidget {
  const _FilterBar();

  @override
  State<StatefulWidget> createState() => _FilterBarState<K, T>();
}

class _FilterBarState<K extends Comparable<K>, T> extends State<_FilterBar<K, T>> {
  late final theme = PagedDataTableTheme.of(context);
  late final controller = TableControllerProvider.of<K, T>(context);

  final chipsListController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    controller.addListener(_onChanged);
  }

  @override
  Widget build(BuildContext context) {
    // var localizations = PagedDataTableLocalization.of(context);

    Widget child = SizedBox(
      height: theme.filterBarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                /* FILTER BUTTON */
                if (controller._filtersState.isNotEmpty)
                  Container(
                    padding: theme.cellPadding,
                    margin: theme.padding,
                    child: Ink(
                      child: InkWell(
                        radius: 20,
                        child: Tooltip(
                          message: "Filter values",
                          child: MouseRegion(
                            cursor:
                                controller._state == _TableState.fetching ? SystemMouseCursors.basic : SystemMouseCursors.click,
                            child: GestureDetector(
                              onTapDown: controller._state == _TableState.fetching
                                  ? null
                                  : (details) => _showFilterOverlay(details, context),
                              child: const Icon(Icons.filter_list_rounded),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                /* SELECTED FILTERS */
                Expanded(
                  child: Scrollbar(
                    controller: chipsListController,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: chipsListController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: controller._filtersState.values
                            .where((element) => element.value != null)
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Chip(
                                  deleteIcon: const Icon(
                                    Icons.close,
                                    size: 20,
                                  ),
                                  deleteButtonTooltipMessage: "Remove filter", //localizations.removeFilterButtonText,
                                  onDeleted: () {
                                    controller.removeFilter(e._filter.id);
                                  },
                                  label: Text((e._filter as dynamic).chipFormatter(e.value)),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Flexible(
            child: Row(
              children: [
                // if (header != null) ...[const Spacer(), Flexible(child: header!)] else const Spacer(),

                // /* MENU */
                // if (menu != null)
                //   IconButton(
                //     splashRadius: 20,
                //     padding: const EdgeInsets.symmetric(horizontal: 16),
                //     tooltip: menu!.tooltip,
                //     icon: Icon(Icons.more_vert, color: theme.buttonsColor),
                //     onPressed: () {
                //       _showMenu(context: context, items: menu!.items);
                //     },
                //   )
              ],
            ),
          )
        ],
      ),
    );

    // if (theme.headerBackgroundColor != null) {
    //   child = DecoratedBox(
    //     decoration: BoxDecoration(color: theme.headerBackgroundColor),
    //     child: child,
    //   );
    // }

    // if (theme.chipTheme != null) {
    //   child = ChipTheme(
    //     data: theme.chipTheme!,
    //     child: child,
    //   );
    // }

    // if (theme.filtersHeaderTextStyle != null) {
    //   child = DefaultTextStyle(style: theme.filtersHeaderTextStyle!, child: child);
    // }

    return child;
  }

  Future<void> _showFilterOverlay(TapDownDetails details, BuildContext context) async {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    var offset = renderBox.localToGlobal(Offset.zero);
    var size = renderBox.size;

    var rect = RelativeRect.fromLTRB(offset.dx + 10, offset.dy + size.height - 10, 0, 0);

    await showDialog(
      context: context,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) => _FiltersDialog<K, T>(
        rect: rect,
        tableController: controller,
      ),
    );
  }

  void _onChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    chipsListController.dispose();
    controller.removeListener(_onChanged);
  }
}

class _FiltersDialog<K extends Comparable<K>, T> extends StatelessWidget {
  final RelativeRect rect;
  final TableController<K, T> tableController;

  const _FiltersDialog({required this.rect, required this.tableController});

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final bool isBottomSheet = mediaWidth < 1000; // TODO: add configurable breakpoint

    final filtersList = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
      child: Form(
        key: tableController._filtersFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Filter by", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...tableController._filtersState.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: entry.value._filter.buildPicker(context, entry.value),
              ),
            )
          ],
        ),
      ),
    );

    final buttons = Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20)),
            onPressed: () {
              Navigator.pop(context);
              tableController.removeFilters();
            },
            child: const Text("Remove all filters"),
          ),
          const Spacer(),
          TextButton(
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20)),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20)),
            onPressed: () {
              // to ensure onSaved is called on filters
              tableController._filtersFormKey.currentState!.save();
              Navigator.pop(context);
              tableController.applyFilters();
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );

    return Stack(
      fit: StackFit.loose,
      children: [
        Positioned(
          top: rect.top,
          left: rect.left,
          child: Container(
            width: mediaWidth / 3,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 3, color: Colors.black54)],
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            child: Material(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
              elevation: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  filtersList,
                  const Divider(height: 0, color: Color(0xFFD6D6D6)),
                  buttons,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

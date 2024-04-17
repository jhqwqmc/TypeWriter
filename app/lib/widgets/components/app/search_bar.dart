import "package:auto_size_text/auto_size_text.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:text_scroll/text_scroll.dart";
import "package:typewriter/utils/debouncer.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/entry_search.dart";
import "package:typewriter/widgets/components/app/page_search.dart";
import "package:typewriter/widgets/components/general/context_menu_region.dart";
import "package:typewriter/widgets/components/general/decorated_text_field.dart";
import "package:typewriter/widgets/components/general/focused_notifier.dart";
import "package:typewriter/widgets/components/general/shortcut_label.dart";

part "search_bar.freezed.dart";
part "search_bar.g.dart";

/// When the user wants to search for nodes.
class SearchIntent extends Intent {}

class ActivateActionIntent extends Intent {
  const ActivateActionIntent(this.shortcut);

  final ShortcutActivator shortcut;
}

@freezed
class Search with _$Search {
  const factory Search({
    @Default("") String query,
    @Default([]) List<SearchFetcher> fetchers,
    @Default([]) List<SearchFilter> filters,
    Function()? onEnd,
  }) = _Search;
}

class SearchNotifier extends StateNotifier<Search?> {
  SearchNotifier(this.ref) : super(null) {
    _debouncer = Debouncer<String>(duration: 200.ms, callback: _updateQuery);
  }

  final Ref ref;
  late Debouncer<String> _debouncer;

  // ignore: use_setters_to_change_properties
  void start(Search search) {
    state = search;
  }

  SearchBuilder asBuilder() {
    return SearchBuilder(this);
  }

  void startGlobalSearch() => asBuilder()
    ..fetchNewEntry()
    ..fetchEntry()
    ..fetchPage()
    ..fetchAddPage()
    ..open();

  void startAddSearch() => asBuilder()
    ..fetchNewEntry()
    ..fetchAddPage()
    ..open();

  void endSearch() {
    state?.onEnd?.call();
    state = null;
    _debouncer.cancel();
  }

  void updateQuery(String query) {
    _debouncer.run(query);
  }

  void _updateQuery(String query) {
    state = state!.copyWith(query: query);
  }

  void toggleFetcher(SearchFetcher fetcher) {
    final fetchers = state?.fetchers;
    if (fetchers == null) return;
    final newFetchers = fetchers.map((f) {
      if (f.runtimeType == fetcher.runtimeType) {
        return f.copyWith(disabled: !f.disabled);
      }
      return f;
    }).toList();
    state = state!.copyWith(fetchers: newFetchers);
  }

  void removeFilter(SearchFilter filter) {
    state = state!
        .copyWith(filters: state!.filters.where((f) => f != filter).toList());
  }

  @override
  void dispose() {
    _debouncer.cancel();
    super.dispose();
  }
}

abstract class SearchFilter {
  const SearchFilter();

  bool get canRemove;
  String get title;
  Color get color;
  IconData get icon;

  bool filter(SearchElement action) {
    return true;
  }
}

abstract class SearchFetcher {
  const SearchFetcher();

  bool get disabled;
  String get title;
  IconData get icon => FontAwesomeIcons.magnifyingGlass;
  Color get color => Colors.blueAccent;

  List<SearchElement> fetch(PassingRef ref) {
    return [];
  }

  SearchFetcher copyWith({
    bool? disabled,
  });
}

final searchProvider = StateNotifierProvider<SearchNotifier, Search?>(
  SearchNotifier.new,
  name: "searchProvider",
);

class SearchBuilder {
  SearchBuilder(this.notifier);

  var _currentSearch = const Search();
  final SearchNotifier notifier;

  void query(String query) {
    _currentSearch = _currentSearch.copyWith(query: query);
  }

  void filters(List<SearchFilter> filters) {
    _currentSearch = _currentSearch.copyWith(filters: filters);
  }

  void filter(SearchFilter filter) {
    _currentSearch =
        _currentSearch.copyWith(filters: [..._currentSearch.filters, filter]);
  }

  void fetch(SearchFetcher fetcher) {
    _currentSearch = _currentSearch
        .copyWith(fetchers: [..._currentSearch.fetchers, fetcher]);
  }

  void open() {
    notifier.start(_currentSearch);
  }
}

@riverpod
List<SearchFetcher> searchFetchers(SearchFetchersRef ref) {
  final search = ref.watch(searchProvider);
  if (search == null) return [];
  return search.fetchers;
}

@riverpod
List<SearchFilter> searchFilters(SearchFiltersRef ref) {
  final search = ref.watch(searchProvider);
  if (search == null) return [];
  return search.filters;
}

@riverpod
List<SearchElement> searchElements(SearchElementsRef ref) {
  final search = ref.watch(searchProvider);
  if (search == null) return [];

  final fetchers = search.fetchers.where((f) => !f.disabled);
  final actions = fetchers.expand((f) => f.fetch(ref.passing));
  final filtered =
      actions.where((e) => search.filters.every((f) => f.filter(e)));

  return filtered.take(30).toList();
}

@riverpod
List<GlobalKey> searchGlobalKeys(SearchGlobalKeysRef ref) {
  final elements = ref.watch(searchElementsProvider);
  return elements.map((e) => GlobalKey(debugLabel: e.title)).toList();
}

@riverpod
List<FocusNode> searchFocusNodes(SearchFocusNodesRef ref) {
  final actionsCount =
      ref.watch(searchElementsProvider.select((value) => value.length));
  return List.generate(actionsCount, (_) => FocusNode());
}

@riverpod
SearchElement? _focusedElement(_FocusedElementRef ref) {
  final elements = ref.watch(searchElementsProvider);
  final focusNodes = ref.watch(searchFocusNodesProvider);

  final focusedIndex = focusNodes.indexWhere((node) => node.hasFocus);
  if (focusedIndex == -1) return null;

  return elements[focusedIndex];
}

@riverpod
Set<ShortcutActivator> _searchActionShortcuts(_SearchActionShortcutsRef ref) {
  final elements = ref.watch(searchElementsProvider);
  final activators = elements
      .expand((e) => e.actions(ref.passing))
      .where((a) => a.onTrigger != null)
      .map((a) => a.shortcut)
      .toSet();
  return activators;
}

class SearchAction {
  const SearchAction(
    this.name,
    this.icon,
    this.shortcut, {
    this.color,
    this.onTrigger,
  });

  final String name;
  final IconData icon;
  final ShortcutActivator shortcut;
  final Color? color;
  final FutureOr<bool> Function(BuildContext, PassingRef ref)? onTrigger;
}

abstract class SearchElement {
  const SearchElement();

  String get title;

  Color color(BuildContext context);

  Widget icon(BuildContext context);

  Widget suffixIcon(BuildContext context);

  String description(BuildContext context);

  List<SearchAction> actions(PassingRef ref);

  /// Runs when the element is activated.
  ///
  /// Returns true if the search should be closed.
  Future<bool> activate(BuildContext context, PassingRef ref);
}

class SearchBar extends HookConsumerWidget {
  const SearchBar({
    super.key,
  });

  Future<void> _activateItem(
    List<SearchElement> actions,
    int index,
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (index >= actions.length) return;
    if (index < 0) return;
    final canEnd = await actions[index].activate(context, ref.passing);
    if (canEnd) ref.read(searchProvider.notifier).endSearch();
  }

  /// Change focus to the next/previous search result.
  void _changeFocus(
    BuildContext context,
    PassingRef ref,
    int index,
  ) {
    final focusNodes = ref.read(searchFocusNodesProvider);
    final keys = ref.read(searchGlobalKeysProvider);
    FocusScope.of(context).requestFocus(focusNodes[index]);
    ref.invalidate(_focusedElementProvider);

    final indexContext = keys[index].currentContext;
    if (indexContext == null) return;
    Scrollable.ensureVisible(
      indexContext,
      alignment: 0.5,
      duration: 300.ms,
    );
  }

  void _changeFocusUp(BuildContext context, PassingRef ref) {
    final focusNodes = ref.read(searchFocusNodesProvider);
    var index = focusNodes.indexWhere((n) => n.hasFocus);
    if (index == -1) index = 0;

    index = (index - 1 + focusNodes.length) % focusNodes.length;
    _changeFocus(context, ref, index);
  }

  void _changeFocusDown(BuildContext context, PassingRef ref) {
    final focusNodes = ref.read(searchFocusNodesProvider);
    var index = focusNodes.indexWhere((n) => n.hasFocus);

    index = (index + 1) % focusNodes.length;

    _changeFocus(context, ref, index);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortcuts = ref.watch(_searchActionShortcutsProvider);

    return Shortcuts(
      shortcuts: {
        for (final shortcut in shortcuts)
          shortcut: ActivateActionIntent(shortcut),
      },
      child: Stack(
        children: [
          const _Barrier(),
          Actions(
            actions: {
              DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
                onInvoke: (intent) => intent.direction == TraversalDirection.up
                    ? _changeFocusUp(
                        context,
                        ref.passing,
                      )
                    : _changeFocusDown(
                        context,
                        ref.passing,
                      ),
              ),
              NextFocusIntent: CallbackAction<NextFocusIntent>(
                onInvoke: (intent) => _changeFocusDown(context, ref.passing),
              ),
              PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
                onInvoke: (intent) => _changeFocusUp(context, ref.passing),
              ),
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (intent) =>
                    ref.read(searchProvider.notifier).endSearch(),
              ),
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (intent) => _activateItem(
                  ref.read(searchElementsProvider),
                  ref
                      .read(searchFocusNodesProvider)
                      .indexWhere((n) => n.hasFocus),
                  context,
                  ref,
                ),
              ),
            },
            child: const Center(
              child: _Modal(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Barrier extends HookConsumerWidget {
  const _Barrier();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearching =
        ref.watch(searchProvider.select((value) => value != null));

    return Positioned.fill(
      child: ModalBarrier(
        dismissible: true,
        color: Colors.black.withOpacity(0.5),
        onDismiss: () {
          ref.read(searchProvider.notifier).endSearch();
        },
      )
          .animate(target: isSearching ? 1 : 0)
          .visibility(end: true, maintain: false, duration: 1.ms)
          .then()
          .fadeIn(duration: 300.ms),
    );
  }
}

class _Modal extends HookConsumerWidget {
  const _Modal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearching =
        ref.watch(searchProvider.select((value) => value != null));

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 500),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchFilters(),
                SizedBox(height: 12),
                _SearchBar(),
                SizedBox(height: 12),
                _SearchResults(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _SearchActions(),
        ],
      )
          .animate(target: isSearching ? 1 : 0)
          .visibility(end: true, maintain: false, duration: 1.ms)
          .then()
          .scaleXY(duration: 200.ms, begin: 0.9, curve: Curves.easeOut)
          .fadeIn(),
    );
  }
}

class _SearchFilters extends HookConsumerWidget {
  const _SearchFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fetchers = ref.watch(searchFetchersProvider);
    final filters = ref.watch(searchFiltersProvider);

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).cardColor,
          child: FaIcon(
            FontAwesomeIcons.filter,
            color: Theme.of(context).iconTheme.color,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            direction: Axis.horizontal,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final fetcher in fetchers)
                Material(
                  color: fetcher.disabled
                      ? Theme.of(context).cardColor
                      : fetcher.color,
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    onTap: () => ref
                        .read(searchProvider.notifier)
                        .toggleFetcher(fetcher),
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            fetcher.icon,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            fetcher.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              for (final filter in filters)
                Material(
                  color: filter.color,
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          filter.icon,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          filter.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (filter.canRemove) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            iconSize: 12,
                            splashRadius: 12,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              maxHeight: 24,
                              maxWidth: 24,
                            ),
                            onPressed: () => ref
                                .read(searchProvider.notifier)
                                .removeFilter(filter),
                            icon: const FaIcon(
                              FontAwesomeIcons.xmark,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends HookConsumerWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(searchProvider);
    final controller = useTextEditingController(text: search?.query ?? "");
    final focusNode = useFocusNode();

    useEffect(
      () {
        focusNode.requestFocus();

        void listener() {
          ref.invalidate(_focusedElementProvider);
        }

        focusNode.addListener(listener);
        return () => focusNode.removeListener(listener);
      },
      [focusNode],
    );

    return Material(
      elevation: 3.0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          FaIcon(
            FontAwesomeIcons.magnifyingGlass,
            color: Theme.of(context).iconTheme.color,
          ),
          Expanded(
            child: DecoratedTextField(
              controller: controller,
              focus: focusNode,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "输入搜索查询...",
                border: InputBorder.none,
                filled: false,
              ),
              onChanged: (query) =>
                  ref.read(searchProvider.notifier).updateQuery(query),
              onSubmitted: (query) =>
                  ref.read(searchProvider.notifier).endSearch(),
            ),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.xmark),
            onPressed: () => ref.read(searchProvider.notifier).endSearch(),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _SearchResults extends HookConsumerWidget {
  const _SearchResults();

  Future<void> _activateItem(
    List<SearchElement> actions,
    int index,
    BuildContext context,
    PassingRef ref,
  ) async {
    if (index >= actions.length) return;
    if (index < 0) return;
    final canEnd = await actions[index].activate(context, ref);
    if (canEnd) ref.read(searchProvider.notifier).endSearch();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elements = ref.watch(searchElementsProvider);
    final focusNodes = ref.watch(searchFocusNodesProvider);
    final globalKeys = ref.watch(searchGlobalKeysProvider);

    return Flexible(
      child: ClipPath(
        clipper: const VerticalClipper(additionalWidth: 100),
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < elements.length; i++)
                _ResultTile(
                  key: globalKeys[i],
                  onPressed: () =>
                      _activateItem(elements, i, context, ref.passing),
                  focusNode: focusNodes[i],
                  title: elements[i].title,
                  color: elements[i].color(context),
                  description: elements[i].description(context),
                  icon: elements[i].icon(context),
                  suffixIcon: elements[i].suffixIcon(context),
                  actions: elements[i].actions(ref.passing),
                ),
            ]
                .animate(interval: 50.ms)
                .scaleXY(
                  begin: 0.9,
                  curve: Curves.elasticOut,
                  duration: 1.seconds,
                )
                .fadeIn(duration: 500.ms),
          ),
        ),
      ),
    );
  }
}

class VerticalClipper extends CustomClipper<Path> {
  const VerticalClipper({this.additionalWidth = 0});

  final double additionalWidth;

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(-additionalWidth, 0)
      ..lineTo(size.width + additionalWidth, 0)
      ..lineTo(size.width + additionalWidth, size.height)
      ..lineTo(-additionalWidth, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    if (oldClipper is VerticalClipper) {
      return oldClipper.additionalWidth != additionalWidth;
    }
    return true;
  }
}

class _ResultTile extends HookConsumerWidget {
  const _ResultTile({
    required this.focusNode,
    required this.onPressed,
    this.color = Colors.white,
    this.icon = const Icon(Icons.search),
    this.suffixIcon = const Icon(Icons.arrow_forward_ios),
    this.title = "",
    this.description = "",
    this.actions = const [],
    super.key,
  });
  final FocusNode focusNode;
  final VoidCallback onPressed;

  final Color color;
  final Widget icon;
  final Widget suffixIcon;
  final String title;
  final String description;
  final List<SearchAction> actions;

  Future<void> _invokeAction(
    BuildContext context,
    PassingRef ref,
    ActivateActionIntent intent,
  ) async {
    final action = actions
        .firstWhereOrNull((action) => action.shortcut == intent.shortcut);
    if (action == null) return;
    final canEnd = await action.onTrigger?.call(context, ref) ?? false;
    if (canEnd) ref.read(searchProvider.notifier).endSearch();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = useState(false);
    final hover = useState(false);
    return ContextMenuRegion(
      builder: (context) {
        return [
          for (final action
              in actions.where((action) => action.onTrigger != null))
            ContextMenuTile.button(
              title: action.name,
              icon: action.icon,
              color: action.color,
              onTap: () => action.onTrigger!(context, ref.passing),
            ),
        ];
      },
      child: Actions(
        actions: {
          ActivateActionIntent: CallbackAction<ActivateActionIntent>(
            onInvoke: (intent) => _invokeAction(context, ref.passing, intent),
          ),
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Material(
              color: Theme.of(context).cardColor,
              elevation: 2,
              child: AnimatedContainer(
                duration: 200.ms,
                curve: Curves.fastLinearToSlowEaseIn,
                height: 56.0,
                width: 400,
                color:
                    focused.value ? color.withOpacity(0.6) : Colors.transparent,
                child: Focus(
                  focusNode: focusNode,
                  autofocus: true,
                  canRequestFocus: true,
                  onFocusChange: (f) => focused.value = f,
                  child: FocusedNotifier(
                    focusNode: focusNode,
                    child: InkWell(
                      canRequestFocus: false,
                      onTap: onPressed,
                      onHover: (h) => hover.value = h,
                      child: Row(
                        children: [
                          Container(
                            height: double.infinity,
                            color:
                                color.withOpacity(color.opacity.clamp(0, 0.8)),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: IconTheme(
                                data: const IconThemeData(color: Colors.white),
                                child: icon,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  maxLines: 1,
                                  title,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color:
                                            focused.value ? Colors.white : null,
                                        fontWeight: focused.value
                                            ? FontWeight.bold
                                            : null,
                                      ),
                                ),
                                if (focused.value || hover.value)
                                  TextScroll(
                                    description,
                                    delayBefore: 1.seconds,
                                    pauseBetween: 3.seconds,
                                    intervalSpaces: 5,
                                    velocity: const Velocity(
                                      pixelsPerSecond: Offset(30, 0),
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: focused.value
                                              ? Colors.white
                                              : null,
                                          fontWeight: focused.value
                                              ? FontWeight.bold
                                              : null,
                                        ),
                                  )
                                else
                                  AutoSizeText(
                                    maxLines: 1,
                                    description,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: focused.value
                                              ? Colors.white
                                              : null,
                                          fontWeight: focused.value
                                              ? FontWeight.bold
                                              : null,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconTheme(
                            data: IconThemeData(
                              size: 14,
                              color: focused.value ? Colors.white : Colors.grey,
                            ),
                            child: suffixIcon,
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
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

@riverpod
List<SearchAction> _searchActions(_SearchActionsRef ref) {
  final focusedElement = ref.watch(_focusedElementProvider);

  return focusedElement?.actions(ref.passing) ?? [];
}

class _SearchActions extends HookConsumerWidget {
  const _SearchActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(_searchActionsProvider);

    if (actions.isEmpty) {
      return const SizedBox(height: 50);
    }

    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "执行",
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in actions) _SearchBarAction(action: action),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).animate().scaleXY(
          duration: 500.ms,
          begin: 0.95,
          end: 1,
          curve: Curves.elasticOut,
        );
  }
}

class _SearchBarAction extends HookConsumerWidget {
  const _SearchBarAction({required this.action});

  final SearchAction action;

  Future<void> _invokeAction(
    BuildContext context,
    PassingRef ref,
  ) async {
    final canEnd = await action.onTrigger?.call(context, ref) ?? false;
    if (canEnd) ref.read(searchProvider.notifier).endSearch();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borderColor = action.color ?? Theme.of(context).dividerColor;
    return Material(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: borderColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: action.onTrigger != null
            ? () => _invokeAction(context, ref.passing)
            : null,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                action.icon,
                color: borderColor,
                size: 12,
              ),
              const SizedBox(width: 8),
              Text(action.name),
              const SizedBox(width: 6),
              ShortcutLabel(activator: action.shortcut),
            ],
          ),
        ),
      ),
    );
  }
}

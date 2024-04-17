import "package:flutter/material.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/header.dart";

class AddHeaderAction extends HookConsumerWidget {
  const AddHeaderAction({
    required this.path,
    required this.onAdd,
    super.key,
  }) : super();

  final String path;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(FontAwesomeIcons.plus, size: 16),
      tooltip: "添加新的 ${ref.watch(pathDisplayNameProvider(path)).singular}",
      onPressed: () {
        onAdd();
        // If we add a new item, we probably want to edit it.
        Header.of(context)?.expanded.value = true;
      },
    );
  }
}

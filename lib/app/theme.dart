import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// NexDesk's own blue, used until the workspace's brand colour is known.
const nexDeskSeed = Color(0xFF0B57D0);

/// The workspace's brand colour (16.5 loads it after sign-in); null means NexDesk's default.
class BrandColor extends Notifier<Color?> {
  @override
  Color? build() => null;

  // A setter would read oddly at call sites (`notifier.state = ...` from outside is discouraged).
  // ignore: use_setters_to_change_properties
  void set(Color? color) => state = color;
}

final brandColorProvider = NotifierProvider<BrandColor, Color?>(BrandColor.new);

ThemeData buildTheme(Color seed, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}

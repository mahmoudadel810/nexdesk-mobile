import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/startup.dart';

/// Opens a page of the web app in the browser, for the flows the app leaves to the web (password reset,
/// email verification, the platform console).
Future<void> openWeb(WidgetRef ref, String path) async {
  final base = ref.read(webBaseUrlProvider);
  if (base == null) return;
  await launchUrl(Uri.parse('$base$path'), mode: LaunchMode.externalApplication);
}

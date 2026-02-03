import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppProvidersWrapper extends ConsumerWidget {
  final Widget child;

  const AppProvidersWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Firebase initialization is handled by the FutureProvider
    return child;
  }
}

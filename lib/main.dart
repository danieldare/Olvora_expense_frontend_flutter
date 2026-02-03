import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app/app_providers_wrapper.dart';
import 'core/app/app_root.dart';
import 'core/bootstrap/app_bootstrap.dart';

void main() {
  AppBootstrap.run(() {
    runApp(
      const ProviderScope(
        child: AppProvidersWrapper(
          child: AppRoot(),
        ),
      ),
    );
  });
}

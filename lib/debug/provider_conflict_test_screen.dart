import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'provider_conflict_test_widget.dart';

class ProviderConflictTestScreen extends ConsumerWidget {
  const ProviderConflictTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ProviderConflictTestWidget();
  }
}

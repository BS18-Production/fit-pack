import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/providers.dart';
import 'data/seed/seed_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  final db = container.read(databaseProvider);

  // Seed initial data
  await SeedManager(db).seedIfNeeded();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FitPackApp(),
    ),
  );
}

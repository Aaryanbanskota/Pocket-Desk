import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/auth/data/models/user_model.dart';

/// Provides an initialized [Isar] instance to the whole app.
///
/// Opening is async, so we use [FutureProvider] — await it at bootstrap.
final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [UserModelSchema],
    directory: dir.path,
    name: 'pocketdesk',
    inspector: false,
  );
});

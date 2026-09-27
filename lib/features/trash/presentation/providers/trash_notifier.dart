import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/isar_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/trash_item_model.dart';
import '../../data/repositories/trash_repository.dart';
import '../../../calendar/presentation/providers/calendar_events_notifier.dart';
import '../../../notes/presentation/providers/notes_notifier.dart';
import '../../../posts/presentation/providers/posts_notifier.dart';
import '../../../tasks/presentation/providers/tasks_notifier.dart';

final trashRepositoryProvider = FutureProvider<TrashRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return TrashRepository(isar: isar);
});

class TrashNotifier extends AutoDisposeAsyncNotifier<List<TrashItemModel>> {
  @override
  Future<List<TrashItemModel>> build() async {
    return _fetchItems();
  }

  Future<List<TrashItemModel>> _fetchItems() async {
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    if (authState is! AuthAuthenticated) return [];

    final repo = await ref.read(trashRepositoryProvider.future);
    return repo.getTrashItemsForUser(authState.user.id);
  }

  Future<void> moveToTrash({
    required TrashItemType itemType,
    required int originalId,
    required String title,
    String? snippet,
    String payloadJson = '{}',
  }) async {
    final authState = ref.read(authNotifierProvider).valueOrNull;
    if (authState is! AuthAuthenticated) return;

    final repo = await ref.read(trashRepositoryProvider.future);
    await repo.moveToTrash(
      userId: authState.user.id,
      itemType: itemType,
      originalId: originalId,
      title: title,
      snippet: snippet,
      payloadJson: payloadJson,
    );

    ref.invalidateSelf();
  }

  Future<void> restoreItem(TrashItemModel item) async {
    final repo = await ref.read(trashRepositoryProvider.future);
    await repo.restoreItem(item);
    
    // Invalidate main feature providers so restored item appears immediately without app restart
    ref.invalidate(notesProvider);
    ref.invalidate(tasksProvider);
    ref.invalidate(calendarEventsProvider);
    ref.invalidate(postsNotifierProvider);
    
    ref.invalidateSelf();
  }

  Future<void> deletePermanently(int trashId) async {
    final repo = await ref.read(trashRepositoryProvider.future);
    await repo.deletePermanently(trashId);
    ref.invalidateSelf();
  }

  Future<void> emptyTrash() async {
    final authState = ref.read(authNotifierProvider).valueOrNull;
    if (authState is! AuthAuthenticated) return;

    final repo = await ref.read(trashRepositoryProvider.future);
    await repo.emptyTrash(authState.user.id);
    ref.invalidateSelf();
  }
}

final trashNotifierProvider =
    AsyncNotifierProvider.autoDispose<TrashNotifier, List<TrashItemModel>>(
  TrashNotifier.new,
);

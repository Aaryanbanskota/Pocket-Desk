import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _kDashboardWidgetOrderKey = 'dashboard_widget_layout_order';
const String _kDashboardWidgetHiddenKey = 'dashboard_widget_layout_hidden';

const List<String> kDefaultDashboardWidgetKeys = [
  'weather',
  'quick_actions',
  'schedule',
  'calendar',
  'tasks',
  'notes',
  'statistics',
  'pinned',
];

class DashboardLayoutState {
  const DashboardLayoutState({
    required this.widgetOrder,
    required this.hiddenWidgets,
    this.isEditing = false,
  });

  final List<String> widgetOrder;
  final Set<String> hiddenWidgets;
  final bool isEditing;

  DashboardLayoutState copyWith({
    List<String>? widgetOrder,
    Set<String>? hiddenWidgets,
    bool? isEditing,
  }) {
    return DashboardLayoutState(
      widgetOrder: widgetOrder ?? this.widgetOrder,
      hiddenWidgets: hiddenWidgets ?? this.hiddenWidgets,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

class DashboardLayoutNotifier extends StateNotifier<DashboardLayoutState> {
  DashboardLayoutNotifier()
      : _storage = const FlutterSecureStorage(),
        super(const DashboardLayoutState(
          widgetOrder: kDefaultDashboardWidgetKeys,
          hiddenWidgets: {},
        )) {
    _loadFromStorage();
  }

  final FlutterSecureStorage _storage;

  Future<void> _loadFromStorage() async {
    final savedOrderJson = await _storage.read(key: _kDashboardWidgetOrderKey);
    final savedHiddenRaw = await _storage.read(key: _kDashboardWidgetHiddenKey);

    List<String> order = kDefaultDashboardWidgetKeys;
    if (savedOrderJson != null) {
      try {
        final decoded = (jsonDecode(savedOrderJson) as List).cast<String>();
        final setDecoded = decoded.toSet();
        final missing = kDefaultDashboardWidgetKeys.where((k) => !setDecoded.contains(k));
        order = [...decoded, ...missing];
      } catch (_) {}
    }

    Set<String> hidden = {};
    if (savedHiddenRaw != null) {
      try {
        final decodedHidden = (jsonDecode(savedHiddenRaw) as List).cast<String>();
        hidden = decodedHidden.toSet();
      } catch (_) {}
    }

    state = DashboardLayoutState(
      widgetOrder: order,
      hiddenWidgets: hidden,
    );
  }

  void toggleEditMode() {
    state = state.copyWith(isEditing: !state.isEditing);
  }

  Future<void> reorderWidgets(int oldIndex, int newIndex) async {
    final updatedList = List<String>.from(state.widgetOrder);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, item);

    state = state.copyWith(widgetOrder: updatedList);
    await _storage.write(key: _kDashboardWidgetOrderKey, value: jsonEncode(updatedList));
  }

  Future<void> toggleWidgetVisibility(String key) async {
    final updatedHidden = Set<String>.from(state.hiddenWidgets);
    if (updatedHidden.contains(key)) {
      updatedHidden.remove(key);
    } else {
      updatedHidden.add(key);
    }

    state = state.copyWith(hiddenWidgets: updatedHidden);
    await _storage.write(key: _kDashboardWidgetHiddenKey, value: jsonEncode(updatedHidden.toList()));
  }

  Future<void> resetLayout() async {
    state = const DashboardLayoutState(
      widgetOrder: kDefaultDashboardWidgetKeys,
      hiddenWidgets: {},
      isEditing: false,
    );
    await _storage.delete(key: _kDashboardWidgetOrderKey);
    await _storage.delete(key: _kDashboardWidgetHiddenKey);
  }
}

final dashboardLayoutProvider =
    StateNotifierProvider<DashboardLayoutNotifier, DashboardLayoutState>(
  (ref) => DashboardLayoutNotifier(),
);

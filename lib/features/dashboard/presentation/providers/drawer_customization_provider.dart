import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _kDrawerOrderKey = 'hamburger_drawer_item_order';
const String _kDrawerDisabledKey = 'hamburger_drawer_disabled_items';

const List<String> kDefaultDrawerItemKeys = [
  'dashboard',
  'calendar',
  'tasks',
  'notes',
  'moneyTracker',
  'posts',
  'fileShare',
  'clock',
  'profile',
  'settings',
  'aboutApp',
  'trash',
];

class DrawerCustomizationState {
  const DrawerCustomizationState({
    required this.itemOrder,
    required this.disabledItems,
  });

  final List<String> itemOrder;
  final Set<String> disabledItems;

  DrawerCustomizationState copyWith({
    List<String>? itemOrder,
    Set<String>? disabledItems,
  }) {
    return DrawerCustomizationState(
      itemOrder: itemOrder ?? this.itemOrder,
      disabledItems: disabledItems ?? this.disabledItems,
    );
  }
}

class DrawerCustomizationNotifier extends StateNotifier<DrawerCustomizationState> {
  DrawerCustomizationNotifier()
      : _storage = const FlutterSecureStorage(),
        super(const DrawerCustomizationState(
          itemOrder: kDefaultDrawerItemKeys,
          disabledItems: {},
        )) {
    _loadFromStorage();
  }

  final FlutterSecureStorage _storage;

  Future<void> _loadFromStorage() async {
    final savedOrderJson = await _storage.read(key: _kDrawerOrderKey);
    final savedDisabledRaw = await _storage.read(key: _kDrawerDisabledKey);

    List<String> order = kDefaultDrawerItemKeys;
    if (savedOrderJson != null) {
      try {
        final decoded = (jsonDecode(savedOrderJson) as List).cast<String>();
        final setDecoded = decoded.toSet();
        final missing = kDefaultDrawerItemKeys.where((k) => !setDecoded.contains(k));
        order = [...decoded, ...missing];
      } catch (_) {}
    }

    Set<String> disabled = {};
    if (savedDisabledRaw != null) {
      try {
        final decodedDisabled = (jsonDecode(savedDisabledRaw) as List).cast<String>();
        disabled = decodedDisabled.toSet();
      } catch (_) {}
    }

    state = DrawerCustomizationState(
      itemOrder: order,
      disabledItems: disabled,
    );
  }

  Future<void> reorderItems(int oldIndex, int newIndex) async {
    final updatedList = List<String>.from(state.itemOrder);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, item);

    state = state.copyWith(itemOrder: updatedList);
    await _storage.write(key: _kDrawerOrderKey, value: jsonEncode(updatedList));
  }

  Future<void> toggleItemVisibility(String itemKey) async {
    final updatedDisabled = Set<String>.from(state.disabledItems);
    if (updatedDisabled.contains(itemKey)) {
      updatedDisabled.remove(itemKey);
    } else {
      if (itemKey == 'dashboard' || itemKey == 'settings') return;
      updatedDisabled.add(itemKey);
    }

    state = state.copyWith(disabledItems: updatedDisabled);
    await _storage.write(key: _kDrawerDisabledKey, value: jsonEncode(updatedDisabled.toList()));
  }

  Future<void> resetToDefaults() async {
    state = const DrawerCustomizationState(
      itemOrder: kDefaultDrawerItemKeys,
      disabledItems: {},
    );
    await _storage.delete(key: _kDrawerOrderKey);
    await _storage.delete(key: _kDrawerDisabledKey);
  }
}

final drawerCustomizationProvider =
    StateNotifierProvider<DrawerCustomizationNotifier, DrawerCustomizationState>(
  (ref) => DrawerCustomizationNotifier(),
);

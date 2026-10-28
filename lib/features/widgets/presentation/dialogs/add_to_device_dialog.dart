import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_icons.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/circular_icon_button.dart';
import '../../../../core/design_system/widgets/undo_toast.dart';
import '../components/calendar_month_widget.dart';

class AddToDeviceDialog extends StatefulWidget {
  final String widgetTitle;
  final String widgetIdentifier;
  final WidgetSize size;

  const AddToDeviceDialog({
    super.key,
    required this.widgetTitle,
    required this.widgetIdentifier,
    required this.size,
  });

  static Future<void> show(
    BuildContext context, {
    required String widgetTitle,
    required String widgetIdentifier,
    required WidgetSize size,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddToDeviceDialog(
        widgetTitle: widgetTitle,
        widgetIdentifier: widgetIdentifier,
        size: size,
      ),
    );
  }

  @override
  State<AddToDeviceDialog> createState() => _AddToDeviceDialogState();
}

class _AddToDeviceDialogState extends State<AddToDeviceDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E22) : const Color(0xFFFFFDF9);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1917);
    final textMuted = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF78716C);
    final surface2 = isDark ? const Color(0xFF282830) : const Color(0xFFF5F3EF);
    final borderColor = isDark ? const Color(0xFF2E2E34) : const Color(0xFFE7E5E4);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: borderColor, width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag pill
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(AppIcons.widget, size: 20, color: AppColors.accentOrange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Widget to Device',
                          style: AppTypography.h3.copyWith(color: textPrimary),
                        ),
                        Text(
                          widget.widgetTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircularIconButton(
                    icon: AppIcons.close,
                    size: 28,
                    iconSize: 14,
                    customColor: Colors.transparent,
                    iconColor: textMuted,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // OS Tabs
              Container(
                decoration: BoxDecoration(
                  color: surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.accentOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: 'Android Phone'),
                    Tab(text: 'iPhone / iOS'),
                    Tab(text: 'Desktop / PC'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab View Content
              SizedBox(
                height: 180,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAndroidGuide(textPrimary, textMuted, surface2),
                    _buildIosGuide(textPrimary, textMuted, surface2),
                    _buildDesktopGuide(textPrimary, textMuted, surface2),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: borderColor),
                      ),
                      icon: const Icon(AppIcons.share, size: 16, color: AppColors.accentOrange),
                      label: Text(
                        'Copy Identifier',
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.widgetIdentifier));
                        UndoToast.show(context, message: 'Copied "${widget.widgetIdentifier}" to clipboard');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_to_home_screen_rounded, size: 18),
                      label: const Text(
                        'Add to Home',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () async {
                        if (Platform.isAndroid) {
                          try {
                            const channel = MethodChannel('pocketdesk/device');
                            String type = 'quick_actions';
                            if (widget.widgetIdentifier.contains('clock') || widget.widgetIdentifier.contains('pie')) {
                              type = 'clock_pie';
                            } else if (widget.widgetIdentifier == '.calendarWidget' || widget.widgetIdentifier.contains('calendar_month')) {
                              type = 'calendar_month';
                            } else if (widget.widgetIdentifier.contains('dual') || widget.widgetIdentifier.contains('agenda')) {
                              type = 'agenda';
                            } else if (widget.widgetIdentifier.contains('task')) {
                              type = 'tasks';
                            } else if (widget.widgetIdentifier.contains('note')) {
                              type = 'notes';
                            } else if (widget.widgetIdentifier.contains('budget') || widget.widgetIdentifier.contains('spendee')) {
                              type = 'budget';
                            }
                            final pinned = await channel.invokeMethod<bool>('requestPinWidget', {'type': type});
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              if (pinned == true) {
                                UndoToast.show(
                                  context,
                                  message: 'Home screen widget prompt opened!',
                                );
                              } else {
                                UndoToast.show(
                                  context,
                                  message: 'Long-press the MyDay icon on your home screen and select "Widgets"!',
                                );
                              }
                            }
                            return;
                          } catch (_) {}
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          UndoToast.show(
                            context,
                            message: '${widget.widgetTitle} configuration synced! Long-press home screen to place.',
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidGuide(Color textPrimary, Color textMuted, Color surface2) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _buildStep(1, 'Long-press the MyDay app icon on your phone home screen.'),
        _buildStep(2, 'Tap "Widgets" in the popup menu.'),
        _buildStep(3, 'Select ${widget.widgetTitle} from the widget tray.'),
        _buildStep(4, 'Touch and hold the widget, then drag it to your home screen.'),
      ],
    );
  }

  Widget _buildIosGuide(Color textPrimary, Color textMuted, Color surface2) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _buildStep(1, 'From the Home Screen, touch and hold a widget or empty area until apps jiggle.'),
        _buildStep(2, 'Tap the Add Button (+) in the upper-left corner.'),
        _buildStep(3, 'Search for "MyDay" and select ${widget.widgetTitle}.'),
        _buildStep(4, 'Choose widget size and tap "Add Widget", then tap Done.'),
      ],
    );
  }

  Widget _buildDesktopGuide(Color textPrimary, Color textMuted, Color surface2) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _buildStep(1, 'In MyDay desktop, widgets can be pinned to your dashboard or side panel.'),
        _buildStep(2, 'Use the Sync Widget Data button to make live SQLite metrics available offline.'),
        _buildStep(3, 'Compatible with Linux desktop gadgets, GNOME extensions, and web widgets.'),
      ],
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentOrange,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

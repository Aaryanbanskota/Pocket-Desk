import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_icons.dart';
import '../app_typography.dart';
import 'circular_icon_button.dart';

enum MyDayNavTab {
  home,
  tasks,
  budget,
  feed,
  calendar,
  notes,
  clock,
  call,
  files,
  trash,
  widgets,
  profile,
  settings;

  static MyDayNavTab get chat => call;
}

/// MyDay Shell matching prototype #top, #view, #bar, #dw
class AppScaffold extends StatefulWidget {
  final MyDayNavTab currentTab;
  final ValueChanged<MyDayNavTab> onTabSelected;
  final VoidCallback onQuickAction;
  final String userName;
  final String accountType; // 'Local account' or cloud email
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;
  final Widget? trailingHeaderAction;
  final Widget child;

  const AppScaffold({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    required this.onQuickAction,
    required this.userName,
    required this.accountType,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLogout,
    this.trailingHeaderAction,
    required this.child,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _getTitle() {
    switch (widget.currentTab) {
      case MyDayNavTab.home:
        return 'Home';
      case MyDayNavTab.tasks:
        return 'Tasks';
      case MyDayNavTab.calendar:
        return 'Calendar';
      case MyDayNavTab.notes:
        return 'Notes';
      case MyDayNavTab.budget:
        return 'Budget';
      case MyDayNavTab.feed:
        return 'Feed';
      case MyDayNavTab.clock:
        return 'Clock';
      case MyDayNavTab.call:
        return 'Call';
      case MyDayNavTab.files:
        return 'Files';
      case MyDayNavTab.trash:
        return 'Trash';
      case MyDayNavTab.widgets:
        return 'Widgets';
      case MyDayNavTab.profile:
        return 'Profile';
      case MyDayNavTab.settings:
        return 'Settings';
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = (widget.userName.isNotEmpty ? widget.userName[0] : 'U').toUpperCase();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.appBg,
      drawer: _buildDrawer(context, initial),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircularIconButton(
                    icon: AppIcons.menu,
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getTitle(),
                      style: AppTypography.h1.copyWith(color: context.appText),
                    ),
                  ),
                  if (widget.trailingHeaderAction != null) ...[
                    widget.trailingHeaderAction!,
                    const SizedBox(width: 8),
                  ],
                  // Settings icon shortcut in header
                  CircularIconButton(
                    icon: AppIcons.settings,
                    onPressed: () => widget.onTabSelected(MyDayNavTab.settings),
                  ),
                  const SizedBox(width: 8),
                  // User Avatar button
                  GestureDetector(
                    onTap: () => widget.onTabSelected(MyDayNavTab.profile),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Screen Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: widget.child,
              ),
            ),

            // Bottom Navigation Bar
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(
          top: BorderSide(color: context.appLine, width: 1.0),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      height: 72 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              // 1. Home
              _buildNavButton(
                context,
                tab: MyDayNavTab.home,
                icon: AppIcons.home,
                label: 'Home',
              ),
              // 2. Tasks
              _buildNavButton(
                context,
                tab: MyDayNavTab.tasks,
                icon: AppIcons.tasks,
                label: 'Tasks',
              ),
              // 3. Protruding FAB placeholder (empty space)
              const Expanded(child: SizedBox()),
              // 4. Budget
              _buildNavButton(
                context,
                tab: MyDayNavTab.budget,
                icon: AppIcons.wallet,
                label: 'Budget',
              ),
              // 5. Feed
              _buildNavButton(
                context,
                tab: MyDayNavTab.feed,
                icon: AppIcons.feed,
                label: 'Feed',
              ),
            ],
          ),

          // Protruding Orange FAB in Center
          Positioned(
            top: -22,
            child: GestureDetector(
              onTap: widget.onQuickAction,
              child: Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x55FF6A2B),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    AppIcons.plus,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required MyDayNavTab tab,
    required IconData icon,
    required String label,
  }) {
    final isSelected = widget.currentTab == tab;

    return Expanded(
      child: InkWell(
        onTap: () => widget.onTabSelected(tab),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected ? context.appSurface2 : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? context.appText : context.appMuted,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? context.appText : context.appMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String initial) {
    return Drawer(
      backgroundColor: context.appSurface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                widget.onTabSelected(MyDayNavTab.profile);
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            style: AppTypography.h4.copyWith(
                              color: context.appText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.accountType,
                            style: AppTypography.captionMuted.copyWith(
                              color: context.appMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Divider(color: context.appLine, height: 1),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _buildDrawerItem(
                    context,
                    tab: MyDayNavTab.home,
                    icon: AppIcons.home,
                    title: 'Home',
                  ),
                  _buildDrawerItem(
                    context,
                    tab: MyDayNavTab.call,
                    icon: AppIcons.phone,
                    title: 'Call',
                  ),
                  _buildDrawerItem(
                    context,
                    tab: MyDayNavTab.tasks,
                    icon: AppIcons.tasks,
                    title: 'Tasks',
                  ),
                  _buildDrawerItem(
                    context,
                    tab: MyDayNavTab.calendar,
                    icon: AppIcons.calendar,
                    title: 'Calendar',
                  ),
                  _buildDrawerItem(
                    context,
                    tab: MyDayNavTab.notes,
                    icon: AppIcons.notes,
                    title: 'Notes',
                  ),
                  _buildDrawerItem(
                    context,
                    tab: MyDayNavTab.budget,
                    icon: AppIcons.wallet,
                    title: 'Budget',
                  ),
                  _buildDrawerItem(
                    context,
                    tab: MyDayNavTab.feed,
                    icon: AppIcons.feed,
                    title: 'Feed',
                  ),
                  _buildDrawerItem(
                    context,
                    tab: MyDayNavTab.clock,
                    icon: AppIcons.clock,
                    title: 'Clock',
                  ),
                  if (widget.accountType != 'Local account')
                    _buildDrawerItem(
                      context,
                      tab: MyDayNavTab.files,
                      icon: AppIcons.files,
                      title: 'Files',
                    ),
                  _buildDrawerItem(
                    context,
                    tab: MyDayNavTab.trash,
                    icon: AppIcons.trash,
                    title: 'Trash',
                  ),
                  _buildDrawerItem(
                    context,
                    tab: MyDayNavTab.widgets,
                    icon: AppIcons.widget,
                    title: 'Widgets',
                  ),
                  _buildDrawerItem(
                    context,
                    tab: MyDayNavTab.settings,
                    icon: AppIcons.settings,
                    title: 'Settings',
                  ),
                ],
              ),
            ),

            Divider(color: context.appLine, height: 1),

            // Footer (Theme Switcher and Logout)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Icon(
                      widget.isDarkMode ? AppIcons.moon : AppIcons.sun,
                      color: context.appMuted,
                    ),
                    title: Text(
                      'Dark mode',
                      style: AppTypography.bodyBold.copyWith(
                        color: context.appText,
                      ),
                    ),
                    trailing: Switch.adaptive(
                      value: widget.isDarkMode,
                      activeTrackColor: AppColors.accentOrange,
                      onChanged: (_) => widget.onToggleTheme(),
                    ),
                    onTap: widget.onToggleTheme,
                  ),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: const Icon(
                      AppIcons.logout,
                      color: AppColors.danger,
                    ),
                    title: Text(
                      'Logout',
                      style: AppTypography.bodyBold.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log out', style: AppTypography.h3.copyWith(color: ctx.appText)),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: AppTypography.body.copyWith(color: ctx.appMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: ctx.appMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      widget.onLogout();
    }
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required MyDayNavTab tab,
    required IconData icon,
    required String title,
  }) {
    final isSelected = widget.currentTab == tab;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: isSelected ? context.appSurface2 : Colors.transparent,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.accent : context.appMuted,
        ),
        title: Text(
          title,
          style: AppTypography.bodyBold.copyWith(
            color: context.appText,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          widget.onTabSelected(tab);
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/background_service.dart';

// Provider to track live threat count for badge
final threatCountProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.shield_outlined, activeIcon: Icons.shield, label: 'Home', path: '/home'),
    _NavItem(icon: Icons.qr_code_scanner_outlined, activeIcon: Icons.qr_code_scanner, label: 'Scan', path: '/scanner/message'),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Community', path: '/community'),
    _NavItem(icon: Icons.smart_toy_outlined, activeIcon: Icons.smart_toy, label: 'AI', path: '/assistant'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', path: '/profile'),
  ];

  @override
  void initState() {
    super.initState();
    _startBackgroundListening();
  }

  void _startBackgroundListening() {
    final bgService = ref.read(backgroundServiceProvider);
    bgService.onThreatDetected = (data) {
      ref.read(threatCountProvider.notifier).state++;
    };
    bgService.startListening();
  }

  @override
  void dispose() {
    ref.read(backgroundServiceProvider).stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final threatCount = ref.watch(threatCountProvider);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          border: const Border(
            top: BorderSide(color: AppColors.darkBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isActive = _currentIndex == index;

                // Show threat badge on Home tab
                final showBadge = index == 0 && threatCount > 0;

                return _NavBarItem(
                  item: item,
                  isActive: isActive,
                  badgeCount: showBadge ? threatCount : 0,
                  onTap: () {
                    setState(() => _currentIndex = index);
                    if (index == 0) {
                      // Clear badge when navigating home
                      ref.read(threatCountProvider.notifier).state = 0;
                    }
                    context.go(item.path);
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.87).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: widget.isActive
                ? AppColors.primary.withOpacity(0.15)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.isActive ? widget.item.activeIcon : widget.item.icon,
                      key: ValueKey(widget.isActive),
                      color: widget.isActive
                          ? AppColors.primary
                          : AppColors.darkSubtext,
                      size: 24,
                    ),
                  ),
                  if (widget.badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${widget.badgeCount > 9 ? '9+' : widget.badgeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: widget.isActive
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: widget.isActive
                      ? AppColors.primary
                      : AppColors.darkSubtext,
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}

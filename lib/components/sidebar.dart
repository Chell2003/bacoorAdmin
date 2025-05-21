import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({Key? key}) : super(key: key);

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout', style: Theme.of(context).textTheme.titleLarge),
        content: Text('Are you sure you want to log out?', style: Theme.of(context).textTheme.bodyLarge),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (Scaffold.of(context).hasDrawer) {
          Navigator.of(context).pop(); // Close drawer if open
        }
        
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color> (Theme.of(context).colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Signing out...', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 1),
          ),
        );

        await context.read<UserProvider>().signOut();
        
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required String route,
    required bool isSelected,
    required int index,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHovered = _hoveredIndex == index;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1,
          (index * 0.1) + 0.5,
          curve: Curves.easeOutCubic,
        ),
      )),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = -1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingXSmall,
          ),
          decoration: BoxDecoration(
            gradient: isSelected 
              ? LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.8),
                    colorScheme.primary,
                  ],
                )
              : null,
            color: isHovered ? colorScheme.primaryContainer.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(borderRadiusMedium),
            boxShadow: isSelected ? [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(borderRadiusMedium),
              onTap: () {
                if (!isSelected) {
                  Navigator.pushReplacementNamed(context, route);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: spacingMedium,
                  vertical: spacingMedium,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(spacingXSmall),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? colorScheme.onPrimary.withOpacity(0.2)
                          : isHovered 
                            ? colorScheme.primaryContainer.withOpacity(0.2)
                            : colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(borderRadiusSmall),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                          ? colorScheme.onPrimary
                          : isHovered
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: spacingMedium),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isSelected
                            ? colorScheme.onPrimary
                            : isHovered
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.onPrimary.withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? currentRoute = ModalRoute.of(context)?.settings.name ?? "/dashboard";
    final isDrawer = Scaffold.of(context).hasDrawer;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isDrawer ? MediaQuery.of(context).size.width * 0.85 : 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: isDrawer ? BorderRadius.zero : const BorderRadius.only(
          topRight: Radius.circular(borderRadiusLarge),
          bottomRight: Radius.circular(borderRadiusLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(spacingLarge),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(spacingSmall),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          Theme.of(context).colorScheme.primary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(borderRadiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: spacingMedium),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Panel',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: spacingLarge,
                vertical: spacingSmall,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: spacingSmall,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(borderRadiusSmall),
              ),
              child: Text(
                'MENU',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: spacingSmall),
            _buildMenuItem(
              title: 'Dashboard',
              icon: Icons.dashboard_rounded,
              route: '/dashboard',
              isSelected: currentRoute == '/dashboard',
              index: 0,
            ),
            _buildMenuItem(
              title: 'Users',
              icon: Icons.people_rounded,
              route: '/users',
              isSelected: currentRoute == '/users',
              index: 1,
            ),
            _buildMenuItem(
              title: 'Places',
              icon: Icons.place_rounded,
              route: '/places',
              isSelected: currentRoute == '/places',
              index: 2,
            ),
            _buildMenuItem(
              title: 'AR Objects',
              icon: Icons.view_in_ar_rounded,
              route: '/ARObjects',
              isSelected: currentRoute == '/ARObjects',
              index: 3,
            ),
            _buildMenuItem(
              title: 'Forums',
              icon: Icons.forum_rounded,
              route: '/forum',
              isSelected: currentRoute == '/forum',
              index: 4,
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(spacingMedium),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(borderRadiusMedium),
              ),
              child: const Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.all(spacingLarge),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      Theme.of(context).colorScheme.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(borderRadiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(borderRadiusLarge),
                    onTap: () => _handleLogout(context),
                    child: Padding(
                      padding: const EdgeInsets.all(spacingMedium),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(spacingXSmall),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(borderRadiusSmall),
                            ),
                            child: Icon(
                              Icons.logout_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: spacingMedium),
                          Text(
                            'Logout',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

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
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                  ),
                ),
                SizedBox(width: 12),
                Text('Signing out...', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: Duration(seconds: 1),
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

  @override
  Widget build(BuildContext context) {
    String? currentRoute = ModalRoute.of(context)?.settings.name ?? "/dashboard";
    final isDrawer = Scaffold.of(context).hasDrawer;
    
    return Container(
      width: isDrawer ? MediaQuery.of(context).size.width * 0.85 : 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: isDrawer ? BorderRadius.circular(0) : const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(2, 0), 
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.admin_panel_settings, color: Theme.of(context).colorScheme.onPrimary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "BACOORDINATES",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (isDrawer) const Spacer(),
                  if (isDrawer)
                    IconButton(
                      icon: Icon(Icons.close, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      _buildNavItem(
                        context: context,
                        title: "Dashboard",
                        icon: Icons.dashboard_outlined,
                        route: '/dashboard',
                        isSelected: currentRoute == '/dashboard',
                      ),
                      _buildNavItem(
                        context: context,
                        title: "Manage Forums",
                        icon: Icons.forum_outlined,
                        route: '/forum',
                        isSelected: currentRoute == '/forum',
                      ),
                      _buildNavItem(
                        context: context,
                        title: "Manage Places",
                        icon: Icons.place_outlined,
                        route: '/places',
                        isSelected: currentRoute == '/places',
                      ),
                      _buildNavItem(
                        context: context,
                        title: "Manage AR Objects",
                        icon: Icons.view_in_ar,
                        route: '/ARObjects',
                        isSelected: currentRoute == '/ARObjects',
                      ),
                      _buildNavItem(
                        context: context,
                        title: "Users",
                        icon: Icons.people_outline,
                        route: '/users',
                        isSelected: currentRoute == '/users',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: _buildNavItem(
                context: context,
                title: "Log Out",
                icon: Icons.logout,
                route: '/login',
                isSelected: false,
                isLogout: true,
                onTap: () => _handleLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String route,
    required bool isSelected,
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    final Color? itemColor = isLogout 
        ? Theme.of(context).colorScheme.error 
        : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7);
    
    final Color selectedItemColor = Theme.of(context).colorScheme.primary;
    
    final Color hoverBgColor = isLogout 
        ? Theme.of(context).colorScheme.error.withOpacity(0.1)
        : Theme.of(context).colorScheme.primary.withOpacity(0.05);
    
    final Color selectedBgColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? selectedBgColor : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap ??
              () {
                if (!isSelected) {
                  if (Scaffold.of(context).hasDrawer) {
                    Navigator.of(context).pop();
                  }
                  Navigator.pushNamed(context, route);
                }
              },
          hoverColor: hoverBgColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected 
                      ? selectedItemColor.withOpacity(0.1)
                      : Colors.transparent,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? selectedItemColor : itemColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected ? selectedItemColor : itemColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selectedItemColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
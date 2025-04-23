import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? currentRoute = ModalRoute.of(context)?.settings.name ?? "/dashboard";
    final isDrawer = Scaffold.of(context).hasDrawer;
    
    return Container(
      width: isDrawer ? MediaQuery.of(context).size.width * 0.85 : 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDrawer ? BorderRadius.circular(0) : const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  bottom: BorderSide(color: Colors.grey[100]!),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue[300]!.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "BACOORDINATES",
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (isDrawer) const Spacer(),
                  if (isDrawer)
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600]),
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
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: _buildNavItem(
                context: context,
                title: "Log Out",
                icon: Icons.logout,
                route: '/login',
                isSelected: false,
                isLogout: true,
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
  }) {
    final color = isLogout ? Colors.red[400] : Colors.grey[700];
    final selectedColor = Colors.blue[700];
    final hoverColor = isLogout ? Colors.red[50] : Colors.blue[50];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.blue[50] : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (!isSelected) {
              if (Scaffold.of(context).hasDrawer) {
                Navigator.of(context).pop();
              }
              Navigator.pushNamed(context, route);
            }
          },
          hoverColor: hoverColor,
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
                      ? selectedColor?.withOpacity(0.1)
                      : Colors.transparent,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? selectedColor : color,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? selectedColor : color,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selectedColor,
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
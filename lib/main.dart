import 'package:admin/screens/ARManagementScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:admin/screens/auth_screen.dart';
import 'package:admin/screens/dashboard_screen.dart';
import 'package:admin/screens/ForumManagementScreen.dart';
import 'package:admin/screens/PlaceManagementScreen.dart';
import 'package:admin/screens/UserManagementScreen.dart';
import 'package:admin/providers/user_provider.dart';
import 'package:admin/providers/place_provider.dart';
import 'package:admin/utils/app_theme.dart'; // Import the custom theme
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => PlaceProvider()),
      ],
      child: MaterialApp(
        title: 'CMS App',
        theme: appTheme, // Apply the custom theme
        // darkTheme: appDarkTheme, // Optional: if you have a dark theme
        // themeMode: ThemeMode.system, // Optional: set theme mode
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(),
        onGenerateRoute: (settings) {
          Widget page;
          switch (settings.name) {
            case '/login':
              page = AuthScreen();
              break;
            case '/dashboard':
              page = DashboardScreen();
              break;
            case '/forum':
              page = ForumManagementScreen();
              break;
            case '/places':
              page = const PlaceManagementScreen();
              break;
            case '/ARObjects':
              page = UploadARObjectScreen();
              break;
            case '/users':
              page = UserManagementScreen();
              break;
            default:
              page = AuthScreen();
          }
          return NoAnimationRoute(builder: (context) => page, settings: settings);
        },
      ),
    );
  }
}

/// AuthWrapper handles the authentication state and redirects users accordingly.
/// It shows a loading indicator while checking auth state, and redirects to
/// either the dashboard or login screen based on authentication status.
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (userProvider.isAuthenticated && userProvider.isAdmin) {
          return DashboardScreen();
        }
        
        return AuthScreen();
      },
    );
  }
}

/// NoAnimationRoute provides instant page transitions without animations.
/// This is useful for authentication-related navigation where animations
/// might feel unnecessary or disruptive.
class NoAnimationRoute<T> extends MaterialPageRoute<T> {
  NoAnimationRoute({required WidgetBuilder builder, RouteSettings? settings})
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

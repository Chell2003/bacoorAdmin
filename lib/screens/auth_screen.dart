import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<UserProvider>().signIn(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using scaffoldBackgroundColor which is set to white in app_theme.dart
    // This effectively uses colorScheme.surfaceContainerLowest behavior if it's white.
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            // Card background should default to Theme.of(context).colorScheme.surface which is white
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 60, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 12),
                        Text(
                          "Admin Login",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(context, "Email", Icons.email_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: _inputDecoration(context, "Password", Icons.lock_outline),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: Text("Forgot Password?", style: TextStyle(color: Theme.of(context).colorScheme.secondary)), // Yellow
                      ),
                    ),
                    const SizedBox(height: 12),

                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        return ElevatedButton(
                          onPressed: userProvider.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary, // Blue
                            foregroundColor: Theme.of(context).colorScheme.onPrimary, // White
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: userProvider.isLoading
                              ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary) // White
                              : const Text('Login', style: TextStyle(fontSize: 16)),
                        );
                      },
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

  void _resetPassword() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Enter your email to reset password.", style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    try {
      await context.read<UserProvider>().resetPassword(emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password reset email sent!", style: TextStyle(color: Theme.of(context).colorScheme.onTertiary)), // Black text
          backgroundColor: Theme.of(context).colorScheme.tertiary, // Yellow background
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}", style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  InputDecoration _inputDecoration(BuildContext context, String label, IconData icon) {
    // Using Theme.of(context).inputDecorationTheme as the base
    final themeInputDecoration = Theme.of(context).inputDecorationTheme;

    return InputDecoration(
      labelText: label,
      labelStyle: themeInputDecoration.labelStyle,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      // Using enabledBorder and focusedBorder from global theme if not overridden explicitly
      enabledBorder: themeInputDecoration.enabledBorder ?? OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: themeInputDecoration.focusedBorder ?? OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      // Using fillColor from global theme
      fillColor: themeInputDecoration.fillColor ?? Theme.of(context).colorScheme.surfaceContainerHighest, 
      filled: true,
      // Ensure border property is also consistent if needed, or rely on enabled/focused
      border: themeInputDecoration.border ?? OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

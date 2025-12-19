import 'package:flutter/material.dart';
import 'login_view.dart';
import 'role_selection_view.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE3F2FD), // Light blue top
              Color(0xFF90CAF9), // Soft blue middle
              Color(0xFF64B5F6), // Slightly deeper blue bottom
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Medical Icon with glow effect
                Container(
                  height: 130,
                  width: 130,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x8042A5F5), // Light blue shadow
                        blurRadius: 25,
                        spreadRadius: 4,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/medical-assistance.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30),

                // App Title
                const Text(
                  'ClickDoc',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black26,
                        offset: Offset(2, 3),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                const Text(
                  'Your smart healthcare companion.\nBook appointments with ease.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 45),

                // Get Started Button (white with soft blue accent)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      final userName = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );

                      if (userName != null && context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RoleSelectionScreen(userName: userName),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                      shadowColor: Colors.black26,
                      backgroundColor: Colors.white.withOpacity(0.9),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0), // Deep blue text
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

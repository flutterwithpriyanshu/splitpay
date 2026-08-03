import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/screens/auth_screen.dart';
import 'package:splitpay/theme/app_colors.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF96cdfa),
      body: Container(
        width: double.infinity,
        height: double.infinity,

        child: SafeArea(
          child: Column(
            children: [
              // Illustration area
              Expanded(
                flex: 5,
                child: Center(
                  child:
                      Image.asset(
                            "assets/icon/playstore.png",
                            width: 260,
                            fit: BoxFit.contain,
                          )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1, 1),
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),
                ),
              ),

              // White floating card
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SplitPay',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Easily split expenses with friends, roommates, colleagues, or anyone—without creating groups.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const AuthScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                            elevation: 4,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

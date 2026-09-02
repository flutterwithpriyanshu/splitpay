import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/widgets/local_avatar.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.userName,
    required this.myUid,
    required this.onProfileTap,
    super.key,
  });

  final String userName;
  final String myUid;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $userName 👋',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Welcome Back',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onProfileTap,
          child: LocalAvatar(localKey: myUid, isProfile: true, radius: 24),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:splitpay/services/local_image_service.dart';
import 'package:splitpay/theme/app_colors.dart';

/// Shows a local image if one exists for [localKey] (profile or friend id).
/// If [isProfile] is true, checks profile storage; otherwise friend storage.
/// If nothing is found and [fallbackUrl] is null, shows a blank circle.
class LocalAvatar extends StatelessWidget {
  final String localKey;
  final bool isProfile;
  final String? fallbackUrl;
  final double radius;

  const LocalAvatar({
    super.key,
    required this.localKey,
    required this.isProfile,
    this.fallbackUrl,
    this.radius = 24,
  });

  Future<File?> _load() {
    return isProfile
        ? LocalImageService.getProfileImage(localKey)
        : LocalImageService.getFriendImage(localKey);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _load(),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file != null) {
          return CircleAvatar(radius: radius, backgroundImage: FileImage(file));
        }
        if (fallbackUrl != null) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: NetworkImage(fallbackUrl!),
          );
        }
        // Blank circle — no photo available.
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(
            Icons.person_rounded,
            color: AppColors.primary.withOpacity(0.4),
            size: radius,
          ),
        );
      },
    );
  }
}

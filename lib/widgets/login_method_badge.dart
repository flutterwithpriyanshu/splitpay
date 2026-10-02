import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Small badge(s) showing how the signed-in user logs in: Google logo
/// and/or phone icon. Uses PNGs from assets/images/.
class LoginMethodBadge extends StatelessWidget {
  final double size;

  const LoginMethodBadge({super.key, this.size = 20});

  static const _googleAsset = 'assets/images/google_logo.png';
  static const _phoneAsset = 'assets/images/phone_icon.png';

  @override
  Widget build(BuildContext context) {
    final providers =
        FirebaseAuth.instance.currentUser?.providerData
            .map((p) => p.providerId)
            .toSet() ??
        <String>{};

    final badges = <Widget>[
      if (providers.contains('google.com'))
        _Badge(asset: _googleAsset, size: size, tooltip: 'Google login'),
      if (providers.contains('phone'))
        _Badge(asset: _phoneAsset, size: size, tooltip: 'Phone login'),
    ];

    if (badges.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < badges.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          badges[i],
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String asset;
  final double size;
  final String tooltip;

  const _Badge({
    required this.asset,
    required this.size,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Image.asset(
        asset,
        width: size,
        height: size-3.5,
        fit: BoxFit.contain,
      ),
    );
  }
}
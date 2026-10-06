import 'dart:io';
import 'package:flutter/material.dart';
import 'package:splitpay/model/friend.dart';
import 'package:splitpay/services/local_image_service.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/theme/app_text.dart';
import 'package:splitpay/widgets/local_avatar.dart';

/// Photo (local file / url) if any, else colored initials.
class FriendPickAvatar extends StatefulWidget {
  const FriendPickAvatar({super.key, required this.friend, this.radius = 22});

  final Friend friend;
  final double radius;

  @override
  State<FriendPickAvatar> createState() => _FriendPickAvatarState();
}

class _FriendPickAvatarState extends State<FriendPickAvatar> {
  late final Future<File?> _file = LocalImageService.getFriendImage(
    widget.friend.id,
  );

  static const _pairs = <(Color, Color)>[
    (Color(0xFF6BF5C6), Color(0xFF0F2A22)),
    (Color(0xFFE4DEFF), Color(0xFF5B3DF5)),
    (Color(0xFFFFD9DF), Color(0xFFF43F5E)),
    (Color(0xFFFFEBC2), Color(0xFFB45309)),
  ];

  String get _initials {
    final parts = widget.friend.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final a = parts.first[0];
    final b = parts.length > 1 ? parts[1][0] : '';
    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.friend;
    return FutureBuilder<File?>(
      future: _file,
      builder: (_, snap) {
        if (snap.data != null || f.avatarUrl.isNotEmpty) {
          return LocalAvatar(
            localKey: f.id,
            isProfile: false,
            fallbackUrl: f.avatarUrl.isEmpty ? null : f.avatarUrl,
            radius: widget.radius,
          );
        }
        final (bg, fg) = _pairs[f.name.hashCode.abs() % _pairs.length];
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: bg,
          child: Text(
            _initials,
            style: AppText.labelMd.copyWith(
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        );
      },
    );
  }
}

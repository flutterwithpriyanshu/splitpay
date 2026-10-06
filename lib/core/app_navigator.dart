import 'package:flutter/material.dart';

/// Global navigator. Lets push-notification taps open a screen
/// without a BuildContext. Set on MaterialApp in main.dart.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

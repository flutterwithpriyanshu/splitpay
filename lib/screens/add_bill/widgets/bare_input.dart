import 'package:flutter/material.dart';

/// Borderless, unfilled input (overrides theme) for fields inside tiles.
InputDecoration bareInput(String hint, {TextStyle? hintStyle}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: hintStyle,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      filled: false,
      isDense: true,
      contentPadding: EdgeInsets.zero,
    );

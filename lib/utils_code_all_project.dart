import 'package:flutter/material.dart';

extension ColorWithOpacityExt on Color {
  Color withOpacityExt(double opacity) {
    return withValues(alpha: opacity);
  }
}

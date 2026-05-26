import 'package:flutter/material.dart';
import 'package:mini_obieraki/core/constants/app_constants.dart';

class ContentWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ContentWrapper({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
        child: Padding(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: child,
        ),
      ),
    );
  }
}

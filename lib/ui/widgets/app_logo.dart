import 'package:flutter/material.dart';

import '../../core/config/app_assets.dart';
import '../theme/bingo_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 100,
    this.circular = true,
    this.backgroundColor = const Color(0xFFF4F4F4),
    this.padding = 6,
    this.borderRadius = 8,
  });

  final double size;
  final bool circular;
  final Color? backgroundColor;
  final double padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final innerSize = backgroundColor == null ? size : size - (padding * 2);
    final cachePx = (innerSize * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(32, 512);
    final image = Image.asset(
      AppAssets.logo,
      width: innerSize,
      height: innerSize,
      cacheWidth: cachePx,
      cacheHeight: cachePx,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.grid_on,
        size: innerSize * 0.55,
        color: BingoColors.primary,
      ),
    );

    final clipped = circular
        ? ClipOval(child: image)
        : ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: image,
          );

    if (backgroundColor == null) return clipped;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(borderRadius),
      ),
      child: clipped,
    );
  }
}

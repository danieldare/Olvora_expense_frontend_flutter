import 'package:flutter/material.dart';

/// Reusable Wallet App Icon Component
/// Used in splash screen and sign-in screen with shimmer effect
class WalletAppIcon extends StatelessWidget {
  final double size;
  final double iconSize;
  final Animation<double>? scaleAnimation;
  final Animation<double>? rotationAnimation;
  final Animation<double>? fadeAnimation;
  final Animation<double>? shimmerPosition;
  final AnimationController? shimmerController;
  final Color primaryColor;
  final Color purpleLight;

  const WalletAppIcon({
    super.key,
    this.size = 90,
    this.iconSize = 42,
    this.scaleAnimation,
    this.rotationAnimation,
    this.fadeAnimation,
    this.shimmerPosition,
    this.shimmerController,
    this.primaryColor = const Color(0xFF624BFF),
    this.purpleLight = const Color(0xFF8B7AFF),
  });

  @override
  Widget build(BuildContext context) {
    final containerWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, purpleLight],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: purpleLight.withValues(alpha: 0.3),
            blurRadius: 45,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glass shimmer effect
          if (shimmerController != null && shimmerPosition != null)
            AnimatedBuilder(
              animation: shimmerController!,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: const [
                          Colors.transparent,
                          Colors.white24,
                          Colors.transparent,
                        ],
                        stops: [
                          shimmerPosition!.value - 0.3,
                          shimmerPosition!.value,
                          shimmerPosition!.value + 0.3,
                        ],
                      ).createShader(rect);
                    },
                    child: Container(color: Colors.white),
                  ),
                );
              },
            ),
          // Wallet icon
          Center(
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: iconSize,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    Widget iconWidget = containerWidget;

    // Apply scale and rotation animations together if both provided
    if (scaleAnimation != null && rotationAnimation != null) {
      iconWidget = AnimatedBuilder(
        animation: Listenable.merge([scaleAnimation!, rotationAnimation!]),
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation!.value,
            child: Transform.rotate(
              angle: rotationAnimation!.value,
              child: child,
            ),
          );
        },
        child: containerWidget,
      );
    } else if (scaleAnimation != null) {
      iconWidget = AnimatedBuilder(
        animation: scaleAnimation!,
        builder: (context, child) {
          return Transform.scale(scale: scaleAnimation!.value, child: child);
        },
        child: containerWidget,
      );
    } else if (rotationAnimation != null) {
      iconWidget = AnimatedBuilder(
        animation: rotationAnimation!,
        builder: (context, child) {
          return Transform.rotate(
            angle: rotationAnimation!.value,
            child: child,
          );
        },
        child: containerWidget,
      );
    }

    // Apply fade animation if provided
    if (fadeAnimation != null) {
      iconWidget = FadeTransition(opacity: fadeAnimation!, child: iconWidget);
    }

    return iconWidget;
  }
}

import 'package:flutter/material.dart';

/// Responsive utility class for Coop Klondike
/// Provides breakpoint constants, device detection, and responsive calculations
class ResponsiveUtils {
  // Breakpoint constants based on Material Design guidelines
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1025;

  // Touch target size constants (44pt minimum for accessibility)
  static const double minTouchTargetSize = 44.0;
  static const double comfortableTouchTargetSize = 48.0;

  // Card aspect ratio (standard playing card ratio)
  static const double cardAspectRatio = 2.5 / 3.5; // width/height

  /// Get the current screen size category
  static ResponsiveSize getSizeCategory(double width) {
    if (width < mobileBreakpoint) {
      return ResponsiveSize.mobile;
    } else if (width < tabletBreakpoint) {
      return ResponsiveSize.tablet;
    } else {
      return ResponsiveSize.desktop;
    }
  }

  /// Check if the current device is mobile
  static bool isMobile(BuildContext context) {
    return getSizeCategory(MediaQuery.of(context).size.width) == ResponsiveSize.mobile;
  }

  /// Check if the current device is tablet
  static bool isTablet(BuildContext context) {
    return getSizeCategory(MediaQuery.of(context).size.width) == ResponsiveSize.tablet;
  }

  /// Check if the current device is desktop
  static bool isDesktop(BuildContext context) {
    return getSizeCategory(MediaQuery.of(context).size.width) == ResponsiveSize.desktop;
  }

  /// Get responsive card width based on screen size
  static double getCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final sizeCategory = getSizeCategory(width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        // Mobile: smaller cards to fit more content
        return width * 0.12; // 12% of screen width
      case ResponsiveSize.tablet:
        // Tablet: medium cards
        return width * 0.08; // 8% of screen width
      case ResponsiveSize.desktop:
        // Desktop: larger cards for better visibility
        return width * 0.06; // 6% of screen width
    }
  }

  /// Get responsive card height based on screen size
  static double getCardHeight(BuildContext context) {
    final cardWidth = getCardWidth(context);
    return cardWidth / cardAspectRatio;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return const EdgeInsets.all(8);
      case ResponsiveSize.tablet:
        return const EdgeInsets.all(12);
      case ResponsiveSize.desktop:
        return const EdgeInsets.all(16);
    }
  }

  /// Get responsive margin based on screen size
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return const EdgeInsets.all(4);
      case ResponsiveSize.tablet:
        return const EdgeInsets.all(8);
      case ResponsiveSize.desktop:
        return const EdgeInsets.all(12);
    }
  }

  /// Get responsive spacing between elements
  static double getElementSpacing(BuildContext context) {
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return 8;
      case ResponsiveSize.tablet:
        return 12;
      case ResponsiveSize.desktop:
        return 16;
    }
  }

  /// Get responsive font size for card text
  static double getCardFontSize(BuildContext context) {
    final cardWidth = getCardWidth(context);

    // Font size should be proportional to card width
    // Minimum readable size is 8, maximum comfortable size is 16
    return (cardWidth * 0.12).clamp(8.0, 16.0);
  }

  /// Get responsive border radius for cards
  static double getCardBorderRadius(BuildContext context) {
    final cardWidth = getCardWidth(context);
    return (cardWidth * 0.08).clamp(4.0, 12.0);
  }

  /// Get responsive shadow blur radius
  static double getShadowBlurRadius(BuildContext context) {
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return 2;
      case ResponsiveSize.tablet:
        return 4;
      case ResponsiveSize.desktop:
        return 6;
    }
  }

  /// Get responsive shadow offset
  static Offset getShadowOffset(BuildContext context) {
    final blurRadius = getShadowBlurRadius(context);
    return Offset(blurRadius * 0.5, blurRadius * 0.5);
  }

  /// Get responsive game board padding
  static EdgeInsets getGameBoardPadding(BuildContext context) {
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return const EdgeInsets.all(8);
      case ResponsiveSize.tablet:
        return const EdgeInsets.all(12);
      case ResponsiveSize.desktop:
        return const EdgeInsets.all(16);
    }
  }

  /// Get responsive app bar height
  static double getAppBarHeight(BuildContext context) {
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return 56; // Standard mobile app bar height
      case ResponsiveSize.tablet:
        return 60;
      case ResponsiveSize.desktop:
        return 64; // Standard desktop app bar height
    }
  }

  /// Get responsive app bar font size
  static double getAppBarFontSize(BuildContext context) {
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return 14.0;
      case ResponsiveSize.tablet:
        return 16.0;
      case ResponsiveSize.desktop:
        return 18.0;
    }
  }

  /// Get responsive button height
  static double getButtonHeight(BuildContext context) {
    return minTouchTargetSize; // Always meet minimum touch target
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context) {
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return 20;
      case ResponsiveSize.tablet:
        return 24;
      case ResponsiveSize.desktop:
        return 28;
    }
  }

  /// Get responsive text scale factor
  static double getTextScaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Scale text based on screen width
    if (width < mobileBreakpoint) {
      return 0.8; // Slightly smaller text on mobile
    } else if (width < tabletBreakpoint) {
      return 0.9; // Slightly smaller text on tablet
    } else {
      return 1.0; // Standard text size on desktop
    }
  }

  /// Get responsive dialog width
  static double getDialogWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final sizeCategory = getSizeCategory(width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return width * 0.9; // 90% of screen width on mobile
      case ResponsiveSize.tablet:
        return width * 0.7; // 70% of screen width on tablet
      case ResponsiveSize.desktop:
        return 400; // Fixed width on desktop
    }
  }

  /// Get responsive dialog height
  static double getDialogHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return height * 0.8; // 80% of screen height on mobile
      case ResponsiveSize.tablet:
        return height * 0.6; // 60% of screen height on tablet
      case ResponsiveSize.desktop:
        return height * 0.5; // 50% of screen height on desktop
    }
  }

  /// Get responsive card spacing in tableau columns
  static double getTableauCardSpacing(BuildContext context) {
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return 15; // Tighter spacing on mobile
      case ResponsiveSize.tablet:
        return 20; // Medium spacing on tablet
      case ResponsiveSize.desktop:
        return 25; // More generous spacing on desktop
    }
  }

  /// Get responsive foundation pile spacing
  static double getFoundationSpacing(BuildContext context) {
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return 4; // Tighter spacing on mobile
      case ResponsiveSize.tablet:
        return 8; // Medium spacing on tablet
      case ResponsiveSize.desktop:
        return 12; // More generous spacing on desktop
    }
  }

  /// Get responsive stock/waste pile size
  static double getStockPileSize(BuildContext context) {
    final cardWidth = getCardWidth(context);
    return cardWidth * 0.7; // Slightly smaller than main cards
  }

  /// Get responsive game area width percentage
  static double getGameAreaWidthPercentage(BuildContext context) {
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return 0.95; // Use most of the screen on mobile
      case ResponsiveSize.tablet:
        return 0.85; // Leave some margin on tablet
      case ResponsiveSize.desktop:
        return 0.75; // More constrained on desktop
    }
  }

  /// Get responsive game area height percentage
  static double getGameAreaHeightPercentage(BuildContext context) {
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return 0.85; // Account for mobile UI elements
      case ResponsiveSize.tablet:
        return 0.90; // More space for game on tablet
      case ResponsiveSize.desktop:
        return 0.95; // Maximum space on desktop
    }
  }

  /// Get responsive animation duration
  static Duration getAnimationDuration(BuildContext context) {
    // Slightly longer animations on mobile for better UX
    return const Duration(milliseconds: 200);
  }

  /// Get responsive drag feedback scale
  static double getDragFeedbackScale(BuildContext context) {
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return 1.05; // Subtle feedback on mobile
      case ResponsiveSize.tablet:
        return 1.1; // More noticeable on tablet
      case ResponsiveSize.desktop:
        return 1.15; // Most pronounced on desktop
    }
  }

  /// Get responsive border width
  static double getBorderWidth(BuildContext context) {
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return 1.0;
      case ResponsiveSize.tablet:
        return 1.5;
      case ResponsiveSize.desktop:
        return 2.0;
    }
  }

  /// Get responsive stroke width for icons and dividers
  static double getStrokeWidth(BuildContext context) {
    final sizeCategory = getSizeCategory(MediaQuery.of(context).size.width);

    switch (sizeCategory) {
      case ResponsiveSize.mobile:
        return 1.0;
      case ResponsiveSize.tablet:
        return 1.5;
      case ResponsiveSize.desktop:
        return 2.0;
    }
  }
}

/// Enum for responsive size categories
enum ResponsiveSize {
  mobile,
  tablet,
  desktop,
}

/// Extension methods for BuildContext to easily access responsive utilities
extension ResponsiveContext on BuildContext {
  /// Get the current responsive size category
  ResponsiveSize get responsiveSize => ResponsiveUtils.getSizeCategory(MediaQuery.of(this).size.width);

  /// Check if the current device is mobile
  bool get isMobile => ResponsiveUtils.isMobile(this);

  /// Check if the current device is tablet
  bool get isTablet => ResponsiveUtils.isTablet(this);

  /// Check if the current device is desktop
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  /// Get responsive card width
  double get cardWidth => ResponsiveUtils.getCardWidth(this);

  /// Get responsive card height
  double get cardHeight => ResponsiveUtils.getCardHeight(this);

  /// Get responsive padding
  EdgeInsets get responsivePadding => ResponsiveUtils.getResponsivePadding(this);

  /// Get responsive margin
  EdgeInsets get responsiveMargin => ResponsiveUtils.getResponsiveMargin(this);

  /// Get responsive element spacing
  double get elementSpacing => ResponsiveUtils.getElementSpacing(this);

  /// Get responsive card font size
  double get cardFontSize => ResponsiveUtils.getCardFontSize(this);

  /// Get responsive card border radius
  double get cardBorderRadius => ResponsiveUtils.getCardBorderRadius(this);

  /// Get responsive shadow blur radius
  double get shadowBlurRadius => ResponsiveUtils.getShadowBlurRadius(this);

  /// Get responsive shadow offset
  Offset get shadowOffset => ResponsiveUtils.getShadowOffset(this);

  /// Get responsive game board padding
  EdgeInsets get gameBoardPadding => ResponsiveUtils.getGameBoardPadding(this);

  /// Get responsive app bar height
  double get appBarHeight => ResponsiveUtils.getAppBarHeight(this);

  /// Get responsive app bar font size
  double get appBarFontSize => ResponsiveUtils.getAppBarFontSize(this);

  /// Get responsive button height
  double get buttonHeight => ResponsiveUtils.getButtonHeight(this);

  /// Get responsive icon size
  double get iconSize => ResponsiveUtils.getIconSize(this);

  /// Get responsive text scale factor
  double get textScaleFactor => ResponsiveUtils.getTextScaleFactor(this);

  /// Get responsive dialog width
  double get dialogWidth => ResponsiveUtils.getDialogWidth(this);

  /// Get responsive dialog height
  double get dialogHeight => ResponsiveUtils.getDialogHeight(this);

  /// Get responsive tableau card spacing
  double get tableauCardSpacing => ResponsiveUtils.getTableauCardSpacing(this);

  /// Get responsive foundation spacing
  double get foundationSpacing => ResponsiveUtils.getFoundationSpacing(this);

  /// Get responsive stock pile size
  double get stockPileSize => ResponsiveUtils.getStockPileSize(this);

  /// Get responsive game area width percentage
  double get gameAreaWidthPercentage => ResponsiveUtils.getGameAreaWidthPercentage(this);

  /// Get responsive game area height percentage
  double get gameAreaHeightPercentage => ResponsiveUtils.getGameAreaHeightPercentage(this);

  /// Get responsive animation duration
  Duration get animationDuration => ResponsiveUtils.getAnimationDuration(this);

  /// Get responsive drag feedback scale
  double get dragFeedbackScale => ResponsiveUtils.getDragFeedbackScale(this);

  /// Get responsive border width
  double get borderWidth => ResponsiveUtils.getBorderWidth(this);

  /// Get responsive stroke width
  double get strokeWidth => ResponsiveUtils.getStrokeWidth(this);
}
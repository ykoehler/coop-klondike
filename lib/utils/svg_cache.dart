import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Utility class to precache all SVG card assets
class SvgCache {
  static const List<String> _suits = ['hearts', 'diamonds', 'clubs', 'spades'];
  static const List<String> _ranks = ['a', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'j', 'q', 'k'];
  
  /// Precache all card SVGs to prevent loading flash
  static Future<void> precacheCardSvgs(BuildContext context) async {
    final futures = <Future<void>>[];
    
    // Precache face down card
    futures.add(_precacheSvg(context, 'assets/cards/svgs/card_face_down.svg'));
    
    // Precache all 52 cards
    for (final suit in _suits) {
      for (final rank in _ranks) {
        final path = 'assets/cards/svgs/${suit}_$rank.svg';
        futures.add(_precacheSvg(context, path));
      }
    }
    
    // Wait for all SVGs to be cached
    await Future.wait(futures);
    debugPrint('✅ All ${futures.length} card SVGs precached successfully');
  }
  
  /// Precache a single SVG asset
  static Future<void> _precacheSvg(BuildContext context, String assetPath) async {
    final loader = SvgAssetLoader(assetPath);
    await svg.cache
        .putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
  }
}

// Script to generate SVG card templates
// Run with: dart assets/cards/generate_cards.dart

import 'dart:io';

void main() {
  final suits = ['hearts', 'diamonds', 'clubs', 'spades'];
  final suitSymbols = ['♥', '♦', '♣', '♠'];
  final suitColors = ['red', 'red', 'black', 'black'];

  // Generate all 52 cards
  for (int suitIndex = 0; suitIndex < suits.length; suitIndex++) {
    final suit = suits[suitIndex];
    final suitSymbol = suitSymbols[suitIndex];
    final suitColor = suitColors[suitIndex];

    for (int rankIndex = 1; rankIndex <= 13; rankIndex++) {
      final rank = _getRankText(rankIndex);
      final filename = '${suit}_${rank.toLowerCase()}.svg';
      final svgContent = _generateCardSVG(suitSymbol, rank, suitColor);

      File('assets/cards/svgs/$filename').writeAsStringSync(svgContent);
      print('Generated: $filename');
    }
  }

  // Generate card back
  final cardBackContent = _generateCardBackSVG();
  File('assets/cards/svgs/card_back.svg').writeAsStringSync(cardBackContent);
  print('Generated: card_back.svg');

  // Generate face down card
  final faceDownContent = _generateFaceDownSVG();
  File('assets/cards/svgs/card_face_down.svg').writeAsStringSync(faceDownContent);
  print('Generated: card_face_down.svg');
}

String _getRankText(int rankIndex) {
  switch (rankIndex) {
    case 1: return 'A';
    case 11: return 'J';
    case 12: return 'Q';
    case 13: return 'K';
    default: return rankIndex.toString();
  }
}

String _generateCardSVG(String suitSymbol, String rank, String suitColor) {
  return '''
<svg width="80" height="112" viewBox="0 0 80 112" xmlns="http://www.w3.org/2000/svg">
  <!-- Card background -->
  <rect width="80" height="112" rx="6" ry="6" fill="white" stroke="#000" stroke-width="1"/>

  <!-- Card shadow -->
  <rect x="2" y="2" width="80" height="112" rx="6" ry="6" fill="none" stroke="#000" stroke-width="0.5" opacity="0.2"/>

  <!-- Top left corner -->
  <g fill="$suitColor">
    <text x="8" y="18" font-family="Arial, sans-serif" font-size="14" font-weight="bold">$rank</text>
    <text x="8" y="32" font-family="Arial, sans-serif" font-size="14">$suitSymbol</text>
  </g>

  <!-- Center suit symbol -->
  <g fill="$suitColor">
    <text x="40" y="56" text-anchor="middle" font-family="Arial, sans-serif" font-size="24">$suitSymbol</text>
  </g>

  <!-- Bottom right corner -->
  <g fill="$suitColor">
    <text x="72" y="104" text-anchor="end" font-family="Arial, sans-serif" font-size="14">$suitSymbol</text>
    <text x="72" y="90" text-anchor="end" font-family="Arial, sans-serif" font-size="14" font-weight="bold">$rank</text>
  </g>
</svg>''';
}

String _generateCardBackSVG() {
  return '''
<svg width="80" height="112" viewBox="0 0 80 112" xmlns="http://www.w3.org/2000/svg">
  <!-- Card background -->
  <rect width="80" height="112" rx="6" ry="6" fill="#1e3a8a" stroke="#000" stroke-width="1"/>

  <!-- Card shadow -->
  <rect x="2" y="2" width="80" height="112" rx="6" ry="6" fill="none" stroke="#000" stroke-width="0.5" opacity="0.2"/>

  <!-- Decorative pattern -->
  <g fill="#ffffff" opacity="0.8">
    <circle cx="20" cy="30" r="3"/>
    <circle cx="60" cy="30" r="3"/>
    <circle cx="20" cy="82" r="3"/>
    <circle cx="60" cy="82" r="3"/>
    <circle cx="40" cy="56" r="4"/>
  </g>

  <!-- Center diamond pattern -->
  <g stroke="#ffffff" stroke-width="2" fill="none" opacity="0.6">
    <path d="M 40 20 L 60 56 L 40 92 L 20 56 Z"/>
    <path d="M 20 30 L 40 56 L 60 30 L 40 20 L 20 30"/>
    <path d="M 20 82 L 40 56 L 60 82 L 40 92 L 20 82"/>
  </g>
</svg>''';
}

String _generateFaceDownSVG() {
  return '''
<svg width="80" height="112" viewBox="0 0 80 112" xmlns="http://www.w3.org/2000/svg">
  <!-- Card background -->
  <rect width="80" height="112" rx="6" ry="6" fill="#4169e1" stroke="#000" stroke-width="1"/>

  <!-- Card shadow -->
  <rect x="2" y="2" width="80" height="112" rx="6" ry="6" fill="none" stroke="#000" stroke-width="0.5" opacity="0.2"/>

  <!-- Face down pattern -->
  <g fill="#ffffff" opacity="0.9">
    <text x="40" y="56" text-anchor="middle" font-family="Arial, sans-serif" font-size="20">♠</text>
  </g>
</svg>''';
}
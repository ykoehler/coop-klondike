# Project Brief: Coop Klondike

## Core Purpose
Build a complete, playable implementation of the classic Klondike Solitaire card game as a Flutter web application.

## Key Requirements
- **Complete Game Logic**: Implement all standard Klondike rules including tableau columns, foundation piles, stock/waste mechanics, and win conditions
- **Interactive UI**: Drag-and-drop card movements, visual feedback, and responsive web design
- **State Management**: Proper game state handling with undo capabilities and game reset functionality
- **Testing**: Comprehensive unit tests covering game logic, models, and critical interactions
- **Performance**: Smooth animations and responsive interactions suitable for web deployment

## Success Criteria
- All standard Klondike solitaire rules correctly implemented
- Intuitive drag-and-drop gameplay
- Win condition detection and celebration
- Clean, maintainable codebase with proper separation of concerns
- Full test coverage for game logic and models
- Deployable as a web application

## Scope Boundaries
- Single-player Klondike variant only (no other solitaire games)
- Web deployment focus (mobile/desktop compatibility secondary)
- No multiplayer or online features
- No scoring system beyond win/lose detection
- No save/load game functionality

## Technical Constraints
- Flutter framework for cross-platform compatibility
- Provider pattern for state management
- Pure Dart implementation (no external game engines)
- Standard playing card deck (52 cards, 4 suits)
- Web-first responsive design
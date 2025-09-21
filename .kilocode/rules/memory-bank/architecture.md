# System Architecture: Coop Klondike

## Overview
Coop Klondike is a Flutter web application implementing the classic Klondike Solitaire card game. The architecture follows clean separation of concerns with distinct layers for models, logic, UI, and state management.

## Source Code Structure

### Core Directories
- `lib/models/` - Data models and business entities
- `lib/logic/` - Pure game logic and rule validation
- `lib/providers/` - State management using Provider pattern
- `lib/screens/` - Main UI screens
- `lib/widgets/` - Reusable UI components
- `test/` - Unit tests for all components

### Key Files
- `lib/main.dart` - Application entry point and provider setup
- `lib/models/card.dart` - Card representation with suit, rank, and stacking logic
- `lib/models/deck.dart` - Card collection management
- `lib/models/game_state.dart` - Complete game state container
- `lib/models/tableau_column.dart` - Tableau pile logic
- `lib/models/foundation_pile.dart` - Foundation pile logic
- `lib/logic/game_logic.dart` - All game rule validation and move execution
- `lib/providers/game_provider.dart` - State management and UI integration
- `lib/screens/game_screen.dart` - Main game interface
- `lib/widgets/` - Card widgets, pile widgets, game board

## Key Technical Decisions

### State Management
**Decision**: Provider pattern with ChangeNotifier
- **Rationale**: Lightweight, built-in Flutter integration, sufficient for game scope
- **Benefits**: Easy testing, clear separation of UI and business logic
- **Trade-offs**: Manual listener management vs. more complex solutions like Riverpod

### Game Logic Organization
**Decision**: Pure functions in GameLogic class
- **Rationale**: Testable, predictable, no side effects
- **Benefits**: Easy unit testing, clear validation logic
- **Implementation**: Static methods for all game operations

### UI Architecture
**Decision**: Widget composition with drag-and-drop
- **Rationale**: Native Flutter capabilities, responsive design
- **Benefits**: Cross-platform compatibility, smooth interactions
- **Implementation**: DragTarget and Draggable widgets for card movement

## Design Patterns

### Model-View-Provider (MVP-like)
- **Models**: Pure data classes with business logic
- **Logic**: Pure functions for game rules
- **Provider**: State management bridging models and UI
- **Widgets**: Reactive UI components

### Command Pattern (Implicit)
- Game moves as discrete operations with validation
- Each move type (waste-to-tableau, tableau-to-foundation, etc.) has dedicated methods
- Validation before execution ensures game integrity

### Factory Pattern
- GameState constructor handles initial deal
- Deck.reset() creates and shuffles new deck
- Consistent game initialization

## Component Relationships

### Data Flow
```
User Interaction → Widget Event → GameProvider Method → GameLogic Validation → GameState Update → UI Rebuild
```

### Key Relationships
- **CardWidget** ↔ **GameProvider**: Card display and drag events
- **Pile Widgets** ↔ **GameProvider**: Pile state and drop events
- **GameLogic** ↔ **GameState**: Pure validation and mutation
- **GameProvider** ↔ **GameState**: State management wrapper

### Dependencies
- Models depend only on themselves (no external dependencies)
- GameLogic depends only on models
- GameProvider depends on GameLogic and models
- Widgets depend on GameProvider
- Tests depend on respective components

## Critical Implementation Paths

### Card Movement Flow
1. User initiates drag on CardWidget
2. DragTarget widgets calculate valid drop zones
3. On drop, target calls GameProvider.moveCard()
4. GameProvider validates move via GameLogic
5. If valid, updates GameState and notifies listeners
6. UI rebuilds with new card positions

### Game Initialization
1. GameState() constructor calls _dealNewGame()
2. Creates fresh deck and shuffles
3. Deals cards to tableau columns (1-7 cards, face-up on top)
4. Initializes empty foundation piles

### Win Condition Detection
- GameProvider exposes isGameWon getter
- Checks if all foundation piles are complete (13 cards each)
- Triggers victory UI overlay

## Testing Strategy

### Unit Test Coverage
- **Models**: Card stacking logic, deck operations, pile validation
- **GameLogic**: All move validations and executions
- **GameProvider**: State management and UI integration
- **Widgets**: UI component behavior (integration tests)

### Test Organization
- Mirror source structure in test/ directory
- Comprehensive test cases for game rules
- Edge cases and invalid moves covered
- Pure logic tests enable fast, reliable CI

## Performance Considerations

### Web Optimization
- Minimal widget rebuilds through Provider
- Efficient drag-and-drop with Flutter's built-in capabilities
- No heavy computations in UI thread

### Memory Management
- Small game state (52 cards maximum)
- No persistent storage or complex caching needed
- Stateless widgets where possible

## Extensibility Points

### Adding New Game Features
- Extend GameLogic with new move types
- Add new pile types to GameState
- Create new widget types following existing patterns

### UI Customization
- CardWidget supports different visual themes
- GameBoard layout can be modified for different screen sizes
- Provider pattern allows easy feature toggles

This architecture provides a solid foundation for the solitaire game while maintaining clean, testable, and maintainable code.
# System Architecture: Coop Klondike

## Overview
Coop Klondike is a Flutter web application implementing collaborative multiplayer Klondike Solitaire with real-time synchronization. The architecture follows clean separation of concerns with distinct layers for models, logic, UI, state management, and Firebase integration for multiplayer coordination.

## Source Code Structure

### Core Directories
- `lib/models/` - Data models and business entities (including multiplayer models)
- `lib/logic/` - Pure game logic and rule validation
- `lib/providers/` - State management using Provider pattern with Firebase integration
- `lib/services/` - External service integrations (Firebase)
- `lib/screens/` - Main UI screens with multiplayer support
- `lib/widgets/` - Reusable UI components
- `lib/utils/` - Utility functions and helpers
- `test/` - Unit tests for all components

### Key Files
- `lib/main.dart` - Application entry point with Firebase initialization and provider setup
- `lib/models/card.dart` - Card representation with suit, rank, and stacking logic
- `lib/models/deck.dart` - Card collection management
- `lib/models/game_state.dart` - Complete game state container with Firebase serialization
- `lib/models/tableau_column.dart` - Tableau pile logic
- `lib/models/foundation_pile.dart` - Foundation pile logic
- `lib/models/game_lock.dart` - Multiplayer concurrency control model
- `lib/models/drag_state.dart` - Real-time drag position sharing model
- `lib/services/firebase_service.dart` - Firebase Realtime Database integration
- `lib/logic/game_logic.dart` - All game rule validation and move execution
- `lib/providers/game_provider.dart` - State management with Firebase synchronization
- `lib/screens/game_screen.dart` - Main multiplayer game interface
- `lib/screens/game_creation_screen.dart` - New game creation with seed input (planned)
- `lib/screens/error_screen.dart` - Error handling for multiplayer issues
- `lib/firebase_options.dart` - Firebase configuration
- `lib/utils/seed_generator.dart` - Utility for generating passphrase-like seeds (planned)
- `lib/widgets/` - Card widgets, pile widgets, game board with multiplayer indicators

## Key Technical Decisions

### Multiplayer Architecture
**Decision**: Firebase Realtime Database for real-time synchronization
- **Rationale**: Built-in real-time capabilities, scalable, web-compatible
- **Benefits**: Automatic conflict resolution, offline support, real-time listeners
- **Trade-offs**: External dependency vs. self-hosted solutions

### State Management
**Decision**: Provider pattern with ChangeNotifier + Firebase integration
- **Rationale**: Lightweight, built-in Flutter integration, compatible with Firebase streams
- **Benefits**: Easy testing, clear separation of UI and business logic, real-time updates
- **Trade-offs**: Manual listener management vs. more complex solutions like Riverpod

### Concurrency Control
**Decision**: Lock-based turn system with timeout
- **Rationale**: Prevents simultaneous conflicting actions, simple to implement and understand
- **Benefits**: Conflict prevention, automatic deadlock resolution, visual feedback
- **Implementation**: GameLock model with 10-second expiration

### Game Logic Organization
**Decision**: Pure functions in GameLogic class (unchanged from single-player)
- **Rationale**: Testable, predictable, no side effects
- **Benefits**: Easy unit testing, clear validation logic, multiplayer compatibility
- **Implementation**: Static methods for all game operations

### Deterministic Shuffling
**Decision**: User-provided seed (10-15 char English-like passphrase) for deterministic deck shuffling, separated by gameId
- **Rationale**: Enables reproducible games for testing, sharing specific deals, and multiplayer consistency without altering existing logic
- **Benefits**: Identical shuffles across players/sessions using same seed; overrideable default derived from gameId; maintains immutability post-creation
- **Implementation**: Seed stored in GameState for Firebase sync; Deck.shuffle() uses seed-initialized Random(); Utility in seed_generator.dart for passphrase generation (e.g., word list-based like "whale42jump"); UI allows input/override before game start, read-only display after
- **Trade-offs**: Adds minor state overhead; requires careful derivation (e.g., hash gameId to seed) for existing games

### UI Architecture
**Decision**: Widget composition with drag-and-drop + real-time indicators
- **Rationale**: Native Flutter capabilities, responsive design, multiplayer feedback
- **Benefits**: Cross-platform compatibility, smooth interactions, real-time collaboration
- **Implementation**: DragTarget and Draggable widgets with Firebase synchronization

## Design Patterns

### Model-View-Provider-Service (MVPS)
- **Models**: Pure data classes with business logic and Firebase serialization
- **Logic**: Pure functions for game rules
- **Provider**: State management bridging models, services, and UI
- **Service**: Firebase integration layer for real-time operations
- **Widgets**: Reactive UI components with multiplayer indicators

### Observer Pattern (Real-Time Listeners)
- Three concurrent Firebase streams for different data types
- Automatic UI updates on remote state changes
- Event-driven architecture for multiplayer coordination

### Command Pattern (Enhanced for Multiplayer)
- Game moves as discrete operations with validation and Firebase persistence
- Each move type wrapped in acquire-lock → execute → release-lock pattern
- Conflict resolution through lock acquisition

### Factory Pattern
- GameState constructor handles initial deal with Firebase persistence
- Deck.reset() creates and shuffles new deck
- Player ID generation for multiplayer sessions

### Singleton Pattern
- FirebaseService as singleton for consistent database access
- Single source of truth for Firebase operations

## Component Relationships

### Multiplayer Data Flow
```
User Interaction → Widget Event → GameProvider Method → GameLock Acquisition → GameLogic Validation → GameState Update → Firebase Sync → Cross-Player UI Rebuild
```

### Firebase Streams Architecture
```
Firebase Database → FirebaseService → GameProvider → UI Components
                                   ↓
                            Real-time Listeners:
                            - Game State Stream
                            - Locks Stream  
                            - Drag Positions Stream
```

### Key Relationships
- **CardWidget** ↔ **GameProvider**: Card display, drag events, and real-time drag sharing
- **Pile Widgets** ↔ **GameProvider**: Pile state, drop events, and lock indicators
- **GameLogic** ↔ **GameState**: Pure validation and mutation (unchanged)
- **GameProvider** ↔ **FirebaseService**: Real-time synchronization and persistence
- **GameProvider** ↔ **GameState**: State management wrapper with multiplayer coordination (now includes seed handling for init)
- **SeedGenerator** ↔ **GameCreationScreen**: Passphrase generation for new games
- **GameState** ↔ **Deck**: Seed passed to shuffle for determinism
- **FirebaseService** ↔ **Firebase Database**: Real-time data persistence and retrieval

### Dependencies
- Models depend only on themselves (with Firebase serialization methods)
- GameLogic depends only on models (unchanged from single-player)
- GameProvider depends on GameLogic, models, and FirebaseService
- FirebaseService depends on Firebase SDK
- Widgets depend on GameProvider (with multiplayer state awareness)
- Tests depend on respective components (with Firebase mocking)

## Critical Implementation Paths

### Multiplayer Card Movement Flow
1. User initiates drag on CardWidget
2. GameProvider broadcasts drag start via DragState to Firebase
3. Other players see real-time drag indicator
4. On drop, GameProvider attempts to acquire GameLock
5. If lock acquired: GameLogic validates move
6. If valid: GameState updated and synced to Firebase
7. GameLock released automatically
8. All connected players' UI rebuilds with new card positions

### Game Creation Flow (with Seed)
```mermaid
graph TD
    A[App Start - No gameId] --> B[Route to GameCreationScreen]
    B --> C[Generate/Show Random Seed in TextField]
    C --> D[User Inputs/Overrides Seed or Clicks Generate]
    D --> E[Derive gameId e.g. hash(seed) or UUID]
    E --> F[Create GameState with Seed, Shuffle Deck using Seeded Random]
    F --> G[Sync GameState to Firebase /games/{gameId}/gameState]
    G --> H[Navigate to /game/{gameId}]
    I[App Start - With gameId] --> J[Load GameState from Firebase]
    J --> K[Extract Seed from GameState]
    K --> L[If New: Shuffle Deck using Seeded Random; If Existing: Use Loaded State]
    L --> H
    H --> M[All Players Sync via GameState Stream, Use Same Seed for Consistency]
```

### Multiplayer Game Initialization
1. Player navigates to `/game/{gameId}` URL or creates new game
2. GameProvider generates unique player ID
3. FirebaseService checks if game exists at `/games/{gameId}`
4. If new: Creates fresh game state and syncs to Firebase
5. If existing: Loads game state from Firebase
6. Establishes three real-time listeners (game state, locks, drag positions)
7. UI renders with current multiplayer game state

### Real-Time Synchronization Flow
1. GameProvider establishes Firebase listeners on game join
2. Game State Listener: Updates local state on remote changes
3. Locks Listener: Shows/hides action availability based on other players' locks
4. Drag Positions Listener: Displays real-time drag indicators from other players
5. All listeners trigger UI rebuilds via ChangeNotifier

### Session Management
1. Game URLs in format `/game/{gameId}` for easy sharing
2. Firebase persistence at `/games/{gameId}` path
3. Automatic cleanup of expired locks (10-second timeout)
4. Game state persists even when no players are connected

### Win Condition Detection (Multiplayer)
- GameProvider exposes isGameWon getter (unchanged logic)
- Win condition broadcasted to all connected players simultaneously
- Victory celebration displayed across all player sessions

## Testing Strategy

### Unit Test Coverage
- **Models**: Card stacking logic, deck operations, pile validation, Firebase serialization
- **GameLogic**: All move validations and executions (unchanged)
- **GameProvider**: State management, Firebase integration, multiplayer coordination
- **FirebaseService**: Database operations, real-time listeners, error handling
- **Multiplayer Models**: GameLock and DragState functionality
- **Widgets**: UI component behavior with multiplayer indicators

### Multiplayer Test Scenarios
- **Concurrent Actions**: Multiple players attempting moves simultaneously
- **Lock Management**: Lock acquisition, timeout, and release
- **Network Issues**: Connection drops, reconnection, state recovery
- **Edge Cases**: Invalid game IDs, corrupted Firebase data, lock conflicts

### Test Organization
- Mirror source structure in test/ directory
- Comprehensive test cases for game rules and multiplayer scenarios
- Firebase service mocking for reliable unit tests
- End-to-end multiplayer testing with multiple browser instances

## Performance Considerations

### Web Optimization
- Minimal widget rebuilds through Provider (unchanged)
- Efficient drag-and-drop with Flutter's built-in capabilities
- Real-time Firebase listeners optimized for web performance
- Debounced drag position updates to reduce Firebase calls

### Memory Management
- Game state limited to 52 cards + multiplayer metadata
- Firebase listeners properly disposed to prevent memory leaks
- Efficient JSON serialization for Firebase operations
- Stateless widgets where possible for performance

### Network Optimization
- Batch Firebase operations where possible
- Optimistic UI updates with rollback on conflicts
- Connection state monitoring and error recovery
- Minimal data transfer through targeted Firebase paths

## Firebase Integration Architecture

### Data Structure
```
/games
  /{gameId}
    /gameState - Complete game state JSON (includes seed field)
    /locks
      /{playerId} - Active locks with expiration
    /dragPositions
      /{playerId} - Real-time drag coordinates
```

### Security Rules
- Games readable/writable by any authenticated session
- Lock cleanup through expiration timestamps
- Drag positions automatically cleaned up on disconnect

### Real-Time Streams
1. **Game State Stream**: `/games/{gameId}/gameState`
   - Triggers: Card movements, game state changes
   - Purpose: Keep all players synchronized with current game
2. **Locks Stream**: `/games/{gameId}/locks`
   - Triggers: Lock acquisition/release, timeout cleanup
   - Purpose: Coordinate turn-based actions between players
3. **Drag Positions Stream**: `/games/{gameId}/dragPositions`
   - Triggers: Real-time drag movements
   - Purpose: Show other players' drag operations in progress

## Extensibility Points

### Adding New Multiplayer Features
- Player indicators and avatars through extended player models
- Chat system via additional Firebase paths
- Spectator mode with read-only game access
- Game history and replay functionality

### Multiplayer Game Variants
- Different solitaire games following same multiplayer pattern
- Custom rule sets synchronized via Firebase
- Tournament and scoring systems

### UI Customization
- Multiplayer-aware themes with player color coding
- Real-time collaboration indicators
- Enhanced visual feedback for multiplayer actions

This architecture provides a robust foundation for real-time multiplayer solitaire gaming while maintaining clean, testable, and scalable code patterns.
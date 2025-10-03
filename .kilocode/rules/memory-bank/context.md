# Current Context: Coop Klondike

## Current Work Focus

Planning integration of user-provided seed for deterministic deck shuffling in multiplayer games. This enhances reproducibility for testing and sharing while maintaining real-time Firebase sync.

## Recent Changes

- **Firebase Integration**: Added Firebase Realtime Database for persistent multiplayer game state
- **Multiplayer Architecture**: Implemented real-time collaborative gameplay with URL-based game sessions
- **Concurrency Control**: Added GameLock model with turn-based locking system (10-second expiration)
- **Real-Time Synchronization**: Three concurrent Firebase streams (game state, locks, drag positions)
- **Player Identity System**: Unique 10-character player IDs for session-based multiplayer
- **Live Drag Sharing**: DragState model enables real-time drag position synchronization across players
- **Session Management**: URL format `/game/{gameId}` for shareable multiplayer sessions
- **Firebase Service**: New FirebaseService for real-time database operations
- **Lock-Based Actions**: All game actions wrapped in acquire-lock → execute → release-lock pattern
- **Cross-Player UI Updates**: Real-time listeners trigger UI rebuilds across all connected players
- **Game State Persistence**: Complete state stored at Firebase path `/games/{gameId}`
- **Conflict Resolution**: Automatic lock timeout and visual feedback for concurrent actions
- **Deterministic Shuffling**: Planned user-provided seed (10-15 char passphrase) for reproducible deck shuffling, stored in GameState and synced via Firebase

## Next Steps

- Implement seed integration: Update models (GameState, Deck), providers (GameProvider init/seed handling), UI (creation screen, settings display), and tests (seeded shuffle determinism)
- Complete memory bank documentation updates to reflect multiplayer architecture
- Address identified synchronization issues in concurrent operations
- Evaluate deployment to Firebase Hosting for production multiplayer sessions
- Consider additional multiplayer features (player indicators, chat, spectator mode)
- Assess testing coverage for multiplayer scenarios and edge cases
- Update brief.md to reflect multiplayer scope and seed feature

## Project Status

- **Codebase**: Complete multiplayer implementation with Firebase integration; seed planning documented
- **Features**: All core Klondike rules implemented in real-time collaborative context; seed integration planned
- **Testing**: Comprehensive unit test coverage + E2E testing setup + multiplayer test scenarios needed; seed tests pending
- **Architecture**: Clean separation maintained with Firebase service layer for real-time operations; seed handling documented
- **Documentation**: Memory bank updates in progress to reflect current multiplayer state and seed planning
- **Deployment**: Ready for Firebase Hosting deployment with multiplayer session support
import '../providers/game_provider.dart';
import 'test_hooks_stub.dart'
    if (dart.library.js_util) 'test_hooks_web.dart';

void registerTestHooks(GameProvider provider) {
  registerTestHooksImpl(provider);
}

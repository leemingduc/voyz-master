import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/services/user_presence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserPresenceService', () {
    test('initializes and manages ticker timer', () {
      final service = UserPresenceService.instance;
      service.init();

      expect(service.currentTick.value, isNotNull);
      final initialTick = service.currentTick.value;
      expect(initialTick.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);

      service.stop();
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:moto_logg/services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingService', () {
    test('defaults to false when key is not set', () async {
      final seen = await OnboardingService.hasSeenFeatures();
      expect(seen, isFalse);
    });

    test('returns true after markFeaturesSeen is called', () async {
      await OnboardingService.markFeaturesSeen();
      final seen = await OnboardingService.hasSeenFeatures();
      expect(seen, isTrue);
    });

    test('resets back to false when resetFeaturesSeen is called', () async {
      await OnboardingService.markFeaturesSeen();
      expect(await OnboardingService.hasSeenFeatures(), isTrue);

      await OnboardingService.resetFeaturesSeen();
      expect(await OnboardingService.hasSeenFeatures(), isFalse);
    });
  });
}

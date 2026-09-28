import 'package:cs2_tracker/models/cs_rank_enums.dart';
import 'package:cs2_tracker/services/weekly_reset_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('PremierTier mapping', () {
    test('rangos correctos', () {
      expect(tierForPremier(0), PremierTier.gray);
      expect(tierForPremier(4999), PremierTier.gray);
      expect(tierForPremier(5000), PremierTier.lightBlue);
      expect(tierForPremier(9999), PremierTier.lightBlue);
      expect(tierForPremier(10000), PremierTier.blue);
      expect(tierForPremier(14999), PremierTier.blue);
      expect(tierForPremier(15000), PremierTier.purple);
      expect(tierForPremier(19999), PremierTier.purple);
      expect(tierForPremier(20000), PremierTier.pink);
      expect(tierForPremier(24999), PremierTier.pink);
      expect(tierForPremier(25000), PremierTier.red);
      expect(tierForPremier(29999), PremierTier.red);
      expect(tierForPremier(30000), PremierTier.gold);
      expect(tierForPremier(99999), PremierTier.gold);
    });
  });

  group('WeeklyResetService', () {
    setUpAll(() {
      tzdata.initializeTimeZones();
    });

    test('nextReset devuelve siempre martes 18:00 en America/Los_Angeles', () {
      final svc = WeeklyResetService();
      final next = svc.nextReset();
      expect(next.weekday, DateTime.tuesday);
      expect(next.hour, 18);
      expect(next.minute, 0);
      expect(next.location.name, 'America/Los_Angeles');
    });

    test('nextReset siempre está en el futuro', () {
      final svc = WeeklyResetService();
      final now = tz.TZDateTime.now(tz.getLocation('America/Los_Angeles'));
      expect(svc.nextReset().isAfter(now), isTrue);
    });

    test('lastReset + 7d == nextReset', () {
      final svc = WeeklyResetService();
      final diff = svc.nextReset().difference(svc.lastReset());
      expect(diff.inHours, 24 * 7);
    });
  });
}

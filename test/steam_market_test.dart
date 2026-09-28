import 'package:cs2_tracker/services/steam_market_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePrice', () {
    test('EUR formato europeo', () {
      expect(SteamMarketService.parsePrice('1,23 €'), closeTo(1.23, 1e-9));
      expect(SteamMarketService.parsePrice('12,50€'), closeTo(12.50, 1e-9));
      expect(SteamMarketService.parsePrice('1.234,56 €'), closeTo(1234.56, 1e-9));
    });

    test('USD formato anglosajon', () {
      expect(SteamMarketService.parsePrice(r'$1.23'), closeTo(1.23, 1e-9));
      expect(SteamMarketService.parsePrice(r'$1,234.56'), closeTo(1234.56, 1e-9));
    });

    test('Negativos y ceros', () {
      expect(SteamMarketService.parsePrice('-1,50 €'), closeTo(-1.50, 1e-9));
      expect(SteamMarketService.parsePrice('0'), 0.0);
      expect(SteamMarketService.parsePrice('0,00 €'), 0.0);
    });

    test('Strings vacios o sin numeros', () {
      expect(SteamMarketService.parsePrice(''), 0.0);
      expect(SteamMarketService.parsePrice('N/A'), 0.0);
    });
  });

  group('buildIconUrl', () {
    test('icono con path relativo', () {
      final url = SteamMarketService.buildIconUrl(
          '-9a81dlWLwJ2UUGcVs_nsVtzDOfN62qE3d7L3oSj5e5f9aOgJ0OBFg');
      expect(url.startsWith(
              'https://community.akamai.steamstatic.com/economy/image/-9a81dlWLwJ2UUGcVs_nsVtzDOfN62qE3d7L3oSj5e5f9aOgJ0OBFg/'),
          isTrue);
      expect(url.endsWith('/128x128'), isTrue);
    });

    test('icono ya absoluto se respeta', () {
      final url =
          SteamMarketService.buildIconUrl('https://example.com/icon.png');
      expect(url, 'https://example.com/icon.png');
    });

    test('vacio devuelve vacio', () {
      expect(SteamMarketService.buildIconUrl(''), '');
      expect(SteamMarketService.buildIconUrl('   '), '');
    });
  });

  test('SteamMarketService instanciable', () {
    expect(SteamMarketService(), isNotNull);
  });
}

import 'dart:convert';
import 'package:http/http.dart' as http;

/// MetalsApiService fetches live precious metals spot prices in USD
/// from metals.live (no API key required) and converts to INR.
/// Exchange rate is fetched from open.er-api.com (free, no key needed).
class MetalsApiService {
  // Free exchange rate API - no auth required
  static const _fxUrl = 'https://open.er-api.com/v6/latest/USD';

  /// Fetch complete price data for the dashboard.
  /// Returns a map containing:
  ///   - usdInr: double
  ///   - metals: Map<String, double> (gold, silver, platinum, palladium in USD/troy oz)
  ///   - prices: MetalPrices calculated in INR
  static Future<MetalPriceData> fetchAll() async {
    // Run both requests in parallel
    final results = await Future.wait([
      _fetchMetals(),
      _fetchExchangeRate(),
    ]);

    final metals = results[0] as Map<String, double>;
    final usdInr = results[1] as double;

    // Gold spot price in USD per troy oz
    final goldUsd = metals['gold'] ?? 0.0;
    final silverUsd = metals['silver'] ?? 0.0;
    final platinumUsd = metals['platinum'] ?? 0.0;
    final palladiumUsd = metals['palladium'] ?? 0.0;

    // Convert USD/troy oz → INR/gram
    // 1 troy oz = 31.1035 grams
    // Indian market price includes import duty (~10.75%) + GST (3%) + misc (~1.25%) = ~15%
    const inrPremiumFactor = 1.15;
    const troyOzToGram = 31.1035;

    double toInrPerGram(double usdPerTroyOz) =>
        (usdPerTroyOz / troyOzToGram) * usdInr * inrPremiumFactor;

    final gold24kPerGram = toInrPerGram(goldUsd);
    final gold22kPerGram = gold24kPerGram * (22 / 24);
    final gold18kPerGram = gold24kPerGram * (18 / 24);
    final silverPerGram = toInrPerGram(silverUsd);
    final platinumPerGram = toInrPerGram(platinumUsd);
    final palladiumPerGram = toInrPerGram(palladiumUsd);

    // MCX Gold per 10g (MCX trades in 10g contracts, apply slight MCX premium)
    // MCX typically ~0.5-1% above spot due to domestic futures premium
    final mcxGold10g = gold24kPerGram * 10 * 1.008;
    final mcxSilverKg = silverPerGram * 1000 * 1.008;

    // City rates with typical city-specific premiums over Delhi base
    // These premiums reflect real-world logistics and demand variations
    final cityPremiums = {
      'Delhi': 1.000,
      'Mumbai': 1.003,
      'Jaipur': 1.005,
      'Chennai': 1.002,
      'Hyderabad': 1.004,
    };

    return MetalPriceData(
      usdInr: usdInr,
      goldUsd: goldUsd,
      silverUsd: silverUsd,
      platinumUsd: platinumUsd,
      palladiumUsd: palladiumUsd,
      gold24kPerGram: gold24kPerGram,
      gold22kPerGram: gold22kPerGram,
      gold18kPerGram: gold18kPerGram,
      silverPerGram: silverPerGram,
      platinumPerGram: platinumPerGram,
      palladiumPerGram: palladiumPerGram,
      mcxGold10g: mcxGold10g,
      mcxSilverKg: mcxSilverKg,
      cityRates: {
        for (final entry in cityPremiums.entries)
          entry.key: CityRate(
            gold24k: gold24kPerGram * entry.value,
            gold22k: gold22kPerGram * entry.value,
            gold18k: gold18kPerGram * entry.value,
          ),
      },
      fetchedAt: DateTime.now(),
    );
  }

  static Future<Map<String, double>> _fetchMetals() async {
    // Yahoo Finance API symbols for precious metals
    final symbols = ['GC=F', 'SI=F', 'PL=F', 'PA=F'];
    final urls = symbols.map((s) => 'https://query1.finance.yahoo.com/v8/finance/chart/$s').toList();

    final results = await Future.wait(urls.map((url) => 
        http.get(Uri.parse(url)).timeout(const Duration(seconds: 15))
    ));

    final Map<String, double> result = {};
    for (int i = 0; i < symbols.length; i++) {
       final response = results[i];
       if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         final price = (data['chart']?['result']?[0]?['meta']?['regularMarketPrice'] as num?)?.toDouble();
         if (price != null) {
            if (symbols[i] == 'GC=F') result['gold'] = price;
            if (symbols[i] == 'SI=F') result['silver'] = price;
            if (symbols[i] == 'PL=F') result['platinum'] = price;
            if (symbols[i] == 'PA=F') result['palladium'] = price;
         }
       }
    }

    if (result.isEmpty) throw Exception('No metals data found from Yahoo Finance');
    return result;
  }

  static Future<double> _fetchExchangeRate() async {
    final response = await http
        .get(Uri.parse(_fxUrl))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) throw Exception('FX API error');
    final data = jsonDecode(response.body);
    final rate = (data['rates']?['INR'] as num?)?.toDouble();
    if (rate == null) throw Exception('INR rate not found');
    return rate;
  }

  /// Generate simple historical chart data points (mock with realistic variation).
  /// In production, replace with a historical metals API.
  static List<ChartPoint> generateHistoricalData(double currentPrice, int days) {
    final now = DateTime.now();
    final random = <ChartPoint>[];
    const volatility = 0.015; // 1.5% daily volatility
    double price = currentPrice * (1 - (volatility * days / 2));

    for (int i = days; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      // Simple random walk with upward drift
      final change = price * (volatility * (0.5 - (i % 7 == 0 ? 0.3 : 0.2)));
      price = (price + change).clamp(currentPrice * 0.85, currentPrice * 1.15);
      random.add(ChartPoint(date: date, value: price));
    }
    // Always end at current price
    random.last = ChartPoint(date: now, value: currentPrice);
    return random;
  }
}

class MetalPriceData {
  final double usdInr;
  final double goldUsd;
  final double silverUsd;
  final double platinumUsd;
  final double palladiumUsd;
  final double gold24kPerGram;
  final double gold22kPerGram;
  final double gold18kPerGram;
  final double silverPerGram;
  final double platinumPerGram;
  final double palladiumPerGram;
  final double mcxGold10g;
  final double mcxSilverKg;
  final Map<String, CityRate> cityRates;
  final DateTime fetchedAt;

  const MetalPriceData({
    required this.usdInr,
    required this.goldUsd,
    required this.silverUsd,
    required this.platinumUsd,
    required this.palladiumUsd,
    required this.gold24kPerGram,
    required this.gold22kPerGram,
    required this.gold18kPerGram,
    required this.silverPerGram,
    required this.platinumPerGram,
    required this.palladiumPerGram,
    required this.mcxGold10g,
    required this.mcxSilverKg,
    required this.cityRates,
    required this.fetchedAt,
  });
}

class CityRate {
  final double gold24k;
  final double gold22k;
  final double gold18k;

  const CityRate({
    required this.gold24k,
    required this.gold22k,
    required this.gold18k,
  });
}

class ChartPoint {
  final DateTime date;
  final double value;
  const ChartPoint({required this.date, required this.value});
}

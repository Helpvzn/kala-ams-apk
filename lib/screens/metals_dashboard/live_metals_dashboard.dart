import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/metals_api_service.dart';
import 'gold_calculator_screen.dart';
import 'price_chart_screen.dart';

// ─── Gold theme constants ───────────────────────────────────────────
const kGold = Color(0xFFD4AF37);
const kGoldLight = Color(0xFFF0D060);
const kGoldDark = Color(0xFF9E7C00);
const kDarkBg = Color(0xFF0A0A0A);
const kCardBg = Color(0xFF111111);
const kCardBorder = Color(0xFF2A2A2A);

class LiveMetalsDashboardScreen extends StatefulWidget {
  const LiveMetalsDashboardScreen({super.key});

  @override
  State<LiveMetalsDashboardScreen> createState() => _LiveMetalsDashboardScreenState();
}

class _LiveMetalsDashboardScreenState extends State<LiveMetalsDashboardScreen>
    with TickerProviderStateMixin {
  MetalPriceData? _data;
  MetalPriceData? _prevData;
  bool _loading = true;
  String _error = '';
  Timer? _refreshTimer;
  int _nextRefresh = 60;
  Timer? _countdownTimer;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  final NumberFormat _inrFmt = NumberFormat('#,##,##0.00', 'en_IN');
  final NumberFormat _inrFmtShort = NumberFormat('#,##,##0', 'en_IN');
  final DateFormat _timeFmt = DateFormat('hh:mm:ss a');
  final DateFormat _dateFmt = DateFormat('EEE, dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.repeat(reverse: true);

    _fetchData();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _nextRefresh = 60;

    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _fetchData();
      setState(() => _nextRefresh = 60);
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _nextRefresh = (_nextRefresh - 1).clamp(0, 60));
    });
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await MetalsApiService.fetchAll();
      if (mounted) {
        setState(() {
          _prevData = _data;
          _data = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not refresh prices. Showing last known values.';
        });
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: kGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [kGoldDark, kGold], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.diamond_outlined, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live Metals', style: TextStyle(color: kGold, fontSize: 15, fontWeight: FontWeight.bold)),
                Text('Dashboard', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined, color: kGold),
            tooltip: 'Gold Calculator',
            onPressed: () {
              if (_data != null) {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => GoldCalculatorScreen(data: _data!)));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kGold),
            tooltip: 'Refresh Now',
            onPressed: () {
              _fetchData();
              setState(() => _nextRefresh = 60);
            },
          ),
        ],
      ),
      body: _data == null && _loading
          ? const Center(child: CircularProgressIndicator(color: kGold))
          : RefreshIndicator(
              color: kGold,
              backgroundColor: kCardBg,
              onRefresh: () async {
                await _fetchData();
                setState(() => _nextRefresh = 60);
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  if (_error.isNotEmpty)
                    SliverToBoxAdapter(child: _buildErrorBanner()),
                  SliverToBoxAdapter(child: _buildSectionTitle('Live Spot Prices', Icons.show_chart_rounded)),
                  SliverToBoxAdapter(child: _buildPriceGrid()),
                  SliverToBoxAdapter(child: _buildSectionTitle('MCX Market', Icons.candlestick_chart_rounded)),
                  SliverToBoxAdapter(child: _buildMcxSection()),
                  SliverToBoxAdapter(child: _buildSectionTitle('City Gold Rates (24K / 10g)', Icons.location_city_rounded)),
                  SliverToBoxAdapter(child: _buildCityRates()),
                  SliverToBoxAdapter(child: _buildSectionTitle('Historical Chart', Icons.bar_chart_rounded)),
                  SliverToBoxAdapter(child: _buildChartButton()),
                  SliverToBoxAdapter(child: _buildSectionTitle('Market Summary', Icons.summarize_outlined)),
                  SliverToBoxAdapter(child: _buildMarketSummary()),
                  SliverToBoxAdapter(child: _buildStatusPanel()),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1500), Color(0xFF0D0D00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGoldDark.withAlpha(100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Live Precious Metals Dashboard',
                    style: TextStyle(color: kGold, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (_, __) {
                      final now = DateTime.now();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_dateFmt.format(now),
                              style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          Text(_timeFmt.format(now),
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      );
                    }),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _error.isEmpty ? Colors.greenAccent : Colors.orangeAccent,
                        boxShadow: [BoxShadow(
                          color: (_error.isEmpty ? Colors.green : Colors.orange).withAlpha(180),
                          blurRadius: 6 * _pulseAnim.value,
                          spreadRadius: 1,
                        )],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(_error.isEmpty ? 'LIVE' : 'CACHED',
                        style: TextStyle(
                            color: _error.isEmpty ? Colors.greenAccent : Colors.orangeAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text('Next refresh: ${_nextRefresh}s',
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
              if (_data != null) ...[
                const SizedBox(height: 2),
                Text('₹ ${_inrFmt.format(_data!.usdInr)} / USD',
                    style: const TextStyle(color: kGoldDark, fontSize: 10)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Error banner ─────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orangeAccent.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(_error,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12))),
        ],
      ),
    );
  }

  // ── Section Title ────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: kGold, size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: kGoldDark.withAlpha(60))),
        ],
      ),
    );
  }

  // ── Price Grid ───────────────────────────────────────────────────
  Widget _buildPriceGrid() {
    if (_data == null) return const Center(child: CircularProgressIndicator(color: kGold));
    final d = _data!;
    final p = _prevData;

    final cards = [
      _MetalCard(
        label: 'Gold 24K',
        sublabel: 'Per Gram',
        icon: '🥇',
        price: d.gold24kPerGram,
        prevPrice: p?.gold24kPerGram,
        color: kGold,
        purity: 99.9,
      ),
      _MetalCard(
        label: 'Gold 22K',
        sublabel: 'Per Gram',
        icon: '🥇',
        price: d.gold22kPerGram,
        prevPrice: p?.gold22kPerGram,
        color: const Color(0xFFE8C441),
        purity: 91.6,
      ),
      _MetalCard(
        label: 'Gold 18K',
        sublabel: 'Per Gram',
        icon: '🥇',
        price: d.gold18kPerGram,
        prevPrice: p?.gold18kPerGram,
        color: const Color(0xFFC8AA30),
        purity: 75.0,
      ),
      _MetalCard(
        label: 'Silver',
        sublabel: 'Per Gram',
        icon: '🥈',
        price: d.silverPerGram,
        prevPrice: p?.silverPerGram,
        color: const Color(0xFFC0C0C0),
        purity: 99.9,
      ),
      _MetalCard(
        label: 'Platinum',
        sublabel: 'Per Gram',
        icon: '💎',
        price: d.platinumPerGram,
        prevPrice: p?.platinumPerGram,
        color: const Color(0xFFE5E4E2),
        purity: 95.0,
      ),
      _MetalCard(
        label: 'Palladium',
        sublabel: 'Per Gram',
        icon: '⚪',
        price: d.palladiumPerGram,
        prevPrice: p?.palladiumPerGram,
        color: const Color(0xFFD0CFD0),
        purity: 95.0,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.25,
        ),
        itemCount: cards.length,
        itemBuilder: (_, i) => _buildPriceCard(cards[i]),
      ),
    );
  }

  Widget _buildPriceCard(_MetalCard c) {
    final cur = c.price;
    final prev = c.prevPrice;
    final diff = (prev != null && prev != 0) ? cur - prev : 0.0;
    final up = diff >= 0;
    final hasChange = prev != null && prev != 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.color.withAlpha(60)),
        gradient: LinearGradient(
          colors: [c.color.withAlpha(25), kCardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(c.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.label,
                        style: TextStyle(
                            color: c.color, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('${c.purity}% Pure',
                        style: const TextStyle(color: Colors.white24, fontSize: 9)),
                  ],
                ),
              ),
              if (hasChange)
                Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 14,
                    color: up ? Colors.greenAccent : Colors.redAccent),
            ],
          ),
          const Spacer(),
          Text('₹${_inrFmtShort.format(cur)}',
              style: TextStyle(
                  color: c.color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          Text(c.sublabel,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
          if (hasChange) ...[
            const SizedBox(height: 2),
            Text(
              '${up ? '+' : ''}₹${_inrFmt.format(diff)}',
              style: TextStyle(
                  fontSize: 10,
                  color: up ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  // ── MCX Section ──────────────────────────────────────────────────
  Widget _buildMcxSection() {
    if (_data == null) return const SizedBox.shrink();
    final d = _data!;
    final p = _prevData;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildMcxCard(
            'MCX Gold',
            '10g',
            d.mcxGold10g,
            p?.mcxGold10g,
            kGold,
            Icons.monetization_on_outlined,
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildMcxCard(
            'MCX Silver',
            '1 Kg',
            d.mcxSilverKg,
            p?.mcxSilverKg,
            const Color(0xFFC0C0C0),
            Icons.water_drop_outlined,
          )),
        ],
      ),
    );
  }

  Widget _buildMcxCard(String label, String unit, double price, double? prev, Color color, IconData icon) {
    final diff = (prev != null && prev != 0) ? price - prev : 0.0;
    final pct = (prev != null && prev != 0) ? (diff / prev) * 100 : 0.0;
    final up = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          Text('₹${_inrFmtShort.format(price)}',
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          Text('Per $unit (Estimated)', style: const TextStyle(color: Colors.white38, fontSize: 10)),
          if (prev != null && prev != 0) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 12, color: up ? Colors.greenAccent : Colors.redAccent),
              const SizedBox(width: 3),
              Text('${pct.abs().toStringAsFixed(2)}%',
                  style: TextStyle(
                      color: up ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ]),
          ],
        ],
      ),
    );
  }

  // ── City Rates ───────────────────────────────────────────────────
  Widget _buildCityRates() {
    if (_data == null) return const SizedBox.shrink();
    final rates = _data!.cityRates;

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: rates.length,
        itemBuilder: (_, i) {
          final entry = rates.entries.elementAt(i);
          final city = entry.key;
          final rate = entry.value;
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kGoldDark.withAlpha(60)),
              gradient: LinearGradient(
                colors: [kGold.withAlpha(20), kCardBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('📍', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(city,
                      style: const TextStyle(color: kGold, fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
                const SizedBox(height: 8),
                _cityRateRow('24K', rate.gold24k * 10),
                _cityRateRow('22K', rate.gold22k * 10),
                _cityRateRow('18K', rate.gold18k * 10),
                const SizedBox(height: 2),
                const Text('Per 10g • Estimated', style: TextStyle(color: Colors.white24, fontSize: 9)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cityRateRow(String label, double val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text('₹${_inrFmtShort.format(val)}',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Historical Chart Button ──────────────────────────────────────
  Widget _buildChartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          if (_data != null) {
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => PriceChartScreen(currentPrice: _data!.gold24kPerGram)));
          }
        },
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kGoldDark.withAlpha(80)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.show_chart_rounded, color: kGold),
              const SizedBox(width: 10),
              const Text('View Historical Price Chart',
                  style: TextStyle(color: kGold, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_ios_rounded, color: kGoldDark, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  // ── Market Summary ───────────────────────────────────────────────
  Widget _buildMarketSummary() {
    if (_data == null) return const SizedBox.shrink();
    final d = _data!;
    final p = _prevData;

    String trend = 'Neutral';
    Color trendColor = Colors.white54;
    IconData trendIcon = Icons.remove_rounded;

    if (p != null && p.gold24kPerGram != 0) {
      final change = d.gold24kPerGram - p.gold24kPerGram;
      if (change > 0.5) {
        trend = '🟢 Bullish';
        trendColor = Colors.greenAccent;
        trendIcon = Icons.trending_up_rounded;
      } else if (change < -0.5) {
        trend = '🔴 Bearish';
        trendColor = Colors.redAccent;
        trendIcon = Icons.trending_down_rounded;
      } else {
        trend = '🟡 Neutral';
        trendColor = Colors.amberAccent;
        trendIcon = Icons.trending_flat_rounded;
      }
    }

    final isMarketHours = () {
      final now = DateTime.now();
      final wd = now.weekday;
      final h = now.hour;
      // MCX: Mon–Fri 9am–11:30pm IST; Sat 9am–2pm
      if (wd >= 1 && wd <= 5) return h >= 9 && h < 23;
      if (wd == 6) return h >= 9 && h < 14;
      return false;
    }();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGoldDark.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem('Market Status',
                  isMarketHours ? 'OPEN' : 'CLOSED',
                  isMarketHours ? Colors.greenAccent : Colors.redAccent),
              _summaryItem('Gold Trend', trend, trendColor),
              _summaryItem('USD/INR', '₹${_inrFmt.format(d.usdInr)}', kGold),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(trendIcon, color: trendColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _generateSummaryText(d, p, trend),
                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _generateSummaryText(MetalPriceData d, MetalPriceData? p, String trend) {
    final goldPer10g = d.gold24kPerGram * 10;
    if (p == null) {
      return 'Gold 24K is trading at ₹${_inrFmtShort.format(goldPer10g)}/10g. '
          'Silver at ₹${_inrFmtShort.format(d.silverPerGram)}/g. '
          'USD/INR at ₹${_inrFmt.format(d.usdInr)}.';
    }
    final diff = d.gold24kPerGram - p.gold24kPerGram;
    final pct = p.gold24kPerGram != 0 ? (diff / p.gold24kPerGram) * 100 : 0.0;
    final dir = diff >= 0 ? 'up' : 'down';
    return 'Gold 24K is $dir ₹${_inrFmt.format(diff.abs())} (${pct.abs().toStringAsFixed(2)}%) '
        'to ₹${_inrFmtShort.format(goldPer10g)}/10g. '
        'Market sentiment is $trend. USD/INR: ₹${_inrFmt.format(d.usdInr)}.';
  }

  // ── Status Panel ─────────────────────────────────────────────────
  Widget _buildStatusPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statusItem(Icons.api_rounded, 'API',
              _error.isEmpty ? 'Connected' : 'Cached',
              _error.isEmpty ? Colors.greenAccent : Colors.orangeAccent),
          _statusItem(Icons.update_rounded, 'Updated',
              _data != null ? _timeFmt.format(_data!.fetchedAt) : '—',
              Colors.white54),
          _statusItem(Icons.timer_outlined, 'Refresh in',
              '${_nextRefresh}s', kGoldDark),
        ],
      ),
    );
  }

  Widget _statusItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9)),
        Text(value,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Internal data class for price card ──────────────────────────
class _MetalCard {
  final String label;
  final String sublabel;
  final String icon;
  final double price;
  final double? prevPrice;
  final Color color;
  final double purity;

  const _MetalCard({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.price,
    this.prevPrice,
    required this.color,
    required this.purity,
  });
}

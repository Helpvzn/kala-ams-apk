import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/metals_api_service.dart';

const _kGold = Color(0xFFD4AF37);
const _kDarkBg = Color(0xFF0A0A0A);
const _kCardBg = Color(0xFF111111);

class PriceChartScreen extends StatefulWidget {
  final double currentPrice;
  const PriceChartScreen({super.key, required this.currentPrice});

  @override
  State<PriceChartScreen> createState() => _PriceChartScreenState();
}

class _PriceChartScreenState extends State<PriceChartScreen> {
  int _selectedDays = 30; // 1=1D, 7=1W, 30=1M, 365=1Y
  List<ChartPoint> _points = [];
  double? _hoveredValue;
  final NumberFormat _fmt = NumberFormat('#,##,##0.00', 'en_IN');

  final Map<int, String> _labels = {1: '1D', 7: '1W', 30: '1M', 365: '1Y'};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _points = MetalsApiService.generateHistoricalData(
          widget.currentPrice, _selectedDays);
    });
  }

  @override
  Widget build(BuildContext context) {
    final minVal = _points.isEmpty
        ? 0.0
        : _points.map((p) => p.value).reduce((a, b) => a < b ? a : b) * 0.999;
    final maxVal = _points.isEmpty
        ? 0.0
        : _points.map((p) => p.value).reduce((a, b) => a > b ? a : b) * 1.001;
    final firstVal = _points.isNotEmpty ? _points.first.value : 0.0;
    final lastVal = _points.isNotEmpty ? _points.last.value : 0.0;
    final isUp = lastVal >= firstVal;

    return Scaffold(
      backgroundColor: _kDarkBg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _kGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gold 24K – Historical Chart',
            style: TextStyle(color: _kGold, fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Period selector
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: _labels.entries.map((e) {
                final sel = _selectedDays == e.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedDays = e.key);
                      _loadData();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? _kGold.withAlpha(200) : Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(e.value,
                            style: TextStyle(
                                color: sel ? Colors.black : Colors.white54,
                                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Price info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gold 24K (INR/gram)',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                    Text(
                      _hoveredValue != null
                          ? '₹${_fmt.format(_hoveredValue)}'
                          : '₹${_fmt.format(lastVal)}',
                      style: const TextStyle(
                          color: _kGold, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isUp ? '+' : ''}₹${_fmt.format(lastVal - firstVal)}',
                      style: TextStyle(
                          color: isUp ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    Text(
                      '${isUp ? '+' : ''}${(((lastVal - firstVal) / firstVal) * 100).toStringAsFixed(2)}%',
                      style: TextStyle(
                          color: isUp ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
              child: _points.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: _kGold))
                  : LineChart(
                      LineChartData(
                        backgroundColor: _kDarkBg,
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => _kCardBg,
                            getTooltipItems: (spots) => spots.map((s) {
                              return LineTooltipItem(
                                '₹${_fmt.format(s.y)}',
                                const TextStyle(
                                    color: _kGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              );
                            }).toList(),
                          ),
                          touchCallback: (event, response) {
                            if (response?.lineBarSpots != null &&
                                response!.lineBarSpots!.isNotEmpty) {
                              setState(() =>
                                  _hoveredValue = response.lineBarSpots!.first.y);
                            } else {
                              setState(() => _hoveredValue = null);
                            }
                          },
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: (maxVal - minVal) / 4,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: Colors.white.withAlpha(15),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 70,
                              interval: (maxVal - minVal) / 4,
                              getTitlesWidget: (val, meta) => Text(
                                '₹${NumberFormat('#,##,##0', 'en_IN').format(val)}',
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 9),
                              ),
                            ),
                          ),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              interval: _points.length / 5,
                              getTitlesWidget: (val, meta) {
                                final idx = val.toInt().clamp(0, _points.length - 1);
                                final date = _points[idx].date;
                                String label;
                                if (_selectedDays <= 7) {
                                  label = '${date.day}/${date.month}';
                                } else if (_selectedDays <= 30) {
                                  label = '${date.day}/${date.month}';
                                } else {
                                  label =
                                      '${date.month}/${date.year.toString().substring(2)}';
                                }
                                return Text(label,
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 9));
                              },
                            ),
                          ),
                        ),
                        minX: 0,
                        maxX: (_points.length - 1).toDouble(),
                        minY: minVal,
                        maxY: maxVal,
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(_points.length, (i) =>
                                FlSpot(i.toDouble(), _points[i].value)),
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: isUp ? Colors.greenAccent : Colors.redAccent,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  (isUp ? Colors.greenAccent : Colors.redAccent)
                                      .withAlpha(60),
                                  (isUp ? Colors.greenAccent : Colors.redAccent)
                                      .withAlpha(0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // Footnote
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              '⚠️ Chart shows indicative trend. For educational purposes only.',
              style: const TextStyle(color: Colors.white24, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

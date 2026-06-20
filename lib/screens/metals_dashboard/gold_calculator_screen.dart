import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/metals_api_service.dart';

const _kGold = Color(0xFFD4AF37);
const _kGoldDark = Color(0xFF9E7C00);
const _kDarkBg = Color(0xFF0A0A0A);
const _kCardBg = Color(0xFF111111);

class GoldCalculatorScreen extends StatefulWidget {
  final MetalPriceData data;
  const GoldCalculatorScreen({super.key, required this.data});

  @override
  State<GoldCalculatorScreen> createState() => _GoldCalculatorScreenState();
}

class _GoldCalculatorScreenState extends State<GoldCalculatorScreen> {
  String _selectedMetal = 'Gold';
  String _selectedPurity = '24K';
  final _weightCtrl = TextEditingController(text: '10');
  final _makingCtrl = TextEditingController(text: '0');
  String _makingType = 'Percentage'; // or 'Fixed'
  bool _includeGst = true;

  final NumberFormat _fmt = NumberFormat('#,##,##0.00', 'en_IN');

  // Purity options per metal
  final Map<String, List<String>> _purities = {
    'Gold': ['24K', '22K', '18K'],
    'Silver': ['99.9%'],
  };

  // Quick weight buttons
  final List<double> _quickWeights = [1, 2, 5, 10, 20, 50, 100];

  double get _pricePerGram {
    final d = widget.data;
    if (_selectedMetal == 'Gold') {
      switch (_selectedPurity) {
        case '24K': return d.gold24kPerGram;
        case '22K': return d.gold22kPerGram;
        case '18K': return d.gold18kPerGram;
      }
    }
    return d.silverPerGram;
  }

  double get _weight => double.tryParse(_weightCtrl.text) ?? 0;
  double get _makingChargeInput => double.tryParse(_makingCtrl.text) ?? 0;

  double get _metalValue => _pricePerGram * _weight;

  double get _makingCharge {
    if (_makingType == 'Fixed') return _makingChargeInput;
    return _metalValue * (_makingChargeInput / 100);
  }

  double get _subtotal => _metalValue + _makingCharge;

  double get _gstAmount => _includeGst ? _subtotal * 0.03 : 0;

  double get _total => _subtotal + _gstAmount;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _makingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDarkBg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _kGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gold Calculator',
            style: TextStyle(color: _kGold, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live rate info
            _buildLiveRateCard(),
            const SizedBox(height: 16),

            // Metal selector
            _buildSectionLabel('Metal Type'),
            _buildToggle(['Gold', 'Silver'], _selectedMetal, (val) {
              setState(() {
                _selectedMetal = val;
                _selectedPurity = _purities[val]!.first;
              });
            }),
            const SizedBox(height: 14),

            // Purity selector
            _buildSectionLabel('Purity'),
            _buildToggle(_purities[_selectedMetal]!, _selectedPurity, (val) {
              setState(() => _selectedPurity = val);
            }),
            const SizedBox(height: 14),

            // Weight input
            _buildSectionLabel('Weight (grams)'),
            TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: _kCardBg,
                hintText: '0.000',
                hintStyle: const TextStyle(color: Colors.white24),
                suffixText: 'g',
                suffixStyle: const TextStyle(color: _kGold),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kGoldDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kGold, width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),

            // Quick weight buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickWeights.map((w) {
                final sel = _weight == w;
                return GestureDetector(
                  onTap: () {
                    _weightCtrl.text = w == w.toInt() ? w.toInt().toString() : w.toString();
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _kGold : _kCardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? _kGold : Colors.white24, width: 1),
                    ),
                    child: Text(
                      '${w == w.toInt() ? w.toInt() : w}g',
                      style: TextStyle(
                          color: sel ? Colors.black : Colors.white54,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Making charge
            _buildSectionLabel('Making Charge'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _makingCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _kCardBg,
                      hintText: '0',
                      hintStyle: const TextStyle(color: Colors.white24),
                      suffixText: _makingType == 'Percentage' ? '%' : '₹',
                      suffixStyle: const TextStyle(color: _kGold),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _kGoldDark),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _kGold, width: 2),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                _buildToggle(['Percentage', 'Fixed'], _makingType, (val) {
                  setState(() => _makingType = val);
                }),
              ],
            ),
            const SizedBox(height: 16),

            // GST toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_outlined, color: _kGoldDark, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Include GST (3%)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        Text('Goods & Services Tax on jewellery',
                            style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _includeGst,
                    onChanged: (v) => setState(() => _includeGst = v),
                    activeThumbColor: _kGold,
                    activeTrackColor: _kGoldDark.withAlpha(150),
                    inactiveTrackColor: Colors.white12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Result card
            _buildResultCard(),
            const SizedBox(height: 20),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                '⚠️ Prices are calculated from live international spot rates (USD → INR). '
                'Actual jewellery prices may vary based on retailer margins and local taxes.',
                style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────

  Widget _buildLiveRateCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1A1500), Color(0xFF0D0D00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGoldDark.withAlpha(80)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _rateItem('Gold 24K', widget.data.gold24kPerGram, '/g'),
          _rateItem('Gold 22K', widget.data.gold22kPerGram, '/g'),
          _rateItem('Gold 18K', widget.data.gold18kPerGram, '/g'),
          _rateItem('Silver', widget.data.silverPerGram, '/g'),
        ],
      ),
    );
  }

  Widget _rateItem(String label, double price, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 2),
        Text('₹${_fmt.format(price)}',
            style: const TextStyle(color: _kGold, fontSize: 11, fontWeight: FontWeight.bold)),
        Text(unit, style: const TextStyle(color: Colors.white24, fontSize: 9)),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildToggle(List<String> options, String selected, ValueChanged<String> onChange) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final sel = selected == opt;
          return GestureDetector(
            onTap: () => onChange(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                gradient: sel
                    ? const LinearGradient(colors: [_kGoldDark, _kGold])
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(opt,
                  style: TextStyle(
                      color: sel ? Colors.black : Colors.white38,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1A1500), Color(0xFF0D0D00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGold.withAlpha(100), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_rounded, color: _kGold, size: 18),
              const SizedBox(width: 8),
              Text(
                '$_selectedPurity $_selectedMetal — ${_weight}g',
                style: const TextStyle(color: _kGold, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _resultRow('Metal Value', _metalValue),
          const Divider(color: Colors.white12, height: 20),
          _resultRow('Making Charge', _makingCharge,
              sub: _makingType == 'Percentage'
                  ? '(${_makingChargeInput.toStringAsFixed(1)}% of metal value)'
                  : '(Fixed amount)'),
          if (_includeGst) ...[
            const Divider(color: Colors.white12, height: 20),
            _resultRow('GST (3%)', _gstAmount),
          ],
          const Divider(color: _kGoldDark, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Price',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('₹${_fmt.format(_total)}',
                  style: const TextStyle(
                      color: _kGold, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kGold.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kGold.withAlpha(60)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Per Gram Rate Used',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                Text('₹${_fmt.format(_pricePerGram)}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, double amount, {String? sub}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            if (sub != null)
              Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
        Text('₹${_fmt.format(amount)}',
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

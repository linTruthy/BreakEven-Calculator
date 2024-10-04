import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Breakeven Calculator',
      theme: ThemeData(
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepOrange)
            .copyWith(secondary: Colors.orangeAccent),
      ),
      home: const BreakevenCalculator(),
    );
  }
}

class FixedCostItem {
  String name;
  double amount;

  FixedCostItem({required this.name, required this.amount});
}

class BreakevenCalculator extends StatefulWidget {
  const BreakevenCalculator({super.key});

  @override
  State<BreakevenCalculator> createState() => _BreakevenCalculatorState();
}

class _BreakevenCalculatorState extends State<BreakevenCalculator>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late AnimationController _resultsAnimationController;
  late Animation<double> _fadeInAnimation;

  List<FixedCostItem> fixedCosts = [
    FixedCostItem(name: 'Rent', amount: 0),
    FixedCostItem(name: 'Salaries', amount: 0),
    FixedCostItem(name: 'Utilities', amount: 0),
  ];
  double foodCost = 0;
  double averageCheck = 0;
  int daysPerMonth = 30;

  double breakEvenCovers = 0;
  double breakEvenSales = 0;
  double profitTargetCovers = 0;
  double profitTargetSales = 0;

  final currencyFormat = NumberFormat.currency(symbol: '\$');

  late AnimationController _totalFixedCostsAnimationController;
  late Animation<double> _totalFixedCostsAnimation;

  @override
  void initState() {
    super.initState();
    _resultsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(_resultsAnimationController);

    _totalFixedCostsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _totalFixedCostsAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
          parent: _totalFixedCostsAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _resultsAnimationController.dispose();
    _totalFixedCostsAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateTotalFixedCosts() {
    double oldTotal = _totalFixedCostsAnimation.value;
    double newTotal = fixedCosts.fold(0, (sum, item) => sum + item.amount);

    _totalFixedCostsAnimation = Tween<double>(
      begin: oldTotal,
      end: newTotal,
    ).animate(CurvedAnimation(
        parent: _totalFixedCostsAnimationController, curve: Curves.easeOut));

    _totalFixedCostsAnimationController.forward(from: 0);
  }

  void _calculateBreakeven() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        double totalFixedCosts =
            fixedCosts.fold(0, (sum, item) => sum + item.amount);
        double contributionMargin = averageCheck - foodCost;
        breakEvenCovers = totalFixedCosts / contributionMargin;
        breakEvenSales = breakEvenCovers * averageCheck;

        double targetProfit = totalFixedCosts * 0.2;
        profitTargetCovers =
            (totalFixedCosts + targetProfit) / contributionMargin;
        profitTargetSales = profitTargetCovers * averageCheck;

        _resultsAnimationController.reset();
        _resultsAnimationController.forward();
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Widget _buildFixedCostInput(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Cost Name',
                hintText: 'E.g., Rent',
              ),
              initialValue: fixedCosts[index].name,
              onChanged: (value) {
                setState(() {
                  fixedCosts[index].name = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              initialValue: fixedCosts[index].amount > 0
                  ? fixedCosts[index].amount.toString()
                  : '',
              onChanged: (value) {
                setState(() {
                  fixedCosts[index].amount = double.tryParse(value) ?? 0;
                  _updateTotalFixedCosts();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required Function(String) onSaved,
    String? initialValue,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        initialValue: initialValue,
        inputFormatters: inputFormatters,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a value';
          }
          if (double.tryParse(value.replaceAll(',', '')) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
        onSaved: (value) => onSaved(value!.replaceAll(',', '')),
      ),
    );
  }

  Widget _buildResultText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Breakeven Calculator'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Theme.of(context).primaryColor, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fixed Costs (Monthly)',
                              style: Theme.of(context).textTheme.titleLarge),
                          ...fixedCosts
                              .asMap()
                              .entries
                              .map((entry) => _buildFixedCostInput(entry.key)),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                fixedCosts
                                    .add(FixedCostItem(name: '', amount: 0));
                              });
                            },
                            child: const Text('Add Fixed Cost'),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Fixed Costs:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              AnimatedBuilder(
                                animation: _totalFixedCostsAnimationController,
                                builder: (context, child) {
                                  return Text(
                                    currencyFormat.format(
                                        _totalFixedCostsAnimation.value),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInputField(
                            label: 'Food Cost (Per Cover)',
                            hint: 'Average cost of food per customer',
                            onSaved: (value) => foodCost = double.parse(value),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'))
                            ],
                          ),
                          _buildInputField(
                            label: 'Average Check',
                            hint: 'Average amount spent per customer',
                            onSaved: (value) =>
                                averageCheck = double.parse(value),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'))
                            ],
                          ),
                          _buildInputField(
                            label: 'Days per Month',
                            hint: 'Number of operating days',
                            initialValue: '30',
                            onSaved: (value) => daysPerMonth = int.parse(value),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _calculateBreakeven,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('Calculate', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (breakEvenCovers > 0) ...[
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Breakeven Results:',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const Divider(),
                              _buildResultText('Monthly Breakeven Covers:',
                                  breakEvenCovers.toStringAsFixed(0)),
                              _buildResultText('Monthly Breakeven Sales:',
                                  currencyFormat.format(breakEvenSales)),
                              _buildResultText(
                                  'Daily Breakeven Sales:',
                                  currencyFormat
                                      .format(breakEvenSales / daysPerMonth)),
                              const SizedBox(height: 16),
                              Text('20% Net Profit Target:',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const Divider(),
                              _buildResultText('Monthly Covers for 20% Profit:',
                                  profitTargetCovers.toStringAsFixed(0)),
                              _buildResultText('Monthly Sales for 20% Profit:',
                                  currencyFormat.format(profitTargetSales)),
                              _buildResultText(
                                  'Daily Sales Target for 20% Profit:',
                                  currencyFormat.format(
                                      profitTargetSales / daysPerMonth)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/substance.dart';
import '../providers/acid_converter_provider.dart';
import '../providers/antibiotic_calculator_provider.dart';

class AntibioticCalculatorScreen extends ConsumerWidget {
  const AntibioticCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(antibioticCalculatorProvider);
    final notifier = ref.read(antibioticCalculatorProvider.notifier);
    final substancesAsync = ref.watch(substancesListProvider);

    return DefaultTabController(
      length: 2,
      initialIndex: state.selectedTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Antibiotic Calculator'),
          bottom: TabBar(
            onTap: notifier.setTab,
            tabs: const [
              Tab(text: 'Stock Solution', icon: Icon(Icons.science)),
              Tab(text: 'Unit Converter', icon: Icon(Icons.swap_horiz)),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.errorMessage != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(state.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
                  ),
                ),

              substancesAsync.when(
                data: (allSubstances) {
                  final antibiotics = allSubstances.where((s) => s.category == 'antibiotic').toList();
                  return DropdownButtonFormField<Substance>(
                    value: state.selectedAntibiotic,
                    decoration: const InputDecoration(labelText: 'Select Antibiotic', border: OutlineInputBorder(), prefixIcon: Icon(Icons.medication)),
                    items: antibiotics.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                    onChanged: (v) {
                      if (v != null) notifier.setAntibiotic(v);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading substances: $e'),
              ),
              const SizedBox(height: 16),

              if (state.selectedTab == 0)
                _StockSolutionView(state: state, notifier: notifier)
              else
                _UnitConverterView(state: state, notifier: notifier),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockSolutionView extends StatelessWidget {
  final AntibioticCalculatorState state;
  final AntibioticCalculatorNotifier notifier;

  const _StockSolutionView({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  initialValue: state.targetConcentration.toString(),
                  decoration: const InputDecoration(labelText: 'Target Concentration (IU/mL)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => notifier.updateInputs(concentration: double.tryParse(v)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: state.finalVolumeMl.toString(),
                  decoration: const InputDecoration(labelText: 'Final Volume (mL)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => notifier.updateInputs(volume: double.tryParse(v)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => notifier.calculate(),
          icon: const Icon(Icons.calculate),
          label: const Text('Calculate Mass Needed'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
        if (state.stockResult != null)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Result', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSecondaryContainer)),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Mass to Weigh:', style: Theme.of(context).textTheme.labelLarge),
                    Text(
                      state.stockResult!.massNeededMg >= 1000 
                          ? '${(state.stockResult!.massNeededMg / 1000).toStringAsFixed(4)} g' 
                          : '${state.stockResult!.massNeededMg.toStringAsFixed(2)} mg',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                      child: Text(state.stockResult!.instructions, style: Theme.of(context).textTheme.bodyLarge),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UnitConverterView extends StatelessWidget {
  final AntibioticCalculatorState state;
  final AntibioticCalculatorNotifier notifier;

  const _UnitConverterView({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: state.convertValue.toString(),
                    decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => notifier.updateConverterInputs(value: double.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: state.convertUnit,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'IU', child: Text('IU')),
                      DropdownMenuItem(value: 'mg', child: Text('mg')),
                      DropdownMenuItem(value: 'mcg', child: Text('µg')),
                    ],
                    onChanged: (v) => notifier.updateConverterInputs(unit: v),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => notifier.calculate(),
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Convert'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
        if (state.conversionResult != null)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Conversions', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onTertiaryContainer)),
                    const Divider(),
                    const SizedBox(height: 8),
                    _ConversionRow(label: 'International Units', value: '${state.conversionResult!.resultIU.toStringAsFixed(0)} IU'),
                    _ConversionRow(label: 'Milligrams', value: '${state.conversionResult!.resultMg.toStringAsFixed(3)} mg'),
                    _ConversionRow(label: 'Micrograms', value: '${state.conversionResult!.resultMcg.toStringAsFixed(1)} µg'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConversionRow extends StatelessWidget {
  final String label;
  final String value;
  const _ConversionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

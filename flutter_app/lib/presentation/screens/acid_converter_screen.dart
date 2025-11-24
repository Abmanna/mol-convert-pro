import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/substance.dart';
import '../providers/acid_converter_provider.dart';

class AcidConverterScreen extends ConsumerWidget {
  const AcidConverterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(acidConverterProvider);
    final notifier = ref.read(acidConverterProvider.notifier);
    final substancesAsync = ref.watch(substancesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Prepare Acid Solution')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.status == AcidConverterStatus.failure)
              _ErrorMessage(message: state.errorMessage!),
            
            substancesAsync.when(
              data: (acids) => _AcidSelector(
                acids: acids,
                selectedAcid: state.selectedAcid,
                onChanged: notifier.setAcid,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _ErrorMessage(message: 'Failed to load acids: $err'),
            ),
            
            const SizedBox(height: 16),
            
            _StockInputSection(
              percent: state.stockPercent,
              density: state.stockDensity,
              onPercentChanged: (v) => notifier.updateInputs(stockPercent: v),
              onDensityChanged: (v) => notifier.updateInputs(stockDensity: v),
            ),
            const SizedBox(height: 16),
            
            _TargetSection(
              concentration: state.targetConcentration,
              isMolarity: state.isMolarity,
              volume: state.finalVolumeMl,
              onConcentrationChanged: (v) => notifier.updateInputs(targetConcentration: v),
              onTypeChanged: (v) => notifier.updateInputs(isMolarity: v),
              onVolumeChanged: (v) => notifier.updateInputs(finalVolumeMl: v),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: state.status == AcidConverterStatus.loading
                  ? null
                  : () => notifier.prepare(),
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            if (state.status == AcidConverterStatus.success)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: _ResultCard(result: state.result!),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;
  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcidSelector extends StatelessWidget {
  final List<Substance> acids;
  final Substance? selectedAcid;
  final ValueChanged<Substance> onChanged;

  const _AcidSelector({required this.acids, required this.selectedAcid, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Substance>(
      value: selectedAcid,
      decoration: const InputDecoration(
        labelText: 'Select Acid',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.science),
      ),
      items: acids.map((acid) {
        return DropdownMenuItem(
          value: acid,
          child: Text(acid.name),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }
}

class _StockInputSection extends StatelessWidget {
  final double percent;
  final double density;
  final ValueChanged<double> onPercentChanged;
  final ValueChanged<double> onDensityChanged;

  const _StockInputSection({
    required this.percent,
    required this.density,
    required this.onPercentChanged,
    required this.onDensityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock Solution Properties', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: percent.toString(),
                    decoration: const InputDecoration(labelText: 'Concentration (%)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => onPercentChanged(double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: density.toString(),
                    decoration: const InputDecoration(labelText: 'Density (g/mL)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => onDensityChanged(double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetSection extends StatelessWidget {
  final double concentration;
  final bool isMolarity;
  final double volume;
  final ValueChanged<double> onConcentrationChanged;
  final ValueChanged<bool> onTypeChanged;
  final ValueChanged<double> onVolumeChanged;

  const _TargetSection({
    required this.concentration,
    required this.isMolarity,
    required this.volume,
    required this.onConcentrationChanged,
    required this.onTypeChanged,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target Solution', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: concentration.toString(),
                    decoration: const InputDecoration(labelText: 'Concentration', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => onConcentrationChanged(double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<bool>(
                    value: isMolarity,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: true, child: Text('M')),
                      DropdownMenuItem(value: false, child: Text('N')),
                    ],
                    onChanged: (v) => onTypeChanged(v ?? true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: volume.toString(),
              decoration: const InputDecoration(labelText: 'Final Volume (mL)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (v) => onVolumeChanged(double.tryParse(v) ?? 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final AcidPrepResult result;
  const _ResultCard({required this.result});

  void _exportAsPdf(BuildContext context, AcidPrepResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting to PDF... (Mock)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Results', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.share), onPressed: () {}),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text('Stock Molarity: ${result.stockMolarity.toStringAsFixed(2)} M',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Volume to Use: ${result.volumeNeededMl.toStringAsFixed(1)} mL',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('INSTRUCTIONS', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(result.instructions, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _exportAsPdf(context, result),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export SOP (PDF)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

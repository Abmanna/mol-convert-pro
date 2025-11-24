import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/hplc_column.dart';
import '../../domain/use_cases/hplc_calculations.dart';
import '../providers/hplc_calculator_provider.dart';

class HplcCalculatorScreen extends ConsumerWidget {
  const HplcCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hplcCalculatorProvider);
    final notifier = ref.read(hplcCalculatorProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('HPLC Method Scaling')),
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
            
            _SectionHeader(title: '1. Column Parameters'),
            Row(
              children: [
                Expanded(child: _ColumnInputCard(title: 'Original Column', column: state.originalColumn, onChanged: notifier.updateOriginalColumn)),
                const SizedBox(width: 8),
                Expanded(child: _ColumnInputCard(title: 'New Column', column: state.newColumn, onChanged: notifier.updateNewColumn)),
              ],
            ),
            const SizedBox(height: 16),

            _SectionHeader(title: '2. Method Parameters'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: state.originalFlowRate.toString(),
                      decoration: const InputDecoration(labelText: 'Original Flow Rate (mL/min)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => notifier.updateFlowRate(double.tryParse(v) ?? 0),
                    ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: const Text('Advanced: Pressure & Dwell Volume (Optional)'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              TextFormField(
                                initialValue: state.originalPressure?.toString() ?? '',
                                decoration: const InputDecoration(labelText: 'Original Backpressure (bar)', border: OutlineInputBorder(), helperText: 'Used to estimate new pressure'),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => notifier.setPressure(double.tryParse(v)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: state.originalDwellVolume?.toString() ?? '',
                                      decoration: const InputDecoration(labelText: 'Orig. Dwell Vol (mL)', border: OutlineInputBorder()),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => notifier.setDwellVolumes(double.tryParse(v), state.newDwellVolume),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: state.newDwellVolume?.toString() ?? '',
                                      decoration: const InputDecoration(labelText: 'New Dwell Vol (mL)', border: OutlineInputBorder()),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => notifier.setDwellVolumes(state.originalDwellVolume, double.tryParse(v)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _SectionHeader(title: '3. Gradient Table (Time vs %B)'),
            _GradientTableEditor(
              steps: state.originalGradient,
              onAdd: notifier.addGradientStep,
              onRemove: notifier.removeGradientStep,
              onUpdate: notifier.updateGradientStep,
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => notifier.calculate(),
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate Scaled Method'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),

            if (state.result != null)
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
    );
  }
}

class _ColumnInputCard extends StatelessWidget {
  final String title;
  final HplcColumn column;
  final Function(HplcColumn) onChanged;

  const _ColumnInputCard({required this.title, required this.column, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            _CompactInput(label: 'Length (mm)', value: column.lengthMm, onChanged: (v) => onChanged(column.copyWith(lengthMm: v))),
            const SizedBox(height: 8),
            _CompactInput(label: 'Diameter (mm)', value: column.diameterMm, onChanged: (v) => onChanged(column.copyWith(diameterMm: v))),
            const SizedBox(height: 8),
            _CompactInput(label: 'Particle (µm)', value: column.particleSizeUm, onChanged: (v) => onChanged(column.copyWith(particleSizeUm: v))),
          ],
        ),
      ),
    );
  }
}

class _CompactInput extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _CompactInput({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(labelText: label, isDense: true, contentPadding: const EdgeInsets.all(8), border: const OutlineInputBorder()),
      keyboardType: TextInputType.number,
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
    );
  }
}

class _GradientTableEditor extends StatelessWidget {
  final List<GradientStep> steps;
  final VoidCallback onAdd;
  final Function(int) onRemove;
  final Function(int, double, double) onUpdate;

  const _GradientTableEditor({required this.steps, required this.onAdd, required this.onRemove, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            if (steps.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No gradient steps defined. Add one below.')),
            ...steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              return Row(
                children: [
                  Expanded(child: _CompactInput(label: 'Time (min)', value: step.time, onChanged: (v) => onUpdate(idx, v, step.percentB))),
                  const SizedBox(width: 8),
                  Expanded(child: _CompactInput(label: '% B', value: step.percentB, onChanged: (v) => onUpdate(idx, step.time, v))),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => onRemove(idx)),
                ],
              );
            }).toList(),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add Step')),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final HplcScalingResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scaled Method', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSecondaryContainer)),
            const Divider(),
            _ResultRow(label: 'New Flow Rate', value: '${result.newFlowRate.toStringAsFixed(3)} mL/min'),
            _ResultRow(label: 'Flow Scale Factor', value: result.flowRateScaleFactor.toStringAsFixed(3)),
            _ResultRow(label: 'Gradient Time Factor', value: result.gradientTimeScaleFactor.toStringAsFixed(3)),
            const SizedBox(height: 12),
            
            Text('USP <621> Compliance (L/dp)', style: Theme.of(context).textTheme.titleSmall),
            _ResultRow(
              label: 'L/dp Change', 
              value: '${result.ldpChangePercent > 0 ? '+' : ''}${result.ldpChangePercent.toStringAsFixed(1)}%',
              valueColor: result.isLdpCompliant ? Colors.green.shade800 : Colors.red.shade800,
            ),
            if (!result.isLdpCompliant)
              Text('Warning: Change is outside -25% to +50%. Revalidation required.', style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
            
            if (result.estimatedNewPressure != null) ...[
              const Divider(),
              Text('Critical Estimates', style: Theme.of(context).textTheme.titleSmall),
              _ResultRow(label: 'Est. New Pressure', value: '${result.estimatedNewPressure!.toStringAsFixed(0)} bar'),
              if (result.pressureWarning != null)
                Text(result.pressureWarning!, style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
            ],

            if (result.dwellVolumeAdjustmentTime != null) ...[
              const SizedBox(height: 8),
              _ResultRow(
                label: 'Dwell Vol Adjustment', 
                value: '${result.dwellVolumeAdjustmentTime!.abs().toStringAsFixed(2)} min',
                subValue: result.dwellVolumeAdjustmentTime! > 0 
                    ? '(Add Isocratic Hold at start)' 
                    : '(Start gradient earlier / Injection Delay)',
              ),
            ],

            const SizedBox(height: 16),
            const Text('New Gradient Table:', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4), color: Colors.white),
              padding: const EdgeInsets.all(8),
              height: 150,
              child: ListView(
                children: result.newGradientTable.map((s) => Text('${s.time.toStringAsFixed(2)} min : ${s.percentB.toStringAsFixed(1)} %B')).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final Color? valueColor;
  const _ResultRow({required this.label, required this.value, this.subValue, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
              if (subValue != null) Text(subValue!, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
            ],
          ),
        ],
      ),
    );
  }
}

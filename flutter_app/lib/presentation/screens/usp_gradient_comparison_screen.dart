import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/usp_gradient_provider.dart';

class UspGradientComparisonScreen extends ConsumerWidget {
  const UspGradientComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspGradientProvider);
    final notifier = ref.read(uspGradientProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('USP <621> Gradient Comparison')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OriginalColumnCard(state: state, notifier: notifier),
            const SizedBox(height: 16),
            _GradientProgramCard(state: state, notifier: notifier),
            const SizedBox(height: 16),
            _InfoBox(),
            const SizedBox(height: 16),
            _ComparisonTable(state: state),
          ],
        ),
      ),
    );
  }
}

class _OriginalColumnCard extends StatelessWidget {
  final UspComparisonState state;
  final UspGradientNotifier notifier;

  const _OriginalColumnCard({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Original Column Parameters', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.indigo.shade900, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _Input(label: 'Length (mm)', value: state.originalColumn.lengthMm, onChanged: (v) => notifier.updateOriginalColumn(length: v))),
                const SizedBox(width: 8),
                Expanded(child: _Input(label: 'Dia (mm)', value: state.originalColumn.diameterMm, onChanged: (v) => notifier.updateOriginalColumn(diameter: v))),
                const SizedBox(width: 8),
                Expanded(child: _Input(label: 'Part (µm)', value: state.originalColumn.particleSizeUm, onChanged: (v) => notifier.updateOriginalColumn(particleSize: v))),
                const SizedBox(width: 8),
                Expanded(child: _Input(label: 'Flow (mL/min)', value: state.originalFlowRate, onChanged: (v) => notifier.updateOriginalColumn(flowRate: v))),
              ],
            ),
            const SizedBox(height: 8),
            Text('L/dp Ratio: ${(state.originalColumn.lengthMm / state.originalColumn.particleSizeUm).toStringAsFixed(1)}', style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _GradientProgramCard extends StatelessWidget {
  final UspComparisonState state;
  final UspGradientNotifier notifier;

  const _GradientProgramCard({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final labels = ['Initial Hold', 'Gradient', 'Wash', 'Re-equilibration'];

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Original Gradient Program', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green.shade900, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...state.gradientSegments.asMap().entries.map((entry) {
              final idx = entry.key;
              final seg = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(labels[idx % labels.length], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    Expanded(child: _Input(label: 'Time', value: seg.time, onChanged: (v) => notifier.updateGradientSegment(idx, v, seg.percentB))),
                    const SizedBox(width: 8),
                    Expanded(child: _Input(label: '% B', value: seg.percentB, onChanged: (v) => notifier.updateGradientSegment(idx, seg.time, v))),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
            Text('Total Runtime: ${state.gradientSegments.fold(0.0, (sum, s) => sum + s.time).toStringAsFixed(2)} min', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'USP <621> Allowable Range: L/dp ratio must be within -25% to +50% of original. Green rows are compliant.',
              style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final UspComparisonState state;

  const _ComparisonTable({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.indigo),
          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text('Column Type')),
            DataColumn(label: Text('Dimensions')),
            DataColumn(label: Text('L/dp Ratio')),
            DataColumn(label: Text('Ratio Change')),
            DataColumn(label: Text('New Flow')),
            DataColumn(label: Text('Total Time')),
          ],
          rows: state.comparisons.map((res) {
            final color = res.isCompliant ? Colors.green.shade50 : Colors.red.shade50;
            return DataRow(
              color: MaterialStateProperty.all(color),
              cells: [
                DataCell(Text(res.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text('${res.column.lengthMm.toInt()}x${res.column.diameterMm} mm, ${res.column.particleSizeUm} µm')),
                DataCell(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(res.newLdp.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('vs ${res.originalLdp.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                )),
                DataCell(Text(
                  '${res.ldpChange > 0 ? '+' : ''}${res.ldpChange.toStringAsFixed(1)}%',
                  style: TextStyle(color: res.isCompliant ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold),
                )),
                DataCell(Text('${res.newFlowRate.toStringAsFixed(3)} mL/min')),
                DataCell(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${res.totalAdjustedTime.toStringAsFixed(2)} min', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('(${(res.totalAdjustedTime / res.totalOriginalTime * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _Input({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.all(8),
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
    );
  }
}

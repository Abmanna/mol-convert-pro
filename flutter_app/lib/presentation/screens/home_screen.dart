import 'package:flutter/material.dart';
import 'acid_converter_screen.dart';
import 'hplc_calculator_screen.dart';
import 'antibiotic_calculator_screen.dart';
import 'usp_gradient_comparison_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MolConvert Pro')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _ToolCard(
            title: 'Acid Preparation',
            icon: Icons.science,
            color: Colors.blue.shade100,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AcidConverterScreen())),
          ),
          _ToolCard(
            title: 'HPLC Scaling',
            icon: Icons.auto_graph,
            color: Colors.purple.shade100,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HplcCalculatorScreen())),
          ),
          _ToolCard(
            title: 'Antibiotic Stock',
            icon: Icons.medication,
            color: Colors.green.shade100,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AntibioticCalculatorScreen())),
          ),
          _ToolCard(
            title: 'USP <621> Study',
            icon: Icons.table_chart,
            color: Colors.indigo.shade100,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UspGradientComparisonScreen())),
          ),
          // Placeholder for future tools
          _ToolCard(
            title: 'Molarity Calc',
            icon: Icons.calculate_outlined,
            color: Colors.grey.shade200,
            onTap: () {}, // TODO
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.black54),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

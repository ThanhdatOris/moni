import 'package:flutter/material.dart';

class HistorySummaryItem extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;

  const HistorySummaryItem({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(height: 3),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// A colored placeholder where a real app shows the product photo.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.id, this.size = 56});

  final String id;
  final double size;

  static const _colors = [
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.green,
  ];

  @override
  Widget build(BuildContext context) {
    // The same product always gets the same color.
    final seed = id.codeUnits.fold(0, (sum, unit) => sum + unit);
    final color = _colors[seed % _colors.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(size / 5),
      ),
      child: Icon(
        Icons.shopping_bag_outlined,
        size: size / 2,
        color: color.shade700,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class RecordButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool recording;

  const RecordButton({Key? key, required this.icon, required this.onPressed, this.recording = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: recording ? color.withOpacity(0.9) : color,
          boxShadow: [BoxShadow(color: color.withOpacity(0.24), blurRadius: 8)],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

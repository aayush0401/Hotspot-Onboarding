import 'dart:async';
import 'package:flutter/material.dart';

class AudioWaveform extends StatefulWidget {
  final Stream<double> amplitudeStream;
  final Color color;
  final int maxBars;

  const AudioWaveform({
    super.key,
    required this.amplitudeStream,
    this.color = Colors.greenAccent,
    this.maxBars = 40,
  });

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform> {
  final List<double> _amplitudes = [];
  StreamSubscription<double>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.amplitudeStream.listen((amplitude) {
      setState(() {
        _amplitudes.add(amplitude);
        if (_amplitudes.length > widget.maxBars) {
          _amplitudes.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _amplitudes.isEmpty
            ? List.generate(20, (i) => _buildBar(0.1))
            : _amplitudes.map((amplitude) => _buildBar(amplitude)).toList(),
      ),
    );
  }

  Widget _buildBar(double amplitude) {
    final height = 10 + (50 * amplitude); // Min 10, max 60
    return Container(
      width: 3,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

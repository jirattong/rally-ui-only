import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Entry: /Analytics
/// Extra: /Analytics/history, /Analytics/detail
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF9EFE6);
    const dark = Color(0xFF3A5150);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Analytics',
            style: TextStyle(fontWeight: FontWeight.w900, color: dark)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: const [
          _SummaryCard(),
          SizedBox(height: 12),
          _MotionChartCard(),
          SizedBox(height: 18),
          _SessionHistoryPreview(),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();
  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: const Color(0xFFFBE0CC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Last Recent Summary',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(children: const [
            _MetricBig(number: '27 min', label: 'Duration'),
            SizedBox(width: 24),
            _MetricBig(number: '50 time', label: 'Motion'),
          ]),
        ]),
      ),
    );
  }
}

class _MetricBig extends StatelessWidget {
  const _MetricBig({required this.number, required this.label});
  final String number;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(number,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ]),
    );
  }
}

class _MotionChartCard extends StatelessWidget {
  const _MotionChartCard();
  @override
  Widget build(BuildContext context) {
    final points = [5.0, 3.0, 2.0, 3.5, 6.0]; // mock data
    return Ink(
      decoration: BoxDecoration(
        color: const Color(0xFFFBE0CC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Motion',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _SimpleLineChartPainter(points: points, maxY: 10),
              child: const SizedBox.expand(),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SimpleLineChartPainter extends CustomPainter {
  final List<double> points;
  final double maxY;
  _SimpleLineChartPainter({required this.points, required this.maxY});

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = const Color(0xFF754A2E)
      ..strokeWidth = 1;
    // axes
    final margin = 24.0;
    final chart = Rect.fromLTWH(
        margin, margin, size.width - margin * 2, size.height - margin * 2);
    // horizontal lines
    for (int i = 0; i <= 4; i++) {
      final y = chart.top + chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y),
          axis..color = const Color(0xFFB98E72));
    }
    // bars (to mimic area under last point style in mock)
    final fill = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFAF66), Color(0xFFFF8A3D)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chart);
    final line = Paint()
      ..color = const Color(0xFFFF7E2F)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = const Color(0xFFFF7E2F);

    // map function
    Offset pt(int i) {
      final x = chart.left + chart.width * (i / (points.length));
      final y = chart.bottom - (points[i] / maxY) * chart.height;
      return Offset(x, y);
    }

    // draw bars and line
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final p = pt(i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
      // bar under point i
      final barRect = Rect.fromLTWH(p.dx - chart.width / (points.length * 2.2),
          p.dy, chart.width / (points.length * 1.1), chart.bottom - p.dy);
      canvas.drawRect(barRect, fill);
    }
    canvas.drawPath(path, line);
    for (int i = 0; i < points.length; i++) {
      final p = pt(i);
      canvas.drawCircle(p, 3.5, dot);
    }

    // x labels 1..5 (just marks)
    final tick = Paint()..color = const Color(0xFF754A2E);
    for (int i = 1; i <= 5; i++) {
      final x = chart.left + chart.width * (i / 5);
      canvas.drawCircle(Offset(x, chart.bottom + 2), 1.2, tick);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SessionHistoryPreview extends StatelessWidget {
  const _SessionHistoryPreview();
  @override
  Widget build(BuildContext context) {
    Widget item(String date, String duration, String motion) {
      return Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFFBE0CC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('$duration    $motion',
                        style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // stub → navigate to detail
                  Navigator.pushNamed(context, '/Analytics/detail', arguments: {
                    'date': date,
                    'duration': duration,
                    'motion': motion,
                  });
                },
                child: const Text('View Detail'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Session History',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      item('August 27', '27 min', '50 time'),
      const SizedBox(height: 10),
      item('August 26', '20 min', '45 time'),
      const SizedBox(height: 8),
      Center(
        child: TextButton(
          onPressed: () => Navigator.pushNamed(context, '/Analytics/history'),
          child: const Text('View More',
              style: TextStyle(decoration: TextDecoration.underline)),
        ),
      ),
    ]);
  }
}

// -------------------- History & Detail pages --------------------

class AnalyticsHistoryPage extends StatelessWidget {
  const AnalyticsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF9EFE6);
    final sessions = List.generate(
        20,
        (i) => {
              'date': 'Aug ${27 - (i % 27)}',
              'duration': '${15 + (i % 20)} min',
              'motion': '${30 + (i % 30)} time',
            });

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('Session History',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF3A5150))),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemBuilder: (context, i) {
          final s = sessions[i];
          return Ink(
            decoration: BoxDecoration(
                color: const Color(0xFFFBE0CC),
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${s['date']}',
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('${s['duration']}    ${s['motion']}',
                          style: const TextStyle(color: Colors.black87)),
                    ])),
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                      context, '/Analytics/detail',
                      arguments: s),
                  child: const Text('View Detail'),
                ),
              ]),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: sessions.length,
      ),
    );
  }
}

class AnalyticsDetailPage extends StatelessWidget {
  const AnalyticsDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF9EFE6);
    final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;
    final date = args['date'] ?? 'Aug 27';
    final duration = args['duration'] ?? '27 min';
    final motion = args['motion'] ?? '50 time';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('Session Detail',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF3A5150))),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          // Header stats
          Ink(
            decoration: BoxDecoration(
                color: const Color(0xFFFBE0CC),
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('$date',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text('Duration: $duration'),
                      Text('Motion: $motion'),
                    ])),
                const Icon(Icons.query_stats, color: Colors.black87),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Mini chart
          Ink(
            decoration: BoxDecoration(
                color: const Color(0xFFFBE0CC),
                borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
                height: 160,
                child: CustomPaint(
                    painter: _SimpleLineChartPainter(
                        points: [3, 5, 4, 6, 5, 7], maxY: 10))),
          ),
          const SizedBox(height: 12),

          // Metrics list
          Ink(
            decoration: BoxDecoration(
                color: const Color(0xFFFBE0CC),
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _MetricRow(
                        icon: Icons.flash_on,
                        label: 'Peak intensity',
                        value: 'High'),
                    SizedBox(height: 8),
                    _MetricRow(
                        icon: Icons.av_timer,
                        label: 'Avg interval',
                        value: '3.2 sec'),
                    SizedBox(height: 8),
                    _MetricRow(
                        icon: Icons.speed, label: 'Consistency', value: '87%'),
                    SizedBox(height: 8),
                    _MetricRow(
                        icon: Icons.sports_tennis,
                        label: 'Top motion',
                        value: 'Smash Ready'),
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 20, color: Colors.black87),
      const SizedBox(width: 8),
      Expanded(
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
      Text(value, style: const TextStyle(color: Colors.black87)),
    ]);
  }
}

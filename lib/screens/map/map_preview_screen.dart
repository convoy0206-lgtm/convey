import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../models/trip_model.dart';
import 'active_tracking_screen.dart';

class MapPreviewScreen extends ConsumerWidget {
  final TripModel trip;

  const MapPreviewScreen({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Preview'),
      ),
      body: Column(
        children: [
          // Graphic Map Preview Wrapper
          Expanded(
            child: Container(
              color: const Color(0xFF0C0E14),
              child: Stack(
                children: [
                  // Topographic mockup background lines
                  CustomPaint(
                    size: Size.infinite,
                    painter: TopoLinesPainter(),
                  ),
                  
                  // Center labels
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          size: 64,
                          color: Color(0xFF00F0FF),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'MAP PREVIEW ACTIVE',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF00F0FF),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sierra Nevada Pass Route Selected',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Overlay route checkpoints
                  Positioned(
                    top: 100,
                    left: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Text('📍', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2029),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Yosemite Start',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 120,
                    right: 80,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🏁', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2029),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Nevada Pass',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map Bottom Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  trip.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Route Length: 48.5 miles',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Invite code copier widget
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: trip.inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite code copied to clipboard!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Invite Code', style: theme.textTheme.labelSmall),
                            const SizedBox(height: 2),
                            Text(
                              trip.inviteCode,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.copy_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => ActiveTrackingScreen(trip: trip),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text(
                    'Start Live Tracking',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TopoLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final pathPaint = Paint()
      ..color = const Color(0xFF00F0FF).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Draw some contour rings
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 160, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 240, paint);
    
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 100, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 180, paint);

    // Draw route dashed preview path
    final routePath = Path()
      ..moveTo(60, 100)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.2, size.width * 0.4, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.8, size.width - 80, size.height - 120);

    canvas.drawPath(routePath, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

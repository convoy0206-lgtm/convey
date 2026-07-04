import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trip_model.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';

class ProximityRadarView extends ConsumerStatefulWidget {
  final TripModel trip;
  final Map<String, dynamic> groupLocations;
  final bool ghostModeActive;

  const ProximityRadarView({
    super.key,
    required this.groupLocations,
    required this.trip,
    required this.ghostModeActive,
  });

  @override
  ConsumerState<ProximityRadarView> createState() => _ProximityRadarViewState();
}

class _ProximityRadarViewState extends ConsumerState<ProximityRadarView>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    // Configure rotation sweep animation loop
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
        (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 0.621371; // Return Distance in Miles
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authServiceProvider).currentUser;
    
    // Find current user's location
    LocationData? myLoc;
    if (currentUser != null && widget.groupLocations.containsKey(currentUser.uid)) {
      myLoc = LocationData.fromMap(widget.groupLocations[currentUser.uid]);
    }

    // Build the companion details items list
    final List<Map<String, dynamic>> companions = [];
    widget.groupLocations.forEach((uid, data) {
      if (uid == currentUser?.uid) return; // Skip self

      final loc = LocationData.fromMap(data);
      double distance = 0.0;
      if (myLoc != null) {
        distance = _calculateDistance(myLoc.latitude, myLoc.longitude, loc.latitude, loc.longitude);
      } else {
        // Fallback simulated distances
        distance = 1.2 + (uid.hashCode % 5) * 0.8;
      }

      companions.add({
        'uid': uid,
        'displayName': data['displayName'] as String? ?? 'Traveler',
        'distance': distance,
        'speed': (data['speed'] as num?)?.toDouble() ?? 0.0,
      });
    });

    // Sort companions by distance (closest first)
    companions.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    return Column(
      children: [
        const SizedBox(height: 16),
        // Topographic Radar scanning display
        Expanded(
          flex: 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _radarController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(260, 260),
                    painter: RadarSweepPainter(
                      angle: _radarController.value * 2 * pi,
                      companions: companions,
                      ghostModeActive: widget.ghostModeActive,
                    ),
                  );
                },
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.ghostModeActive ? Icons.visibility_off : Icons.radar,
                    color: widget.ghostModeActive ? theme.colorScheme.error : const Color(0xFF00F0FF),
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.ghostModeActive ? 'GHOST INVISIBLE' : 'RADAR SYNC ACTIVE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: widget.ghostModeActive ? theme.colorScheme.error : const Color(0xFF00F0FF),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // List of companions and proximity gauges (Screen 5 active groups)
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: companions.isEmpty
                ? Center(
                    child: Text(
                      'No other active companions in range.\nShare your invite code to sync!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    itemCount: companions.length,
                    itemBuilder: (context, index) {
                      final comp = companions[index];
                      final name = comp['displayName'] as String;
                      final distance = comp['distance'] as double;
                      final speed = comp['speed'] as double;
                      
                      // Spacing thresholds indicator
                      final isClose = distance < 1.0;
                      final isTooFar = distance > 5.0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isClose 
                                ? Colors.green.withOpacity(0.3) 
                                : (isTooFar ? Colors.red.withOpacity(0.3) : theme.colorScheme.outlineVariant),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isClose 
                                    ? Colors.green.withOpacity(0.2) 
                                    : (isTooFar ? Colors.red.withOpacity(0.2) : theme.colorScheme.surfaceVariant),
                                child: Text(
                                  name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isClose ? Colors.green : (isTooFar ? Colors.red : Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.speed, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 4),
                                        Text('${speed.toStringAsFixed(0)} mph', style: theme.textTheme.bodySmall),
                                        const SizedBox(width: 12),
                                        Icon(Icons.social_distance, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 4),
                                        Text('${distance.toStringAsFixed(2)} miles away', style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Distance sync flag badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isClose 
                                      ? Colors.green.withOpacity(0.15) 
                                      : (isTooFar ? Colors.red.withOpacity(0.15) : Colors.blue.withOpacity(0.15)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isClose ? 'NEARBY' : (isTooFar ? 'LAGGING' : 'SYNCED'),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isClose ? Colors.green : (isTooFar ? Colors.red : Colors.blue),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class RadarSweepPainter extends CustomPainter {
  final double angle;
  final List<Map<String, dynamic>> companions;
  final bool ghostModeActive;

  RadarSweepPainter({
    required this.angle,
    required this.companions,
    required this.ghostModeActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFF10121A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw concentric radar lines
    final linePaint = Paint()
      ..color = (ghostModeActive ? Colors.red : const Color(0xFF00F0FF)).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, linePaint);
    canvas.drawCircle(center, radius * 0.66, linePaint);
    canvas.drawCircle(center, radius * 0.33, linePaint);

    // Draw Radar Sweep cone
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: pi * 2,
        colors: [
          (ghostModeActive ? Colors.red : const Color(0xFF00F0FF)).withOpacity(0.0),
          (ghostModeActive ? Colors.red : const Color(0xFF00F0FF)).withOpacity(0.15),
        ],
        stops: const [0.85, 1.0],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    // Plot companions as glowing blinking radar dots
    for (int i = 0; i < companions.length; i++) {
      final comp = companions[i];
      final double distance = comp['distance'] as double;
      final String name = comp['displayName'] as String;

      // Map distance scaling relative to radar boundaries (say, max distance 10 miles)
      final normDist = (distance / 10.0).clamp(0.1, 0.9) * radius;
      // Distribute dots angularly to represent spatial placement
      final dotAngle = (i * 72.0) * pi / 180.0;
      
      final dotX = center.dx + normDist * cos(dotAngle);
      final dotY = center.dy + normDist * sin(dotAngle);
      final dotCenter = Offset(dotX, dotY);

      final dotPaint = Paint()
        ..color = const Color(0xFF00FF66)
        ..style = PaintingStyle.fill;
      
      // Outer blinking glow
      final glowPaint = Paint()
        ..color = const Color(0xFF00FF66).withOpacity(0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotCenter, 8.0, glowPaint);
      canvas.drawCircle(dotCenter, 4.0, dotPaint);

      // Label coordinate initial
      final textPainter = TextPainter(
        text: TextSpan(
          text: name.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, dotCenter - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

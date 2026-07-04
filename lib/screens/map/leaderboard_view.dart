import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trip_model.dart';
import '../../services/auth_service.dart';

class LeaderboardView extends ConsumerWidget {
  final TripModel trip;
  final Map<String, dynamic> groupLocations;

  const LeaderboardView({
    super.key,
    required this.trip,
    required this.groupLocations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authServiceProvider).currentUser;

    // Parse list of members and details
    final List<Map<String, dynamic>> leaderboardData = [];
    groupLocations.forEach((uid, data) {
      final name = data['displayName'] as String? ?? 'Traveler';
      final speed = (data['speed'] as num?)?.toDouble() ?? 0.0;
      final isCurrentUser = uid == currentUser?.uid;

      leaderboardData.add({
        'uid': uid,
        'displayName': isCurrentUser ? 'You (Ghost)' : name,
        'speed': speed,
        'isCurrentUser': isCurrentUser,
      });
    });

    // Sort leaderboard by speed (highest first)
    leaderboardData.sort((a, b) => (b['speed'] as double).compareTo(a['speed'] as double));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Graphic speed curves graph card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'VELOCITY TRENDS',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF00F0FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Live Sync',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Wave speed graph Custom Painter
                  SizedBox(
                    height: 140,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: SpeedCurvesPainter(
                        leaderboardData: leaderboardData,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Leaderboard Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SQUAD LEADERBOARD',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.emoji_events_outlined, color: Colors.amber),
            ],
          ),
          const SizedBox(height: 12),

          // Leaderboard List
          Expanded(
            child: leaderboardData.isEmpty
                ? Center(
                    child: Text(
                      'No companion stats syncing.\nStart simulated movements to view!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: leaderboardData.length,
                    itemBuilder: (context, index) {
                      final member = leaderboardData[index];
                      final name = member['displayName'] as String;
                      final speed = member['speed'] as double;
                      final isMe = member['isCurrentUser'] as bool;

                      // Leader awards trophies or icons
                      IconData rankIcon = Icons.military_tech_outlined;
                      Color rankColor = Colors.white54;
                      if (index == 0) {
                        rankIcon = Icons.emoji_events;
                        rankColor = Colors.amber;
                      } else if (index == 1) {
                        rankIcon = Icons.emoji_events;
                        rankColor = const Color(0xFFC0C0C0); // Silver
                      } else if (index == 2) {
                        rankIcon = Icons.emoji_events;
                        rankColor = const Color(0xFFCD7F32); // Bronze
                      }

                      return Card(
                        color: isMe 
                            ? theme.colorScheme.primaryContainer.withOpacity(0.3) 
                            : Colors.transparent,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isMe 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.outlineVariant.withOpacity(0.5),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.05),
                            child: Icon(rankIcon, color: rankColor),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text('Rank #${index + 1}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                speed.toStringAsFixed(1),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: index == 0 ? Colors.amber : const Color(0xFF00F0FF),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text('mph', style: theme.textTheme.labelSmall),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SpeedCurvesPainter extends CustomPainter {
  final List<Map<String, dynamic>> leaderboardData;

  SpeedCurvesPainter({required this.leaderboardData});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw background grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Colors mapping for velocity curves
    final colors = [
      const Color(0xFF00F0FF), // Primary Cyan
      const Color(0xFF00FF66), // Green
      const Color(0xFFFF5E5E), // Red
      const Color(0xFFFFCC00), // Yellow
    ];

    // Plot velocity curves
    for (int m = 0; m < leaderboardData.length; m++) {
      final speed = leaderboardData[m]['speed'] as double;
      final color = colors[m % colors.length];

      final curvePaint = Paint()
        ..color = color.withOpacity(0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final fillPaint = Paint()
        ..color = color.withOpacity(0.04)
        ..style = PaintingStyle.fill;

      // Draw custom sine curve representing speed variations
      final path = Path()..moveTo(0, size.height * 0.7);
      
      // Interpolate points
      for (double x = 0; x <= size.width; x += 10.0) {
        final double factor = sin((x / size.width) * 2 * pi + m) * 20.0;
        // Map baseline speed to height
        final double mappedY = (size.height * 0.5) - (speed * 0.8) + factor;
        path.lineTo(x, mappedY.clamp(10.0, size.height - 10.0));
      }

      canvas.drawPath(path, curvePaint);

      // Draw color fill below path
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(fillPath, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trip_model.dart';
import '../../services/location_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'proximity_radar_view.dart';
import 'leaderboard_view.dart';
import '../chat/chat_screen.dart';
import '../expenses/expense_screen.dart';
import '../itinerary/itinerary_screen.dart';

class ActiveTrackingScreen extends ConsumerStatefulWidget {
  final TripModel trip;

  const ActiveTrackingScreen({
    super.key,
    required this.trip,
  });

  @override
  ConsumerState<ActiveTrackingScreen> createState() => _ActiveTrackingScreenState();
}

class _ActiveTrackingScreenState extends ConsumerState<ActiveTrackingScreen> {
  late bool _ghostModeActive;
  int _activeTab = 0; // 0: Live Map, 1: Proximity Radar, 2: Leaderboard/Stats
  double _currentSpeed = 0.0;
  double _progressPercentage = 0.0;
  Map<String, dynamic> _groupLocations = {};
  LocationService? _locationService; // cached to avoid ref.read in dispose

  @override
  void initState() {
    super.initState();
    _ghostModeActive = widget.trip.isGhostActive;
    
    // Start background location broadcast
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationService = ref.read(locationServiceProvider);
      _locationService?.startTracking(
        widget.trip.id,
        ghostMode: _ghostModeActive,
      );
    });
  }

  @override
  void dispose() {
    // Stop broadcast tracking — use cached reference, NOT ref.read (unsafe in dispose)
    _locationService?.stopTracking();
    super.dispose();
  }

  Future<void> _toggleGhostMode() async {
    final newStatus = !_ghostModeActive;
    setState(() {
      _ghostModeActive = newStatus;
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateGhostMode(
        tripId: widget.trip.id,
        isGhostActive: newStatus,
      );

      // Reconfigure the location service broadcast active tracking
      final locationService = ref.read(locationServiceProvider);
      await locationService.stopTracking();
      await locationService.startTracking(widget.trip.id, ghostMode: newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus
                ? 'Ghost Mode Active. Your location is hidden.'
                : 'Ghost Mode Disabled. Broadcasting your location.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update privacy mode: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationService = ref.watch(locationServiceProvider);
    
    // Listen to personal location changes to update speedometer
    ref.listen<AsyncValue<LocationData>>(locationStreamProvider, (prev, next) {
      next.whenData((data) {
        setState(() {
          _currentSpeed = data.speed;
        });
      });
    });

    // Subscribes to real-time group coordinates changes
    return StreamBuilder<Map<String, dynamic>>(
      stream: locationService.streamGroupLocations(widget.trip.id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _groupLocations = snapshot.data!;
          
          // Calculate simulated trip progress from positions (mock progress percentage)
          final currentUser = ref.read(authServiceProvider).currentUser;
          if (currentUser != null && _groupLocations.containsKey(currentUser.uid)) {
            // Find current simulation index or calculate progress
            final loc = LocationData.fromMap(_groupLocations[currentUser.uid]);
            // Estimate progress along the sierra route
            double minDistance = double.infinity;
            int closestIndex = 0;
            for (int i = 0; i < LocationService.sierraNevadaRoute.length; i++) {
              final routePoint = LocationService.sierraNevadaRoute[i];
              final dist = (routePoint[0] - loc.latitude) * (routePoint[0] - loc.latitude) + 
                           (routePoint[1] - loc.longitude) * (routePoint[1] - loc.longitude);
              if (dist < minDistance) {
                minDistance = dist;
                closestIndex = i;
              }
            }
            _progressPercentage = (closestIndex / (LocationService.sierraNevadaRoute.length - 1)) * 100;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.trip.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_outlined),
                tooltip: 'Chat',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(trip: widget.trip),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  _ghostModeActive ? Icons.visibility_off : Icons.visibility,
                  color: _ghostModeActive ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
                tooltip: 'Toggle Ghost Mode',
                onPressed: _toggleGhostMode,
              ),
            ],
          ),
          body: _buildActiveTabContent(theme),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _activeTab,
            onDestinationSelected: (index) {
              setState(() {
                _activeTab = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Live Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.radar_outlined),
                selectedIcon: Icon(Icons.radar),
                label: 'Proximity Radar',
              ),
              NavigationDestination(
                icon: Icon(Icons.leaderboard_outlined),
                selectedIcon: Icon(Icons.leaderboard),
                label: 'Leaderboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.attach_money_outlined),
                selectedIcon: Icon(Icons.attach_money),
                label: 'Expenses',
              ),
              NavigationDestination(
                icon: Icon(Icons.timeline_outlined),
                selectedIcon: Icon(Icons.timeline),
                label: 'Timeline',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveTabContent(ThemeData theme) {
    switch (_activeTab) {
      case 1:
        return ProximityRadarView(
          trip: widget.trip,
          groupLocations: _groupLocations,
          ghostModeActive: _ghostModeActive,
        );
      case 2:
        return LeaderboardView(
          trip: widget.trip,
          groupLocations: _groupLocations,
        );
      case 3:
        return ExpenseScreen(trip: widget.trip);
      case 4:
        return ItineraryScreen(trip: widget.trip);
      case 0:
      default:
        return _buildLiveMapContent(theme);
    }
  }

  Widget _buildLiveMapContent(ThemeData theme) {
    return Stack(
      children: [
        // Vector topographic live map canvas
        Positioned.fill(
          child: Container(
            color: const Color(0xFF090A0F),
            child: CustomPaint(
              size: Size.infinite,
              painter: ActiveTopoPainter(
                groupLocations: _groupLocations,
                currentUserId: ref.read(authServiceProvider).currentUser?.uid ?? '',
                ghostModeActive: _ghostModeActive,
              ),
            ),
          ),
        ),

        // HUD Dashboard Overlay (Top HUD card)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 8,
                color: theme.colorScheme.surface.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Velocity / Speedometer
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VELOCITY', style: theme.textTheme.labelSmall),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _currentSpeed.toStringAsFixed(1),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00F0FF),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text('mph', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                      // Progress bar along route
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('ROUTE SYNC PROGRESS', style: theme.textTheme.labelSmall),
                                  Text(
                                    '${_progressPercentage.toStringAsFixed(0)}%',
                                    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _progressPercentage / 100,
                                  minHeight: 8,
                                  backgroundColor: Colors.white10,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Live Dynamic Member Panels (Bottom Overlay List)
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _groupLocations.length,
                  itemBuilder: (context, index) {
                    final uid = _groupLocations.keys.elementAt(index);
                    final data = _groupLocations[uid] as Map<String, dynamic>;
                    final name = data['displayName'] as String? ?? 'User';
                    final speed = (data['speed'] as num?)?.toDouble() ?? 0.0;
                    final isCurrentUser = uid == ref.read(authServiceProvider).currentUser?.uid;
                    
                    return Card(
                      color: isCurrentUser 
                          ? theme.colorScheme.primaryContainer.withOpacity(0.85) 
                          : theme.colorScheme.surface.withOpacity(0.85),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isCurrentUser 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      margin: const EdgeInsets.only(right: 12),
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isCurrentUser ? theme.colorScheme.primary : Colors.blueGrey,
                              child: Text(
                                name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCurrentUser ? 'You (Ghost)' : name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  Text(
                                    'Speed: ${speed.toStringAsFixed(0)} mph',
                                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ActiveTopoPainter extends CustomPainter {
  final Map<String, dynamic> groupLocations;
  final String currentUserId;
  final bool ghostModeActive;

  ActiveTopoPainter({
    required this.groupLocations,
    required this.currentUserId,
    required this.ghostModeActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final topoPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final routePaint = Paint()
      ..color = const Color(0xFF00F0FF).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Draw contours
    for (int i = 1; i <= 6; i++) {
      canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), i * 70.0, topoPaint);
    }

    // Draw Sierra Route line overlay
    final routePath = Path()
      ..moveTo(60, 140)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.2, size.width * 0.4, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.8, size.width - 80, size.height - 180);

    canvas.drawPath(routePath, routePaint);

    // Draw members as customized marker avatars on the canvas
    groupLocations.forEach((uid, data) {
      final loc = LocationData.fromMap(data);
      final isCurrentUser = uid == currentUserId;
      final displayName = data['displayName'] as String? ?? 'User';

      // Map latitude & longitude coordinates to Canvas screen coordinates
      // Map Yosemite coordinates [37.7456, -119.5332] to Yosemite pass [37.7960, -119.4100]
      final latDiff = loc.latitude - 37.7456;
      final lngDiff = loc.longitude - (-119.5332);
      
      final latRange = 37.7960 - 37.7456;
      final lngRange = -119.4100 - (-119.5332);

      // Interpolate canvas positions
      final x = 60.0 + (size.width - 140.0) * (lngDiff / lngRange).clamp(0.0, 1.0);
      final y = 140.0 + (size.height - 320.0) * (1.0 - (latDiff / latRange).clamp(0.0, 1.0));

      final center = Offset(x, y);
      
      // Paint avatar marker
      final pinPaint = Paint()
        ..color = isCurrentUser 
            ? (ghostModeActive ? const Color(0xFFFF5E5E) : const Color(0xFF00F0FF))
            : const Color(0xFF00FF66)
        ..style = PaintingStyle.fill;

      // Draw pulse animation ring for active movements
      final pulsePaint = Paint()
        ..color = pinPaint.color.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 18, pulsePaint);

      // Draw marker center
      canvas.drawCircle(center, 10, pinPaint);

      // Draw avatar background details
      final innerPaint = Paint()
        ..color = const Color(0xFF1E2029)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 8, innerPaint);

      // Text Painter for Member Initial
      final textPainter = TextPainter(
        text: TextSpan(
          text: displayName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: pinPaint.color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas, 
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );

      // Draw Member label on top of marker
      final labelPainter = TextPainter(
        text: TextSpan(
          text: isCurrentUser ? 'You (Ghost)' : displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            backgroundColor: Color(0xCC000000),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        center - Offset(labelPainter.width / 2, 22),
      );
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

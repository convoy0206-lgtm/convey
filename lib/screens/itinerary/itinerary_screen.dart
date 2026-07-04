import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/trip_model.dart';
import '../../models/itinerary_item_model.dart';
import '../../services/firestore_service.dart';

class ItineraryScreen extends ConsumerStatefulWidget {
  final TripModel trip;

  const ItineraryScreen({
    super.key,
    required this.trip,
  });

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _timeController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _distController = TextEditingController();
  final _estController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _timeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _distController.dispose();
    _estController.dispose();
    super.dispose();
  }

  /// Launch Apple/Google Maps deep-linking direction details.
  Future<void> _launchDirections(double lat, double lng) async {
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    final appleMapsUrl = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not find compatible maps application.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch maps: $e')),
        );
      }
    }
  }

  /// Populate pre-planned Yosemite/Sierra milestones.
  Future<void> _populatePreplannedItinerary() async {
    setState(() {
      _isLoading = true;
    });

    final firestoreService = ref.read(firestoreServiceProvider);

    final preplanned = [
      ItineraryItemModel(
        id: '',
        tripId: widget.trip.id,
        title: 'Yosemite Valley Start Point',
        description: 'Squad gathering, trail briefings, and initial GPS coordinate check-ins.',
        timeLabel: 'Day 1 - 08:00 AM',
        latitude: 37.7456,
        longitude: -119.5332,
        distanceMiles: 0.0,
        estimatedTimeMinutes: 0,
      ),
      ItineraryItemModel(
        id: '',
        tripId: widget.trip.id,
        title: 'Tuolumne Meadows Rest Station',
        description: 'First milestone rest point, water refills, and device battery checks.',
        timeLabel: 'Day 1 - 01:00 PM',
        latitude: 37.8768,
        longitude: -119.3556,
        distanceMiles: 18.2,
        estimatedTimeMinutes: 300,
      ),
      ItineraryItemModel(
        id: '',
        tripId: widget.trip.id,
        title: 'Nevada Pass Summit Peak',
        description: 'High altitude pass crossing. Extreme weather warning checkpoint.',
        timeLabel: 'Day 2 - 11:30 AM',
        latitude: 37.7960,
        longitude: -119.4100,
        distanceMiles: 30.3,
        estimatedTimeMinutes: 520,
      ),
    ];

    try {
      for (var item in preplanned) {
        await firestoreService.addItineraryItem(widget.trip.id, item);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pre-populate itinerary: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddMilestoneDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Milestone Checkpoint'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Tuolumne Rest Point'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description', hintText: 'Battery recharge and snack stop'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(labelText: 'Time / Day Label', hintText: 'Day 2 - 10:00 AM'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Latitude', hintText: '37.785'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _lngController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Longitude', hintText: '-119.45'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _distController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Dist. (miles)', hintText: '12.5'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _estController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Est. Min', hintText: '240'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = _titleController.text.trim();
                final desc = _descController.text.trim();
                final timeLabel = _timeController.text.trim();
                final lat = double.tryParse(_latController.text) ?? 0.0;
                final lng = double.tryParse(_lngController.text) ?? 0.0;
                final dist = double.tryParse(_distController.text) ?? 0.0;
                final est = int.tryParse(_estController.text) ?? 0;

                if (title.isEmpty || timeLabel.isEmpty) return;

                Navigator.of(context).pop(); // Close Dialog
                setState(() {
                  _isLoading = true;
                });

                try {
                  final firestoreService = ref.read(firestoreServiceProvider);
                  final item = ItineraryItemModel(
                    id: '',
                    tripId: widget.trip.id,
                    title: title,
                    description: desc,
                    timeLabel: timeLabel,
                    latitude: lat,
                    longitude: lng,
                    distanceMiles: dist,
                    estimatedTimeMinutes: est,
                  );
                  await firestoreService.addItineraryItem(widget.trip.id, item);
                  
                  _titleController.clear();
                  _descController.clear();
                  _timeController.clear();
                  _latController.clear();
                  _lngController.clear();
                  _distController.clear();
                  _estController.clear();

                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add milestone: $e')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestoreService = ref.watch(firestoreServiceProvider);

    return Scaffold(
      body: StreamBuilder<List<ItineraryItemModel>>(
        stream: firestoreService.streamItinerary(widget.trip.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Screen 9: Timeline empty state UI dashboard
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 72,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No planned milestones or itinerary checkpoints found for this trip.',
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _populatePreplannedItinerary,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Load Yosemite Pass Pre-planned Itinerary'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showAddMilestoneDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Custom Checkpoint'),
                  ),
                ],
              ),
            );
          }

          final list = snapshot.data!;
          // Sort list chronologically or based on distance
          list.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline connector bar UI
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      if (index != list.length - 1)
                        Container(
                          width: 2,
                          height: 160,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  
                  // Milestone topographic preview card (Screen 7 chronological milestone feed)
                  Expanded(
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Custom Paint Topographic preview map inside the card
                          Container(
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0C0E14),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: CustomPaint(
                                painter: MilestoneMiniMapPainter(
                                  checkpointName: item.title,
                                  lat: item.latitude,
                                  lng: item.longitude,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.timeLabel,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${item.distanceMiles.toStringAsFixed(1)} miles',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.title,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.description,
                                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Est: ${item.estimatedTimeMinutes} min duration',
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
                                    ),
                                    // Maps directions linking
                                    ElevatedButton.icon(
                                      onPressed: () => _launchDirections(item.latitude, item.longitude),
                                      icon: const Icon(Icons.directions_outlined, size: 16),
                                      label: const Text('Directions', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        minimumSize: Size.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMilestoneDialog(context),
        child: const Icon(Icons.add_location_alt_outlined),
      ),
    );
  }
}

class MilestoneMiniMapPainter extends CustomPainter {
  final String checkpointName;
  final double lat;
  final double lng;

  MilestoneMiniMapPainter({
    required this.checkpointName,
    required this.lat,
    required this.lng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.fill;

    // Draw topographic circles
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.5), 30, ringPaint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.5), 60, ringPaint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.2), 20, ringPaint);

    // Draw connecting trail path line
    final pathPaint = Paint()
      ..color = const Color(0xFF00F0FF).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path()
      ..moveTo(20, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.2, size.width - 40, size.height * 0.5);

    canvas.drawPath(path, pathPaint);

    // Draw active checkpoint dot
    final center = Offset(size.width - 40, size.height * 0.5);
    canvas.drawCircle(center, 5.0, dotPaint);

    // Coordinate text painter label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°',
        style: const TextStyle(color: Colors.white54, fontSize: 8, fontFamily: 'monospace'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      center - Offset(textPainter.width + 10, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../providers/app_provider.dart';
import '../services/ringer_service.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:dio/dio.dart';

// ═══════════════════════════════════════════════════════
// Location Zone Model
// ═══════════════════════════════════════════════════════
class LocationZone {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;
  final String mode; // 'Silent' | 'Vibrate' | 'DND'
  final bool isEnabled;

  LocationZone({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
    required this.mode,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id':            id,
    'name':          name,
    'lat':           lat,
    'lng':           lng,
    'radiusMeters':  radiusMeters,
    'mode':          mode,
    'isEnabled':     isEnabled,
  };

  factory LocationZone.fromJson(Map<String, dynamic> j) => LocationZone(
    id:           j['id'] ?? '',
    name:         j['name'] ?? 'Zone',
    lat:          (j['lat'] as num).toDouble(),
    lng:          (j['lng'] as num).toDouble(),
    radiusMeters: (j['radiusMeters'] as num).toDouble(),
    mode:         j['mode'] ?? 'Silent',
    isEnabled:    j['isEnabled'] ?? true,
  );

  LocationZone copyWith({
    String? name, double? lat, double? lng,
    double? radiusMeters, String? mode, bool? isEnabled,
  }) => LocationZone(
    id:           id,
    name:         name          ?? this.name,
    lat:          lat           ?? this.lat,
    lng:          lng           ?? this.lng,
    radiusMeters: radiusMeters  ?? this.radiusMeters,
    mode:         mode          ?? this.mode,
    isEnabled:    isEnabled     ?? this.isEnabled,
  );
}

// ═══════════════════════════════════════════════════════
// Location Screen
// ═══════════════════════════════════════════════════════
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final MapController _mapController = MapController();

  List<LocationZone> _zones = [];
  LatLng? _currentLocation;
  LatLng? _pendingPin;
  bool _isLoadingLocation = true;
  bool _isMonitoring      = false;
  Timer? _monitorTimer;

  static const _zonesKey     = 'location_zones';
  static const _radii        = [100.0, 200.0, 500.0];
  static const _radiusLabels = ['100m', '200m', '500m'];
  static const _modes        = ['Silent', 'Vibrate', 'DND'];

  @override
  void initState() {
    super.initState();
    _loadZones();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  // ── Load saved zones ──
  Future<void> _loadZones() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_zonesKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() => _zones = list.map((e) => LocationZone.fromJson(e)).toList());
      _startMonitoring();
    }
  }

  // ── Save zones ──
  Future<void> _saveZones() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_zonesKey, jsonEncode(_zones.map((z) => z.toJson()).toList()));
  }

  // ── Get current GPS location ──
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        setState(() => _isLoadingLocation = false);
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation   = LatLng(pos.latitude, pos.longitude);
        _isLoadingLocation = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(_currentLocation!, 15);
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      debugPrint('Location error: $e');
    }
  }

  // ── Start background monitoring ──
  void _startMonitoring() {
    _monitorTimer?.cancel();
    if (_zones.isEmpty) return;
    setState(() => _isMonitoring = true);
    _monitorTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkZones());
  }

  // ── Check if inside any zone ──
  Future<void> _checkZones() async {
    if (_zones.isEmpty) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final current = LatLng(pos.latitude, pos.longitude);
      if (mounted) setState(() => _currentLocation = current);

      bool insideAny = false;
      for (final zone in _zones.where((z) => z.isEnabled)) {
        final dist = Geolocator.distanceBetween(
          current.latitude, current.longitude,
          zone.lat, zone.lng,
        );
        if (dist <= zone.radiusMeters) {
          insideAny = true;
          // Use applyMode which correctly maps Silent/Vibrate/DND
          await RingerService.applyMode(zone.mode);
          break;
        }
      }

      // Restore normal if outside all zones
      if (!insideAny) {
        await RingerService.setNormal();
      }
    } catch (_) {}
  }

  // ── Mode icon helper ──
  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'Silent':  return Icons.volume_off_rounded;
      case 'Vibrate': return Icons.vibration_rounded;
      case 'DND':     return Icons.do_not_disturb_on_rounded;
      default:        return Icons.volume_off_rounded;
    }
  }

  // ── Add zone from pending pin ──
  void _showAddZoneSheet(LatLng pin) {
    final nameCtrl = TextEditingController();
    double selectedRadius = 100.0;
    String selectedMode   = 'Silent';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tc(context).surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: tc(context).border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('Add Silent Zone',
                  style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: tc(context).textPrimary,
                  )),
              const SizedBox(height: 4),
              Text('Phone will auto-silence when you enter this area',
                  style: GoogleFonts.dmMono(
                    fontSize: 10, color: tc(context).textSecondary,
                  )),
              const SizedBox(height: 20),

              // Zone name
              Text('ZONE NAME',
                  style: GoogleFonts.dmMono(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: tc(context).textSecondary, letterSpacing: 1.5,
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.outfit(
                    color: tc(context).textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Office, Mosque, Library',
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: tc(context).textSecondary, size: 20),
                ),
              ),
              const SizedBox(height: 20),

              // Radius
              Text('RADIUS',
                  style: GoogleFonts.dmMono(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: tc(context).textSecondary, letterSpacing: 1.5,
                  )),
              const SizedBox(height: 8),
              Row(
                children: List.generate(_radii.length, (i) {
                  final selected = selectedRadius == _radii[i];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedRadius = _radii[i]),
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.accent : tc(context).surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.accent : tc(context).border,
                          ),
                        ),
                        child: Center(
                          child: Text(_radiusLabels[i],
                              style: GoogleFonts.dmMono(
                                color: selected ? Colors.black : tc(context).textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              )),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Mode — Silent | Vibrate | DND
              Text('SILENCE MODE',
                  style: GoogleFonts.dmMono(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: tc(context).textSecondary, letterSpacing: 1.5,
                  )),
              const SizedBox(height: 8),
              Row(
                children: _modes.map((mode) {
                  final selected = selectedMode == mode;
                  final isLast   = mode == _modes.last;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedMode = mode),
                      child: Container(
                        margin: EdgeInsets.only(right: isLast ? 0 : 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.accent : tc(context).surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.accent : tc(context).border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_modeIcon(mode),
                                color: selected ? Colors.black : tc(context).textPrimary,
                                size: 15),
                            const SizedBox(width: 4),
                            Text(mode,
                                style: GoogleFonts.dmMono(
                                  color: selected ? Colors.black : tc(context).textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                )),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Save button
              GestureDetector(
                onTap: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final zone = LocationZone(
                    id:           DateTime.now().millisecondsSinceEpoch.toString(),
                    name:         name,
                    lat:          pin.latitude,
                    lng:          pin.longitude,
                    radiusMeters: selectedRadius,
                    mode:         selectedMode,
                  );
                  setState(() {
                    _zones.add(zone);
                    _pendingPin = null;
                  });
                  _saveZones();
                  _startMonitoring();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: AppColors.accent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    content: Text('Zone "$name" saved!',
                        style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontWeight: FontWeight.w600)),
                  ));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text('Save Zone',
                        style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delete zone ──
  void _deleteZone(LocationZone zone) {
    setState(() => _zones.removeWhere((z) => z.id == zone.id));
    _saveZones();
    if (_zones.isEmpty) {
      _monitorTimer?.cancel();
      setState(() => _isMonitoring = false);
      RingerService.setNormal();
    }
  }

  // ── Toggle zone enabled ──
  void _toggleZone(LocationZone zone) {
    setState(() {
      final idx = _zones.indexWhere((z) => z.id == zone.id);
      if (idx != -1) {
        _zones[idx] = zone.copyWith(isEnabled: !zone.isEnabled);
      }
    });
    _saveZones();
  }

  @override
  Widget build(BuildContext context) {
    final colors = tc(context);

    return SafeArea(
      child: Column(
        children: [

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LOCATION ZONES',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Tap map to add a zone',
                        style: GoogleFonts.outfit(fontSize: 14, color: colors.textSecondary)),
                  ],
                ),
                // Monitoring indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isMonitoring ? AppColors.accent.withOpacity(0.1) : colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isMonitoring ? AppColors.accent.withOpacity(0.4) : colors.border,
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: _isMonitoring ? AppColors.accent : colors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isMonitoring ? 'ACTIVE' : 'OFF',
                      style: GoogleFonts.dmMono(
                        color: _isMonitoring ? AppColors.accentOrBlack(context) : colors.textMuted,
                        fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1,
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: TypeAheadField<Map<String, dynamic>>(
              builder: (context, controller, focusNode) => TextField(
                controller: controller,
                focusNode: focusNode,
                style: GoogleFonts.outfit(color: colors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search location...',
                  prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary, size: 20),
                  suffixIcon: Icon(Icons.location_searching_rounded, color: AppColors.accent, size: 20),
                ),
              ),
              suggestionsCallback: (query) async {
                if (query.length < 3) return [];
                try {
                  final res = await Dio().get(
                    'https://nominatim.openstreetmap.org/search',
                    queryParameters: {'q': query, 'format': 'json', 'limit': 5},
                    options: Options(headers: {
                      'User-Agent': 'AutoSilence/1.0 (contact@autosilence.app)',
                      'Accept-Language': 'en',
                    }),
                  );
                  return List<Map<String, dynamic>>.from(res.data);
                } catch (_) { return []; }
              },
              itemBuilder: (context, item) => ListTile(
                tileColor: colors.surface,
                leading: Icon(Icons.location_on_outlined, color: AppColors.accent, size: 20),
                title: Text(
                  item['display_name'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              onSelected: (item) {
                final lat   = double.parse(item['lat']);
                final lng   = double.parse(item['lon']);
                final point = LatLng(lat, lng);
                _mapController.move(point, 15);
                setState(() => _pendingPin = point);
                _showAddZoneSheet(point);
              },
              decorationBuilder: (context, child) => Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                elevation: 4,
                child: child,
              ),
            ),
          ),

          // ── Map ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: _isLoadingLocation
                ? Container(
              color: colors.surface,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                    const SizedBox(height: 12),
                    Text('Getting your location...', style: GoogleFonts.outfit(color: colors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            )
                : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? const LatLng(24.8607, 67.0011),
                initialZoom: 15,
                onTap: (_, latLng) {
                  setState(() => _pendingPin = latLng);
                  _showAddZoneSheet(latLng);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.autosilence.app',
                ),
                CircleLayer(
                  circles: _zones.map((z) => CircleMarker(
                    point: LatLng(z.lat, z.lng),
                    radius: z.radiusMeters,
                    useRadiusInMeter: true,
                    color: (z.isEnabled ? AppColors.accent : colors.textMuted).withOpacity(0.15),
                    borderColor: (z.isEnabled ? AppColors.accent : colors.textMuted).withOpacity(0.5),
                    borderStrokeWidth: 1.5,
                  )).toList(),
                ),
                MarkerLayer(
                  markers: [
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        width: 20, height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 8)],
                          ),
                        ),
                      ),
                    ..._zones.map((z) => Marker(
                      point: LatLng(z.lat, z.lng),
                      width: 36, height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: z.isEnabled ? AppColors.accent : colors.textMuted,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: (z.isEnabled ? AppColors.accent : colors.textMuted).withOpacity(0.4),
                            blurRadius: 8,
                          )],
                        ),
                        child: Icon(_modeIcon(z.mode),
                            color: z.isEnabled ? Colors.black : Colors.white, size: 18),
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),

          // ── Hint ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Row(children: [
              Icon(Icons.touch_app_rounded, color: colors.textMuted, size: 14),
              const SizedBox(width: 6),
              Text('Tap anywhere on the map to add a silent zone',
                  style: GoogleFonts.dmMono(color: colors.textMuted, fontSize: 9)),
              const Spacer(),
              GestureDetector(
                onTap: _getCurrentLocation,
                child: Icon(Icons.my_location_rounded, color: AppColors.accent, size: 18),
              ),
            ]),
          ),

          // ── Zones List ──
          Expanded(
            child: _zones.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(Icons.location_off_rounded, color: colors.textMuted, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text('No zones yet',
                      style: GoogleFonts.outfit(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Tap the map to add your first zone',
                      style: GoogleFonts.dmMono(color: colors.textMuted, fontSize: 10)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: _zones.length,
              itemBuilder: (_, i) => _ZoneTile(
                zone: _zones[i],
                onToggle: () => _toggleZone(_zones[i]),
                onDelete: () => _deleteZone(_zones[i]),
                onTap: () => _mapController.move(LatLng(_zones[i].lat, _zones[i].lng), 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Zone Tile
// ═══════════════════════════════════════════════════════
class _ZoneTile extends StatelessWidget {
  final LocationZone zone;
  final VoidCallback onToggle, onDelete, onTap;

  const _ZoneTile({
    required this.zone,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  IconData get _icon {
    switch (zone.mode) {
      case 'Silent':  return Icons.volume_off_rounded;
      case 'Vibrate': return Icons.vibration_rounded;
      case 'DND':     return Icons.do_not_disturb_on_rounded;
      default:        return Icons.volume_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors   = tc(context);
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final isActive = zone.isEnabled;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.accent.withOpacity(0.25) : colors.border,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent.withOpacity(0.08) : colors.border2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.accent : Colors.black87),
              ),
              child: Icon(_icon, color: isDark ? AppColors.accent : Colors.black87, size: 20),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone.name,
                      style: GoogleFonts.outfit(
                          color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('${zone.mode}  ·  ${zone.radiusMeters.toInt()}m radius',
                      style: GoogleFonts.dmMono(color: colors.textSecondary, fontSize: 9)),
                ],
              ),
            ),

            // Mode badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : colors.surface2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                zone.mode.toUpperCase(),
                style: GoogleFonts.dmMono(
                  color: isActive ? Colors.black : colors.textMuted,
                  fontSize: 8, fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Toggle
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40, height: 22,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent : colors.border2,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 16, height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.black : Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Delete
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.delete_rounded, color: AppColors.danger, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
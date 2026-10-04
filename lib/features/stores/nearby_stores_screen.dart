// lib/features/stores/nearby_stores_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/repositories/places_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../models/care_models.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/tappable.dart';

class NearbyStoresScreen extends ConsumerStatefulWidget {
  const NearbyStoresScreen({super.key});

  @override
  ConsumerState<NearbyStoresScreen> createState() => _NearbyStoresScreenState();
}

class _NearbyStoresScreenState extends ConsumerState<NearbyStoresScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  final TextEditingController _manualLocationCtrl = TextEditingController();

  LatLng _currentLocation = const LatLng(28.6139, 77.2090); // Default New Delhi
  double _selectedRadiusKm = 5.0;
  bool _isLoading = false;
  bool _permissionDenied = false;
  String? _selectedPlaceId;

  List<PlaceResult> _pharmacies = [];
  List<PlaceResult> _dermatologists = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _getUserLocationAndSearch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualLocationCtrl.dispose();
    super.dispose();
  }

  Future<void> _getUserLocationAndSearch() async {
    setState(() => _isLoading = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
      }
      _fetchPlaces(_currentLocation);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _permissionDenied = true;
            _isLoading = false;
          });
        }
        _fetchPlaces(_currentLocation);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
      }
      _fetchPlaces(_currentLocation);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final userLatLng = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _currentLocation = userLatLng;
          _permissionDenied = false;
        });
      }
      _fetchPlaces(userLatLng);
    } catch (_) {
      _fetchPlaces(_currentLocation);
    }
  }

  Future<void> _fetchPlaces(LatLng location) async {
    setState(() => _isLoading = true);
    final repo = ref.read(placesRepositoryProvider);

    final phs = await repo.searchPharmacies(lat: location.latitude, lon: location.longitude, radiusKm: _selectedRadiusKm);
    final derms = await repo.searchDermatologists(lat: location.latitude, lon: location.longitude, radiusKm: _selectedRadiusKm);

    if (mounted) {
      setState(() {
        _pharmacies = phs;
        _dermatologists = derms;
        _isLoading = false;
      });
      _mapController.move(location, 13.0);
    }
  }

  Future<void> _searchManualLocation() async {
    final query = _manualLocationCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    final repo = ref.read(placesRepositoryProvider);
    final loc = await repo.geocodeAddress(query);

    if (loc != null && mounted) {
      setState(() {
        _currentLocation = loc;
      });
      _fetchPlaces(loc);
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('City/Area not found. Try another search.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePlaces = _tabController.index == 0 ? _pharmacies : _dermatologists;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nearby Stores & Clinics', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Pharmacies'),
            Tab(text: 'Dermatologists & Clinics'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Radius Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualLocationCtrl,
                    onSubmitted: (_) => _searchManualLocation(),
                    decoration: InputDecoration(
                      hintText: _permissionDenied ? 'Enter city or area name...' : 'Search near city/area...',
                      prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        onPressed: _searchManualLocation,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<double>(
                  onSelected: (val) {
                    setState(() => _selectedRadiusKm = val);
                    _fetchPlaces(_currentLocation);
                  },
                  itemBuilder: (ctx) => [1.0, 3.0, 5.0, 10.0].map((r) {
                    return PopupMenuItem<double>(
                      value: r,
                      child: Text('${r.toInt()} km radius'),
                    );
                  }).toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text('${_selectedRadiusKm.toInt()} km', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                        const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryDark, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // OSM Map Viewport
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.glowai.app',
                    ),
                    MarkerLayer(
                      markers: activePlaces.map((place) {
                        final isSel = place.id == _selectedPlaceId;
                        return Marker(
                          point: LatLng(place.lat, place.lon),
                          width: 36,
                          height: 36,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPlaceId = place.id),
                            child: Icon(
                              _tabController.index == 0 ? Icons.local_pharmacy_rounded : Icons.local_hospital_rounded,
                              color: isSel ? AppColors.danger : AppColors.primaryDark,
                              size: isSel ? 34 : 26,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Re-center search button
                Positioned(
                  top: 10,
                  right: 10,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter',
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location_rounded, color: AppColors.primaryDark),
                    onPressed: () => _getUserLocationAndSearch(),
                  ),
                ),

                // OSM Attribution
                Positioned(
                  bottom: 4,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                    child: const Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 9, color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),

          // Search Results List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : activePlaces.isEmpty
                    ? _buildEmptyResults()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: activePlaces.length,
                        itemBuilder: (context, index) {
                          final item = activePlaces[index];
                          final isSel = item.id == _selectedPlaceId;
                          final phoneStr = item.phone ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Tappable(
                              onTap: () => setState(() => _selectedPlaceId = item.id),
                              child: GlowCard(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isSel ? AppColors.primaryDark : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primarySoft.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${item.distanceKm} km',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.address,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                    if (item.openingHours.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Hours: ${item.openingHours}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        if (phoneStr.isNotEmpty) ...[
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                ref.read(placesRepositoryProvider).launchCall(phoneStr);
                                              },
                                              icon: const Icon(Icons.phone_rounded, size: 16),
                                              label: const Text('Call', style: TextStyle(fontSize: 12)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: GlowButton(
                                            label: 'Directions',
                                            icon: Icons.directions_rounded,
                                            height: 38,
                                            onPressed: () {
                                              ref.read(placesRepositoryProvider).launchDirections(item.lat, item.lon, item.name);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

  Widget _buildEmptyResults() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            const Text(
              'No results found nearby',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'OpenStreetMap coverage can be limited in some areas. Try increasing the radius or search directly on Google Maps.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(placesRepositoryProvider).launchGoogleMapsSearch(
                      _tabController.index == 0 ? 'pharmacies' : 'dermatologists',
                      _currentLocation.latitude,
                      _currentLocation.longitude,
                    );
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Search on Google Maps'),
            ),
          ],
        ),
      ),
    );
  }
}

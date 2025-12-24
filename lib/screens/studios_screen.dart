import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'profile/artist_profile_screen.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class StudiosScreen extends StatefulWidget {
  const StudiosScreen({super.key});

  @override
  State<StudiosScreen> createState() => _StudiosScreenState();
}

class _StudiosScreenState extends State<StudiosScreen> {
  final List<String> _selectedFilters = [];
  String _sortOption = AppConstants.sortPopular; 
  bool _showMap = false;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  Position? _currentPosition;

  final Map<String, LatLng> _cityCoordinates = {
    'istanbul': const LatLng(41.0082, 28.9784),
    'ankara': const LatLng(39.9334, 32.8597),
    'izmir': const LatLng(38.4237, 27.1428),
    'antalya': const LatLng(36.8969, 30.7133),
  };

  final Map<String, LatLng> _districtCoordinates = {
    'kadıköy': const LatLng(40.9819, 29.0254),
    'beşiktaş': const LatLng(41.0422, 29.0077),
    'çankaya': const LatLng(39.9208, 32.8541),
    'nilüfer': const LatLng(40.2156, 28.9373),
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<bool> _requestUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) _showSnackBar('Konum servisi kapalı.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) _showSnackBar('Konum izni reddedildi.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showSnackBar('Konum izni kalıcı olarak reddedildi. Ayarlardan açmalısınız.');
      return false;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  LatLng _addJitter(LatLng original) {
    final random = Random();
    double offsetLat = (random.nextDouble() - 0.5) * 0.005;
    double offsetLng = (random.nextDouble() - 0.5) * 0.005;
    return LatLng(original.latitude + offsetLat, original.longitude + offsetLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 50,
                    child: CachedNetworkImage(
                      imageUrl: AppConstants.logoUrl,
                      height: 50,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const SizedBox(width: 50),
                      errorWidget: (context, url, error) => const SizedBox(width: 50, child: Icon(Icons.error)),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_showMap ? Icons.list : Icons.map),
                        color: _showMap ? AppTheme.primaryColor : const Color(0xFF757575),
                        onPressed: () async {
                          if (!_showMap) {
                            await _requestUserLocation();
                          }
                          setState(() {
                            _showMap = !_showMap;
                            _showSearch = false;
                          });
                          if (_showMap && _currentPosition != null && _mapController != null) {
                            _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
                              LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 13));
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        color: const Color(0xFF757575),
                        onPressed: () => setState(() { _showSearch = !_showSearch; _showMap = false; }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Stüdyo ya da semt ara',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _showSearch = false; _searchController.clear(); })),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
            
            if (!_showMap)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  children: [
                    _buildFilterChip(AppConstants.serviceTattoo, 'Dövme'),
                    _buildFilterChip(AppConstants.servicePiercing, 'Piercing'),
                    _buildFilterChip(AppConstants.serviceMakeup, 'Makyaj'),
                    _buildFilterChip(AppConstants.serviceRasta, 'Rasta'),
                  ],
                ),
              ),
            ),
            
            if (!_showMap)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _sortOption = AppConstants.sortPopular),
                      icon: const Icon(Icons.local_fire_department),
                      label: const Text('Popüler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _sortOption == AppConstants.sortPopular ? Theme.of(context).colorScheme.primary : const Color(0xFF323232),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_sortOption != AppConstants.sortDistance) {
                           bool hasLocation = await _requestUserLocation();
                           if (hasLocation) {
                             setState(() => _sortOption = AppConstants.sortDistance);
                           }
                        }
                      },
                      icon: const Icon(Icons.near_me),
                      label: const Text('Mesafe'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _sortOption == AppConstants.sortDistance ? Theme.of(context).colorScheme.primary : const Color(0xFF323232),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: _showMap ? _buildMapView() : _buildArtistList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilters.contains(value);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () => setState(() => isSelected ? _selectedFilters.remove(value) : _selectedFilters.add(value)),
        child: Container(
          height: 30, padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFF323232), borderRadius: BorderRadius.circular(10), border: isSelected ? null : Border.all(color: Colors.grey)),
          child: Center(child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12))),
        ),
      ),
    );
  }

  Widget _buildArtistList() {
    Query query = FirebaseFirestore.instance.collection(AppConstants.collectionUsers)
        .where('role', whereIn: [AppConstants.roleArtistApproved, AppConstants.roleArtistUnapproved])
        .where('isApproved', isEqualTo: true);

    if (_sortOption == AppConstants.sortPopular) {
      query = query.orderBy('totalLikes', descending: true);
    } 
    else {
      query = query.orderBy('createdAt', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var docs = snapshot.data!.docs;
        List<UserModel> artists = docs.map((d) => UserModel.fromFirestore(d)).toList();

        if (_selectedFilters.isNotEmpty) {
           artists = artists.where((a) => _selectedFilters.any((f) => a.applications.contains(f) || a.applicationStyles.contains(f))).toList();
        }
        if (_showSearch && _searchController.text.isNotEmpty) {
           artists = artists.where((a) => a.fullName.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
        }

        if (_sortOption == AppConstants.sortDistance && _currentPosition != null) {
          artists.sort((a, b) {
            LatLng? posA = _getArtistLatLng(a);
            LatLng? posB = _getArtistLatLng(b);
            
            if (posA == null) return 1;
            if (posB == null) return -1;

            double distA = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, posA.latitude, posA.longitude);
            double distB = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, posB.latitude, posB.longitude);
            return distA.compareTo(distB);
          });
        }

        if (artists.isEmpty) return const Center(child: Text('Sonuç yok'));

        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, index) {
            return _buildArtistCard(artists[index]);
          },
        );
      },
    );
  }

  LatLng? _getArtistLatLng(UserModel artist) {
    if (artist.latitude != null && artist.longitude != null) {
      return LatLng(artist.latitude!, artist.longitude!);
    } else if (artist.district != null && _districtCoordinates.containsKey(artist.district!.toLowerCase())) {
      return _districtCoordinates[artist.district!.toLowerCase()];
    } else if (artist.city != null && _cityCoordinates.containsKey(artist.city!.toLowerCase())) {
      return _cityCoordinates[artist.city!.toLowerCase()];
    }
    return null;
  }

  Widget _buildArtistCard(UserModel artist) {
     String distanceText = "";
     if (_currentPosition != null) {
       LatLng? pos = _getArtistLatLng(artist);
       if (pos != null) {
         double dist = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, pos.latitude, pos.longitude);
         distanceText = " • ${(dist / 1000).toStringAsFixed(1)} km";
       }
     }

     return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: const Color(0xFF212121),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ArtistProfileScreen(userId: artist.uid))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ÜST KISIM: Kapak Fotoğrafı ve Profil Fotoğrafı
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      image: artist.coverImageUrl != null
                          ? DecorationImage(image: NetworkImage(artist.coverImageUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: 16,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF212121),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: artist.profileImageUrl != null
                          ? NetworkImage(artist.profileImageUrl!)
                          : null,
                      child: artist.profileImageUrl == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35), 
            
            // ALT KISIM: Bilgiler
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        artist.username ?? artist.fullName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      // BEĞENİ VE TAKİPÇİ SAYISI ALANI
                      Row(
                        children: [
                          // Beğeni Sayısı
                          const Icon(Icons.favorite, color: AppTheme.primaryColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            artist.totalLikes.toString(),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(width: 12), // İkonlar arası boşluk
                          
                          // Takipçi Sayısı (StreamBuilder ile canlı veri)
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection(AppConstants.collectionFollows)
                                .where('followingId', isEqualTo: artist.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final followerCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                              return Row(
                                children: [
                                  const Icon(Icons.people, color: Colors.grey, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    followerCount.toString(),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (artist.locationString.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "${artist.locationString}$distanceText",
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ],
                  // Etiketler
                  if (artist.applications.isNotEmpty || artist.applicationStyles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        ...artist.applications.map((app) => _buildTinyTag(app, Colors.blueGrey.withOpacity(0.3))),
                        ...artist.applicationStyles.map((style) => _buildTinyTag(style, AppTheme.primaryColor.withOpacity(0.2))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTinyTag(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildMapView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .where('role', whereIn: [AppConstants.roleArtistApproved, AppConstants.roleArtistUnapproved])
          .where('isApproved', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final artists = snapshot.data!.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        final markers = <Marker>{};

        for (var artist in artists) {
          if (_selectedFilters.isNotEmpty) {
             bool match = _selectedFilters.any((f) => artist.applications.contains(f) || artist.applicationStyles.contains(f));
             if (!match) continue;
          }

          LatLng? position = _getArtistLatLng(artist);
          if (position != null) {
            position = _addJitter(position); 
            markers.add(Marker(
              markerId: MarkerId(artist.uid),
              position: position,
              infoWindow: InfoWindow(
                title: artist.username ?? artist.fullName,
                snippet: artist.locationString,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ArtistProfileScreen(userId: artist.uid))),
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            ));
          }
        }

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition != null 
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) 
                : const LatLng(41.0082, 28.9784),
            zoom: _currentPosition != null ? 12 : 10,
          ),
          markers: markers,
          myLocationEnabled: true, 
          myLocationButtonEnabled: true, 
          onMapCreated: (controller) {
            _mapController = controller;
            if (_currentPosition != null) {
              controller.animateCamera(CameraUpdate.newLatLngZoom(
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 13));
            }
          },
        );
      },
    );
  }
}
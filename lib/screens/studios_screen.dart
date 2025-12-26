import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart'; // EKLENDİ: ID kontrolü için
import 'dart:math';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/turkey_locations.dart';
import 'profile/artist_profile_screen.dart';
import '../theme/app_theme.dart';

class StudiosScreen extends StatefulWidget {
  const StudiosScreen({super.key});

  @override
  State<StudiosScreen> createState() => _StudiosScreenState();
}

class _StudiosScreenState extends State<StudiosScreen> {
  // --- FİLTRE DEĞİŞKENLERİ ---
  final List<String> _selectedApplications = [];
  final List<String> _selectedStyles = [];
  
  // --- ARAMA DEĞİŞKENLERİ (HİBRİT) ---
  String? _selectedSearchCity;      
  String? _selectedSearchDistrict;  
  String _nameSearchQuery = "";     
  List<String> _locationSuggestions = [];

  String _sortOption = AppConstants.sortPopular; 
  bool _showMap = false;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  Position? _currentPosition;

  // Harita Koordinatları (Sabit)
  final Map<String, LatLng> _cityCoordinates = {
    'istanbul': const LatLng(41.0082, 28.9784),
    'ankara': const LatLng(39.9334, 32.8597),
    'izmir': const LatLng(38.4237, 27.1428),
    'antalya': const LatLng(36.8969, 30.7133),
    'bursa': const LatLng(40.1885, 29.0610),
    'adana': const LatLng(37.0000, 35.3213),
  };

  final Map<String, LatLng> _districtCoordinates = {
    'kadıköy': const LatLng(40.9819, 29.0254),
    'beşiktaş': const LatLng(41.0422, 29.0077),
    'çankaya': const LatLng(39.9208, 32.8541),
    'nilüfer': const LatLng(40.2156, 28.9373),
    'muratpaşa': const LatLng(36.8841, 30.7056),
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
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

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

  LatLng _addJitter(LatLng original) {
    final random = Random();
    double offsetLat = (random.nextDouble() - 0.5) * 0.005;
    double offsetLng = (random.nextDouble() - 0.5) * 0.005;
    return LatLng(original.latitude + offsetLat, original.longitude + offsetLng);
  }

  // --- ARAMA & LOKASYON FONKSİYONLARI ---
  void _updateLocationSuggestions(String query) {
    if (query.length < 2) {
      setState(() => _locationSuggestions = []);
      return;
    }
    List<String> matches = [];
    String lowerQuery = query.toLowerCase();
    TurkeyLocations.citiesWithDistricts.forEach((city, districts) {
      if (city.toLowerCase().contains(lowerQuery)) matches.add(city);
      for (var district in districts) {
        if (district.toLowerCase().contains(lowerQuery)) matches.add("$district, $city");
      }
    });
    setState(() => _locationSuggestions = matches.take(5).toList());
  }

  void _onLocationSelected(String selection) {
    if (selection.contains(',')) {
      var parts = selection.split(',');
      setState(() {
        _selectedSearchDistrict = parts[0].trim();
        _selectedSearchCity = parts[1].trim();
        _nameSearchQuery = "";
        _searchController.text = selection;
        _locationSuggestions = [];
      });
    } else {
      setState(() {
        _selectedSearchCity = selection.trim();
        _selectedSearchDistrict = null;
        _nameSearchQuery = "";
        _searchController.text = selection;
        _locationSuggestions = [];
      });
    }
  }

  void _performNameSearch() {
    setState(() {
      _selectedSearchCity = null;
      _selectedSearchDistrict = null;
      _locationSuggestions = [];
      _nameSearchQuery = _searchController.text.trim();
    });
  }

  void _clearSearch() {
    setState(() {
      _showSearch = false;
      _searchController.clear();
      _selectedSearchCity = null;
      _selectedSearchDistrict = null;
      _nameSearchQuery = "";
      _locationSuggestions = [];
    });
  }

  // --- YENİ FİLTRELEME BOTTOM SHEET ---
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(child: Text('Filtrele', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFEBEBEB)))),
                    Positioned(
                      right: 0,
                      child: TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedApplications.clear();
                            _selectedStyles.clear();
                          });
                        },
                        child: const Text('Sıfırla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterSection('Uygulamalar', AppConstants.applications, _selectedApplications, setModalState),
                      const SizedBox(height: 24),
                      _buildFilterSection('Stiller', AppConstants.styles, _selectedStyles, setModalState),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Uygula', style: TextStyle(color: Color(0xFFEBEBEB), fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options, List<String> selectedList, StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedList.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setModalState(() {
                  selected ? selectedList.add(option) : selectedList.remove(option);
                });
              },
              backgroundColor: const Color(0xFF161616),
              selectedColor: AppTheme.primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isFilterActive = _selectedApplications.isNotEmpty || _selectedStyles.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
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
                      errorWidget: (context, url, error) => const SizedBox(width: 50, child: Icon(Icons.error)),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_showMap ? Icons.list : Icons.map),
                        color: _showMap ? AppTheme.primaryColor : const Color(0xFF757575),
                        onPressed: () async {
                          if (!_showMap) await _requestUserLocation();
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
                        icon: Icon(Icons.search, color: _showSearch ? AppTheme.primaryColor : const Color(0xFF757575)),
                        onPressed: () => setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) _clearSearch();
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // --- ARAMA KUTUSU ---
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) => _performNameSearch(),
                      decoration: InputDecoration(
                        hintText: 'Stüdyo adı veya semt...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: GestureDetector(onTap: _performNameSearch, child: const Icon(Icons.search, color: Colors.grey)),
                        suffixIcon: IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: _clearSearch),
                        filled: true,
                        fillColor: const Color(0xFF212121),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) {
                        if (val.isEmpty) {
                          setState(() { _selectedSearchCity = null; _selectedSearchDistrict = null; _nameSearchQuery = ""; });
                        }
                        _updateLocationSuggestions(val);
                      },
                    ),
                    if (_locationSuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[800]!)),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _locationSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = _locationSuggestions[index];
                            return ListTile(
                              leading: const Icon(Icons.place, size: 18, color: Colors.grey),
                              title: Text(suggestion, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              onTap: () => _onLocationSelected(suggestion),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            
            if (!_showMap)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    // YENİ: Tam Genişlikte FİLTRELE Butonu
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showFilterBottomSheet,
                        icon: const Icon(Icons.tune, color: AppTheme.primaryColor),
                        label: Text(
                          isFilterActive 
                            ? 'Filtreler Aktif (${_selectedApplications.length + _selectedStyles.length})' 
                            : 'Filtrele',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: isFilterActive ? FontWeight.bold : FontWeight.normal
                          )
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // SIRALAMA BUTONLARI
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _sortOption = AppConstants.sortPopular),
                            icon: const Icon(Icons.local_fire_department, size: 18),
                            label: const Text('Popüler'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _sortOption == AppConstants.sortPopular ? AppTheme.primaryColor : const Color(0xFF323232),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                            icon: const Icon(Icons.near_me, size: 18),
                            label: const Text('Mesafe'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _sortOption == AppConstants.sortDistance ? AppTheme.primaryColor : const Color(0xFF323232),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildArtistList() {
    Query query = FirebaseFirestore.instance.collection(AppConstants.collectionUsers)
        .where('role', whereIn: [AppConstants.roleArtistApproved, AppConstants.roleArtistUnapproved])
        .where('isApproved', isEqualTo: true);

    if (_sortOption == AppConstants.sortPopular) {
      query = query.orderBy('totalLikes', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var docs = snapshot.data!.docs;
        List<UserModel> artists = docs.map((d) => UserModel.fromFirestore(d)).toList();

        // --- HİBRİT FİLTRELEME ---
        
        if (_selectedSearchCity != null) {
          artists = artists.where((artist) {
            bool cityMatch = artist.city != null && artist.city!.toLowerCase() == _selectedSearchCity!.toLowerCase();
            if (_selectedSearchDistrict != null) {
              bool districtMatch = artist.district != null && artist.district!.toLowerCase() == _selectedSearchDistrict!.toLowerCase();
              return cityMatch && districtMatch;
            }
            return cityMatch;
          }).toList();
        } 
        else if (_nameSearchQuery.isNotEmpty) {
           artists = artists.where((a) {
             final query = _nameSearchQuery.toLowerCase();
             final nameMatch = a.fullName.toLowerCase().contains(query);
             final studioMatch = (a.studioName ?? '').toLowerCase().contains(query);
             return nameMatch || studioMatch;
           }).toList();
        }

        if (_selectedApplications.isNotEmpty) {
          artists = artists.where((artist) {
            return artist.applications.any((artistApp) {
              return _selectedApplications.any((selected) => 
                selected.toLowerCase() == artistApp.toLowerCase()
              );
            });
          }).toList();
        }

        if (_selectedStyles.isNotEmpty) {
          artists = artists.where((artist) {
            return artist.applicationStyles.any((artistStyle) {
              return _selectedStyles.any((selected) => 
                selected.toLowerCase() == artistStyle.toLowerCase()
              );
            });
          }).toList();
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

        if (artists.isEmpty) return const Center(child: Text('Sonuç yok', style: TextStyle(color: Colors.grey)));

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
    if (artist.latitude != null && artist.longitude != null) return LatLng(artist.latitude!, artist.longitude!);
    else if (artist.district != null && _districtCoordinates.containsKey(artist.district!.toLowerCase())) return _districtCoordinates[artist.district!.toLowerCase()];
    else if (artist.city != null && _cityCoordinates.containsKey(artist.city!.toLowerCase())) return _cityCoordinates[artist.city!.toLowerCase()];
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF212121),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // --- GÜNCELLENDİ: KENDİ PROFİLİNE TIKLARSA GİTME ---
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId == artist.uid) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Bu sizin kendi profiliniz. Profil sekmesinden düzenleyebilirsiniz."),
                backgroundColor: AppTheme.primaryColor,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ArtistProfileScreen(userId: artist.uid)));
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      image: artist.coverImageUrl != null
                          ? DecorationImage(image: NetworkImage(artist.coverImageUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: artist.coverImageUrl == null ? Center(child: Icon(Icons.image, color: Colors.white.withOpacity(0.2), size: 50)) : null,
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Color(0xFF212121), shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey[700],
                      backgroundImage: artist.profileImageUrl != null ? NetworkImage(artist.profileImageUrl!) : null,
                      child: artist.profileImageUrl == null ? const Icon(Icons.person, size: 35, color: Colors.white) : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35), 
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(artist.username ?? artist.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                      ),
                      Row(
                        children: [
                          Icon(Icons.favorite, color: AppTheme.primaryColor, size: 14),
                          const SizedBox(width: 4),
                          Text(artist.totalLikes.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                          const SizedBox(width: 12),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection(AppConstants.collectionFollows).where('followingId', isEqualTo: artist.uid).snapshots(),
                            builder: (context, snapshot) {
                              final followerCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                              return Row(children: [const Icon(Icons.people, color: Colors.grey, size: 14), const SizedBox(width: 4), Text(followerCount.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70))]);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (artist.locationString.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [const Icon(Icons.location_on, size: 12, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text("${artist.locationString}$distanceText", style: TextStyle(fontSize: 12, color: Colors.grey[400]), overflow: TextOverflow.ellipsis))]),
                  ],
                  if (artist.applications.isNotEmpty || artist.applicationStyles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...artist.applications.take(3).map((app) => _buildTinyTag(app, Colors.blueGrey.withOpacity(0.3))),
                        ...artist.applicationStyles.take(4).map((style) => _buildTinyTag(style, AppTheme.primaryColor.withOpacity(0.15))),
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
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white.withOpacity(0.05))), child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)));
  }

  Widget _buildMapView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.collectionUsers).where('role', whereIn: [AppConstants.roleArtistApproved, AppConstants.roleArtistUnapproved]).where('isApproved', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final artists = snapshot.data!.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        final markers = <Marker>{};
        final currentUserId = FirebaseAuth.instance.currentUser?.uid; // Map için de ID al

        for (var artist in artists) {
          bool showArtist = true;
          // ... (filtreleme kodları aynı kaldı)
          if (_selectedSearchCity != null) {
             bool cityMatch = artist.city != null && artist.city!.toLowerCase() == _selectedSearchCity!.toLowerCase();
             if (!cityMatch) showArtist = false;
             if (showArtist && _selectedSearchDistrict != null) {
                bool districtMatch = artist.district != null && artist.district!.toLowerCase() == _selectedSearchDistrict!.toLowerCase();
                if (!districtMatch) showArtist = false;
             }
          } else if (_nameSearchQuery.isNotEmpty) {
             final query = _nameSearchQuery.toLowerCase();
             final nameMatch = artist.fullName.toLowerCase().contains(query);
             final studioMatch = (artist.studioName ?? '').toLowerCase().contains(query);
             if (!nameMatch && !studioMatch) showArtist = false;
          }
          if (showArtist && _selectedApplications.isNotEmpty) {
            if (!artist.applications.any((app) => _selectedApplications.any((sel) => sel.toLowerCase() == app.toLowerCase()))) showArtist = false;
          }
          if (showArtist && _selectedStyles.isNotEmpty) {
            if (!artist.applicationStyles.any((style) => _selectedStyles.any((sel) => sel.toLowerCase() == style.toLowerCase()))) showArtist = false;
          }
          if (!showArtist) continue;
          
          LatLng? position = _getArtistLatLng(artist);
          if (position != null) {
            position = _addJitter(position); 
            markers.add(Marker(
              markerId: MarkerId(artist.uid), 
              position: position, 
              infoWindow: InfoWindow(
                title: artist.username ?? artist.fullName, 
                snippet: artist.locationString, 
                onTap: () {
                  // --- GÜNCELLENDİ: HARİTADA KENDİNE TIKLARSA GİTME ---
                  if (currentUserId == artist.uid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Bu sizin kendi profiliniz."), backgroundColor: AppTheme.primaryColor),
                    );
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ArtistProfileScreen(userId: artist.uid)));
                  }
                }
              ), 
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet)
            ));
          }
        }
        return GoogleMap(initialCameraPosition: CameraPosition(target: _currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : const LatLng(41.0082, 28.9784), zoom: _currentPosition != null ? 12 : 10), markers: markers, myLocationEnabled: true, myLocationButtonEnabled: true, onMapCreated: (controller) { _mapController = controller; if (_currentPosition != null) { controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 13)); }});
      },
    );
  }
}
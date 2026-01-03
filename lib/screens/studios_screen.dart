import '../widgets/featured_artist_card.dart';
import '../app_localizations.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'dart:math';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/turkey_locations.dart';
import 'profile/artist_profile_screen.dart';
import '../theme/app_theme.dart';

class StudiosScreen extends StatefulWidget {
  const StudiosScreen({super.key});

  @override
  // DEĞİŞİKLİK 1: State sınıfını public yaptık (_ kaldırdık)
  State<StudiosScreen> createState() => StudiosScreenState();
}
  
// DEĞİŞİKLİK 2: Sınıf isminden _ işaretini kaldırdık
class StudiosScreenState extends State<StudiosScreen> {
  
  // DEĞİŞİKLİK 3: ScrollController Tanımladık
  final ScrollController _scrollController = ScrollController();

  UserModel? _selectedMapArtist;
  // --- FİLTRE VE ARAMA DEĞİŞKENLERİ ---
  final List<String> _selectedApplications = [];
  final List<String> _selectedStyles = [];
  
  String? _selectedSearchCity;      
  String? _selectedSearchDistrict;  
  String _nameSearchQuery = "";     

  String _sortOption = AppConstants.sortPopular; 
  bool _showMap = false;
  
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  Position? _currentPosition;

  // Header yüksekliği
  final double headerHeight = 165.0; 

  // Harita Koordinatları (Senin kodların aynen duruyor)
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

  late PageController _pageController; 
  int _prevPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.85); 
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _scrollController.dispose(); // DEĞİŞİKLİK 4: Controller'ı dispose ettik
    super.dispose();
  }
  
  // --- DEĞİŞİKLİK 5: YUKARI ÇIKMA FONKSİYONU (MainScreen Çağıracak) ---
  void scrollToTop() {
    // Eğer haritadaysa listeye dön (Opsiyonel, istersen kaldırabilirsin)
    if (_showMap) {
      setState(() {
        _showMap = false;
      });
    }
    
    // Listeyi en başa animasyonlu sar
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
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
      setState(() { _currentPosition = position; });
      return true;
    } catch (e) { return false; }
  }

  // ... (Zoom ve Jitter fonksiyonların aynen kalıyor) ...
  LatLng _addJitter(LatLng original) {
    final random = Random();
    double offsetLat = (random.nextDouble() - 0.5) * 0.005;
    double offsetLng = (random.nextDouble() - 0.5) * 0.005;
    return LatLng(original.latitude + offsetLat, original.longitude + offsetLng);
  }

  Future<void> _zoomToFitAll(List<UserModel> artists) async {
      // (Senin mevcut kodun burası)
      if (_mapController == null || _currentPosition == null) return;
      var localArtists = artists.where((artist) {
        if (artist.latitude == null || artist.longitude == null) return false;
        double latDiff = (artist.latitude! - _currentPosition!.latitude).abs();
        double lngDiff = (artist.longitude! - _currentPosition!.longitude).abs();
        return latDiff < 0.5 && lngDiff < 0.5; 
      }).toList();

      if (localArtists.isEmpty) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          13 
        ));
        return;
      }

      double minLat = _currentPosition!.latitude;
      double maxLat = _currentPosition!.latitude;
      double minLng = _currentPosition!.longitude;
      double maxLng = _currentPosition!.longitude;

      for (var artist in localArtists) {
        if (artist.latitude != null && artist.longitude != null) {
          if (artist.latitude! < minLat) minLat = artist.latitude!;
          if (artist.latitude! > maxLat) maxLat = artist.latitude!;
          if (artist.longitude! < minLng) minLng = artist.longitude!;
          if (artist.longitude! > maxLng) maxLng = artist.longitude!;
        }
      }

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  // --- ANA WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    bool isFilterActive = _selectedApplications.isNotEmpty || _selectedStyles.isNotEmpty || _nameSearchQuery.isNotEmpty || _selectedSearchCity != null;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.atmosphericBackgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        
        body: Stack(
          children: [
            
            // DURUM A: HARİTA GÖRÜNÜMÜ
            if (_showMap)
              Positioned.fill(
                child: _buildMapView(), // Senin mevcut fonksiyonun
              )
            
            // DURUM B: LİSTE GÖRÜNÜMÜ
            else
              Positioned.fill(
                child: SingleChildScrollView(
                  // DEĞİŞİKLİK 6: Controller'ı buraya bağladık!
                  controller: _scrollController, 
                  
                  // Liste için üstten header kadar boşluk bırakıyoruz
                  padding: EdgeInsets.only(top: headerHeight + MediaQuery.of(context).padding.top), 
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 0.0),
                        child: cs.CarouselSlider(
                          options: cs.CarouselOptions(
                            height: 40,
                            viewportFraction: 1.0,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 4),
                            enlargeCenterPage: false,
                          ),
                          items: [
                            _buildBannerItem(AppLocalizations.of(context)!.translate('new_year_campaign'), Icons.campaign, Colors.blueAccent),
                            _buildBannerItem(AppLocalizations.of(context)!.translate('discover_new_studios'), Icons.explore, Colors.deepPurpleAccent),
                            _buildBannerItem(AppLocalizations.of(context)!.translate('free_consultation_opportunity'), Icons.event_available, Colors.teal),
                          ],
                        ),
                      ),
                      
                      // Liste Elemanları (Senin mevcut fonksiyonun)
                      _buildArtistList(shrinkWrap: true),
                    ],
                  ),
                ),
              ),

            // KATMAN 2: HEADER (Aynen Kalıyor)
            Positioned(
              top: 0, left: 0, right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor.withOpacity(0.9), 
                      border: Border(
                        bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8, 
                        bottom: 10, left: 12, right: 12
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. SATIR: LOGO - HARİTA İKONU
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                height: 40,
                                child: CachedNetworkImage(
                                  imageUrl: AppConstants.logoUrl,
                                  height: 40,
                                  fit: BoxFit.contain,
                                  errorWidget: (context, url, error) => const SizedBox(width: 35, child: Icon(Icons.error)),
                                ),
                              ),
                              IconButton(
                                icon: Icon(_showMap ? Icons.list : Icons.map),
                                color: _showMap ? AppTheme.primaryColor : Colors.grey,
                                onPressed: () async {
                                  if (!_showMap) await _requestUserLocation();
                                  setState(() {
                                    _showMap = !_showMap;
                                  });
                                  if (_showMap && _currentPosition != null && _mapController != null) {
                                    _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
                                      LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 13));
                                  }
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),

                          // 2. SATIR: FİLTRELEME VE 3. SATIR (Aynen Kalıyor)
                          // ... Kodun geri kalanı senin attığınla aynı ...
                          if (!_showMap)
                          SizedBox(
                            width: double.infinity,
                            height: 36, 
                            child: OutlinedButton.icon(
                              onPressed: () => _showFilterBottomSheet(context),
                              icon: const Icon(Icons.tune, size: 16, color: AppTheme.primaryColor),
                              label: Text(
                                isFilterActive
                                  ? AppLocalizations.of(context)!.translate('filters_active')
                                  : AppLocalizations.of(context)!.translate('search_and_filter'),
                                style: const TextStyle(color: AppTheme.primaryColor)
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppTheme.backgroundColor.withOpacity(0.0),
                                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.8)),
                                padding: const EdgeInsets.symmetric(horizontal: 4), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),

                          if (!_showMap)
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 35,
                                  child: _sortOption == AppConstants.sortPopular
                                    ? ElevatedButton.icon(
                                        onPressed: () => setState(() => _sortOption = AppConstants.sortPopular),
                                        icon: const Icon(Icons.local_fire_department, size: 16),
                                        label: Text(AppLocalizations.of(context)!.translate('popular'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryColor.withOpacity(0.8),
                                          foregroundColor: AppTheme.textColor,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 4), 
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                                        ),
                                      )
                                    : OutlinedButton.icon(
                                        onPressed: () => setState(() => _sortOption = AppConstants.sortPopular),
                                        icon: const Icon(Icons.local_fire_department, size: 16, color: AppTheme.primaryColor),
                                        label: Text(AppLocalizations.of(context)!.translate('popular'), style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor)),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: AppTheme.backgroundColor.withOpacity(0.3),
                                          side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 35,
                                  child: _sortOption == AppConstants.sortDistance
                                    ? ElevatedButton.icon(
                                        onPressed: () async {
                                          if (_sortOption != AppConstants.sortDistance) {
                                             bool hasLocation = await _requestUserLocation();
                                             if (hasLocation) {
                                               setState(() => _sortOption = AppConstants.sortDistance);
                                             }
                                          }
                                        },
                                        icon: const Icon(Icons.near_me, size: 16),
                                        label: Text(AppLocalizations.of(context)!.translate('distance'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryColor.withOpacity(0.8),
                                          foregroundColor: AppTheme.textColor,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                                        ),
                                      )
                                    : OutlinedButton.icon(
                                        onPressed: () async {
                                          if (_sortOption != AppConstants.sortDistance) {
                                             bool hasLocation = await _requestUserLocation();
                                             if (hasLocation) {
                                               setState(() => _sortOption = AppConstants.sortDistance);
                                             }
                                          }
                                        },
                                        icon: const Icon(Icons.near_me, size: 16, color: AppTheme.primaryColor),
                                        label: Text(AppLocalizations.of(context)!.translate('distance'), style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor)),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: AppTheme.backgroundColor.withOpacity(0.3),
                                          side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // --- MODAL AÇMA FONKSİYONU ---
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            
            // --- STİL HESAPLAMA MANTIĞI ---
            Set<String> dynamicStylesSet = {};
            if (_selectedApplications.isNotEmpty) {
              for (var app in _selectedApplications) {
                if (AppConstants.applicationStylesMap.containsKey(app)) {
                  dynamicStylesSet.addAll(AppConstants.applicationStylesMap[app]!);
                }
              }
            }
            List<String> relevantStyles = dynamicStylesSet.toList()..sort();

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor.withOpacity(0.8),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                      left: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                      right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                      bottom: BorderSide.none, // Alt kenarı tamamen devre dışı bıraktık
                    ),
                  ),
                  child: Column(
                    children: [
                      // Gri Çubuk
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 10),
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                           // SIFIRLA BUTONU (Sağ Üst)

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, // İki uca yaslar
                            children: [
                              // SOL TARAFTA BAŞLIK
                              const Text(
                                " ",
                                style: TextStyle(
                                  color: AppTheme.textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold
                                ),
                              ),

                              // SAĞ TARAFTA SIFIRLA BUTONU
                              TextButton(
                                onPressed: () {
                                  setModalState(() {
                                    _selectedApplications.clear();
                                    _selectedStyles.clear();
                                    _selectedSearchDistrict = null;
                                    _selectedSearchCity = null;
                                    _nameSearchQuery = "";
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  overlayColor: Colors.transparent,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.translate('reset'),
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // --- İÇERİK ---
                      Expanded(
                        child: Stack(
                          children: [
                            SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  
                                  // 1. ARAMA: TEK ARAMA ÇUBUĞU (EN BAŞTA)
                                  _UnifiedSearchWidget(
                                    initialValue: _nameSearchQuery.isNotEmpty 
                                        ? _nameSearchQuery 
                                        : (_selectedSearchCity != null 
                                            ? "${_selectedSearchDistrict ?? ''} ${_selectedSearchCity}".trim() 
                                            : ""),
                                    onSearchChanged: (query) {
                                      setModalState(() {
                                        _nameSearchQuery = query;
                                        _selectedSearchCity = null;
                                        _selectedSearchDistrict = null;
                                      });
                                    },
                                    onLocationSelected: (district, city) {
                                      setModalState(() {
                                        _selectedSearchCity = city;
                                        _selectedSearchDistrict = district;
                                        _nameSearchQuery = ""; 
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 24),

                                  // 2. UYGULAMA TÜRÜ
                                  _buildSectionTitle(AppLocalizations.of(context)!.translate('application_type')),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Wrap(
                                      spacing: 8, runSpacing: 8, alignment: WrapAlignment.start,
                                      children: AppConstants.applications.map((app) {
                                        final isSelected = _selectedApplications.contains(app);
                                        return Theme(
                                          data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                                          child: FilterChip(
                                            label: Text(AppLocalizations.of(context)!.translate(app)),
                                            selected: isSelected,
                                            showCheckmark: false,
                                            // -- Outlined Tasarım Ayarları --
                                            selectedColor: AppTheme.primaryColor.withOpacity(0.5),
                                            backgroundColor: Colors.transparent, // Seçili değilken şeffaf
                                            labelStyle: TextStyle(
                                              color: isSelected ? AppTheme.textColor : Colors.grey[400], 
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8), 
                                              side: BorderSide(
                                                color: isSelected ? AppTheme.primaryColor.withOpacity(0.8) : Colors.grey[700]!, // Çerçeve rengi
                                                width: 1
                                              )
                                            ),
                                            // -------------------------------
                                            onSelected: (selected) {
                                              setModalState(() {
                                                selected ? _selectedApplications.add(app) : _selectedApplications.remove(app);
                                              });
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // 3. STİLLER
                                  if (_selectedApplications.isNotEmpty && relevantStyles.isNotEmpty) ...[
                                    _buildSectionTitle(AppLocalizations.of(context)!.translate('styles')),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Wrap(
                                        spacing: 8, runSpacing: 8, alignment: WrapAlignment.start,
                                        children: relevantStyles.map((style) {
                                          final isSelected = _selectedStyles.contains(style);
                                          return Theme(
                                            data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                                            child: FilterChip(
                                              label: Text(AppLocalizations.of(context)!.translate(style)),
                                              selected: isSelected,
                                              showCheckmark: false,
                                              selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                                              backgroundColor: AppTheme.cardColor.withOpacity(0.6),
                                              labelStyle: TextStyle(color: isSelected ? AppTheme.textColor : Colors.grey[400], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.grey[800]!)),
                                              onSelected: (selected) {
                                                setModalState(() {
                                                  selected ? _selectedStyles.add(style) : _selectedStyles.remove(style);
                                                });
                                              },
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ] else if (_selectedApplications.isEmpty) ...[
                                    _buildSectionTitle(AppLocalizations.of(context)!.translate('styles')),
                                    Text(AppLocalizations.of(context)!.translate('select_application_for_styles'), style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                                    const SizedBox(height: 24),
                                  ],

                                  const SizedBox(height: 80), // Alttaki buton için boşluk
                                ],
                              ),
                            ),
                            
                            
                          ],
                        ),
                      ),

                      // Uygula Butonu
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                        decoration: BoxDecoration(
                          
                          color: Colors.transparent,
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {}); 
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            // BURASI KRİTİK: Genişliği sonsuz, yüksekliği 50 yapıyoruz
                            minimumSize: const Size(double.infinity, 50), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.translate('show_results'),
                            style: const TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }



  // --- LİSTE OLUŞTURMA (GÜNCELLENMİŞ VIP VERSİYON) ---
  Widget _buildArtistList({bool shrinkWrap = false}) {
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
        if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()));
        
        var docs = snapshot.data!.docs;
        List<UserModel> artists = docs.map((d) => UserModel.fromFirestore(d)).toList();

        // --- 1. FİLTRELEME MANTIKLARI (Aynı Kalıyor) ---
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
        
        if (_nameSearchQuery.isNotEmpty) {
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
              return _selectedApplications.any((selected) => selected.toLowerCase() == artistApp.toLowerCase());
            });
          }).toList();
        }

        if (_selectedStyles.isNotEmpty) {
          artists = artists.where((artist) {
            return artist.applicationStyles.any((artistStyle) {
              return _selectedStyles.any((selected) => selected.toLowerCase() == artistStyle.toLowerCase());
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

        // Eğer hiçbir artist yoksa ve VIP de yoksa diye kontrolü aşağıya alacağız
        
        return MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: ListView.builder(
            shrinkWrap: shrinkWrap, 
            physics: const NeverScrollableScrollPhysics(), 
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
            // +1 ekliyoruz çünkü listenin 0. elemanı bizim VIP alanımız olacak
            itemCount: artists.length + 1,
            itemBuilder: (context, index) {
              
              // --- 2. EN TEPEYE VIP (ÖNE ÇIKANLAR) EKLEME ---
              if (index == 0) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(AppConstants.collectionUsers)
                      .where('isFeatured', isEqualTo: true)
                      // ÖNEMLİ: Bazı durumlarda Firestore Timestamp hassasiyeti sorun çıkarabilir.
                      // Query'yi burada yapıp, tarihi aşağıda manuel kontrol etmek daha güvenlidir:
                      .snapshots(),
                  builder: (context, vipSnapshot) {
                    if (!vipSnapshot.hasData || vipSnapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink(); 
                    }

                    // Gelen verileri burada tarih filtresinden geçiriyoruz (Client-side filtering)
                    final now = DateTime.now();
                    final featuredDocs = vipSnapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['featuredEndDate'] == null) return false;
                      
                      // Firebase'den gelen Timestamp'i DateTime'a çevirip kıyaslıyoruz
                      final expiry = (data['featuredEndDate'] as Timestamp).toDate();
                      return expiry.isAfter(now);
                    }).toList();

                    if (featuredDocs.isEmpty) return const SizedBox.shrink();

                    return Column(
                      children: featuredDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        
                        // Şehir filtresi varsa burada uygula
                        if (_selectedSearchCity != null) {
                          if (data['city']?.toString().toLowerCase() != _selectedSearchCity!.toLowerCase()) {
                            return const SizedBox.shrink();
                          }
                        }

                        return FeaturedArtistCard(
                          title: data['studioName'] ?? data['firstName'] ?? "Sanatçı",
                          subtitle: "${data['district'] ?? ''}, ${data['city'] ?? ''}",
                          imageUrl: data['profileImageUrl'],
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => ArtistProfileScreen(userId: doc.id, isOwnProfile: false),
                            ));
                          },
                        );
                      }).toList(),
                    );
                  },
                );
              }

              // --- 3. NORMAL LİSTE (Index kaydırarak devam eder) ---
              // Eğer normal liste boşsa "Sonuç yok" uyarısı göster
              if (artists.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(AppLocalizations.of(context)!.translate('no_results'), style: const TextStyle(color: Colors.grey))
                  )
                );
              }

              // index-1 yapıyoruz çünkü 0. index'i VIP'ye ayırdık
              return _buildArtistCard(artists[index - 1]);
            },
          ),
        );
      },
    );
  }

  // --- DİĞER YARDIMCI METODLAR ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  LatLng? _getArtistLatLng(UserModel artist) {
    if (artist.latitude != null && artist.longitude != null) return LatLng(artist.latitude!, artist.longitude!);
    else if (artist.district != null && _districtCoordinates.containsKey(artist.district!.toLowerCase())) return _districtCoordinates[artist.district!.toLowerCase()];
    else if (artist.city != null && _cityCoordinates.containsKey(artist.city!.toLowerCase())) return _cityCoordinates[artist.city!.toLowerCase()];
    return null;
  }

  Widget _buildArtistCard(UserModel artist) {
  String? imageUrl;
  if (artist.coverImageUrl != null && artist.coverImageUrl!.isNotEmpty) {
    imageUrl = artist.coverImageUrl;
  } else if (artist.studioImageUrls.isNotEmpty) {
    imageUrl = artist.studioImageUrls.first;
  }
  
  String distanceText = "";
  if (_currentPosition != null) {
    LatLng? pos = _getArtistLatLng(artist);
    if (pos != null) {
      double dist = Geolocator.distanceBetween(
          _currentPosition!.latitude, _currentPosition!.longitude, pos.latitude, pos.longitude);
      distanceText = " • ${(dist / 1000).toStringAsFixed(1)} km";
    }
  }

  return Card(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    color: AppTheme.cardColor,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      splashColor: AppTheme.cardLightColor.withOpacity(0.3),
      highlightColor: AppTheme.cardLightColor.withOpacity(0.1),
      onTap: () {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId == artist.uid) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!
                      .translate('this_is_your_own_profile') ??
                  'Bu senin kendi profilin'),
              backgroundColor: AppTheme.primaryColor));
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ArtistProfileScreen(userId: artist.uid)));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- KAPAK FOTOĞRAFI VE AVATAR ALANI ---
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
                    image: imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(imageUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: imageUrl == null
                      ? Center(
                          child: Icon(Icons.image,
                              color: AppTheme.textColor.withOpacity(0.2),
                              size: 50))
                      : null,
                ),
              ),
              Positioned(
                bottom: -30,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: AppTheme.cardColor, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey[700],
                    backgroundImage: artist.profileImageUrl != null
                        ? NetworkImage(artist.profileImageUrl!)
                        : null,
                    child: artist.profileImageUrl == null
                        ? const Icon(Icons.person,
                            size: 35, color: AppTheme.textColor)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // --- BİLGİ ALANI ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İSİM + TİK (SOLDA) ---- BEĞENİ/TAKİPÇİ (SAĞDA)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center, // Hizalama ortalı olsun
                  children: [
                    // SOL TARAFTAKİ GRUP (İsim + Mavi Tik)
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible( // Uzun isimlerde taşmayı önler
                            child: Text(
                              artist.username ?? artist.fullName,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          // Mavi Tik İkonu (İsmin hemen yanında)
                          if (artist.isApproved) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // SAĞ TARAFTAKİ GRUP (Beğeni ve Takipçi)
                    const SizedBox(width: 8), // İsim çok uzunsa istatistiklere yapışmasın
                    Row(
                      children: [
                        Icon(Icons.favorite,
                            color: AppTheme.primaryLightColor, size: 14),
                        const SizedBox(width: 4),
                        Text(artist.totalLikes.toString(),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor)),
                        const SizedBox(width: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection(AppConstants.collectionFollows)
                              .where('followingId', isEqualTo: artist.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final followerCount =
                                snapshot.hasData ? snapshot.data!.docs.length : 0;
                            return Row(children: [
                              const Icon(Icons.people,
                                  color: AppTheme.primaryLightColor, size: 14),
                              const SizedBox(width: 4),
                              Text(followerCount.toString(),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textColor))
                            ]);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                
                // --- LOKASYON ---
                if (artist.locationString.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on,
                        size: 12, color: AppTheme.textGreyColor),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text("${artist.locationString}$distanceText",
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textGreyColor),
                            overflow: TextOverflow.ellipsis))
                  ]),
                ],

                // --- ETİKETLER ---
                if (artist.applications.isNotEmpty ||
                    artist.applicationStyles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...artist.applications.take(3).map((app) => _buildTinyTag(
                          AppLocalizations.of(context)!.translate(app),
                          AppTheme.primaryColor.withOpacity(0.3))),
                      ...artist.applicationStyles.take(4).map((style) =>
                          _buildTinyTag(
                              AppLocalizations.of(context)!.translate(style),
                              AppTheme.primaryLightColor.withOpacity(0.15))),
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
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.primaryColor.withOpacity(0))), child: Text(text, style: const TextStyle(fontSize: 10, color: AppTheme.textColor, fontWeight: FontWeight.w500)));
  }

  Widget _buildBannerItem(String text, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppTheme.textColor, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const Icon(Icons.arrow_forward_ios, color: AppTheme.textColor, size: 12),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.collectionUsers)
          .where('role', whereIn: [AppConstants.roleArtistApproved, AppConstants.roleArtistUnapproved])
          .where('isApproved', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        
        // Veriyi modele çevir
        var allArtists = snapshot.data!.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        List<UserModel> filteredArtists = [];

        // --- FİLTRELEME MANTIĞI ---
        for (var artist in allArtists) {
          bool showArtist = true;
          
          // 1. Koordinat Kontrolü (Harita için zorunlu)
          if (artist.latitude == null || artist.longitude == null) {
            showArtist = false;
          }

          // 2. Şehir Filtresi
          if (showArtist && _selectedSearchCity != null) {
             bool cityMatch = artist.city != null && artist.city!.toLowerCase() == _selectedSearchCity!.toLowerCase();
             if (!cityMatch) showArtist = false;
          }

          // 3. İlçe Filtresi
          if (showArtist && _selectedSearchDistrict != null) {
             bool districtMatch = artist.district != null && artist.district!.toLowerCase() == _selectedSearchDistrict!.toLowerCase();
             if (!districtMatch) showArtist = false;
          }

          // 4. İsim Arama (Ad, Kullanıcı Adı veya Stüdyo Adı)
          if (showArtist && _nameSearchQuery.isNotEmpty) {
            final query = _nameSearchQuery.toLowerCase();
            final name = artist.fullName.toLowerCase();
            final username = artist.username?.toLowerCase() ?? '';
            final studio = artist.studioName?.toLowerCase() ?? '';
            
            if (!name.contains(query) && !username.contains(query) && !studio.contains(query)) {
              showArtist = false;
            }
          }

          // 5. Uygulama (Application) Filtresi
          if (showArtist && _selectedApplications.isNotEmpty) {
            final artistApps = artist.applications.map((e) => e.toLowerCase()).toList();
            bool hasMatch = _selectedApplications.any((selected) => artistApps.contains(selected.toLowerCase()));
            if (!hasMatch) showArtist = false;
          }

          // 6. Stil (Style) Filtresi (DÜZELTİLDİ: styles -> applicationStyles)
          if (showArtist && _selectedStyles.isNotEmpty) {
             // Kullanıcının belirttiği alan adı düzeltildi
             final artistStyles = artist.applicationStyles.map((e) => e.toLowerCase()).toList();
             bool hasMatch = _selectedStyles.any((selected) => artistStyles.contains(selected.toLowerCase()));
             if (!hasMatch) showArtist = false;
          }
          
          // Eğer tüm şartları sağladıysa listeye ekle
          if (showArtist) filteredArtists.add(artist);
        }
        // --------------------------------

        // MARKERLARI OLUŞTUR (LOOP İLE)
        final markers = <Marker>{};
        
        for (int i = 0; i < filteredArtists.length; i++) {
          final artist = filteredArtists[i];
          // Koordinatları al (Jitter ekleyerek üst üste binmeyi engellemek iyi olur)
          LatLng position = _addJitter(LatLng(artist.latitude!, artist.longitude!));
          
          markers.add(Marker(
            markerId: MarkerId(artist.uid), 
            position: position,
            infoWindow: InfoWindow(
              title: artist.studioName ?? artist.fullName,
              snippet: artist.applications.isNotEmpty ? artist.applications.first : null,
            ), 
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            
            // --- PİNE TIKLAYINCA LİSTEYİ KAYDIR ---
            onTap: () {
              setState(() {
                _selectedMapArtist = artist;
              });
              
              if (_pageController.hasClients) {
                _pageController.animateToPage(
                  i, 
                  duration: const Duration(milliseconds: 300), 
                  curve: Curves.easeInOut
                );
              }
            },
          ));
        }

        return Stack(
          children: [
            // 1. HARİTA (ARKADA)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null 
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) 
                  : const LatLng(39.9334, 32.8597),
                zoom: 10
              ),
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false, 
              zoomControlsEnabled: false,
              padding: EdgeInsets.only(top: headerHeight, bottom: 160),
              
              onMapCreated: (controller) { 
                _mapController = controller;
                
                // Harita yüklenince herkesi ekrana sığdır
                if (filteredArtists.isNotEmpty) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _zoomToFitAll(filteredArtists);
                  });
                }
              },
            ),

            // 2. LİSTE (ALTTA - CAROUSEL)
            if (filteredArtists.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20, 
                height: 140, 
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: filteredArtists.length,
                  
                  // --- KART KAYDIRILINCA HARİTAYI ORAYA GÖTÜR ---
                  onPageChanged: (index) {
                    final artist = filteredArtists[index];
                    
                    setState(() {
                      _selectedMapArtist = artist;
                    });

                    if (_mapController != null && artist.latitude != null && artist.longitude != null) {
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(LatLng(artist.latitude!, artist.longitude!), 15)
                      );
                      _mapController!.showMarkerInfoWindow(MarkerId(artist.uid));
                    }
                  },
                  
                  itemBuilder: (context, index) {
                    return _buildMapUserCard(context, filteredArtists[index]);
                  },
                ),
              ),

             // Eğer filtre sonucu hiç artist yoksa uyarı göster
             if (filteredArtists.isEmpty)
               Positioned(
                 bottom: 100,
                 left: 20,
                 right: 20,
                 child: Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: Colors.black87,
                     borderRadius: BorderRadius.circular(12)
                   ),
                   child: Text(
                     AppLocalizations.of(context)!.translate('no_studios_found_criteria'),
                     textAlign: TextAlign.center,
                     style: const TextStyle(color: Colors.white),
                   ),
                 ),
               )
          ],
        );
      },
    );
  }
}

  // --- HARİTA İÇİN KOMPAKT KART TASARIMI ---
  Widget _buildMapUserCard(BuildContext context, UserModel artist) {
    // --- YENİ RESİM SEÇİM MANTIĞI ---
    // 1. Öncelik: Profil Fotoğrafı
    // 2. Öncelik: Kapak Fotoğrafı
    // 3. Hiçbiri yoksa: null
    String? displayImageUrl;
    
    if (artist.profileImageUrl != null && artist.profileImageUrl!.isNotEmpty) {
      displayImageUrl = artist.profileImageUrl;
    } else if (artist.coverImageUrl != null && artist.coverImageUrl!.isNotEmpty) {
      displayImageUrl = artist.coverImageUrl;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          
          if (currentUserId == artist.uid) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                // Burası zaten doğruydu
                content: Text(AppLocalizations.of(context)!.translate('this_is_your_own_profile')),
                backgroundColor: AppTheme.primaryColor,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => ArtistProfileScreen(userId: artist.uid))
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // 1. RESİM ALANI (SOL)
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 120,
                height: double.infinity,
                child: displayImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: displayImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: AppTheme.backgroundColor),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.backgroundColor,
                          child: const Icon(Icons.person, color: Colors.white24),
                        ),
                      )
                    : Container(
                        color: AppTheme.backgroundColor,
                        child: const Icon(Icons.person, color: Colors.white24),
                      ),
              ),
            ),
            
            // 2. BİLGİLER (SAĞ)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // İsim ve Mavi Tik
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            artist.username ?? artist.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (artist.isApproved) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Lokasyon
                    if (artist.locationString.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              artist.locationString,
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Beğeni ve Etiketler
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          "${artist.totalLikes}",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                        ),
                        const SizedBox(width: 12),
                        
                        // --- DÜZELTİLEN KISIM BURASI ---
                        if (artist.applications.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 0.5)
                            ),
                            child: Text(
                              // DİKKAT: Doğrudan yazdırmak yerine translate içine aldık
                              AppLocalizations.of(context)!.translate(artist.applications.first),
                              style: const TextStyle(fontSize: 10, color: AppTheme.textColor),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// --- MODAL İÇİNDEKİ ARAMA WIDGET'I (EN ALTA EKLEYİN) ---
class _DistrictSearchWidgetInModal extends StatefulWidget {
  final String? selectedDistrict;
  final String? selectedCity;
  final Function(String?, String?) onLocationSelected;

  const _DistrictSearchWidgetInModal({
    required this.selectedDistrict,
    required this.selectedCity,
    required this.onLocationSelected,
  });

  @override
  State<_DistrictSearchWidgetInModal> createState() => _DistrictSearchWidgetInModalState();
}

class _DistrictSearchWidgetInModalState extends State<_DistrictSearchWidgetInModal> {
  late TextEditingController _controller;
  List<Map<String, String>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.selectedDistrict != null 
        ? '${widget.selectedDistrict}, ${widget.selectedCity}'
        : (widget.selectedCity ?? '')
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateSuggestions(String query) {
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    List<Map<String, String>> matches = [];
    String lower = query.toLowerCase();
    TurkeyLocations.citiesWithDistricts.forEach((city, districts) {
      if (city.toLowerCase().contains(lower)) {
        matches.add({'district': '', 'city': city});
      }
      for (var district in districts) {
        if (district.toLowerCase().contains(lower)) {
          matches.add({'district': district, 'city': city});
        }
      }
    });
    setState(() => _suggestions = matches.take(5).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          style: const TextStyle(color: AppTheme.textColor),
          decoration: InputDecoration(
            hintText: 'Şehir veya semt ara...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
            filled: true,
            fillColor: AppTheme.cardColor.withOpacity(0.6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            suffixIcon: widget.selectedCity != null ? IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                _controller.clear();
                widget.onLocationSelected(null, null);
                setState(() => _suggestions = []);
              },
            ) : null,
          ),
          onChanged: _updateSuggestions,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[800]!)),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                final text = item['district']!.isEmpty ? item['city']! : '${item['district']}, ${item['city']}';
                return ListTile(
                  title: Text(text, style: const TextStyle(color: AppTheme.textColor)),
                  onTap: () {
                    _controller.text = text;
                    widget.onLocationSelected(
                      item['district']!.isEmpty ? null : item['district'], 
                      item['city']
                    );
                    setState(() => _suggestions = []);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
// --- BU SINIFI DOSYANIN EN ALTINA, HER ŞEYİN DIŞINA YAPIŞTIRIN ---

class _UnifiedSearchWidget extends StatefulWidget {
  final String initialValue;
  final Function(String) onSearchChanged; // Düz yazı yazınca çalışır
  final Function(String?, String?) onLocationSelected; // Konum seçince çalışır

  const _UnifiedSearchWidget({
    required this.initialValue,
    required this.onSearchChanged,
    required this.onLocationSelected,
  });

  @override
  State<_UnifiedSearchWidget> createState() => _UnifiedSearchWidgetState();
}

class _UnifiedSearchWidgetState extends State<_UnifiedSearchWidget> {
  late TextEditingController _controller;
  List<Map<String, String>> _locationSuggestions = [];
  bool _isLocationSelected = false; 

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    // Eğer başlangıçta "İstanbul" gibi bir şey yazıyorsa bu bir konum seçimidir diye varsayalım
    if (widget.initialValue.isNotEmpty) {
      _isLocationSelected = widget.initialValue.contains(',') || 
                            TurkeyLocations.citiesWithDistricts.containsKey(widget.initialValue) ||
                             TurkeyLocations.citiesWithDistricts.values.any((list) => list.contains(widget.initialValue));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String query) {
    // 1. Ana ekrana "Bu bir isim aramasıdır" diye haber ver
    widget.onSearchChanged(query);
    
    setState(() {
      _isLocationSelected = false; // Kullanıcı elle değiştirdiği an konum seçimi bozulur
    });

    // 2. Konum önerilerini hesapla
    if (query.length < 2) {
      setState(() => _locationSuggestions = []);
      return;
    }

    List<Map<String, String>> matches = [];
    String lower = query.toLowerCase();

    TurkeyLocations.citiesWithDistricts.forEach((city, districts) {
      // Şehir eşleşmesi
      if (city.toLowerCase().contains(lower)) {
        matches.add({'district': '', 'city': city});
      }
      // İlçe eşleşmesi
      for (var district in districts) {
        if (district.toLowerCase().contains(lower)) {
          matches.add({'district': district, 'city': city});
        }
      }
    });

    setState(() => _locationSuggestions = matches.take(5).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          style: const TextStyle(color: AppTheme.textColor),
          decoration: InputDecoration(
            hintText: 'Stüdyo adı, Şehir veya Semt...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            
            // Seçili duruma göre ikon değişir
            prefixIcon: Icon(
              _isLocationSelected ? Icons.location_on : Icons.search, 
              color: _isLocationSelected ? AppTheme.primaryColor : Colors.grey
            ),
            
            filled: true,
            fillColor: AppTheme.cardColor.withOpacity(0.6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            
            // Temizleme butonu
            suffixIcon: _controller.text.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearchChanged(""); 
                    widget.onLocationSelected(null, null);
                    setState(() {
                      _locationSuggestions = [];
                      _isLocationSelected = false;
                    });
                  },
                ) 
              : null,
          ),
          onChanged: _onTextChanged,
        ),

        // --- KONUM ÖNERİ LİSTESİ ---
        if (_locationSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C), // Koyu arka plan
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[800]!),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _locationSuggestions.length,
              itemBuilder: (context, index) {
                final item = _locationSuggestions[index];
                final isCityOnly = item['district']!.isEmpty;
                final displayText = isCityOnly 
                    ? item['city']! 
                    : '${item['district']}, ${item['city']}';

                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                  title: Text(displayText, style: const TextStyle(color: AppTheme.textColor)),
                  subtitle: Text(
                    isCityOnly ? "Şehir" : "Bölge", 
                    style: TextStyle(color: AppTheme.primaryColor.withOpacity(0.7), fontSize: 10)
                  ),
                  onTap: () {
                    // Seçimi metin kutusuna yaz
                    _controller.text = displayText;
                    // Listeyi kapat ve ikon durumunu güncelle
                    setState(() {
                      _locationSuggestions = [];
                      _isLocationSelected = true;
                    });
                    // Ana ekrana "Bu bir konum seçimidir" diye haber ver
                    widget.onLocationSelected(
                      isCityOnly ? null : item['district'], 
                      item['city']
                    );
                    // Klavyeyi kapat
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

// --- GOOGLE MAPS DARK THEME JSON ---
const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#181818"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#1b1b1b"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#2c2c2c"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#8a8a8a"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#373737"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#3c3c3c"
      }
    ]
  },
  {
    "featureType": "road.highway.controlled_access",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#4e4e4e"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#000000"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#3d3d3d"
      }
    ]
  }
]
''';
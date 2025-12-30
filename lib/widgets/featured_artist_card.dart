  //ÖNE ÇIKAN ARTİST KARTLARI//
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart'; // Tema dosyanın yolunu kontrol et

  class FeaturedArtistCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onTap;

  const FeaturedArtistCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade700.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade900.withOpacity(0.1), 
            blurRadius: 15, 
            spreadRadius: 2
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 220, // Liste içinde çok kaba durmaması için biraz kısalttık
                  width: double.infinity,
                  child: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!, 
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.black12),
                      )
                    : Container(color: Colors.black26, child: const Icon(Icons.person, size: 50)),
                ),
              ),
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87, 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: Colors.amber)
                  ),
                  child: const Row(children: [
                    Icon(Icons.stars, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    Text("ÖNE ÇIKAN ARTİST", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20, 
                  backgroundColor: AppTheme.backgroundColor, 
                  child: Icon(Icons.verified, color: Colors.blue, size: 18)
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text(title, style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ]
                  )
                ),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  child: const Text("Profili Gör", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


  // ÇAĞIRMA KODU//
  //// İstediğin sayfada tek satırla çağırabilirsin
   // FeaturedArtistCard(
   // title: "Viking Tattoo Studio",
   // subtitle: "Kadıköy, İstanbul",
   // imageUrl: ...,
   // onTap: () => ...,
   //  );
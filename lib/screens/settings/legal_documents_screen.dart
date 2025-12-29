import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LegalDocumentsScreen extends StatelessWidget {
  const LegalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Hukuki Metinler', style: TextStyle(color: AppTheme.textColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: AppTheme.textColor),
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Kullanım Şartları'),
              Tab(text: 'Gizlilik Politikası'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildScrollableText(_termsOfService),
            _buildScrollableText(_privacyPolicy),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableText(String text) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.textColor, fontSize: 14, height: 1.5),
      ),
    );
  }

  // --- METİNLER ---
  static const String _termsOfService = """
KULLANIM ŞARTLARI VE KOŞULLARI
Son Güncelleme: Aralık 2025

1. TARAFLAR VE KAPSAM
Bu Kullanım Şartları, TattInk mobil uygulamasını ("Uygulama") kullanan tüm sanatçılar ("Artist") ve kullanıcılar ("Müşteri") için geçerlidir. Uygulamayı indirerek veya kullanarak bu şartları gayrikabili rücu kabul etmiş sayılırsınız.

2. PLATFORMUN ROLÜ (ARACILIK BEYANI)
TattInk, dövme sanatçıları ile müşterileri bir araya getiren dijital bir platformdur.

Uygulama, Artist ile Müşteri arasında gerçekleşen dövme, piercing veya benzeri fiziksel işlemlerin bir tarafı değildir.

Uygulama, bir "İşveren", "Dövme Stüdyosu İşletmecisi" veya "Sağlık Kuruluşu" sıfatına sahip değildir.

Taraflar arasındaki anlaşmazlıklardan (randevu iptali, sonuçtan memnuniyetsizlik, ücret iadesi vb.) Uygulama sorumlu tutulamaz.

3. SAĞLIK VE GÜVENLİK SORUMLULUK REDDİ (KRİTİK)
Dövme ve benzeri vücut sanatı işlemleri deri bütünlüğünü bozan müdahalelerdir.

Tıbbi Sorumluluk: Uygulama üzerinde listelenen Artistlerin hijyen standartlarını, kullanılan boyaların içeriğini veya sterilizasyon süreçlerini denetlemez.

Olası Komplikasyonlar: İşlem sonrası oluşabilecek enfeksiyon, alerjik reaksiyon, skar dokusu (keloid) veya bulaşıcı hastalıklar gibi tıbbi durumlarda tüm sorumluluk işlemi gerçekleştiren Artist ve işlemi kabul eden Müşteri'ye aittir.

Müşteri Yükümlülüğü: Müşteri, varsa kronik hastalıklarını, alerjilerini ve kan yoluyla bulaşan rahatsızlıklarını Artist'e bildirmekle yükümlüdür.

4. YAŞ SINIRI
Uygulama üzerinden randevu oluşturmak için 18 yaşını doldurmuş olmak esastır. 18 yaş altındaki kullanıcıların yasal vasilerinden yazılı izin almaları ve bu izni Artist'e sunmaları kendi sorumluluklarındadır. Uygulama, yaş beyanının doğruluğunu garanti etmez.

5. RANDEVU VE ÖDEME KOŞULLARI
Uygulama üzerinden oluşturulan randevu talepleri birer "ön görüşme" niteliğindedir.

Artist tarafından talep edilebilecek "kapora" veya "ön ödeme" işlemleri Uygulama dışı yöntemlerle (havale/EFT/nakit) yapılıyorsa, bu ödemelerin iadesi ve takibi Uygulama'nın sorumluluğunda değildir.

6. İÇERİK VE FİKRİ MÜLKİYET
Artistler tarafından yüklenen portfolyo görselleri sanatçının kendi mülkiyetindedir.

Kullanıcılar, başkasına ait çalışmaları kendisininmiş gibi yükleyemez. Yapay zeka veya topluluk denetimi tarafından tespit edilen sahte içerikli hesaplar kalıcı olarak uzaklaştırılır.

7. HESAP SİLME VE DURDURMA
Topluluk kurallarını (taciz, hakaret, yanıltıcı bilgi vb.) ihlal eden kullanıcıların hesapları, hiçbir ön ihbara gerek kalmaksızın [Uygulama Adı] yönetimi tarafından askıya alınabilir veya silinebilir.

8. YETKİLİ MAHKEME
Bu sözleşmeden doğacak ihtilaflarda T.C. Bursa Mahkemeleri ve İcra Daireleri yetkilidir. 
""";

  static const String _privacyPolicy = """
GİZLİLİK POLİTİKASI
1. VERİ TOPLAMA
Konum verileriniz sadece en yakın stüdyoları bulmak için kullanılır.

2. MESAJLAŞMA GİZLİLİĞİ
Sohbet içerikleri topluluk kuralları denetimi dışında üçüncü taraflarla paylaşılmaz.
""";
}
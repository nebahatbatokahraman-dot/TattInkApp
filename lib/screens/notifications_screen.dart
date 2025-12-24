import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';
import '../utils/slide_route.dart';
import 'profile/customer_profile_screen.dart';
import 'appointments_screen.dart';
import 'chat_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF161616),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFEBEBEB)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Bildirimler',
            style: TextStyle(color: Color(0xFFEBEBEB)),
          ),
        ),
        body: const Center(
          child: Text(
            'Giriş yapmanız gerekiyor',
            style: TextStyle(color: Color(0xFFEBEBEB)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF161616),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFEBEBEB)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bildirimler',
          style: TextStyle(
            color: Color(0xFFEBEBEB),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.collectionNotifications)
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Yeni bildirimin yok',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.message:
        iconData = Icons.message;
        iconColor = AppTheme.primaryColor;
        break;
      case NotificationType.appointment:
        iconData = Icons.calendar_today;
        iconColor = AppTheme.primaryColor;
        break;
      case NotificationType.like:
        iconData = Icons.favorite;
        iconColor = AppTheme.primaryColor;
        break;
      case NotificationType.follow:
        iconData = Icons.person_add;
        iconColor = AppTheme.primaryColor;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppTheme.primaryColor;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: AppTheme.cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.2),
          child: Icon(iconData, color: iconColor, size: 24),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(
            color: Color(0xFFEBEBEB),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          notification.body,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () => _handleNotificationTap(context, notification),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) async {
    // Mark as read
    await FirebaseFirestore.instance
        .collection(AppConstants.collectionNotifications)
        .doc(notification.id)
        .update({'isRead': true});

    // Navigate based on type
    switch (notification.type) {
      case NotificationType.message:
        // Navigate to messages tab in profile
        Navigator.pop(context); // Close notifications screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              final authService = Provider.of<AuthService>(context, listen: false);
              final userId = authService.currentUser?.uid ?? '';
              return CustomerProfileScreen(userId: userId);
            },
          ),
        );
        // TODO: Navigate to specific message if relatedId is available
        break;
      case NotificationType.appointment:
        // Navigate to appointments
        Navigator.pop(context); // Close notifications screen
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const AppointmentsScreen(),
          ),
        );
        break;
      default:
        // Do nothing for other types
        break;
    }
  }
}


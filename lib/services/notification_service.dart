import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize(Function(String) onNotificationClick) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          print("Notification payload: $payload");
          onNotificationClick(payload);
        }
      },
    );
  }

  static Future<void> handleMessage(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      String? imageUrl = notification.android?.imageUrl;
      print("Received image URL: $imageUrl");

      String? url = message.data['url'];

      bool isValidImage = imageUrl != null && await _isImageUrl(imageUrl);

      if (isValidImage) {
        final bigPictureStyleInformation = BigPictureStyleInformation(
          ByteArrayAndroidBitmap(await _getByteArrayFromUrl(imageUrl!)),
          largeIcon: ByteArrayAndroidBitmap(await _getByteArrayFromUrl(imageUrl)),
          contentTitle: notification.title,
          summaryText: notification.body,
        );

        final androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          styleInformation: bigPictureStyleInformation,
          importance: Importance.max,
        );

        final platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
        );

        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          platformChannelSpecifics,
          payload: url,
        );
      } else {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
            ),
          ),
          payload: url,
        );
      }
    }
  }

  static Future<bool> _isImageUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      final contentType = response.headers['content-type'];
      return contentType != null && contentType.startsWith('image/');
    } catch (e) {
      print(e);
      return false;
    }
  }

  static Future<Uint8List> _getByteArrayFromUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    return response.bodyBytes;
  }
}

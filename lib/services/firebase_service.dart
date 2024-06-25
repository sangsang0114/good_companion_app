import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseService {
  static Function(String)? _getAccessTokenAndSendToBackend;

  static void setGetAccessTokenAndSendToBackend(Function(String) callback) {
    _getAccessTokenAndSendToBackend = callback;
  }

  static Future<void> setupFirebaseMessaging(
      Function(RemoteMessage) onMessage, Function(RemoteMessage) onMessageOpenedApp) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 권한 요청
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen(onMessage);

    // 백그라운드 메시지 처리
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);

    // FCM 토큰 가져오기
    String? token = await messaging.getToken();
    if (token != null) {
      print("FCM Token: $token");
    } else {
      print("Failed to get FCM token");
    }
  }

  static Future<void> getMyDeviceTokenAndSendToBackend() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    if (token != null) {
      print("FCM Token: $token");
      if (_getAccessTokenAndSendToBackend != null) {
        await _getAccessTokenAndSendToBackend!(token);
      } else {
        print("Callback is null");
      }
    } else {
      print("Failed to get FCM token");
    }
  }
}

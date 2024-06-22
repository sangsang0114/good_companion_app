import 'package:firebase_messaging/firebase_messaging.dart';
import 'webview_service.dart';

class FirebaseService {
  static void setupFirebaseMessaging(
      Function(RemoteMessage) onMessage, Function(RemoteMessage) onMessageOpenedApp) {
    FirebaseMessaging.onMessage.listen(onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
  }

  static Future<void> getMyDeviceTokenAndSendToBackend() async {
    final token = await FirebaseMessaging.instance.getToken();
    print("내 디바이스 토큰: $token");

    if (token != null) {
      await WebViewService.sendFcmTokenToBackend(token, null);
    }
  }
}

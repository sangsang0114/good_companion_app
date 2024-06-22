import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:dio/dio.dart';
import 'firebase_service.dart';

class WebViewService {
  static void setupJavaScriptHandlers(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'saveNotificationSettings',
      callback: (args) async {
        await FirebaseService.getMyDeviceTokenAndSendToBackend();
      },
    );
  }

  static Future<void> loadUrl(InAppWebViewController? controller, String url) async {
    if (controller != null) {
      controller.loadUrl(
        urlRequest: URLRequest(url: Uri.parse(url)),
      );
    }
  }

  static Future<NavigationActionPolicy> shouldOverrideUrlLoading(
      InAppWebViewController controller, NavigationAction navigationAction) async {

    var uri = navigationAction.request.url;
    print("tst : : ${uri.toString()}");
    if (uri == null) {
      return NavigationActionPolicy.CANCEL;
    }

    final uriString = uri.toString();
    if (uriString.startsWith('http://') || uriString.startsWith('https://')) {
      print("Allowing URL: $uriString");
      return NavigationActionPolicy.ALLOW;
    } else if (uriString.startsWith('tel:')) {
      final uri = Uri.parse(uriString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        print('Could not launch $uriString');
      }
      return NavigationActionPolicy.CANCEL;
    } else if (uriString.startsWith('intent:')) {
      try {
        print('Handling intent URL: $uriString');
        final intent = AndroidIntent(
          action: 'action_view',
          data: uriString.substring(7),
        );
        await intent.launch();
        return NavigationActionPolicy.CANCEL;
      } catch (e) {
        print('Error handling intent URL: $e');
        final fallbackUrl = Uri.parse(uriString).queryParameters['browser_fallback_url'];
        if (fallbackUrl != null) {
          controller.loadUrl(urlRequest: URLRequest(url: Uri.parse(fallbackUrl)));
          return NavigationActionPolicy.CANCEL;
        }
      }
    }

    return NavigationActionPolicy.CANCEL;
  }

  static Future<String?> getAccessTokenFromLocalStorage(InAppWebViewController? controller) async {
    if (controller != null) {
      final result = await controller.evaluateJavascript(
        source: "sessionStorage.getItem('atk');",
      );
      if (result != null && result is String) {
        // JavaScript 결과가 JSON 문자열로 인코딩되어 있을 수 있으므로 디코딩
        final decodedResult = result.replaceAll('"', '');
        print("accessToken: $decodedResult");
        return decodedResult;
      }
    }
    return null;
  }

  static Future<void> sendFcmTokenToBackend(String token, InAppWebViewController? controller) async {
    print('tests');
    final backendUrl = 'http://good-companion.shop:8080/api/v1/member/update-fcm'; // 백엔드 URL을 여기에 입력하세요
    try {
      final accessToken = await getAccessTokenFromLocalStorage(controller);

      if (accessToken == null) {
        print('accessToken을 가져올 수 없습니다.');
        return;
      }

      final dio = Dio();
      final response = await dio.patch(
        backendUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
        data: {
          'fcmToken': token,
        },
      );

      print("result: ${response.statusCode}");
      if (response.statusCode == 200) {
        print('FCM 토큰 전송 성공');
      } else {
        print('FCM 토큰 전송 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('FCM 토큰 전송 중 오류 발생: $e');
    }
  }
}

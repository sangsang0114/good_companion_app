import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'services/webview_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
    FirebaseService.setGetAccessTokenAndSendToBackend(_getAccessTokenAndSendToBackend);
    FirebaseService.setupFirebaseMessaging(_handleMessage, _handleMessageOpenedApp);
  }

  @override
  void dispose() {
    FirebaseService.setGetAccessTokenAndSendToBackend((_) {});
    super.dispose();
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    await NotificationService.handleMessage(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    if (message.data.containsKey('url')) {
      final url = message.data['url'];
      if (webViewController != null) {
        WebViewService.loadUrl(webViewController, url);
      } else {
        print("webViewController is null");
      }
    }
  }

  Future<void> _getAccessTokenAndSendToBackend(String token) async {
    if (webViewController != null) {
      final accessToken = await WebViewService.getAccessTokenFromLocalStorage(webViewController);
      if (accessToken != null) {
        await WebViewService.sendFcmTokenToBackend(token, webViewController);
      } else {
        print('Failed to get access token');
      }
    } else {
      print('webViewController is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (webViewController != null && await webViewController!.canGoBack()) {
          webViewController!.goBack();
          return false;
        }
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: Uri.parse("https://good-companion.shop"),
                    ),
                    initialOptions: InAppWebViewGroupOptions(
                      crossPlatform: InAppWebViewOptions(
                          javaScriptEnabled: true,
                          useShouldOverrideUrlLoading: true
                      ),
                    ),
                    onWebViewCreated: (controller) {
                      setState(() {
                        webViewController = controller;
                      });
                      WebViewService.setupJavaScriptHandlers(controller);
                    },
                    onLoadStart: (controller, url) {
                      print("Page started loading: ${url.toString()}");
                    },
                    onLoadStop: (controller, url) {
                      print("Page finished loading: ${url.toString()}");
                    },
                    onUpdateVisitedHistory: (controller, url, androidIsReload) {
                      print("Page visited: ${url.toString()}");
                      if (url.toString().contains("/notification-setting")) {
                        controller.evaluateJavascript(source: "window.isFlutterInAppWebView = true;");
                      }
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      return WebViewService.shouldOverrideUrlLoading(controller, navigationAction);
                    },
                    androidOnGeolocationPermissionsShowPrompt: (controller, origin) async {
                      return GeolocationPermissionShowPromptResponse(
                        origin: origin,
                        allow: true,
                        retain: true,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:http/http.dart' as http;
import 'dart:typed_data';

class HttpUtils {
  static Future<bool> isImageUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      final contentType = response.headers['content-type'];
      return contentType != null && contentType.startsWith('image/');
    } catch (e) {
      print(e);
      return false;
    }
  }

  static Future<Uint8List> getByteArrayFromUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    return response.bodyBytes;
  }
}

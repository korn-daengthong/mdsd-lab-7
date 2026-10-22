import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/listing_draft.dart';

class GeminiVisionService {
  GeminiVisionService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-3.8-flash';
  final http.Client _client;
  final bool _ownsClient;

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<ListingDraft> analyzeProductImage(File image) async {
    if (_apiKey.isEmpty) {
      throw const GeminiVisionException(
        'ยังไม่ได้ตั้งค่า GEMINI_API_KEY กรุณาตั้งค่าก่อนใช้งาน',
      );
    }

    final extension = image.path.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
    final imageData = base64Encode(await image.readAsBytes());
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_model:generateContent',
    );
    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'text':
                        'วิเคราะห์ภาพสินค้า เขียนชื่อสินค้า หมวดหมู่ และรายละเอียดภาษาไทย '
                        'ห้ามคาดเดารายละเอียดที่มองไม่เห็น ตอบกลับเป็น JSON เท่านั้น',
                  },
                  {
                    'inline_data': {'mime_type': mimeType, 'data': imageData},
                  },
                ],
              },
            ],
            'generationConfig': {
              'responseMimeType': 'application/json',
              'responseSchema': {
                'type': 'OBJECT',
                'properties': {
                  'title': {'type': 'STRING'},
                  'category': {'type': 'STRING'},
                  'description': {'type': 'STRING'},
                },
                'required': ['title', 'category', 'description'],
              },
            },
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeminiVisionException(
        _apiErrorMessage(response.body, response.statusCode),
      );
    }

    return _parseListingDraft(jsonDecode(response.body));
  }

  String _apiErrorMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic> && error['message'] is String) {
          return error['message'] as String;
        }
      }
    } on FormatException {
      return 'Gemini API ตอบกลับด้วยสถานะ $statusCode';
    }
    return 'Gemini API ตอบกลับด้วยสถานะ $statusCode';
  }

  ListingDraft _parseListingDraft(dynamic responseBody) {
    if (responseBody is! Map<String, dynamic>) {
      throw const FormatException('รูปแบบคำตอบไม่ถูกต้อง');
    }
    final candidates = responseBody['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const FormatException('ไม่พบคำแนะนำในคำตอบ');
    }
    final candidate = candidates.first;
    if (candidate is! Map<String, dynamic>) {
      throw const FormatException('รูปแบบคำตอบไม่ถูกต้อง');
    }
    final content = candidate['content'];
    final parts = content is Map<String, dynamic> ? content['parts'] : null;
    if (parts is! List) {
      throw const FormatException('ไม่พบข้อความคำแนะนำ');
    }
    final text = parts
        .whereType<Map<String, dynamic>>()
        .where((part) => part['thought'] != true)
        .map((part) => part['text'])
        .whereType<String>()
        .join();
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('รูปแบบคำแนะนำไม่ถูกต้อง');
    }
    final title = decoded['title'];
    final category = decoded['category'];
    final description = decoded['description'];
    if (title is! String || category is! String || description is! String) {
      throw const FormatException('ข้อมูลคำแนะนำไม่ครบถ้วน');
    }
    return ListingDraft(
      title: title,
      category: category,
      description: description,
    );
  }
}

class GeminiVisionException implements Exception {
  const GeminiVisionException(this.message);

  final String message;

  @override
  String toString() => message;
}

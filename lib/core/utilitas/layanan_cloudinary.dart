import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../theme/app_constants.dart';

// Helper Terpusat untuk Unggah Gambar ke Cloudinary (Unsigned Upload Preset)
class LayananCloudinary {
  static Future<Map<String, String>?> unggahGambar(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${AppConstants.kCloudinaryCloudName}/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = AppConstants.kCloudinaryUploadPreset
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ));

      final streamedResp = await request.send();
      final resp = await http.Response.fromStream(streamedResp);

      if (resp.statusCode == 200) {
        final jsonResp = json.decode(resp.body);
        final secureUrl = (jsonResp['secure_url'] ?? '').toString();
        final publicId = (jsonResp['public_id'] ?? '').toString();
        if (secureUrl.isNotEmpty) {
          return {
            'secure_url': secureUrl,
            'public_id': publicId,
          };
        }
      }
    } catch (e) {
      debugPrint('Error unggah Cloudinary: $e');
    }
    return null;
  }
}

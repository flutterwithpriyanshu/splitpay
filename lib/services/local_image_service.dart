import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class LocalImageService {
  static Future<Directory> _imagesDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/splitpay_images');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> _profileFile(String uid) async {
    final dir = await _imagesDir();
    return File('${dir.path}/profile_$uid.jpg');
  }

  static Future<File> _friendFile(String friendId) async {
    final dir = await _imagesDir();
    return File('${dir.path}/friend_$friendId.jpg');
  }

  static Future<File?> saveProfileImage(String uid, Uint8List bytes) async {
    final file = await _profileFile(uid);
    return file.writeAsBytes(bytes);
  }

  static Future<File?> getProfileImage(String uid) async {
    final file = await _profileFile(uid);
    return await file.exists() ? file : null;
  }

  static Future<File?> saveFriendImage(String friendId, Uint8List bytes) async {
    final file = await _friendFile(friendId);
    return file.writeAsBytes(bytes);
  }

  static Future<File?> getFriendImage(String friendId) async {
    final file = await _friendFile(friendId);
    return await file.exists() ? file : null;
  }
}

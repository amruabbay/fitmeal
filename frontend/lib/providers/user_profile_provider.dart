import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_meal/models/user_profile.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfile _profile = UserProfile();
  bool _isLoaded = false;

  UserProfile get profile => _profile;
  bool get isLoaded => _isLoaded;
  bool get isOnboardingComplete => _profile.onboardingComplete;

  UserProfileProvider() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('user_profile');
    if (encoded != null) {
      _profile = UserProfile.fromEncodedString(encoded);
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    profile.onboardingComplete = true;
    _profile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', profile.toEncodedString());
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    profile.onboardingComplete = true;
    _profile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', profile.toEncodedString());
    notifyListeners();
  }

  Future<void> resetProfile() async {
    _profile = UserProfile();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile');
    notifyListeners();
  }

  Future<void> updateProfileImage(String imagePath) async {
    final bool isBase64 = _profile.profileImagePath != null && _profile.profileImagePath!.startsWith('data:image/');
    // Delete previous profile photo if it exists (only on non-web platforms and if not base64)
    if (!kIsWeb && !isBase64 && _profile.profileImagePath != null && _profile.profileImagePath!.isNotEmpty) {
      try {
        final oldFile = File(_profile.profileImagePath!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      } catch (e) {
        debugPrint('Error deleting old profile image: $e');
      }
    }


    if (imagePath.isEmpty) {
      _profile.profileImagePath = '';
    } else {
      if (kIsWeb) {
        _profile.profileImagePath = imagePath;
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}_${imagePath.split('/').last}';
        final localFile = File('${appDir.path}/$fileName');
        final savedFile = await File(imagePath).copy(localFile.path);
        _profile.profileImagePath = savedFile.path;
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', _profile.toEncodedString());
    notifyListeners();
  }
}

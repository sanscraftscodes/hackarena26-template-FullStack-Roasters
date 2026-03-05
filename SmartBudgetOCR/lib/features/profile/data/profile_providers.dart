import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/service_locator.dart';
import '../../../models/user_profile.dart';

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ServiceLocator.auth.currentUser;
  if (user == null) return null;
  
  return await ServiceLocator.firestore.getUserProfile(user.uid);
});

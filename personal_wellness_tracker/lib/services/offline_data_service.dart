import 'package:firebase_auth/firebase_auth.dart';
import '../app/database_service.dart';
import 'sync_service.dart';

class OfflineDataService {
  static final OfflineDataService _instance = OfflineDataService._internal();
  factory OfflineDataService() => _instance;
  OfflineDataService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final SyncService _syncService = SyncService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _currentUserId;
    if (uid == null) return null;
    return await _databaseService.getUserProfile(uid);
  }

  Future<void> saveUserProfile(Map<String, dynamic> userProfileData) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception("No authenticated user");
    userProfileData['uid'] = uid;
    await _databaseService.saveUserProfile(userProfileData);
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception("No authenticated user");

    await _databaseService.updateUserProfile(uid, updates);

    _syncService.uploadLocalChangesToFirestore().then((success) {
      if (success) {
        print('✅ Background upload successful.');
      } else {
        print('⚠️ Background upload failed, will retry on next sync.');
      }
    });
  }

  Future<bool> uploadLocalChanges() async {
    print('📤 Checking for local changes to upload...');
    return await _syncService.uploadLocalChangesToFirestore();
  }

  Future<void> addFoodLog({
    required String date,
    required Map<String, dynamic> mealData,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception("No authenticated user");
    await _databaseService.addFoodLog(uid: uid, date: date, mealData: mealData);
  }

  Future<List<Map<String, dynamic>>> getFoodLogsForDate(String date) async {
    final uid = _currentUserId;
    if (uid == null) return [];
    return await _databaseService.getFoodLogsForDate(uid, date);
  }

  Future<void> updateFoodLog({
    required String date,
    required String mealId,
    required Map<String, dynamic> mealData,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception("No authenticated user");
    await _databaseService.updateFoodLog(
      uid: uid,
      date: date,
      mealId: mealId,
      mealData: mealData,
    );
  }

  Future<void> deleteFoodLog({
    required String date,
    required String mealId,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception("No authenticated user");
    await _databaseService.deleteFoodLog(uid: uid, date: date, mealId: mealId);
  }

  // --- Daily Tasks Methods ---

  Future<void> saveDailyTask(
    Map<String, dynamic> taskData,
    DateTime dateTime,
  ) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception("No authenticated user");
    await _databaseService.saveDailyTask(uid, taskData, dateTime);
  }

  Future<Map<String, dynamic>?> getDailyTask(DateTime dateTime) async {
    final uid = _currentUserId;
    if (uid == null) return null;
    return await _databaseService.getDailyTask(uid, dateTime);
  }

  // --- Other Log Methods (Exercise, Water, Sleep, etc.) ---
  // These would follow the same pattern of getting the UID and calling the corresponding _databaseService method.

  // --- Data Aggregation for UI ---

  Future<Map<String, dynamic>> getDashboardData() async {
    final uid = _currentUserId;
    if (uid == null) return {};

    try {
      final today = DateTime.now();
      final todayString =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      // Fetch all data in parallel for better performance
      final results = await Future.wait([
        getFoodLogsForDate(todayString),
        getDailyTask(today),
        getUserProfile(),
        _databaseService.getDataCounts(uid),
      ]);

      final foodLogs = results[0] as List<Map<String, dynamic>>;
      final dailyTask = results[1] as Map<String, dynamic>?;
      final userProfile = results[2] as Map<String, dynamic>?;
      final counts = results[3] as Map<String, int>;

      int totalCalories = foodLogs.fold(
        0,
        (sum, meal) => sum + ((meal['cal'] as int?) ?? 0),
      );

      return {
        'userProfile': userProfile,
        'todayFoodLogs': foodLogs,
        'todayTotalCalories': totalCalories,
        'todayTasks': dailyTask,
        'dataCounts': counts,
        'date': todayString,
      };
    } catch (e) {
      print('Error getting dashboard data: $e');
      return {};
    }
  }

  // --- Sync Methods (Delegation to SyncService) ---

  Future<bool> syncWithFirestore() async {
    return await _syncService.syncUserDataFromFirestore();
  }

  Future<bool> forceSyncFromFirestore() async {
    return await _syncService.forceSyncFromFirestore();
  }

  // --- Utility Methods ---

  Future<bool> hasUserProfile() async {
    final profile = await getUserProfile();
    return profile != null && (profile['profileCompleted'] == true);
  }

  Future<String> getUserDisplayName() async {
    final profile = await getUserProfile();
    final user = _auth.currentUser;

    return profile?['username'] ??
        user?.displayName ??
        user?.email?.split('@').first ??
        'User';
  }

  Future<void> clearAllLocalData() async {
    await _databaseService.clearAllData();
  }
}

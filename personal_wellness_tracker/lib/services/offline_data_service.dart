import 'package:firebase_auth/firebase_auth.dart';
import '../app/database_service.dart';
import '../services/sync_service.dart';

class OfflineDataService {
  static final OfflineDataService _instance = OfflineDataService._internal();
  factory OfflineDataService() => _instance;
  OfflineDataService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final SyncService _syncService = SyncService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Initialize the service (removed auto sync since we sync on login)
  Future<void> initialize() async {
    print('🔧 Initializing OfflineDataService...');
    // Just initialize the database, no sync needed here
  }

  // User Profile Methods
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _currentUserId;
    if (uid == null) return null;

    return await _databaseService.getUserProfile(uid);
  }

  Future<void> saveUserProfile(Map<String, dynamic> userProfileData) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception("No authenticated user");

    // Add uid to the data
    userProfileData['uid'] = uid;
    await _databaseService.saveUserProfile(userProfileData);
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception("No authenticated user");

    await _databaseService.updateUserProfile(uid, updates);
  }

  // Food Log Methods
  Future<void> addFoodLog({
    required String date,
    required Map<String, dynamic> mealData,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception("No authenticated user");

    await _databaseService.addFoodLog(
      uid: uid,
      date: date,
      mealData: mealData,
    );
  }

  Future<List<Map<String, dynamic>>> getFoodLogsForDate(String date) async {
    final uid = _currentUserId;
    if (uid == null) {
      print('❌ No user ID found for getFoodLogsForDate');
      return [];
    }

    print('📊 Getting food logs for date: $date, uid: $uid');
    final result = await _databaseService.getFoodLogsForDate(uid, date);
    print('📊 Found ${result.length} food logs for date: $date');
    
    return result;
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

    await _databaseService.deleteFoodLog(
      uid: uid,
      date: date,
      mealId: mealId,
    );
  }

  // Daily Tasks Methods
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
    if (uid == null) {
      print('🚫 getDailyTask: No current user ID found');
      return null;
    }
    
    final dateString = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    print('🔍 getDailyTask: Fetching for uid=$uid, date=$dateString');

    final result = await _databaseService.getDailyTask(uid, dateTime);
    
    if (result != null) {
      print('✅ getDailyTask: Found task data with ${result.keys.length} keys: ${result.keys.toList()}');
      result.forEach((key, value) {
        print('   - $key: $value');
      });
    } else {
      print('❌ getDailyTask: No task data found for $dateString');
    }
    
    return result;
  }

  // Exercise Log Methods
  Future<void> saveExerciseLog({
    required String date,
    required String exerciseType,
    required int durationMinutes,
    required int caloriesBurned,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception("No authenticated user");

    await _databaseService.saveExerciseLog(
      uid: uid,
      date: date,
      exerciseType: exerciseType,
      durationMinutes: durationMinutes,
      caloriesBurned: caloriesBurned,
    );
  }

  // Water Log Methods
  Future<void> saveWaterLog({
    required String date,
    required int totalCups,
    required int targetCups,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception("No authenticated user");

    await _databaseService.saveWaterLog(
      uid: uid,
      date: date,
      totalCups: totalCups,
      targetCups: targetCups,
    );
  }

  // Sleep Log Methods
  Future<void> saveSleepLog({
    required String date,
    required String sleepStart,
    required String sleepEnd,
    required int durationMinutes,
    required int quality,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception("No authenticated user");

    await _databaseService.saveSleepLog(
      uid: uid,
      date: date,
      sleepStart: sleepStart,
      sleepEnd: sleepEnd,
      durationMinutes: durationMinutes,
      quality: quality,
    );
  }

  // Mood Log Methods
  Future<void> saveMoodLog({
    required String date,
    required int moodLevel,
    required String moodDescription,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw Exception("No authenticated user");

    await _databaseService.saveMoodLog(
      uid: uid,
      date: date,
      moodLevel: moodLevel,
      moodDescription: moodDescription,
    );
  }

  // Statistics and Analytics Methods
  Future<Map<String, dynamic>> getDashboardData() async {
    final uid = _currentUserId;
    if (uid == null) return {};

    try {
      final today = DateTime.now();
      final todayString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      
      // Get today's data
      final foodLogs = await getFoodLogsForDate(todayString);
      final dailyTask = await getDailyTask(today);
      final userProfile = await getUserProfile();

      // Calculate total calories for today
      int totalCalories = 0;
      for (final meal in foodLogs) {
        totalCalories += (meal['cal'] as int?) ?? 0;
      }

      // Get data counts
      final counts = await _databaseService.getDataCounts(uid);

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

  // Sync Methods
  Future<bool> syncWithFirestore() async {
    return await _syncService.syncUserDataFromFirestore();
  }

  Future<Map<String, dynamic>> getDataStatus() async {
    return await _syncService.getLocalDataStatus();
  }

  Future<bool> forceSyncFromFirestore() async {
    return await _syncService.forceSyncFromFirestore();
  }

  // Weekly/Monthly Statistics (example methods)
  Future<Map<String, dynamic>> getWeeklyCalorieStats() async {
    final uid = _currentUserId;
    if (uid == null) return {};

    try {
      final now = DateTime.now();
      Map<String, int> weeklyCalories = {};
      
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        
        final foodLogs = await getFoodLogsForDate(dateString);
        int dayCalories = 0;
        
        for (final meal in foodLogs) {
          dayCalories += (meal['cal'] as int?) ?? 0;
        }
        
        weeklyCalories[dateString] = dayCalories;
      }

      return {
        'weeklyCalories': weeklyCalories,
        'period': '7days',
      };
    } catch (e) {
      print('Error getting weekly calorie stats: $e');
      return {};
    }
  }

  // Utility Methods
  Future<bool> hasUserProfile() async {
    final profile = await getUserProfile();
    return profile != null && (profile['profileCompleted'] == true);
  }

  Future<void> clearAllLocalData() async {
    await _databaseService.clearAllData();
  }

  // Get user display name
  Future<String> getUserDisplayName() async {
    final profile = await getUserProfile();
    final user = _auth.currentUser;
    
    return profile?['username'] ?? 
           user?.displayName ?? 
           user?.email?.split('@').first ?? 
           'User';
  }
}

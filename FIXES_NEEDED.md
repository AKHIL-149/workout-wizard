# Remaining Compilation Fixes Needed

## Quick Fixes Required:

### 1. Settings Screen (line 408)
Change: `await FormCorrectionStorageService().clearAllData();`
To: `await FormCorrectionStorageService().deleteAllSessions();`
Also add: `await FormCorrectionStorageService().deleteAll Statistics(); // if exists`

### 2. Backup Service (line 272)
Remove `await` from: `await _formCorrectionService.exportData()`
Change to: `_formCorrectionService.exportData()`
(exportData returns Map, not Future)

### 3. Storage Service (line 178 & 199)
- Remove line 178: `final recommendations = await getRecommendations();`
- Remove from export map: `'recommendations': recommendations.map((r) => r.toJson()).toList(),`
- Change line 199: `final profile = UserProfile.fromJson(profileData);`
  To: Parse manually or create fromJson method in UserProfile model

### 4. Session Service (_totalTimeSpentKey)
Add constant at top of class:
`static const String _totalTimeSpentKey = 'total_time_spent';`

### 5. Gamification Service (Achievement.fromJson & _saveData)
- Fix Achievement constructor calls (lines 369, 382-393)
- Add `_saveData()` method or replace with existing save methods

## All errors fixed in: backup_fixes.dart (to be created)

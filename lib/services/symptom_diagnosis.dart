import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiagnosisResult {
  final List<String> suspectedDiseases;
  final Map<String, List<String>> matchedSymptoms;
  final Map<String, int> scores;
  final DateTime timestamp;

  DiagnosisResult({
    required this.suspectedDiseases,
    required this.matchedSymptoms,
    required this.scores,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isHealthy => suspectedDiseases.isEmpty;

  Map<String, dynamic> toMap() {
    return {
      'suspectedDiseases': suspectedDiseases,
      'matchedSymptoms': matchedSymptoms,
      'scores': scores,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class SymptomDiagnosis {
  // Define the canonical symptom lists for each disease
  static const List<String> brownSpot = [
    'Brown Spots',
    'Gray Centers',
    'Drying Leaves',
    'Poor Grains',
    'Leaf Death',
  ];

  static const List<String> rys = [
    'Yellow Leaves',
    'Stunted Growth',
    'Excess Tillers',
    'Twisted Leaves',
    'Empty Grains',
  ];

  static const List<String> sheathBlight = [
    'Wet Spots',
    'Gray Patches',
    'Fast Spread',
    'Dry Leaves',
    'Sclerotia/Black Spot-like',
  ];

  // Diagnose based on simple scoring: each symptom matched increases the disease score.
  // If a disease has at least 2 matched symptoms OR >=50% of its known symptoms matched,
  // it will be considered suspected. Multiple diseases can be suspected.
  static DiagnosisResult diagnose(List<String> selectedSymptoms) {
    // Normalize symptoms (strip translations in parentheses) before matching
    String normalize(String s) {
      final idx = s.indexOf('(');
      if (idx >= 0) return s.substring(0, idx).trim();
      return s.trim();
    }

    final sel = selectedSymptoms.map((s) => normalize(s)).toSet();

    final Map<String, int> scores = {
      'Brown Spot Disease': 0,
      'Rice Yellowing Syndrome': 0,
      'Sheath Blight': 0,
    };

    final Map<String, List<String>> matched = {
      'Brown Spot Disease': [],
      'Rice Yellowing Syndrome': [],
      'Sheath Blight': [],
    };

    for (final s in sel) {
      if (brownSpot.contains(s)) {
        scores['Brown Spot Disease'] = scores['Brown Spot Disease']! + 1;
        matched['Brown Spot Disease']!.add(s);
      }
      if (rys.contains(s)) {
        scores['Rice Yellowing Syndrome'] =
            scores['Rice Yellowing Syndrome']! + 1;
        matched['Rice Yellowing Syndrome']!.add(s);
      }
      if (sheathBlight.contains(s)) {
        scores['Sheath Blight'] = scores['Sheath Blight']! + 1;
        matched['Sheath Blight']!.add(s);
      }
    }

    List<String> suspected = [];

    // Helper to decide if disease should be suspected
    bool shouldSuspect(int matches, int total) {
      if (matches >= 2) return true;
      if (total > 0 && (matches / total) >= 0.5) return true;
      return false;
    }

    if (shouldSuspect(scores['Brown Spot Disease']!, brownSpot.length)) {
      suspected.add('Brown Spot Disease');
    }
    if (shouldSuspect(scores['Rice Yellowing Syndrome']!, rys.length)) {
      suspected.add('Rice Yellowing Syndrome');
    }
    if (shouldSuspect(scores['Sheath Blight']!, sheathBlight.length)) {
      suspected.add('Sheath Blight');
    }

    return DiagnosisResult(
      suspectedDiseases: suspected,
      matchedSymptoms: matched,
      scores: scores,
    );
  }

  // Persist diagnosis to Firestore. If plotId is provided, save under that plot's subcollection
  // and update the plot document with a `status` and `lastDiagnosis`. Otherwise save under
  // users/{uid}/diagnoses.
  static Future<void> saveDiagnosisToFirestore(
    DiagnosisResult result, {
    String? plotId,
    String? changesDescription,
    List<String>? originalSelectedSymptoms,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('User must be signed in to save diagnosis');
    }

    final base = FirebaseFirestore.instance.collection('users').doc(user.uid);

    final entry = {
      'selectedSymptoms':
          originalSelectedSymptoms ??
          result.matchedSymptoms.values.expand((e) => e).toList(),
      'matchedSymptoms': result.matchedSymptoms,
      'suspectedDiseases': result.suspectedDiseases,
      'scores': result.scores,
      'timestamp': Timestamp.fromDate(result.timestamp),
      'changes': changesDescription ?? '',
      'userId': user.uid,
    };

    if (plotId != null && plotId.isNotEmpty) {
      // add to subcollection
      await base
          .collection('plots')
          .doc(plotId)
          .collection('diagnoses')
          .add(entry);

      // update plot status + lastDiagnosis using set with merge to avoid permission issues
      final status = result.isHealthy
          ? 'Healthy'
          : result.suspectedDiseases.join(', ');
      final plotUpdate = {
        'status': status,
        'lastDiagnosis': entry,
        'lastDiagnosisAt': Timestamp.fromDate(result.timestamp),
        'symptoms': originalSelectedSymptoms ?? entry['selectedSymptoms'],
        'ownerUid': user.uid,
      };

      await base
          .collection('plots')
          .doc(plotId)
          .set(plotUpdate, SetOptions(merge: true));
    } else {
      // save to top-level diagnoses collection for user
      await base.collection('diagnoses').add(entry);
    }
  }
}

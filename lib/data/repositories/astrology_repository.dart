import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/birth_chart.dart';
import '../models/planet_position.dart';

/// Repository for managing birth chart and astrology data in Firestore.
class AstrologyRepository {
  AstrologyRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _userId => _auth.currentUser?.uid ?? '';

  static const String _birthChartsCollection = 'birth_charts';

  /// Create or update a birth chart
  Future<BirthChart> saveBirthChart(BirthChart birthChart) async {
    final docRef =
        _firestore.collection(_birthChartsCollection).doc(_userId);
    
    final data = birthChart.toMap();
    await docRef.set(data, SetOptions(merge: true));
    
    return birthChart.copyWith(id: _userId);
  }

  /// Get user's birth chart
  Future<BirthChart?> getBirthChart() async {
    try {
      final doc = await _firestore
          .collection(_birthChartsCollection)
          .doc(_userId)
          .get();
      
      if (!doc.exists) return null;
      return BirthChart.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Get another user's birth chart by their ID
  Future<BirthChart?> getUserBirthChart(String userId) async {
    try {
      final doc = await _firestore
          .collection(_birthChartsCollection)
          .doc(userId)
          .get();
      
      if (!doc.exists) return null;
      return BirthChart.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Stream birth chart updates
  Stream<BirthChart?> watchBirthChart() {
    return _firestore
        .collection(_birthChartsCollection)
        .doc(_userId)
        .snapshots()
        .map((doc) => doc.exists ? BirthChart.fromFirestore(doc) : null);
  }

  /// Get planet positions for a user
  Future<List<PlanetPosition>> getPlanetPositions() async {
    try {
      final birthChart = await getBirthChart();
      if (birthChart == null) return [];
      
      return birthChart.planets.values.toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Update planet positions in birth chart
  Future<void> updatePlanetPositions(Map<String, PlanetPosition> planets) async {
    final birthChart = await getBirthChart();
    if (birthChart == null) throw Exception('Birth chart not found');
    
    await saveBirthChart(birthChart.copyWith(planets: planets));
  }

  /// Get houses for a user
  Future<List<HouseData>> getHouses() async {
    try {
      final birthChart = await getBirthChart();
      if (birthChart == null) return [];
      
      return birthChart.houses.values.toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Update houses in birth chart
  Future<void> updateHouses(Map<String, HouseData> houses) async {
    final birthChart = await getBirthChart();
    if (birthChart == null) throw Exception('Birth chart not found');
    
    await saveBirthChart(birthChart.copyWith(houses: houses));
  }

  /// Get aspects for a user
  Future<List<AspectData>> getAspects() async {
    try {
      final birthChart = await getBirthChart();
      if (birthChart == null) return [];
      
      return birthChart.aspects;
    } catch (e) {
      rethrow;
    }
  }

  /// Update aspects in birth chart
  Future<void> updateAspects(List<AspectData> aspects) async {
    final birthChart = await getBirthChart();
    if (birthChart == null) throw Exception('Birth chart not found');
    
    await saveBirthChart(birthChart.copyWith(aspects: aspects));
  }

  /// Delete birth chart
  Future<void> deleteBirthChart() async {
    try {
      await _firestore
          .collection(_birthChartsCollection)
          .doc(_userId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate cosmic energy based on current planetary positions
  Future<double> calculateCosmicEnergy() async {
    try {
      final birthChart = await getBirthChart();
      if (birthChart == null) return 0.0;
      
      // Calculate based on aspect harmony and planet positions
      double energy = 50.0;
      
      // Add points for harmonious aspects
      for (final aspect in birthChart.aspects) {
        if (aspect.type == 'trine' || aspect.type == 'sextile') {
          energy += 5;
        } else if (aspect.type == 'square' || aspect.type == 'opposition') {
          energy -= 3;
        }
      }
      
      // Normalize to 0-100 range
      return energy.clamp(0.0, 100.0);
    } catch (e) {
      rethrow;
    }
  }
}

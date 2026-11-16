import '../core/member_colors.dart';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'models.dart';

/// All Firebase access lives here. Firestore's offline cache makes every write
/// instant locally and uploads it when the device is online.
class Repository {
  Repository({FirebaseAuth? auth, FirebaseFirestore? db})
      : auth = auth ?? FirebaseAuth.instance,
        db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth auth;
  final FirebaseFirestore db;

  // ---------- auth ----------
  Stream<User?> authChanges() => auth.userChanges(); // also fires when a guest links Google

  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});
    if (kIsWeb) {
      await auth.signInWithPopup(provider);
    } else {
      await auth.signInWithProvider(provider);
    }
  }

  Future<void> signInAsGuest() => auth.signInAnonymously();

  bool get isGuest => auth.currentUser?.isAnonymous ?? false;

  /// Upgrades a guest to a Google account. The uid stays the same, so every
  /// log, pair and setting carries over.
  Future<void> linkGoogle() async {
    final provider = GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});
    final user = auth.currentUser!;
    if (kIsWeb) {
      await user.linkWithPopup(provider);
    } else {
      await user.linkWithProvider(provider);
    }
  }

  Future<void> signOut() => auth.signOut();

  // ---------- profile ----------
  DocumentReference<Map<String, dynamic>> _user(String uid) => db.collection('users').doc(uid);

  Stream<UserProfile?> watchProfile(String uid) =>
      _user(uid).snapshots().map((s) => s.exists ? UserProfile.fromMap(uid, s.data()!) : null);

  Future<void> saveProfile(String uid, Map<String, dynamic> fields) =>
      _user(uid).set({...fields, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

  // ---------- pairs ----------
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I

  String _newCode() {
    final r = math.Random.secure();
    return List.generate(6, (_) => _alphabet[r.nextInt(_alphabet.length)]).join();
  }

  /// Creates a pair with me as the only member and returns its code.
  /// [name] and [color] are copied onto the pair so a joiner can check for a
  /// color clash before they're allowed to read the inviter's profile.
  Future<String> createInvite(String uid, {required String name, required int color}) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _newCode();
      final ref = db.collection('pairs').doc(code);
      try {
        await db.runTransaction((tx) async {
          final snap = await tx.get(ref);
          if (snap.exists) throw StateError('taken');
          tx.set(ref, {'members': [uid], 'ownerName': name, 'ownerColor': color, 'createdAt': FieldValue.serverTimestamp()});
          tx.set(_user(uid), {'pairId': code}, SetOptions(merge: true));
        });
        return code;
      } on StateError {
        continue;
      }
    }
    throw StateError('Could not create an invite code. Try again.');
  }

  /// An open pair's members and the inviter's name/color, or null if the code doesn't exist.
  Future<({List<String> members, String ownerName, int ownerColor})?> pairInfo(String code) async {
    final s = await db.collection('pairs').doc(code.toUpperCase()).get();
    if (!s.exists) return null;
    final d = s.data()!;
    return (
      members: (d['members'] as List).cast<String>(),
      ownerName: (d['ownerName'] as String?) ?? 'Your partner',
      ownerColor: storedColor((d['ownerColor'] as num?)?.toInt()).toARGB32(),
    );
  }

  /// Joins an existing pair. Throws a [PairError] with a readable message.
  Future<void> joinPair(String uid, String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    final ref = db.collection('pairs').doc(code);
    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw const PairError('No partner found with that code. Check it and try again.');
      final members = (snap.data()!['members'] as List).cast<String>();
      if (members.contains(uid)) return;
      if (members.length >= 2) throw const PairError('That code is already used by a pair.');
      tx.update(ref, {'members': FieldValue.arrayUnion([uid])});
      tx.set(_user(uid), {'pairId': code}, SetOptions(merge: true));
    });
  }

  Stream<List<String>> watchPairMembers(String code) =>
      db.collection('pairs').doc(code).snapshots().map((s) => s.exists ? (s.data()!['members'] as List).cast<String>() : <String>[]);

  Future<void> leavePair(String uid, String code) async {
    final batch = db.batch();
    batch.update(db.collection('pairs').doc(code), {'members': FieldValue.arrayRemove([uid])});
    batch.set(_user(uid), {'pairId': FieldValue.delete()}, SetOptions(merge: true));
    await batch.commit();
  }

  // ---------- days ----------
  DocumentReference<Map<String, dynamic>> _day(String uid, String key) => _user(uid).collection('days').doc(key);

  Stream<DayLog> watchDay(String uid, String key) => _day(uid, key).snapshots().map((s) => DayLog.fromMap(s.data()));

  /// Last [days] days keyed by yyyy-MM-dd.
  Stream<Map<String, DayLog>> watchHistory(String uid, {int days = 60}) {
    final from = dayKey(DateTime.now().subtract(Duration(days: days)));
    return _user(uid)
        .collection('days')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: from)
        .snapshots()
        .map((q) => {for (final d in q.docs) d.id: DayLog.fromMap(d.data())});
  }

  /// Logs between two yyyy-MM-dd keys, inclusive.
  Stream<Map<String, DayLog>> watchRange(String uid, String from, String to) => _user(uid)
      .collection('days')
      .where(FieldPath.documentId, isGreaterThanOrEqualTo: from)
      .where(FieldPath.documentId, isLessThanOrEqualTo: to)
      .snapshots()
      .map((q) => {for (final d in q.docs) d.id: DayLog.fromMap(d.data())});

  Future<void> setDeed(String uid, String key, Deed deed, bool done) => _day(uid, key).set({
        'deeds': done ? FieldValue.arrayUnion([deed.name]) : FieldValue.arrayRemove([deed.name]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> setPrayed(String uid, String key, Prayer p, bool prayed) => _day(uid, key).set({
        'prayed': prayed ? FieldValue.arrayUnion([p.name]) : FieldValue.arrayRemove([p.name]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> addCounts(String uid, String key, {int ayat = 0, int istighfar = 0}) => _day(uid, key).set({
        if (ayat != 0) 'ayat': FieldValue.increment(ayat),
        if (istighfar != 0) 'istighfar': FieldValue.increment(istighfar),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  /// Deletes every log, the profile, the pair membership and the login.
  Future<void> deleteAccount(String uid, String? pairId) async {
    final user = auth.currentUser;
    // Google accounts must have signed in recently; ask again first so we
    // never delete the data but fail to delete the login.
    if (user != null && !user.isAnonymous) {
      final provider = GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});
      if (kIsWeb) {
        await user.reauthenticateWithPopup(provider);
      } else {
        await user.reauthenticateWithProvider(provider);
      }
    }
    if (pairId != null) {
      try {
        await leavePair(uid, pairId);
      } catch (_) {}
    }
    final days = await _user(uid).collection('days').get();
    var batch = db.batch();
    var n = 0;
    for (final d in days.docs) {
      batch.delete(d.reference);
      if (++n % 400 == 0) {
        await batch.commit();
        batch = db.batch();
      }
    }
    batch.delete(_user(uid));
    await batch.commit();
    await user?.delete();
  }

  Future<void> addAyat(String uid, String key, int n) =>
      _day(uid, key).set({'ayat': FieldValue.increment(n), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

  Future<void> addIstighfar(String uid, String key, int n) =>
      _day(uid, key).set({'istighfar': FieldValue.increment(n), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
}

class PairError implements Exception {
  const PairError(this.message);
  final String message;
  @override
  String toString() => message;
}

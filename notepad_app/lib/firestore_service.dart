import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getNotes() async {
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await _db.collection('notes').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<DocumentReference<Map<String, dynamic>>> addNote(
      String content) async {
    return await _db.collection('notes').add({'content': content});
  }

  Future<void> updateNote(String id, String newContent) async {
    await _db.collection('notes').doc(id).update({'content': newContent});
  }

  Future<void> deleteNote(String id) async {
    await _db.collection('notes').doc(id).delete();
  }
}

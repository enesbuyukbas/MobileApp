import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String content;

  Note({
    required this.id,
    required this.content,
  });
}

abstract class FirestoreService {
  Future<List<Note>> getNotes();

  Future<DocumentReference> addNote(String content);

  Future<void> updateNote(String id, String newContent);

  Future<void> deleteNote(String id);
}

class FirestoreServiceImpl implements FirestoreService {
  final CollectionReference _notesCollection =
      FirebaseFirestore.instance.collection('notes');

  @override
  Future<List<Note>> getNotes() async {
    QuerySnapshot<Object?> snapshot = await _notesCollection.get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return Note(
        id: doc.id,
        content: data['content'] as String,
      );
    }).toList();
  }

  @override
  Future<DocumentReference> addNote(String content) async {
    return await _notesCollection.add({'content': content});
  }

  @override
  Future<void> updateNote(String id, String newContent) async {
    await _notesCollection.doc(id).update({'content': newContent});
  }

  @override
  Future<void> deleteNote(String id) async {
    await _notesCollection.doc(id).delete();
  }
}

void main() async {
  FirestoreService firestoreService = FirestoreServiceImpl();

  List<Note> notes = await firestoreService.getNotes();
  print('Mevcut Notlar:');
  notes.forEach((note) {
    print('ID: ${note.id}, İçerik: ${note.content}');
  });

  String newNoteContent = 'Bu yeni bir nottur.';
  DocumentReference newNoteRef = await firestoreService.addNote(newNoteContent);
  print('Yeni not eklendi, ID: ${newNoteRef.id}');

  String noteIdToUpdate = 'güncellenecek_not_id';
  String updatedContent = 'Güncellenmiş not içeriği.';
  await firestoreService.updateNote(noteIdToUpdate, updatedContent);
  print('IDsi $noteIdToUpdate olan not güncellendi.');

  String noteIdToDelete = 'silinecek_not_id';
  await firestoreService.deleteNote(noteIdToDelete);
  print('IDsi $noteIdToDelete olan not silindi.');
}
